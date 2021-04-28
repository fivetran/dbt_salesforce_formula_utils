{{
  config(
    materialized = 'view'
  )
}}

with account_view as (
    select 
        *,
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='account_data') }}
    from {{ source('salesforce', 'account_data') }}
)

select * 
from account_view