{%- macro sfdc_formula_view(source_table, source_name='salesforce', materialization='view', using_quoted_identifiers=False, full_statement_version=true, reserved_table_name=none, fields_to_include=none) -%}

-- Best practice for this model is to be materialized as view. That is why we have set that here.
{{
    config(
        materialized = materialization
    )
}}

{# Raise a warning if users are trying to use full_statement_version=false. We are keeping the variable in the macro, however, since we don't want errors if they previously set it to true. #}
{% if not full_statement_version %}
    {{ exceptions.warn("\nERROR: The full_statement_version=false, reserved_table_name, and fields_to_include parameters are no longer supported. Please update your " ~ this.identifier|upper ~ " model to remove these parameters.\n") }}
    See_full_model_error_in_log

{% else %}
    {% if target.type == 'redshift' %}
        {% set columns = adapter.get_columns_in_relation(source(source_name, 'fivetran_formula_model')) %}
        {% set column_names = columns | map(attribute='name') | list %}
        {%- set using_model_large = 'model_large' in column_names -%}
        {%- set model_column_name = 'model_large' if using_model_large else 'model' -%}
    {% else %}
        {%- set using_model_large = false -%}
        {%- set model_column_name = 'MODEL' if target.type == 'snowflake' else 'model' -%}
    {% endif %}

    {% if using_quoted_identifiers %}
    {%- set table_results = dbt_utils.get_column_values(
        table=source(source_name, 'fivetran_formula_model'), 
        column=adapter.quote(model_column_name), 
        where=adapter.quote('OBJECT' if target.type == 'snowflake' else 'object') ~ " = '" ~ source_table ~ "'"
        ) -%}

    {% else %}
    {%- set table_results = dbt_utils.get_column_values(
        table=source(source_name, 'fivetran_formula_model'),
        column=model_column_name,
        where="object = '" ~ source_table ~ "'"
        ) -%}


    {% if using_model_large %}
        {# Use dbt's built-in JSON parsing to handle all escape sequences automatically #}
        {% set cleaned_table_results = fromjson(fromjson(table_results[0])) %}
        {{ cleaned_table_results }}
    {% else %}
        {{ table_results[0] }}
    {% endif %}

{% endif %}
{%- endmacro -%}