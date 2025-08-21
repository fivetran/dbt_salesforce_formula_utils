# Including Deleted Records in Salesforce Formula Field Models

This guide explains how to use the enhanced `sfdc_formula_view` macro to include deleted records in your Salesforce formula field calculations.

## Overview

By default, Salesforce formula field models automatically filter out deleted records using `WHERE NOT _fivetran_deleted` conditions. The enhanced macro now provides an option to include deleted records in your models.

## Updated Macro Parameters

The `sfdc_formula_view` macro now includes a new parameter:

```sql
{{ sfdc_formula_view(
    source_table='account',
    source_name='salesforce',
    materialization='view',
    using_quoted_identifiers=false,
    include_deleted_records=true  -- NEW PARAMETER (default: true)
) }}
```

### Parameters

- **`include_deleted_records`** (boolean, default: `true`)
  - `true`: Remove all deletion filtering logic - includes deleted records
  - `false`: Keep original deletion filtering logic - excludes deleted records

## Usage Examples

### Example 1: Include Deleted Records (Default Behavior)

```sql
-- models/account_with_deleted.sql
{{ config(materialized='view') }}

{{ sfdc_formula_view(
    source_table='account'
) }}
```

This will generate a model that includes all records (active and deleted) with formula field calculations.

### Example 2: Explicitly Include Deleted Records

```sql
-- models/opportunity_all_records.sql
{{ config(materialized='view') }}

{{ sfdc_formula_view(
    source_table='opportunity',
    include_deleted_records=true
) }}
```

### Example 3: Exclude Deleted Records (Original Behavior)

```sql
-- models/contact_active_only.sql
{{ config(materialized='view') }}

{{ sfdc_formula_view(
    source_table='contact',
    include_deleted_records=false
) }}
```

This maintains the original filtering behavior where deleted records are excluded.

## What Gets Modified

The macro automatically removes the following patterns from the generated SQL:

### WHERE Clause Filters
- `WHERE NOT table._fivetran_deleted`
- `WHERE table._fivetran_deleted = false`
- `WHERE table._fivetran_deleted != true`
- `WHERE table._fivetran_active` (for history tables)
- Complex combinations with other conditions

### JOIN Condition Filters
- `AND NOT joined_table._fivetran_deleted` in JOIN clauses
- `AND joined_table._fivetran_active` in JOIN clauses

### Quoted Identifier Support
Handles all deletion filtering patterns with:
- Backticks: `` `_fivetran_deleted` ``
- Double quotes: `"_fivetran_deleted"`
- Unquoted: `_fivetran_deleted`

## Advanced Use Cases

### Creating Status-Aware Models

```sql
-- models/account_with_status.sql
{{ config(materialized='view') }}

SELECT 
  *,
  CASE 
    WHEN _fivetran_deleted THEN 'DELETED'
    ELSE 'ACTIVE'
  END as record_status,
  
  -- Formula fields will be calculated for both active and deleted records
  -- But you might want special handling for deleted records
  CASE 
    WHEN _fivetran_deleted THEN NULL 
    ELSE calculated_formula_field 
  END as safe_formula_field

FROM (
  {{ sfdc_formula_view(
      source_table='account',
      include_deleted_records=true
  ) }}
) base
```

### Comparing Active vs All Records

```sql
-- models/account_comparison.sql
{{ config(materialized='view') }}

WITH active_only AS (
  {{ sfdc_formula_view(
      source_table='account',
      include_deleted_records=false
  ) }}
),

all_records AS (
  {{ sfdc_formula_view(
      source_table='account',
      include_deleted_records=true
  ) }}
)

SELECT 
  'active_only' as dataset_type,
  COUNT(*) as record_count,
  AVG(annual_revenue_formula) as avg_formula_value
FROM active_only

UNION ALL

SELECT 
  'all_records' as dataset_type,
  COUNT(*) as record_count,
  AVG(annual_revenue_formula) as avg_formula_value
FROM all_records
```

## Benefits

1. **Historical Analysis**: Include deleted records in trend analysis and historical reporting
2. **Data Completeness**: Ensure no data is lost in calculations spanning record lifecycle
3. **Audit Trails**: Maintain complete record of all formula field calculations
4. **Flexible Reporting**: Choose per-model whether to include deleted records

## Important Considerations

1. **Performance**: Including deleted records may impact query performance on large datasets
2. **Data Quality**: Deleted records may have stale or incomplete field values
3. **Business Logic**: Consider whether deleted records should participate in calculations
4. **Storage**: Models with deleted records will be larger

## Migration Guide

### From Original Behavior (Excluding Deleted Records)

If you want to maintain the original behavior:

```sql
-- Keep this for models that should exclude deleted records
{{ sfdc_formula_view(
    source_table='account',
    include_deleted_records=false
) }}
```

### To New Behavior (Including Deleted Records)

Simply use the macro without the parameter (defaults to including deleted records):

```sql
-- This now includes deleted records by default
{{ sfdc_formula_view(
    source_table='account'
) }}
```

## Troubleshooting

### Common Issues

1. **Empty WHERE clauses**: The macro automatically cleans up empty WHERE clauses
2. **Malformed SQL**: The macro handles complex nested conditions and parentheses
3. **Performance issues**: Consider materializing as tables for large datasets with many deleted records

### Debugging

To see the modified SQL, you can compile your model:

```bash
dbt compile --select your_model_name
```

Then check the compiled SQL in `target/compiled/` to verify the deletion filtering has been properly removed.

## Support

This enhancement maintains backward compatibility. Existing models will continue to work, but now include deleted records by default. Use `include_deleted_records=false` to maintain the original filtering behavior.