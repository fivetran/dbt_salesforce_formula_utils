# Fivetran Salesforce Formula Utils

This package includes macros to be used within a Salesforce dbt project to accurately map Salesforce Formulas to existing tables.

## Installation Instructions
In order to use this macro it is expected that you have set up your own dbt project. If you have not, you can reference the [dbt installation docs](https://docs.getdbt.com/dbt-cli/installation) for the latest installation instructions, and then reference [the dbt package docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Macro Instructions
This macro is intended to be used within a salesforce dbt project model. To leverage the macro, you will add the below configuration to your `packages.yml` file (if you do not have a `packages.yml` file you can create one).
```yml
packages:
  - git: https://github.com/fivetran/dbt_salesforce_formula_utils.git
    revision: main
    warn-unpinned: false
```
> **Note**: In order to use the macros included in this package you will need to have a properly configured source package with a source named `salesforce`. To see an example of a properly configured Salesforce source yml you can reference [integration_tests](integration_tests/models/src_fivetran_formula.yml). You are also welcome to copy/paste this source configuration into your dbt root project and modify for your Salesforce use case.

Once the package is added, you may use the macro within your salesforce models. To do so you will create a new file in your models folder and name it (`your_table_name_here`_view.sql). Then add the below snippet into the file. You will then update the `your_table_name_here` argument to be the table for which you are generating the model:
```sql
{{ dbt_salesforce_formula_utils.sfdc_formula_view('your_table_name_here') }}
```

Once you have created all your desired models and copied/modified the sql snippet into each model you will execute `dbt deps` to install the macro package, then execute `dbt run` to generate the models.

Additionally, you can reference the [integration_tests](integration_tests/models/) folder for examples on how to use the macro within your models.
If you have multiple models you need to create, you can also Leverage the [sfdc_formula_model_automation](sfdc_formula_model_automation.sh) script within this project to automatically create models locally via the command line. Below is an example command to copy and edit.

```bash
source dbt_modules/dbt_salesforce_formula_utils/automate.sh "path/to/directory" desired_table
```

## Macro Descriptions
### sfdc_formula_view ([source](macros/sfdc_formula_view.sql))
This macro generates the final sql needed to join the Salesforce formula fields to the desired table.

**Usage:**
```sql
{{ dbt_salesforce_formula_utils.sfdc_formula_view(join_to_table_first='fivetran_sfdc_example_table') }}
```
**Args:**
* `join_to_table_first` (required): The table with which you are joining the formula fields.
----
### sfdc_formula_pivot ([source](macros/sfdc_formula_pivot.sql))
This macro pivots the dictionary results generated from the [sfdc_fet_formula_column_values](macros/sfdc_fet_formula_column_values.sql) macro to populate the formula field and sql for each record within the designated table this macro is used.

**Usage:**
```sql
{{ dbt_salesforce_formula_utils.sfdc_formula_pivot(join_to_table='fivetran_sfdc_example_table') }}
```
**Args:**
* `join_to_table` (required): The table with which you are joining the formula fields.
----

### sfdc_get_formula_column_values ([source](macros/sfdc_fet_formula_column_values.sql))
This macro is designed to look within the users source defined `salesforce_schema` for the `fivetran_formula` table. The macro will then filter to only include records from the `join_to_table` argument, and search for distinct combinations of the `field` and `sql` columns. The distinct combination of columns for the join_table argument are then returned as a dictionary.
> Note: This macro will not work accurately unless you have a `src.yml` configured appropriately. For reference, look within this packages [integration_tests](integration_tests/models/fivetran_formula_src.yml) folder for an example of a source configuration.

**Usage:**
```sql
{{ dbt_salesforce_formula_utils.sfdc_get_formula_column_values(fivetran_formula='salesforce', key='field', value='sql', join_to_table='fivetran_sfdc_example_table') }}
```
**Args:**
* `fivetran_formula` (required): The source configuration for the `salesforce.fivetran_formula` table.
* `key` (required): The key column within `fivetran_formula` you are querying. This argument is typically `field`.
* `value` (required): The value column within `fivetran_formula` you are querying. This argument is typically `sql`.
* `join_to_table` (required): The table with which you are joining the formula fields.
----

## Automation Bash Script
### sfdc_formula_model_automation.sh ([source](sfdc_formula_model_automation.sh))
This bash script is intended to be used in order to automatically create the desired salesforce models via the command line within your dbt project. This bash script will generate a model file within your dbt project that is a contains the `sfdc_formula_view` macro for the appropriately defined table. In order for this command to work you must be within the root directory of your dbt project. 

**Usage:**
```bash
source dbt_modules/dbt_salesforce_formula_utils/sfdc_formula_model_automation.sh "path/to/directory" desired_table
```

**Example**
Assuming the path to your directory is `"../dbt_salesforce"` and the table you want to generate the model for is `opportunity`.
```bash
source dbt_modules/dbt_salesforce_formula_utils/sfdc_formula_model_automation.sh "../dbt_salesforce" opportunity
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
- Learn how to orchestrate [dbt transformations with Fivetran](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
