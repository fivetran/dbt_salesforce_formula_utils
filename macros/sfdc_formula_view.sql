{%- macro sfdc_formula_view(source_table, source_name='salesforce', reserved_table_name=source_table, fields_to_include=none, materialization='view', using_quoted_identifiers=False, full_statement_version=true) -%}

-- Best practice for this model is to be materialized as view. That is why we have set that here.
{{
    config(
        materialized = materialization
    )
}}

-- Raise a compiler error if users are trying to use full_statement_version=false. We are keeping the variable in the macro, however, since we don't want errors if they previously set it to true.
{% if not full_statement_version %}
{{ exceptions.raise_compiler_error("\ERROR: Parameter full_statement_version=false is no longer supported. Update your " ~ this.identifier|upper ~ " model to remove the full_statement_version parameter.\n") }}
{% endif %}

/*
    The below sets the old_formula_fields variable to the results of the get_column_values results which queries the field column from the fivetran_formula table.
    The logic here is that the variable will be a list of all current salesforce formula field names. This list is then used within the dbt_utils.star operation to exclude them.
    This allows users with the Fivetran legacy Salesforce fields to ignore them and be replaced by the new fields.
*/

{% if using_quoted_identifiers %}
{%- set table_results = dbt_utils.get_column_values(table=source(source_name, 'fivetran_formula_model'), 
                                                    column='"MODEL"' if target.type in ('snowflake') else '"model"' if target.type in ('postgres', 'redshift', 'snowflake') else '`model`', 
                                                    where=("\"OBJECT\" = '" if target.type in ('snowflake') else "\"object\" = '" if target.type in ('postgres', 'redshift') else "`object` = '") ~ source_table ~ "'") -%}

{% else %}
{%- set table_results = dbt_utils.get_column_values(table=source(source_name, 'fivetran_formula_model'), column='model', where="object = '" ~ source_table ~ "'") -%}

{% endif %}

{{ table_results[0] }}

{%- endmacro -%}