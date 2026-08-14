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

    {%- set object_column = adapter.quote('OBJECT' if target.type == 'snowflake' else 'object') if using_quoted_identifiers else 'object' -%}
    {%- set target_engine = target.type | lower -%}

    {%- set formula_query -%}
        select *
        from {{ source(source_name, 'fivetran_formula_model') }}
        where {{ object_column }} = '{{ source_table }}'
    {%- endset -%}

    {%- if execute -%}

        {%- set results = run_query(formula_query) -%}
        {%- set column_names = results.column_names | map('lower') | list -%}

        {%- set model_idx = column_names.index('model') if 'model' in column_names else none -%}
        {%- set model_large_idx = column_names.index('model_large') if 'model_large' in column_names else none -%}
        {%- set query_engine_idx = column_names.index('query_engine') if 'query_engine' in column_names else none -%}
        {%- set synced_idx = column_names.index('_fivetran_synced') if '_fivetran_synced' in column_names else none -%}

        {%- set ns = namespace(best_row=none, best_rank=none, best_synced=none, used_model_large=false) -%}

        {%- for row in results.rows -%}

            {%- set row_model_large = row[model_large_idx] if model_large_idx is not none else none -%}
            {%- set row_model = row[model_idx] if model_idx is not none else none -%}
            {%- set row_value = row_model_large if row_model_large is not none else row_model -%}

            {%- set stored_engine = row[query_engine_idx] if query_engine_idx is not none else none -%}
            {%- set engine = ((stored_engine | trim | lower) or none) if stored_engine is not none else none -%}

            {%- set row_rank = 1 if query_engine_idx is none
                            else (1 if engine == target_engine
                            else (2 if engine == 'generic'
                            else (3 if engine is none else none))) -%}

            {%- set row_synced = row[synced_idx] if synced_idx is not none else none -%}

            {%- set supersedes_best = row_rank is not none
                                    and (ns.best_rank is none
                                        or row_rank < ns.best_rank
                                        or (row_rank == ns.best_rank and row_synced is not none
                                            and (ns.best_synced is none or row_synced > ns.best_synced))) -%}

            {%- if row_value is not none and supersedes_best -%}
                {%- set ns.best_row = row -%}
                {%- set ns.best_rank = row_rank -%}
                {%- set ns.best_synced = row_synced -%}
                {%- set ns.used_model_large = row_model_large is not none -%}
            {%- endif -%}

        {%- endfor -%}

        {%- if ns.best_row is none -%}
            {{ exceptions.raise_compiler_error("sfdc_formula_view: no formula model found for object '" ~ source_table ~ "'. Verify the object name matches a row in the fivetran_formula_model table") }}
        {%- endif -%}

        {%- if ns.used_model_large and target.type == 'redshift' -%}
            {{ fromjson(ns.best_row[model_large_idx]) }}
        {%- elif ns.used_model_large -%}
            {{ ns.best_row[model_large_idx] }}
        {%- else -%}
            {{ ns.best_row[model_idx] }}
        {%- endif -%}

    {%- else -%}
        select 1 as _fivetran_formula_placeholder where false
    {%- endif -%}

{% endif %}
{%- endmacro -%}
