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
