
{{
  config(
    materialized = 'view'
  )
}}

with user_role_view as (
    select
        *,
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='user_role') }}
    from {{ source('salesforce','user_role') }}
)

select * 
from user_role_view
