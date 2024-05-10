<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
</p>

# Fivetran Salesforce Formula Utils
# 📣 What does this dbt package do?
This package includes macros and scipts to be used within a dbt project to accurately map Salesforce Formulas to existing tables. It is designed to  work with data from [Fivetran's Salesforce connector](https://fivetran.com/docs/applications/salesforce) in the format described by [this ERD](https://fivetran.com/docs/applications/salesforce#schema).

> Note: this package is distinct from the [Salesforce dbt package](https://github.com/fivetran/dbt_salesforce), which _transforms_ Salesforce data and outputs analytics-ready end models.

# 🎯 How do I use the dbt package?
## Step 1: Prerequisites
To use this dbt package, you must have the following:
- At least one Fivetran Salesforce connector syncing data into your destination. 
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

## Step 2: Install the package
The [`sfdc_formula_view`](https://github.com/fivetran/dbt_salesforce_formula_utils#sfdc_formula_view-source) macro is intended to be leveraged within a dbt project that uses the source tables from Fivetran's Salesforce connector. To leverage the macro, you will add the below configuration to your `packages.yml` file (if you do not have a `packages.yml` file, create one in your root dbt project).
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yml
packages:
  - package: fivetran/salesforce_formula_utils
    version: [">=0.9.0", "<0.10.0"] # we recommend using ranges to capture non-breaking changes automatically
```

## Step 3: Define required source tables
In order to use the macros included in this package, you will need to have a properly configured Salesforce source named `salesforce` in your own dbt project. An example of a properly configured Salesforce source yml can be found in the `src_salesforce.yml` file in [integration_tests](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/integration_tests/models/src_fivetran_formula.yml). This integration_tests folder is just for testing purposes - your source file will need to be in the models folder of your root dbt project. You are welcome to copy/paste the [example](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/integration_tests/models/src_fivetran_formula.yml) source configuration into your `src_salesforce.yml` file and modify for your use case. 

In particular, you will need the following sources defined in your `src_salesforce.yml` file:
```yml
version: 2

sources:
  - name: salesforce # It would be best to keep this named salesforce
    schema: "{{ var('salesforce_schema', 'salesforce') }}" # Configure the salesforce_schema var from your dbt_project.yml (alternatively you can hard-code the schema here if only using one Salesforce connector)
    # Add the database where your Salesforce data resides if different from the target database. Eg. 'my_salesforce_database'. By default the target.database is used.
    tables:
      - name: fivetran_formula_model
        description: Contains SQL models produced by Fivetran Salesforce connector

      ## Any other source tables you are creating models for should be defined here as well. They aren't required, but it is best organizational practice and allows Fivetran to compile data lineage graphs
```

## Step 4: Create models
### Generate models using connector-made query

To create a model that includes all formula fields:
1. Create a new file in your models folder and name it `your_table_name_here.sql` (e.g. `customer.sql`; this is not necessary but recommended as best practice). 
2. Add the below snippet calling the [`sfdc_formula_view`](https://github.com/fivetran/dbt_salesforce_formula_utils#sfdc_formula_view-source) macro into the file. Update the `source_table` argument to be the source table name for which you are generating the model (e.g. `customer`). 
```sql
{{ salesforce_formula_utils.sfdc_formula_view(source_table='your_source_table_name_here') }}
```

**Output**: All formulas for the chosen source table will be included in the resulting `select` statement. 


### Automate model creation
If you have multiple models you need to create, you can also leverage the [sfdc_formula_model_automation](https://github.com/fivetran/dbt_salesforce_formula_utils#sfdc_formula_model_automationsh-source) script within this project to automatically create models locally via the command line. Below is an example command to copy and edit.

```bash
source dbt_packages/salesforce_formula_utils/sfdc_formula_model_automation.sh "../path/to/directory" "desired_table_1,desired_table_2,desired_table_infinity"
```

**Output**: Model files for each table, populated with `{{ salesforce_formula_utils.sfdc_formula_view(source_table='table_name') }}`. 

> Note: In order for this command to work, you must currently be within the root directory of your dbt project. 


## Step 5: Execute models
Once you have created all your desired models and copied/modified the sql snippet into each model you will execute `dbt deps` to install the macro package, then execute `dbt run` to generate the models. Additionally, you can reference the [integration_tests](https://github.com/fivetran/dbt_salesforce_formula_utils/tree/main/integration_tests/models) folder for examples on how to use the macro within your models.

## (Optional) Step 6: Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand to view details</summary>
<br>
    
Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).
</details>

# 📖 Macro & script documentation

## sfdc_formula_view ([source](macros/sfdc_formula_view.sql))
This macro generates the final sql needed to join the Salesforce formula fields to the desired table.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_view(source_table='fivetran_sfdc_example_table') }}
```
**Args:**
* `source_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional, default = `'salesforce'`): The dbt source containing the table you want to join with formula fields (as defined [here](https://github.com/fivetran/dbt_salesforce_formula_utils/tree/main#step-3-define-required-source-tables)). Must contain the `fivetran_formula_model` table.
* `using_quoted_identifiers` (optional, default = `false`): For warehouses with case sensitivity enabled this argument **must** be set to `true` in order for the underlying macros within this project to properly compile and execute successfully. 
* `materialization` (optional, default = `view`): By default the model will be materialized as a view. If you would like to materialize as a table, you can adjust using this argument.
----

## sfdc_formula_model_automation.sh ([source](sfdc_formula_model_automation.sh))
This bash script is intended to be used in order to automatically create the desired salesforce models via the command line within your dbt project. This bash script will generate a model file within your dbt project that contains the [sfdc_formula_view](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view.sql) macro for the appropriately defined table(s). In order for this command to work you must be within the root directory of your dbt project.

**Usage:**
```bash
source dbt_packages/salesforce_formula_utils/sfdc_formula_model_automation.sh "../path/to/directory" "desired_table(s)"
```

**Example**
Assuming the path to your directory is `"../dbt_salesforce"` and the table(s) you want to generate the model for are `opportunity` and `account`.
```bash
source dbt_packages/salesforce_formula_utils/sfdc_formula_model_automation.sh "../dbt_salesforce" "opportunity,account"
```

## Under the hood macros
<details><summary>Expand to view documenation</summary>
<br>

### sfdc_formula_pivot ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_pivot.sql))
This macro pivots the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro to populate the formula field and sql for each record within the designated table this macro is used.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='fivetran_sfdc_example_table') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional, default = `'salesforce'`): The dbt source containing the table you want to join with formula fields. Must also contain the `fivetran_formula` table.
* `added_inclusion_fields` (optional, default = `none`): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----

### sfdc_formula_refactor ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_refactor.sql))
This macro checks the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro to determine if any formula fields reference other formula fields. If a formula references another generated formula field, then the macro will insert the first formula sql into the second formula. This ensures formulas that reference another formula field will be generated successfully. 

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_refactor(join_to_table='fivetran_sfdc_example_table',source_name='salesforce') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional, default = `salesforce`): The name of the source defined.
* `added_inclusion_fields` (optional, default = `none`): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----
### sfdc_formula_view_fields ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view_fields.sql))
This macro checks the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro and returns the field name with the index of the view sql to be used in the primary select statement of the [sfdc_formula_view](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view.sql) macro.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_field_views(join_to_table='fivetran_sfdc_example_table',source_name='salesforce') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional): The name of the source defined. Default is `salesforce`.
* `inclusion_fields` (optional, default = `none`): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----
### sfdc_formula_view_sql ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view_sql.sql))
This macro checks the dictionary results generated from the [sfdc_get_formula_column_values](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql) macro and returns the view_sql value results while also replacing the `from` and `join` syntax to be specific to the source defined. Additionally, the where logic will be applied to ensure the view_sql is properly joined to the base table.

**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_formula_view_sql(join_to_table='fivetran_sfdc_example_table',source_name='salesforce') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
* `source_name` (optional): The name of the source defined. Default is `salesforce`.
* `inclusion_fields` (optional, default = `none`): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
----

### sfdc_get_formula_column_values ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_get_formula_column_values.sql))
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
* `added_inclusion_fields` (optional, default = `none`): The list of fields you want to be included in the macro. If no fields are selected then all fields will be included.
* `no_nulls` (optional, default = `true`): Used by the macro to identify if the `null` fields within the `view_sql` column should be included.
----

### sfdc_star_exact ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_star_exact.sql))
This macro mirrors the [dbt_utils.star()](https://github.com/dbt-labs/dbt-utils#star-source) macro with the minor adjustment to properly work with the return results of the [dbt_utils.get_column_values()](https://github.com/dbt-labs/dbt-utils#get_column_values-source). The major change being how the return result of the dbt_utils.get_column_values() macro returns results with single quotes, while the dbt_utils.star() macro exclusively requires double quotes.
**Usage:**
```sql
{{ salesforce_formula_utils.sfdc_star_exact(from=ref('my_model'), relation_alias='my_table', except=["exclude_field_1", "exclude_field_2"]) }}
```
**Args:**
* `from` (required): The table which you want to select all fields.
* `relation_alias` (optional, default = `none`): Used if you would like to add a relation alias to the fields queried in the select star statement (i.e. `my_table.field_name`).
* `except` (optional, default = `none`): A list of fields you would like to exclude from the select star statement.
----
</details>

# 🔍 Does this package have dependencies?
This dbt package is dependent on the following dbt packages. Please be aware that these dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```

# 🙌 How is this package maintained and can I contribute?
## Package Maintenance
The Fivetran team maintaining this package _only_ maintains the latest version of the package. We highly recommend that you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/shopify_source/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

## Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions! 

We highly encourage and welcome contributions to this package. Check out [this dbt Discourse article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) to learn how to contribute to a dbt package!

# 🏪 Are there any resources available?
- If you have questions or want to reach out for help, please refer to the [GitHub Issue](https://github.com/fivetran/dbt_salesforce_formula_utils/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
- Have questions or want to just say hi? Book a time during our office hours [on Calendly](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com.
