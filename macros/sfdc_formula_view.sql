{%- macro sfdc_formula_view(join_to_table_first) -%}

-- Best practice for this model is to be materialized as view. That is why we have set that here.
{{
    config(
        materialized = 'view'
    )
}}

/*
    The below sets the old_formula_fields variable to the results of the get_column_values results which queries the field column from the fivetran_formula table.
    The logic here is that the variable will be a list of all current salesforce formula field names. This list is then used within the dbt_utils.star operation to exclude them.
    This allows users with the Fivetran legacy Salesforce fields to ignore them and be replaced by the new fields.
*/
{%- set source_name_used = var('salesforce_source_name',"salesforce") | string -%}
{%- set old_formula_fields = dbt_utils.get_column_values(source(source_name_used, 'fivetran_formula'),'field') -%}
    
    select 
        {{ dbt_utils.star(source(source_name_used,join_to_table_first), except=old_formula_fields) }},
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table=join_to_table_first, source_name=source_name_used) }}
    from {{ source(source_name_used,join_to_table_first) }}

{%- endmacro -%}