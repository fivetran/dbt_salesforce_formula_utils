{%- macro sfdc_formula_view(join_to_table_first, source_name='salesforce') -%}

{{
    config(
        materialized = 'view'
    )
}}

{%- set old_formula_fields = dbt_utils.get_column_values(source(source_name, 'fivetran_formula'),'field') -%}
    
    select 
        {{ dbt_utils.star(source(source_name,join_to_table_first), except=old_formula_fields) }},
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table=join_to_table_first) }}
    from {{ source(source_name,join_to_table_first) }}

{%- endmacro -%}