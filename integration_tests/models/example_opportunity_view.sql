{{
  config(
    materialized = 'view'
  )
}}

with opportunity_view as (
    select 
        *,
        {{ sfdc_fivetran_formula.sfdc_formula_pivot(join_to_table='opportunity_data') }}
    from {{ source('salesforce', 'opportunity_data') }}
)

select * 
from opportunity_view