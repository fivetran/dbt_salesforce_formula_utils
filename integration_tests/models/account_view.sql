{{
  config(
    materialized = 'view'
  )
}}

with account_view as (
    select 
        *,
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='account') }}
    from {{ source('salesforce', 'account') }}
)

select * 
from account_view