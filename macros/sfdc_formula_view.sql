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

        {# Specifically for redshift we need to check if the model_large column exists and has_values. #}
        {% set ffm_columns = adapter.get_columns_in_relation(source(source_name, 'fivetran_formula_model')) %}
        {%- set ffm_column_names = ffm_columns | map(attribute='name') | map('lower') | list -%}
        {%- set model_large_col_exists = 'model_large' in ffm_column_names -%}

        {%- if model_large_col_exists %}
            {%- set run_query %}
                select 'has_values'
                from {{ source(source_name, 'fivetran_formula_model') }}
                where model_large is not null
                limit 1
            {%- endset %}
            {%- set model_large_has_values = dbt_utils.get_single_value(run_query) == 'has_values' -%}
        {%- else %}
            {%- set model_large_has_values = false -%}
        {%- endif %}

        {%- set model_column_name = 'model_large' if model_large_has_values else 'model' -%}

        {# Check datatype #}
        {%- set ns = namespace(column_type='string') -%}
        {%- for column in ffm_columns if column.name|lower == model_column_name -%}
            {%- set ns.column_type = column.dtype|lower -%}
        {%- endfor -%}
        {%- set model_column_datatype = ns.column_type -%}

    {% else %}
        {%- set model_column_name = 'MODEL' if target.type == 'snowflake' else 'model' -%}
        {%- set model_column_datatype = 'string' -%}
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
    {% endif %}

    {% if model_column_datatype == 'super' %} -- Defaults to string processing for non-Redshift warehouses
        {# Use dbt's built-in JSON parsing to handle all escape sequences automatically #}
        {% set cleaned_table_results = fromjson(table_results[0]) %}
        {{ cleaned_table_results }}
    {% else %}
        {{ table_results[0] }}
    {% endif %}

{% endif %}
{%- endmacro -%}