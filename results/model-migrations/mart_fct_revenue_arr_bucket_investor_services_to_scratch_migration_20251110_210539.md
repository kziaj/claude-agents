# Migration Report: mart_fct_revenue_arr_bucket_investor_services → mart_fct_revenue_arr_bucket_investor_services_scratch
Generated: Mon Nov 10 21:04:56 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 0 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated
No downstream references found in models_scratch directory.

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/marts/revenue/mart_fct_revenue_arr_bucket_investor_services.sql` → `models/models_scratch/marts/revenue/mart_fct_revenue_arr_bucket_investor_services_scratch.sql` (using git mv)
- **Alias Added**: `alias='mart_fct_revenue_arr_bucket_investor_services'` (preserves table name in database)
- **References Updated**:  files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='mart_fct_revenue_arr_bucket_investor_services'
    ...
) }}
```

The alias ensures that:
- The model file is named: `mart_fct_revenue_arr_bucket_investor_services_scratch.sql`
- The database table is still: `mart_fct_revenue_arr_bucket_investor_services`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('mart_fct_revenue_arr_bucket_investor_services_scratch') }}
```

Instead of:
```sql  
{{ ref('mart_fct_revenue_arr_bucket_investor_services') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*mart_fct_revenue_arr_bucket_investor_services" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select mart_fct_revenue_arr_bucket_investor_services+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select mart_fct_revenue_arr_bucket_investor_services_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select mart_fct_revenue_arr_bucket_investor_services_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select mart_fct_revenue_arr_bucket_investor_services_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate mart_fct_revenue_arr_bucket_investor_services to scratch naming convention

- Rename: mart_fct_revenue_arr_bucket_investor_services → mart_fct_revenue_arr_bucket_investor_services_scratch (using git mv)
- Add alias to preserve table name in database
- Update  downstream references in models_scratch directory

The model file is now mart_fct_revenue_arr_bucket_investor_services_scratch.sql but the database 
table remains mart_fct_revenue_arr_bucket_investor_services due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `mart_fct_revenue_arr_bucket_investor_services`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `mart_fct_revenue_arr_bucket_investor_services` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 21:05:39 EST 2025  
**Command**: migrate-model-to-scratch mart_fct_revenue_arr_bucket_investor_services  
**Status**: ✅ Success - Ready to commit
