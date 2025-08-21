{{ config(materialized='view') }}

-- Test model to verify the include_deleted_records parameter works correctly
-- This model includes deleted records by using the default behavior

{{ sfdc_formula_view(
    source_table='account',
    include_deleted_records=true
) }}