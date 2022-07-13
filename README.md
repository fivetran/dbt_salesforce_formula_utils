[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
# Fivetran Salesforce Formula Utils

This package includes macros to be used within a Salesforce dbt project to accurately map Salesforce Formulas to existing tables.

## Installation Instructions
In order to use this macro it is expected that you have set up your own dbt project. If you have not, you can reference the [dbt installation docs](https://docs.getdbt.com/dbt-cli/installation) for the latest installation instructions, and then reference [the dbt package docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Macro Instructions
### Installing the Macro Package
This macro is intended to be used within a salesforce dbt project model. To leverage the macro, you will add the below configuration to your `packages.yml` file (if you do not have a `packages.yml` file you can create one).
```yml
packages:
  - package: fivetran/salesforce_formula_utils
    version: [">=0.7.0", "<0.8.0"]
```
> **Note**: In order to use the macros included in this package you will need to have a properly configured source package with a source named `salesforce`. To see an example of a properly configured Salesforce source yml you can reference [integration_tests](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/integration_tests/models/src_fivetran_formula.yml). You are also welcome to copy/paste this source configuration into your dbt root project and modify for your Salesforce use case.

## Package Maintenance
The Fivetran team maintaining this package **only** maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/salesforce_formula_utils/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.
## Model Creation
The salesforce_formula_utils macro may be used in one of two ways. You may either use the macro to create a table with **all** relevant formula fields applied, or you may use the macro to include **only** specified formula fields. Refer to the two options below for more details.
### Option 1: Generate all relevant formula fields at once
If you would like your model to generate all the formula fields at once related to your source table then you will create a new file in your models folder and name it (`your_table_name_here`.sql). You will then add the below snippet into the file. Finally, update the `source_table` argument to be the source table name for which you are generating the model:
```sql
{{ salesforce_formula_utils.sfdc_formula_view(
    source_table='your_source_table_name_here',
    full_statement_version=true) 
}}
```
### Option 2: Generate all relevant formula fields individually
If you would like your model to generate all the formula fields related to your source table then you may create a new file in your models folder and name it (`your_table_name_here`.sql). You will then add the below snippet into the file. Finally, update the `source_table` argument to be the source table name for which you are generating the model:
```sql
{{ salesforce_formula_utils.sfdc_formula_view(
    source_table='your_source_table_name_here') 
}}
```
### Option 2: Generate only specified formula fields
If you would like your model to generate only a specified subset of your formula fields related to your source table then you may create a new file in your models folder and name it (`your_table_name_here`.sql). You will then add the below snippet into the file. Finally, update the `source_table` argument to be the source table name for which you are generating the model and update the `fields_to_include` argument to contain all the fields from your source that you would like to be included in the final output. Be sure that the field(s) you would like to include are enclosed within brackets as an array (ie. `[]`):
```sql
{{ salesforce_formula_utils.sfdc_formula_view(
    source_table='your_source_table_name_here', 
    fields_to_include=['i_want_this_field','also_this_one','maybe_a_third_as_well','lets_add_more']) 
}}
```
### Formula Fields that Reference Other Formula Fields
This macro has been created to allow for two degrees of formula field reference. For example:
- :white_check_mark: : A formula field references standard fields from the base Salesforce table.
- :white_check_mark: : A formula field references another formula field that does not reference other formula fields.
- :x:     : A formula field references another formula field that references another formula field (etc.).

If you have a formula field that would fall under the :x: example, exclude it from all your models by configuring the `sfdc_exclude_formulas` variable within your root `dbt_project.yml` file. Configure this variable as a set of all the fields you would like to exclude from all models. See below for an example:
```yml
vars:
  sfdc_exclude_formulas: ('field_that_references_other_formula','other_triple_ref_field','field_i_just_dont_want')
```
> **Note**: You should not add this variable to your `dbt_project.yml` file if you do not need to exclude any fields.

Once you have created all your desired models and copied/modified the sql snippet into each model you will execute `dbt deps` to install the macro package, then execute `dbt run` to generate the models. Additionally, you can reference the [integration_tests](https://github.com/fivetran/dbt_salesforce_formula_utils/tree/main/integration_tests/models) folder for examples on how to use the macro within your models.

### Model Creation Automation
If you have multiple models you need to create, you can also Leverage the [sfdc_formula_model_automation](sfdc_formula_model_automation.sh) script within this project to automatically create models locally via the command line. Below is an example command to copy and edit.

```bash
source dbt_modules/salesforce_formula_utils/sfdc_formula_model_automation.sh "../path/to/directory" "desired_table_1,desired_table_2,desired_table_infinity"
```

## Macro Descriptions
### sfdc_formula_view ([source](macros/sfdc_formula_view.sql))
This macro generates the final sql needed to join the Salesforce formula fields to the desired table.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_view(source_table='fivetran_sfdc_example_table') }}
```
**Args:**
* `source_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional, default 'salesforce'): The dbt source containing the table you want to join with formula fields. Must also contain the `fivetran_formula` table.
* `fields_to_include` (optional, default is none): If a users wishes to only run the formula fields macro for designated fields then they may be applied within this variable. This variable will ensure the model only generates the sql for the designated fields. 
* `full_statement_version` (optional, default is false): Allows a user to leverage the `fivetran_formula_table` version of the macro which will generate the formula fields via the complete sql statement, rather than individual formulas being generated within the macro.
* `materialization` (optional, default is `view`): By default the model will be materialized as a view. If you would like to materialize as a table, you can adjust using this argument.
> Note: If you populate the `fields_to_include` argument then the package will exclusively look for those fields. If you have designated a field to be excluded within the `sfdc_exclude_formulas` variable, then this will be ignored and the field will be included in the final model.
----

