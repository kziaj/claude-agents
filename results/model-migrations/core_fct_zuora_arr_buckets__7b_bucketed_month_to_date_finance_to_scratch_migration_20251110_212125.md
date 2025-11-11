# Migration Report: core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance → core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch
Generated: Mon Nov 10 21:20:40 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 1 files with text references
- **dbt list**: Found 1 files with dependency references

## Downstream References Updated (1 files)

- **models/models_scratch//core/zuora/intermediate/finance_official/core_fct_zuora_arr_buckets__8b_bucketed_time_to_date_finance.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/core/zuora/intermediate/finance_official/core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance.sql` → `models/models_scratch/core/zuora/intermediate/finance_official/core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch.sql` (using git mv)
- **Alias Added**: `alias='core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance'` (preserves table name in database)
- **References Updated**: 1 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance'
    ...
) }}
```

The alias ensures that:
- The model file is named: `core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch.sql`
- The database table is still: `core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch') }}
```

Instead of:
```sql  
{{ ref('core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance to scratch naming convention

- Rename: core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance → core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch (using git mv)
- Add alias to preserve table name in database
- Update 1 downstream references in models_scratch directory

The model file is now core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch.sql but the database 
table remains core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 21:21:25 EST 2025  
**Command**: migrate-model-to-scratch core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance  
**Status**: ✅ Success - Ready to commit
