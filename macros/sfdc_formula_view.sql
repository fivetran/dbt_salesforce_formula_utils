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

    {% set formula_model_columns = adapter.get_columns_in_relation(source(source_name, 'fivetran_formula_model')) %}
    {%- set formula_model_column_names = formula_model_columns | map(attribute='name') | map('lower') | list -%}

    {% if target.type == 'redshift' %}

        {# Specifically for redshift we need to check if the model_large column exists and has non-null values. #}
        {%- set model_large_col_exists = 'model_large' in formula_model_column_names -%}

        {%- set run_query %}
            select 'has_values'
            from {{ source(source_name, 'fivetran_formula_model') }}
            where model_large is not null
            limit 1
        {%- endset %}

        {# Use the run_query only if model_large_col_exists #}
        {%- set model_large_has_values = (dbt_utils.get_single_value(run_query) == 'has_values') if model_large_col_exists else false -%}
        {%- set model_column_name = 'model_large' if model_large_has_values else 'model' -%}

        {# Check datatype #}
        {%- set ns = namespace(column_type='string') -%}
        {%- for column in formula_model_columns if column.name|lower == model_column_name -%}
            {%- set ns.column_type = column.dtype|lower -%}
        {%- endfor -%}
        {%- set model_column_datatype = ns.column_type -%}

    {% else %}
        {%- set model_column_name = 'MODEL' if target.type == 'snowflake' else 'model' -%}
        {%- set model_column_datatype = 'string' -%}
    {% endif %}

    {%- set object_column = adapter.quote('OBJECT' if target.type == 'snowflake' else 'object') if using_quoted_identifiers else 'object' -%}
    {%- set model_col = adapter.quote(model_column_name) if using_quoted_identifiers else model_column_name -%}
    {%- set query_engine_col = adapter.quote('QUERY_ENGINE' if target.type == 'snowflake' else 'query_engine') if using_quoted_identifiers else 'query_engine' -%}
    {%- set query_engine = target.type|lower if target.type|lower in ("bigquery", "snowflake", "redshift", "databricks") else "generic"  -%}

    {# Detect if query_engine column exists — only MDLS destinations have it #}
    {% set is_mdls = 'query_engine' in formula_model_column_names %}

    {%- set table_results = dbt_utils.get_column_values(
        table=source(source_name, 'fivetran_formula_model'),
        column=model_col,
        where=object_column ~ " = '" ~ source_table ~ "'" ~ (" and " ~ query_engine_col ~ " = '" ~ query_engine ~ "'" if is_mdls else "")
    ) -%}

    {# Use dbt's built-in JSON parsing to handle all escape sequences for SUPER datatype #}
    {{ fromjson(table_results[0]) if model_column_datatype == 'super' else table_results[0] }}

{% endif %}
{%- endmacro -%}