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
