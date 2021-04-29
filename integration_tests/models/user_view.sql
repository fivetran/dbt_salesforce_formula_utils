
{{
  config(
    materialized = 'view'
  )
}}

with user_view as (
    select
        *,
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='user') }}
    from {{ source('salesforce','user') }}
)

select * 
from user_view
