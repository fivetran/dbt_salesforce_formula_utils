# Using `fivetran/salesforce_formula_utils` with Snowflake + Fivetran MDLS

This guide covers the architecture decision you need to make before writing
any dbt code when running this package against Salesforce data landed by
Fivetran's Managed Data Lake Service (MDLS), with **Snowflake** as the query
engine.

## 1. The common architecture

Fivetran syncs Salesforce and lands the data as **Apache Iceberg** tables in
cloud object storage, cataloged in a Fivetran-hosted **Polaris** (Iceberg
REST) catalog. This is true no matter which Snowflake pattern you pick below.

Two things matter specifically for `salesforce_formula_utils`:

- **Raw object tables** (`account`, `contact`, `opportunity`, `user_role`, ...)
  land as ordinary Iceberg tables, one per Salesforce object.
- **`fivetran_formula_model`** is a special metadata table Fivetran also
  lands. Salesforce formula fields (fields computed from other fields) aren't
  stored values — Salesforce computes them at read time, and Fivetran can't
  replicate that computation as static data. Instead, `fivetran_formula_model`
  ships the *computation itself* as generated SQL text: one row per
  Salesforce object per target query engine (`object`, `query_engine`,
  `model`, `_fivetran_synced` columns). `salesforce_formula_utils.sfdc_formula_view()`
  reads the right row for your engine and materializes it as a model.

**Prerequisite this guide assumes you've already done:** created a Snowflake
[catalog integration](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-catalog-integration-rest)
pointing at the Fivetran-hosted Polaris catalog (`CATALOG_SOURCE = ICEBERG_REST`).
That step is Fivetran/MDLS-side setup and isn't covered here — this guide
picks up right after it, at the decision you make *inside* Snowflake with
that integration in hand.

## 2. The decision: how do you expose that catalog inside Snowflake?

Once a catalog integration exists, Snowflake gives you two structurally
different ways to consume (and write to) it.

### Path A — Catalog-Linked Database (CLD)

A CLD is a Snowflake database object that stays **continuously, automatically
synced** to the remote catalog:

```sql
CREATE DATABASE my_lakehouse
  LINKED_CATALOG = (
    CATALOG = 'my_polaris_catalog_integration'
    ALLOWED_WRITE_OPERATIONS = ALL      -- default; set NONE for read-only
    SYNC_INTERVAL_SECONDS = 30          -- default; range 30–86400
  )
  EXTERNAL_VOLUME = 'my_external_volume';  -- omit if using vended credentials
```

Snowflake polls the remote catalog on `SYNC_INTERVAL_SECONDS` (default 30s).
Every namespace in Polaris shows up as a schema automatically; every table
shows up as an **externally managed Iceberg table** automatically — no
manual registration, ever. This includes every new Salesforce object a
customer enables in Fivetran later.

**dbt config for this path:**
```yml
# catalogs.yml
catalogs:
  - name: my_catalog_writer
    active_write_integration: snowflake_write_integration
    write_integrations:
      - name: snowflake_write_integration
        table_format: iceberg
        catalog_type: iceberg_rest
        adapter_properties:
          auto_refresh: true
          iceberg_version: 3
          catalog_linked_database: my_lakehouse   # the CLD's name
```

```yml
# dbt_project.yml
models:
  +table_format: iceberg
  +catalog_name: my_catalog_writer
```

**Best practices:**
- **Always set `iceberg_version: 3` explicitly.** Snowflake's default Iceberg
  format is still v2, which only supports microsecond-precision timestamps.
  Salesforce formula output frequently includes nanosecond-precision
  timestamp expressions (e.g. anything derived from `SYSDATE()`), which
  require v3.
- **Materialize as `table`, never `view`.** CLDs only support schemas,
  externally managed Iceberg tables, and database roles — nothing else. A
  view will fail with `This operation is not supported in a catalog-linked
  database`.
- Make sure `ALLOWED_WRITE_OPERATIONS = ALL` is set on the CLD (it's the
  default, but confirm) — `NONE` makes it read-only and every dbt write
  fails.
- Use **`fivetran/salesforce_formula_utils` v0.12.0 or later.** Earlier
  versions fail against CLD sources with a `load_relation()` error inside
  `dbt_utils.get_column_values()`.

**Drawbacks:**
- No views, dynamic tables, streams, tasks, or any non-Iceberg object type —
  the whole database is locked to that restricted object set.
- No cloning, no `UNDROP ICEBERG TABLE`, no replication of the database
  itself, no listings-based sharing (direct sharing is fine).
- Only *position* deletes are supported; equality deletes aren't.
- v2→v3 Iceberg format upgrades are one-way; there's no downgrading or
  in-place upgrading of an existing v2 table.
- If you're on dbt-fusion and try the newer `catalogs.yml` **v2 spec**, be
  aware that some preview builds silently drop `iceberg_version` for CLD
  targets, which downgrades new tables to v2 and can reintroduce the
  nanosecond-timestamp failure above. Stick with the spec shown here until
  that's confirmed fixed for your dbt-fusion version.

### Path B — Individually-registered Iceberg tables in a native database

Instead of linking a whole database, you register specific tables one at a
time inside an ordinary, otherwise-native Snowflake database:

```sql
CREATE ICEBERG TABLE my_native_db.salesforce.account
  EXTERNAL_VOLUME = 'my_external_volume'
  CATALOG = 'my_polaris_catalog_integration'
  CATALOG_NAMESPACE = 'salesforce'
  CATALOG_TABLE_NAME = 'account'
  AUTO_REFRESH = TRUE;
```

No column definitions — Snowflake reads the schema from the remote table's
own metadata. You do this once per table you want visible; nothing else in
Polaris shows up until you explicitly register it.

