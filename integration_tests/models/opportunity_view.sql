{{
  config(
    materialized = 'view'
  )
}}

with opportunity_view as (
    select 
        *,
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='opportunity') }}
    from {{ source('salesforce', 'opportunity') }}
)

select * 
from opportunity_view