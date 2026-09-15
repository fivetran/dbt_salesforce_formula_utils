{%- macro sfdc_formula_view(source_table, source_name='salesforce', materialization='view', using_quoted_identifiers=False, full_statement_version=true, reserved_table_name=none, fields_to_include=none) -%}

-- Default materialization is view. Redshift MDLS users must pass materialization='table' — Redshift Spectrum external schemas do not support views.
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

    {# Identifiers for the destination. #}
    {%- set object_column = adapter.quote('OBJECT' if target.type == 'snowflake' else 'object') if using_quoted_identifiers else 'object' -%}
    {%- set target_engine = target.type | lower -%}

    {# One warehouse query per model. `select *` so the returned columns tell us the destination shape. #}
    {%- set formula_query -%}
        select *
        from {{ source(source_name, 'fivetran_formula_model') }}
        where {{ object_column }} = '{{ source_table }}'
    {%- endset -%}

    {%- if execute -%}

        {%- set results = run_query(formula_query) -%}
        {%- set column_names = results.column_names | map('lower') | list -%}

        {# Find columns by name, read rows by position, so identifier casing doesn't matter. `query_engine` exists on MDLS only, `model_large` on Redshift only. #}
        {%- set model_idx = column_names.index('model') if 'model' in column_names else none -%}
        {%- set model_large_idx = column_names.index('model_large') if 'model_large' in column_names else none -%}
        {%- set query_engine_idx = column_names.index('query_engine') if 'query_engine' in column_names else none -%}

        {# Collect each usable row, keyed by its query engine. #}
        {%- set by_engine = {} -%}

        {%- for row in results.rows -%}

            {%- set row_model_large = row[model_large_idx] if model_large_idx is not none else none -%}
            {%- set row_model = row[model_idx] if model_idx is not none else none -%}
            {%- set row_value = row_model_large if row_model_large is not none else row_model -%}

            {%- set stored_engine = row[query_engine_idx] if query_engine_idx is not none else none -%}
            {%- set engine = ((stored_engine | trim | lower) or none) if stored_engine is not none else none -%}

            {%- if row_value is not none -%}
                {%- do by_engine.update({engine: row}) -%}
            {%- endif -%}

        {%- endfor -%}

        {# Use the row matching this destination's engine, then 'generic', then unset. Non-MDLS has no query_engine column, so its single row lands under the unset key. #}
        {%- set best_row = by_engine.get(target_engine) or by_engine.get('generic') or by_engine.get(none) -%}

        {%- if best_row is none -%}
            {{ exceptions.raise_compiler_error("sfdc_formula_view: no formula model found for object '" ~ source_table ~ "'. Verify the object name matches a row in the fivetran_formula_model table") }}
        {%- endif -%}

        {# Emit the model. On Redshift, model_large may be a JSON-encoded SUPER value that needs unwrapping
           via fromjson(), or it may be plain VARCHAR holding raw SQL. Fall back to the raw value when
           fromjson() returns none (parse failure), so a VARCHAR model_large never silently becomes None. #}
        {%- set best_model_large = best_row[model_large_idx] if model_large_idx is not none else none -%}
        {%- set unwrapped = fromjson(best_model_large) if best_model_large is not none else none -%}

        {%- if unwrapped is not none -%}
            {{ unwrapped }}
        {%- elif best_model_large is not none -%}
            {{ best_model_large }}
        {%- else -%}
            {{ best_row[model_idx] }}
        {%- endif -%}

    {%- else -%}
        select 1 as _fivetran_formula_placeholder where false
    {%- endif -%}

{% endif %}
{%- endmacro -%}