### sfdc_formula_pivot ([source](macros/sfdc_formula_pivot.sql))
This macro pivots the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro to populate the formula field and sql for each record within the designated table this macro is used.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='fivetran_sfdc_example_table') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional, default 'salesforce'): The dbt source containing the table you want to join with formula fields. Must also contain the `fivetran_formula` table.
* `added_inclusion_fields` (optional, default is none): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----

### sfdc_formula_refactor ([source](macros/sfdc_formula_refactor.sql))
This macro checks the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro to determine if any formula fields reference other formula fields. If a formula references another generated formula field, then the macro will insert the first formula sql into the second formula. This ensures formulas that reference another formula field will be generated successfully. 

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_refactor(join_to_table='fivetran_sfdc_example_table',source_name='salesforce') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional, default is `salesforce`): The name of the source defined.
* `added_inclusion_fields` (optional, default is none): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----
### sfdc_formula_view_fields ([source](macros/sfdc_formula_view_fields.sql))
This macro checks the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro and returns the field name with the index of the view sql to be used in the primary select statement of the [sfdc_formula_view](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view.sql) macro.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_field_views(join_to_table='fivetran_sfdc_example_table',source_name='salesforce') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional): The name of the source defined. Default is `salesforce`.
* `inclusion_fields` (optional, default is none): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----
### sfdc_formula_view_sql ([source](macros/sfdc_formula_view_sql.sql))
This macro checks the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro and returns the view_sql value results while also replacing the `from` and `join` syntax to be specific to the source defined. Additionally, the where logic will be applied to ensure the view_sql is properly joined to the base table.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_view_sql(join_to_table='fivetran_sfdc_example_table',source_name='salesforce') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional): The name of the source defined. Default is `salesforce`.
* `inclusion_fields` (optional, default is none): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----

### sfdc_get_formula_column_values ([source](macros/sfdc_get_formula_column_values.sql))
This macro is designed to look within the users source defined `salesforce_schema` for the `fivetran_formula` table. The macro will then filter to only include records from the `join_to_table` argument, and search for distinct combinations of the `field` and `sql` columns. The distinct combination of columns for the join_table argument are then returned as a dictionary. 
Further, if there are any formula fields that are a third degree referential formula (eg. a formula field is contains a field that is a formula field, and that formula field also references another formula field) or greater then you can add those fields to the `sfdc_exclude_formulas` variable within your root `dbt_project.yml` file to exclude them from the macro as they will fail in the final view creation.
> Note: This macro will not work accurately unless you have a `src.yml` configured appropriately. For reference, look within this packages [integration_tests](https://github.com/fivetran/dbt_salesforce_formula_utils/tree/main/integration_tests/models) folder for an example of a source configuration.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_get_formula_column_values(fivetran_formula='salesforce', key='field', value='sql', join_to_table='fivetran_sfdc_example_table') }}
```
**Args:**
* `fivetran_formula` (required): The source configuration for the `fivetran_formula` table. If this is in a different source than the default `salesforce`, that source will also apply to the `join_to_table` parameter.
* `key` (required): The key column within `fivetran_formula` you are querying. This argument is typically `field`.
* `value` (required): The value column within `fivetran_formula` you are querying. This argument is typically `sql`.
* `join_to_table` (required): The table with which you are joining the formula fields.
* `added_inclusion_fields` (optional, default is none): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
* `no_nulls` (optional, default is true): Used by the macro to identify if the `null` fields within the `view_sql` column should be included.
----

### sfdc_star_exact_ ([source](macros/sfdc_star_exact.sql))
This macro mirrors the [dbt_utils.star()](https://github.com/dbt-labs/dbt-utils#star-source) macro with the minor adjustment to properly work with the return results of the [dbt_utils.get_column_values()](https://github.com/dbt-labs/dbt-utils#get_column_values-source). The major change being how the return result of the dbt_utils.get_column_values() macro returns results with single quotes, while the dbt_utils.star() macro exclusively requires double quotes.
**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_star_exact(from=ref('my_model'), relation_alias='my_table', except=["exclude_field_1", "exclude_field_2"]) }}
```
**Args:**
* `from` (required): The table which you want to select all fields.
* `relation_alias` (optional, default is none): Used if you would like to add a relation alias to the fields queried in the select star statement (i.e. `my_table.field_name`).
* `except` (optional, default is none): A list of fields you would like to exclude from the select star statement.
----
## Automation Bash Script
### sfdc_formula_model_automation.sh ([source](sfdc_formula_model_automation.sh))
This bash script is intended to be used in order to automatically create the desired salesforce models via the command line within your dbt project. This bash script will generate a model file within your dbt project that contains the [sfdc_formula_view](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view.sql) macro for the appropriately defined table(s). In order for this command to work you must be within the root directory of your dbt project. 

**Usage:**
```bash
source dbt_modules/salesforce_formula_utils/sfdc_formula_model_automation.sh "../path/to/directory" "desired_table(s)"
```

**Example**
Assuming the path to your directory is `"../dbt_salesforce"` and the table(s) you want to generate the model for are `opportunity` and `account`.
```bash
source dbt_modules/salesforce_formula_utils/sfdc_formula_model_automation.sh "../dbt_salesforce" "opportunity,account"
```

## Contributions
Don't see a model or specific metric you would have liked to be included? Notice any bugs when installing 
and running the package? If so, we highly encourage and welcome contributions to this package! 
Please create issues or open PRs against `master`. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Database Support
This package has been tested on BigQuery, Snowflake, Redshift, and Postgres.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions, feedback, or need help? Book a time during our office hours [using Calendly](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate your models with [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
