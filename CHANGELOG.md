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