# Migration Report: core_fct_zuora_arr_buckets__1based → core_fct_zuora_arr_buckets__1based_scratch
Generated: Mon Nov 10 21:05:55 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 3 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (3 files)

- **models/models_scratch//core/zuora/intermediate/arr_final/core_fct_zuora_arr_buckets__3delta.sql**: Updated 1 references
- **models/models_scratch//core/zuora/intermediate/arr_final/core_fct_zuora_arr_buckets__2churned.sql**: Updated 1 references
- **models/models_scratch//core/zuora/intermediate/arr_final/core_fct_zuora_arr_buckets__7bucketed_month_to_date.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/core/zuora/intermediate/arr_final/core_fct_zuora_arr_buckets__1based.sql` → `models/models_scratch/core/zuora/intermediate/arr_final/core_fct_zuora_arr_buckets__1based_scratch.sql` (using git mv)
- **Alias Added**: `alias='core_fct_zuora_arr_buckets__1based'` (preserves table name in database)
- **References Updated**: 3 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='core_fct_zuora_arr_buckets__1based'
    ...
) }}
```

The alias ensures that:
- The model file is named: `core_fct_zuora_arr_buckets__1based_scratch.sql`
- The database table is still: `core_fct_zuora_arr_buckets__1based`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('core_fct_zuora_arr_buckets__1based_scratch') }}
```

Instead of:
```sql  
{{ ref('core_fct_zuora_arr_buckets__1based') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*core_fct_zuora_arr_buckets__1based" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select core_fct_zuora_arr_buckets__1based+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select core_fct_zuora_arr_buckets__1based_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select core_fct_zuora_arr_buckets__1based_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select core_fct_zuora_arr_buckets__1based_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate core_fct_zuora_arr_buckets__1based to scratch naming convention

- Rename: core_fct_zuora_arr_buckets__1based → core_fct_zuora_arr_buckets__1based_scratch (using git mv)
- Add alias to preserve table name in database
- Update 3 downstream references in models_scratch directory

The model file is now core_fct_zuora_arr_buckets__1based_scratch.sql but the database 
table remains core_fct_zuora_arr_buckets__1based due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `core_fct_zuora_arr_buckets__1based`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `core_fct_zuora_arr_buckets__1based` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 21:06:38 EST 2025  
**Command**: migrate-model-to-scratch core_fct_zuora_arr_buckets__1based  
**Status**: ✅ Success - Ready to commit
