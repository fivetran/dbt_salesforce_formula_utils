{%- macro sfdc_formula_view(source_table, source_name='salesforce', materialization='view', using_quoted_identifiers=False, full_statement_version=true) -%}

-- Best practice for this model is to be materialized as view. That is why we have set that here.
{{
    config(
        materialized = materialization
    )
}}

-- Raise a warning if users are trying to use full_statement_version=false. We are keeping the variable in the macro, however, since we don't want errors if they previously set it to true.
{% if not full_statement_version %}
    {{ exceptions.warn("\ERROR: The full_statement_version=false, reserved_table_name, and fields_to_include parameters are no longer supported. Please update your " ~ this.identifier|upper ~ " model to remove these parameters.\n") }}
    * See full model error in log.

{% else %}

    {% if using_quoted_identifiers %}
    {%- set table_results = dbt_utils.get_column_values(table=source(source_name, 'fivetran_formula_model'), 
                                                        column='"MODEL"' if target.type in ('snowflake') else '"model"' if target.type in ('postgres', 'redshift', 'snowflake') else '`model`', 
                                                        where=("\"OBJECT\" = '" if target.type in ('snowflake') else "\"object\" = '" if target.type in ('postgres', 'redshift') else "`object` = '") ~ source_table ~ "'") -%}

    {% else %}
    {%- set table_results = dbt_utils.get_column_values(table=source(source_name, 'fivetran_formula_model'), column='model', where="object = '" ~ source_table ~ "'") -%}

    {% endif %}

    {{ table_results[0] }}
{% endif %}
{%- endmacro -%}