#!/bin/bash
mkdir -p $1/models
echo "" >> $1/models/$3_view.sql
echo "{{
  config(
    materialized = 'view'
  )
}}

with $3_view as (
    select
        *,
        {{ salesforce_formula_utils.sfdc_formula_pivot(join_to_table='$3') }}
    from {{ source('$2','$3') }}
)

select * 
from $3_view" >> $1/models/$3_view.sql