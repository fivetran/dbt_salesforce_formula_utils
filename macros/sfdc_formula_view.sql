{%- macro sfdc_formula_view(join_to_table_first) -%}


{{
    config(
        materialized = 'view'
    )
}}
    select 
        *,
        {{ dbt_salesforce_formula_utils.sfdc_formula_pivot(join_to_table=join_to_table_first) }}
    from {{ source('salesforce',join_to_table_first) }}

{%- endmacro -%}