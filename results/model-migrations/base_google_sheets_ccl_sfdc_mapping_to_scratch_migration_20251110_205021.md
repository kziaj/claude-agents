# Migration Report: base_google_sheets_ccl_sfdc_mapping → base_google_sheets_ccl_sfdc_mapping_scratch
Generated: Mon Nov 10 20:49:37 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 4 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (4 files)

- **models/models_scratch//core/zuora/core_fct_zuora_arr_scratch.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_fct_zuora_arr_by_rate_plan.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_fct_zuora_arr_by_salesforce_entity.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_dim_zuora_accounts.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/base/base_fivetran/base_google_sheets/base_google_sheets_ccl_sfdc_mapping.sql` → `models/models_scratch/base/base_fivetran/base_google_sheets/base_google_sheets_ccl_sfdc_mapping_scratch.sql` (using git mv)
- **Alias Added**: `alias='base_google_sheets_ccl_sfdc_mapping'` (preserves table name in database)
- **References Updated**: 4 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='base_google_sheets_ccl_sfdc_mapping'
    ...
) }}
```

The alias ensures that:
- The model file is named: `base_google_sheets_ccl_sfdc_mapping_scratch.sql`
- The database table is still: `base_google_sheets_ccl_sfdc_mapping`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('base_google_sheets_ccl_sfdc_mapping_scratch') }}
```

Instead of:
```sql  
{{ ref('base_google_sheets_ccl_sfdc_mapping') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*base_google_sheets_ccl_sfdc_mapping" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select base_google_sheets_ccl_sfdc_mapping+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select base_google_sheets_ccl_sfdc_mapping_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select base_google_sheets_ccl_sfdc_mapping_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select base_google_sheets_ccl_sfdc_mapping_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate base_google_sheets_ccl_sfdc_mapping to scratch naming convention

- Rename: base_google_sheets_ccl_sfdc_mapping → base_google_sheets_ccl_sfdc_mapping_scratch (using git mv)
- Add alias to preserve table name in database
- Update 4 downstream references in models_scratch directory

The model file is now base_google_sheets_ccl_sfdc_mapping_scratch.sql but the database 
table remains base_google_sheets_ccl_sfdc_mapping due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `base_google_sheets_ccl_sfdc_mapping`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `base_google_sheets_ccl_sfdc_mapping` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 20:50:21 EST 2025  
**Command**: migrate-model-to-scratch base_google_sheets_ccl_sfdc_mapping  
**Status**: ✅ Success - Ready to commit
