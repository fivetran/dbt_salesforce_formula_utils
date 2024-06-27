# dbt_salesforce_formula_utils v0.10.0
[PR #109](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/109) includes the following updates:

## 🚨 Breaking Changes 🚨
- The parameter `full_statement_version=false` has been fully sunset from the `sfdc_formula_view` macro. You will now need to remove this parameter to avoid a compilation error.

## Under the hood
- Included auto-releaser GitHub Actions workflow to automate future releases.
- Updated maintainer pull request template.

# dbt_salesforce_formula_utils v0.9.3
[PR #101](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/101) includes the following updates:

## 🗒️ Documentation Update 🗒️
- Fivetran has deprecated support for the `full_statement_version=false`. We've removed mention of this obsolete method [in the README](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/README.md). 

## 🚇 Under the Hood 🚇
- Users will not see functional differences from v0.9.2. However, due to changes in the Fivetran Salesforce connector, users still utilizing the `full_statement_version=false` should expect formula field values to be null.

# dbt_salesforce_formula_utils v0.9.2
[PR #96](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/96) includes the following updates:

## 🗒️ Documentation Update 🗒️
- Fivetran will be deprecating support for the `full_statement_version=false` config by October 1, 2023. We've highlighted this change to users of the package [in the README](https://github.com/fivetran/dbt_salesforce_formula_utils#step-4-create-models). 

## 🚇 Under the Hood 🚇
- Users still utilizing the `full_statement_version=false` config will receive a log message in their `dbt run` indicating deprecation of support for those options.

# dbt_salesforce_formula_utils v0.9.1
## Bugfix
- Databricks users faced a syntax error resulting from the `sfdc_formula_view_sql` macro not correctly compiling. This update adds the Databricks warehouse to a conditional in the macro that allows the sql to correctly compile. ([PR #94](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/94)) ([PR #92](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/92))
- Postgres users faced a syntax error resulting from the `sfdc_formula_view_sql` macro not correctly compiling. This update adds the Postgres warehouse to a conditional in the macro that allows the sql to correctly compile. ([PR #94](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/94))

## Contributors:
- [@corca](https://github.com/corca) ([PR #92](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/92))

# dbt_salesforce_formula_utils v0.9.0
## 🎉 Feature Update 🎉
- Databricks compatibility! ([#89](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/89))

# dbt_salesforce_formula_utils v0.8.2
## Features
- Clarify Step 5 of the README that `sfdc_exclude_formulas` works only with Options 2 and 3. ([#88](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/88))

## Under the Hood:
- Renamed macro filename from `sfdc_current_formula_fields` to `sfdc_current_formula_values` to be consistent with its macro name. ([#86](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/86))
- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job. ([#82](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/82))
- Updated the pull request [templates](/.github). ([#82](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/82))

## Contributors:
- [@duncan771](https://github.com/duncan771) ([#86](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/86))

# dbt_salesforce_formula_utils v0.8.1

## Features
- Updated the README for easier use and navigation of the package ([PR #78](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/78)).

## Bug Fixes
([PR #77](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/77)) includes the following changes:
- In v0.8.0, the `using_quoted_identifiers` argument in the `sfdc_formula_view()` macro was erroneously removed, making its default value of `False` immutable. It has been reintroduced.
- `using_quoted_identifiers` now uses warehouse-specific quoting syntax.

# dbt_salesforce_formula_utils v0.8.0

## 🚨 Breaking Changes 🚨:
[PR #64](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/64) includes the following breaking changes:
- The default behavior of the `sfdc_formula_view` macro now has the `full_statement_version` equal to `true`. This means, by default the macro will search for the `fivetran_formula_model` source table (full SQL statement for each object) opposed to the `fivetran_formula` source table (individual formulas). 
  - Please be sure to update your macros that intend to reference the `fivetran_formula` source table accordingly.
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- Dependencies on `fivetran/fivetran_utils` have been upgraded, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.

# dbt_salesforce_formula_utils v0.7.2
## Features
- Incorporated a new boolean argument (`using_quoted_identifiers`) to the `sfdc_formula_view` macro. This argument allows users to quote the compiled sql generated by the macro. This is especially necessary when a users warehouse has case sensitivity enabled. If a user has a warehouse with case sensitivity, they will likely see the macro fail by default. If this is the case, you will want to set the `using_quoted_identifiers` argument to `true` (the argument is `false` by default). ([#72](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/72))
- Updated documentation within the README for easier understanding of the macros and how to use them in a dbt project. ([#70](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/70))

## Under the Hood
- Added BuildKite integration tests. ([#72](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/72))
- Added the `docs` folder for dbt docs hosting on GitHub Pages. ([#72](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/72))
- Upgraded dbt-expectations dependency within the package integration_tests to the `[">=0.8.0", "<0.9.0"]` range. ([#72](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/72))

## Contributors
- [@fivetran-adamrees](https://github.com/fivetran-adamrees) ([#70](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/70))
# dbt_salesforce_formula_utils v0.7.1
## Features
- README edits for easier navigation and understanding of how to use the solution. ([#61](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/61))
## Bug Fixes
- The `dbt_utils.get_column_values` macro for the full_statement_version of the package was not properly filtering for only the relevant source table records within the `fivetran_formula_model` source table. A where clause has been added to remedy this issue. ([#61](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/61))
# dbt_salesforce_formula_utils v0.7.0
## Features
- Addition of the `full_statement_version` argument within the `sfdc_formula_view` macro. This argument is a boolean and will allow users to either leverage the default (`false`) version of the macro to pull individual formulas from the `fivetran_formula` table to be produced in the materialized view, or (`true`) leverage the `fivetran_formula_model` source to generate the entire sql statement that will be materialized in warehouse. ([#55](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/55))
# dbt_salesforce_formula_utils v0.6.5
## Features
- Inclusion of the `materialization` argument to the `sfdc_formula_view` macro. The argument is `view` by default. However, if a user wishes to override the materialization then they may do so with this argument.
# dbt_salesforce_formula_utils v0.6.4
## Under the Hood
- The string `__table` is now appended to the table alias to match with the data provided within the connector. To ensure consistency across the board, the `reserved_table_name` argument is now ignored in place of the `{{source_table}}__table` format. ([#51](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/51))
  - The `reserved_table_name` argument is still accepted, but it will now be ignored for the time being. This will be removed in the next breaking release.
# dbt_salesforce_formula_utils v0.6.3
## Fixes
- Adjusted the conditional within the `sfdc_formula_views` macro to reference the properly named `current_formula_fields` variable opposed to the incorrect `old_formula_fields` variable that is not longer referenced. ([#46](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/46))
# dbt_salesforce_formula_utils v0.6.2

## Fixes
- Resolving dependency issues for use of `fields_to_include` feature of `sfdc_formula_view` macro. Previously if the list of `fields_to_include` included formulas that referenced other formulas excluded from `fields_to_include`, an error was served for the excluded formulas. ([#42](https://github.com/fivetran/dbt_salesforce_formula_utils/issues/42))
- All formula references will now be included until the final output model where `fields_to_include` is used to filter returned columns.
- Unused `*inclusion_fields` arguments have been removed from macros.
# dbt_salesforce_formula_utils v0.6.1

## Fixes
- Modified the `sfdc_formula_view_sql` macro to remove extranneous double quotes on Redshift databases ([#36](https://github.com/fivetran/dbt_salesforce_formula_utils/issues/36))
- Formulas were previously being lower cased within the macro to be consistent across the board. However, this resulted in some translations to be incorrect if they required specific casing. A fix has been implemented to rely on the casing within the `fivetran_formula` table instead of casing within the macro. ((#37)[https://github.com/fivetran/dbt_salesforce_formula_utils/pull/37])

## Under the Hood
- Removal of the `main_table` aliasing within the translated `view_sql` formulas. This would result in errors when self joins were being conducted. Therefore, this logic is not handled natively within the Salesforce connector. ((#38)[https://github.com/fivetran/dbt_salesforce_formula_utils/pull/38])

# dbt_salesforce_formula_utils v0.6.0
🎉 dbt v1.0.0 Compatibility 🎉
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_fivetran_utils`. The latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.

# dbt_salesforce_formula_utils v0.5.1
## Fixes
- Modified the `sfdc_formula_view` macro to wrap the arguments within an additional parenthesis. This is required for Snowflake warehouses with mixed casing enabled. ([#32](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/32))
- Updated the `sfdc_old_formula_fields` macro to properly work with mixed-quoting styles in Snowflake. This was fixed by setting the target relation in the macro to explicitly be set to a table relation. ([#32](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/32))

## Contributors
- @morgankrey-amplitude ([#32](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/32))

# dbt_salesforce_formula_utils v0.5.0

## 🚨 Breaking changes
- Update to the `fields_to_include` argument within the `sfdc_formula_view` macro. The macro now **MUST** be passed through as an array (using brackets `[]`) rather than a string (using parenthesis `()`). ([#28](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/28))
    - This fixes a bug where more than one field to include would not work and you would be required to add two or more fields ([#25](https://github.com/fivetran/dbt_salesforce_formula_utils/issues/25)). Additionally, passing the argument in as an array aligns more with dbt best practices.

## Bug Fixes
- Addition of the `reserved_table` argument to the `sfdc_formula_view_sql` macro which resolves a bug identified where a duplicate alias error would occur due to aliasing not properly being accounted for in the final compile query. ([#30](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/30))

## Under the hood
- Addition of the `sfdc_old_formula_fields` macro which changes the nature of the `old_formula_fields` variable within the `sfdc_formula_view` macro to exclude **only** formula fields that are related to the base table. ([29](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/29))
    - Previously, if a formula field existed as a base field for another table then it would be erroneously excluded. With this update those fields will not be excluded.

## Contributors
- [nhrebinka](https://github.com/nhrebinka) ([#30](https://github.com/fivetran/dbt_salesforce_formula_utils/pull/30))
