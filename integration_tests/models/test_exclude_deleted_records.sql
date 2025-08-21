{{ config(materialized='view') }}

-- Test model to verify the original behavior (exclude deleted records) still works
-- This model excludes deleted records by explicitly setting include_deleted_records=false

{{ sfdc_formula_view(
    source_table='account',
    include_deleted_records=false
) }}