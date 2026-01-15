<!--section="salesforce-formula-utils_transformation_model"-->
# Salesforce Formula Utils dbt Package

<p align="left">
    <a alt="License"
        href="https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_,<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/data-models/quickstart-management#quickstartmanagement">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

This dbt package provides a macro which can be used to generate views on top of Salesforce objects while recreating formula fields.

## Resources

- Number of materialized models¹: However many upstream salesforce objects include formula fields.
- Connector documentation
  - [Salesforce Formula documentation](https://fivetran.com/docs/connectors/applications/salesforce/formula#formulafields)
  - [Salesforce Formula Quickstart](https://fivetran.com/docs/connectors/applications/salesforce/formula#salesforcequickstartmodel)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_salesforce_formula_utils)
  - [Changelog](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/CHANGELOG.md)

## What does this dbt package do?
This package enables you to accurately map Salesforce formulas to existing tables through macros and scripts. It creates enriched models with formula fields integrated into your Salesforce data.

> Note: this package is distinct from the [Salesforce dbt package](https://github.com/fivetran/dbt_salesforce), which _transforms_ Salesforce data and outputs analytics-ready end models.
> Additionally, please this solution **does not support** formula field history mode. The formula fields recreated from this package will only use the most recent formula available in your Salesforce environment.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_salesforce_formula_utils
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| Salesforce Object Name | Table which includes the base Salesforce object fields in addition to any applicable Salesforce formula fields. |

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all formula field models materialized as `view`.

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Salesforce connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the package
The [`sfdc_formula_view`](https://github.com/fivetran/dbt_salesforce_formula_utils#sfdc_formula_view-source) macro is intended to be leveraged within a dbt project that uses the source tables from Fivetran's Salesforce connector. To leverage the macro, you will add the below configuration to your `packages.yml` file (if you do not have a `packages.yml` file, create one in your root dbt project).
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yml
packages:
  - package: fivetran/salesforce_formula_utils
    version: [">=0.11.0", "<0.12.0"] # we recommend using ranges to capture non-breaking changes automatically
```

### Define required source tables
In order to use the macros included in this package, you will need to have a properly configured Salesforce source named `salesforce` in your own dbt project. An example of a properly configured Salesforce source yml can be found in the `src_salesforce.yml` file in [integration_tests](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/integration_tests/models/src_fivetran_formula.yml). This integration_tests folder is just for testing purposes - your source file will need to be in the models folder of your root dbt project. You are welcome to copy/paste the [example](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/integration_tests/models/src_fivetran_formula.yml) source configuration into your `src_salesforce.yml` file and modify for your use case.

In particular, you will need the following sources defined in your `src_salesforce.yml` file:
```yml
version: 2

sources:
  - name: salesforce # It would be best to keep this named salesforce
    schema: "{{ var('salesforce_schema', 'salesforce') }}" # Configure the salesforce_schema var from your dbt_project.yml (alternatively you can hard-code the schema here if only using one Salesforce connection)
    # Add the database where your Salesforce data resides if different from the target database. Eg. 'my_salesforce_database'. By default the target.database is used.
    tables:
      - name: fivetran_formula_model
        description: Contains SQL models produced by Fivetran Salesforce connector

      ## Any other source tables you are creating models for should be defined here as well. They aren't required, but it is best organizational practice and allows Fivetran to compile data lineage graphs
```

### Create models
#### Generate models using connector-made query

To create a model that includes all formula fields:
1. Create a new file in your models folder and name it `your_table_name_here.sql` (e.g. `customer.sql`; this is not necessary but recommended as best practice).
2. Add the below snippet calling the [`sfdc_formula_view`](https://github.com/fivetran/dbt_salesforce_formula_utils#sfdc_formula_view-source) macro into the file. Update the `source_table` argument to be the source table name for which you are generating the model (e.g. `customer`).
```sql
{{ salesforce_formula_utils.sfdc_formula_view(source_table='your_source_table_name_here') }}
```

**Output**: All formulas for the chosen source table will be included in the resulting `select` statement.

#### Automate model creation
If you have multiple models you need to create, you can also leverage the [sfdc_formula_model_automation](https://github.com/fivetran/dbt_salesforce_formula_utils#sfdc_formula_model_automationsh-source) script within this project to automatically create models locally via the command line. Below is an example command to copy and edit.

```bash
source dbt_packages/salesforce_formula_utils/sfdc_formula_model_automation.sh "../path/to/directory" "desired_table_1,desired_table_2,desired_table_infinity"
```

**Output**: Model files for each table, populated with `{{ salesforce_formula_utils.sfdc_formula_view(source_table='table_name') }}`.

> Note: In order for this command to work, you must currently be within the root directory of your dbt project.

### Execute models
Once you have created all your desired models and copied/modified the sql snippet into each model you will execute `dbt deps` to install the macro package, then execute `dbt run` to generate the models. Additionally, you can reference the [integration_tests](https://github.com/fivetran/dbt_salesforce_formula_utils/tree/main/integration_tests/models) folder for examples on how to use the macro within your models.

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand to view details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt/setup-guide#transformationsfordbtcoresetupguide).
</details>

## Macro & script documentation

### sfdc_formula_view ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view.sql))
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

### sfdc_formula_model_automation.sh ([source](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/sfdc_formula_model_automation.sh))
This bash script is intended to be used in order to automatically create the desired salesforce models via the command line within your dbt project. This bash script will generate a model file within your dbt project that contains the [sfdc_formula_view](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/macros/sfdc_formula_view.sql) macro for the appropriately defined table(s). In order for this command to work you must be within the root directory of your dbt project. Note that this script is designed for dbt Core and is **not** compatible with dbt Cloud.

**Usage:**
```bash
source dbt_packages/salesforce_formula_utils/sfdc_formula_model_automation.sh "../path/to/directory" "desired_table(s)"
```

**Example**
Assuming the path to your directory is `"../dbt_salesforce"` and the table(s) you want to generate the model for are `opportunity` and `account`.
```bash
source dbt_packages/salesforce_formula_utils/sfdc_formula_model_automation.sh "../dbt_salesforce" "opportunity,account"
```

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```

<!--section="salesforce-formula-utils_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/salesforce_formula_utils/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_salesforce_formula_utils/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_salesforce_formula_utils/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
