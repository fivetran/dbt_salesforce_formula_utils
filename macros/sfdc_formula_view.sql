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

    {%- set table_results = dbt_utils.get_column_values(table=source(source_name, 'fivetran_formula_model'), column=adapter.quote(model_column_name) if using_quoted_identifiers else model_column_name, where="object = '" ~ source_table ~ "'") -%}

    {% if using_model_large %}
        {# Extract SQL from model_large super column and remove escape characters #}
        {% set raw_sql = table_results[0] %}
        {% if raw_sql %}
            {{ log("DEBUG: Raw SQL from super column: " ~ raw_sql, info=True) }}

            {# Remove outer quotes if present (JSON string format) #}
            {% if raw_sql.startswith('"') and raw_sql.endswith('"') %}
                {% set clean_sql = raw_sql[1:-1] %}
            {% else %}
                {% set clean_sql = raw_sql %}
            {% endif %}

            {{ log("DEBUG: After removing outer quotes: " ~ clean_sql, info=True) }}

            {# Process double-escaped characters from super column #}
            {% set clean_sql = clean_sql.replace('\\\\n', '\n') %}
            {% set clean_sql = clean_sql.replace('\\\\t', '\t') %}
            {% set clean_sql = clean_sql.replace('\\\\\"', '"') %}
            {% set clean_sql = clean_sql.replace('\\\\_', '_') %}

            {# Clean up any remaining single-escaped characters #}
            {% set clean_sql = clean_sql.replace('\\n', '\n') %}
            {% set clean_sql = clean_sql.replace('\\t', '\t') %}
            {% set clean_sql = clean_sql.replace('\\"', '"') %}
            {% set clean_sql = clean_sql.replace('\\_', '_') %}

            {# Remove any trailing empty quotes #}
            {% set clean_sql = clean_sql.replace('""', '') %}
            {% set clean_sql = clean_sql.rstrip('"') %}

            {{ log("DEBUG: Final cleaned SQL: " ~ clean_sql, info=True) }}
            {{ clean_sql }}
        {% endif %}
    {% else %}
        {{ table_results[0] }}
    {% endif %}

{% endif %}
{%- endmacro -%}