**Refresh behavior is per-table, not automatic-by-database:**
- `AUTO_REFRESH = TRUE` polls on the *catalog integration's*
  `REFRESH_INTERVAL_SECONDS` (default 30s) for new snapshots/data.
- Even with auto-refresh on, **schema-only changes at the remote catalog
  (e.g. a new column with no accompanying data write) aren't reliably
  picked up** — run `ALTER ICEBERG TABLE <name> REFRESH;` manually when that
  happens.
- If you leave `AUTO_REFRESH` off, every snapshot needs a manual
  `ALTER ... REFRESH`. There's no CLD-style whole-database sync backing this.

**What you get in exchange:** a completely ordinary native Snowflake
database. Views, dynamic tables, streams, tasks, cloning of everything
*except* the Iceberg tables themselves, replication — all work normally, and
coexist with the registered Iceberg tables without restriction.

**dbt config for reading from this path:** Since these are just native
tables from dbt's point of view, no special `catalogs.yml` entry is required
to *read* them. Only a `source` configuration is necessary:
```yml
# models/sources.yml
sources:
  - name: salesforce
    database: my_native_db
    schema: salesforce
    tables: [account, user_role, fivetran_formula_model]
```

**dbt config for writing from this path** — write plain Snowflake objects,
not new Iceberg tables, by pointing at the native database directly and
opting out of the Iceberg catalog machinery:
```yml
# dbt_project.yml
models:
  +table_format: iceberg
  +catalog_name: # unset the project's default Iceberg catalog
  +database: my_native_db
```

**Not yet validated:** having *dbt itself* create new, individually-cataloged
(non-CLD) Iceberg tables via `catalogs.yml`. If you need dbt to *write new
Iceberg tables* under Path B (as opposed to writing plain views/tables, or
reading pre-registered Iceberg tables), test that specifically — don't
assume it works the same way as Path A.

**Best practices:**
- Use this path when you only need a **curated subset** of the MDLS catalog —
  a handful of objects sitting alongside an existing native-database-centric
  warehouse — and specifically want views, streams, tasks, or cloning that a
  CLD structurally can't offer.
- Budget for registration overhead: every new Salesforce object Fivetran adds
  later needs an explicit `CREATE ICEBERG TABLE` here. Nothing appears
  automatically the way it does in a CLD.
- Still use v0.12.0+ of the package — the MDLS compatibility fix in the macro
  itself (detecting the `query_engine` column) applies regardless of which
  Snowflake pattern reads the table.

**Drawbacks:**
- Manual, ongoing registration effort — no auto-discovery of new
  tables/namespaces at all.
- Per-table refresh management (`AUTO_REFRESH` + periodic manual
  `ALTER ... REFRESH` for schema-only changes).
- Time travel only covers snapshots since your refresh history began, not the
  table's full remote history.
- No cloning of the Iceberg tables themselves (native objects around them
  clone fine).
- Streams on these tables must be `INSERT_ONLY = TRUE`.

### Decision summary

| | CLD | Individually-registered |
|---|---|---|
| New Salesforce objects appear automatically | Yes | No — manual `CREATE ICEBERG TABLE` per table |
| Views / streams / tasks / cloning | No | Yes |
| Refresh model | Whole-database, implicit | Per-table, explicit |
| Best fit | Consuming most/all of an MDLS catalog that changes continuously | A curated subset sitting next to an existing native warehouse |

**Recommendation for `salesforce_formula_utils` specifically:** since the
package is meant to reconstruct formula fields across potentially every
synced Salesforce object, and Fivetran/MDLS creates and updates those objects
continuously, **Path A (CLD) is the better default** unless you already run
a native-database-centric warehouse and only care about a small, fixed set
of objects.

Snowflake's own docs don't publish this comparison as a stated
recommendation — the table above is this guide's synthesis from the
individual CLD/Iceberg-table doc pages, not a quoted Snowflake position.
Treat it as guidance, not gospel.

## 3. Package compatibility notes (applies to either path)

- **Requires `fivetran/salesforce_formula_utils >= 0.12.0`.** Prior versions
  fail against any MDLS/catalog-backed source (CLD or otherwise) with a
  `load_relation()` error inside `dbt_utils.get_column_values()`.
- The v0.12.0+ macro's MDLS code path has **no explicit tie-breaker**
  (`ORDER BY`/`LIMIT`) if `fivetran_formula_model` ever has more than one row
  for the same `(object, query_engine)` pair — e.g. after a resync leaves
  stale rows around. Worth monitoring against a fresh sync.
- `packages.yml`:
```yml
  packages:
    - package: fivetran/salesforce_formula_utils
      version: [">=0.12.0", "<0.13.0"]
```

## 4. Example: Path A (CLD) end to end

```yml
# catalogs.yml
catalogs:
  - name: my_catalog_writer
    active_write_integration: snowflake_write_integration
    write_integrations:
      - name: snowflake_write_integration
        table_format: iceberg
        catalog_type: iceberg_rest
        adapter_properties:
          auto_refresh: true
          iceberg_version: 3
          catalog_linked_database: my_lakehouse
```
```yml
# dbt_project.yml (relevant excerpt)
models:
  +materialized: table
  +table_format: iceberg
  +catalog_name: my_catalog_writer
```

```yml
# models/sources.yml
sources:
  - name: salesforce
    schema: salesforce
    database: my_lakehouse
    tables: [fivetran_formula_model, account, user_role]
```

```sql
-- models/account.sql
{{ salesforce_formula_utils.sfdc_formula_view(source_table='account', materialization='table') }}

-- models/user_role.sql
{{ salesforce_formula_utils.sfdc_formula_view(source_table='user_role', materialization='table') }}
```
