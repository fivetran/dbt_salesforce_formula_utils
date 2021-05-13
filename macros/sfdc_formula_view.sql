{%- macro sfdc_formula_view(join_to_table_first) -%}

{{
    config(
        materialized = 'view'
    )
}}

{%- set old_formula_fields = dbt_utils.get_column_values(source('salesforce', 'fivetran_formula'),'field') -%}
    
    select 
        {{ dbt_utils.star(source('salesforce',join_to_table_first), except=old_formula_fields) }},
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table=join_to_table_first) }}
    from {{ source('salesforce',join_to_table_first) }}

{%- endmacro -%}