# Google Sheets Base Model Pattern

Google Sheets source models follow a simple ephemeral passthrough pattern.

## Standard Pattern

```sql
{{
  config(
    materialized = "ephemeral"
  )
}}

SELECT *
FROM {{ source("google_sheets", "source_table_name") }}
```

## When to Use

- All base models sourcing from Fivetran Google Sheets connector
- Models that don't need transformation at base layer
- Simple passthrough to preserve raw Google Sheets data

## Naming Convention

**File naming:** `base_google_sheets_[sheet_purpose].sql`

**Examples:**
- `base_google_sheets_arr_manual_override.sql`
- `base_google_sheets_arr_finance_official.sql`
- `base_google_sheets_ccl_sfdc_mapping.sql`
- `base_google_sheets_arr_cap_table_manual_override.sql`
- `base_google_sheets_arr_ctc_manual_override.sql`
- `base_google_sheets_arr_tax_manual_override.sql`

## Migration Pattern

When migrating Google Sheets models to verified:

### Step 1: Create Verified Version
Create new file in `models/models_verified/base/google_sheets/`:
```sql
{{
  config(
    materialized = "ephemeral"
  )
}}

SELECT *
FROM {{ source("google_sheets", "source_table_name") }}
```

### Step 2: Rename Scratch Version
```bash
# Rename scratch file with _scratch suffix
git mv models/models_scratch/base/base_fivetran/base_google_sheets/base_google_sheets_arr_manual_override.sql \
     models/models_scratch/base/base_fivetran/base_google_sheets/base_google_sheets_arr_manual_override_scratch.sql
```

### Step 3: Add Alias to Scratch
Edit the scratch file and add alias config:
```sql
{{
  config(
    alias='base_google_sheets_arr_manual_override',  -- Preserve table name
    materialized = "ephemeral"
  )
}}

SELECT *
FROM {{ source("google_sheets", "arr_manual_override") }}
```

### Step 4: Update References
- Scratch models continue referencing `ref('base_google_sheets_arr_manual_override_scratch')`
- Verified models reference `ref('base_google_sheets_arr_manual_override')`

## Common Use Cases

### Manual ARR Overrides
Finance team uses Google Sheets to override ARR values for specific corporations and date ranges:
- `base_google_sheets_arr_manual_override` - All products override
- `base_google_sheets_arr_cap_table_manual_override` - Cap Table product
- `base_google_sheets_arr_ctc_manual_override` - Compensation product
- `base_google_sheets_arr_tax_manual_override` - Tax product

### Finance Official Data
Monthly revenue close values ingested from Google Sheets:
- `base_google_sheets_arr_finance_official` - Official ARR numbers per month

### Mapping Tables
Manual mapping tables maintained by operations teams:
- `base_google_sheets_ccl_sfdc_mapping` - CCL to Salesforce account mapping
- `base_google_sheets_investor_services_pk_lookup` - Primary key lookup for Investor Services

## Key Points

✅ **Always use ephemeral materialization** - These are passthrough models  
✅ **SELECT * is acceptable** - No transformation needed at base layer  
✅ **Preserve source structure** - Don't rename columns or add logic  
✅ **Document source sheet** - Include Google Sheets URL in comment  

❌ **Don't add transformations** - Keep pure passthrough  
❌ **Don't use table materialization** - Ephemeral only  
❌ **Don't rename columns** - Preserve raw structure
