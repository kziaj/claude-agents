# Migration Report: core_finance_arr_official → core_finance_arr_official_scratch
Generated: Mon Nov 10 21:01:18 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 10 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (10 files)

- **models/models_scratch//core/zuora/core_fct_zuora_arr_scratch.sql**: Updated 3 references
- **models/models_scratch//core/zuora/intermediate/finance_official/core_fct_zuora_arr_buckets__3b_delta_finance.sql**: Updated 1 references
- **models/models_scratch//core/zuora/intermediate/finance_official/core_fct_zuora_arr_buckets__8b_bucketed_time_to_date_finance.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/core_fct_subscription_arr.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/intermediate/core_fct_subscription_arr__4joined.sql**: Updated 2 references
- **models/models_scratch//core/finance/core_finance_corp_arr_diff.sql**: Updated 1 references
- **models/models_scratch//marts/corporations/mart_fct_corporations_renewal_pricing_analysis.sql**: Updated 3 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporation_buckets/finance_official/mart_corporations_delta_finance_official.sql**: Updated 2 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporation_buckets/finance_official/mart_fct_corporation_buckets__5c_bucketed_time_to_date_finance_official.sql**: Updated 1 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporation_buckets/arr_with_overrides/mart_corporations_churned.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/core/finance/core_finance_arr_official.sql` → `models/models_scratch/core/finance/core_finance_arr_official_scratch.sql` (using git mv)
- **Alias Added**: `alias='core_finance_arr_official'` (preserves table name in database)
- **References Updated**: 10 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='core_finance_arr_official'
    ...
) }}
```

The alias ensures that:
- The model file is named: `core_finance_arr_official_scratch.sql`
- The database table is still: `core_finance_arr_official`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('core_finance_arr_official_scratch') }}
```

Instead of:
```sql  
{{ ref('core_finance_arr_official') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*core_finance_arr_official" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select core_finance_arr_official+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select core_finance_arr_official_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select core_finance_arr_official_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select core_finance_arr_official_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate core_finance_arr_official to scratch naming convention

- Rename: core_finance_arr_official → core_finance_arr_official_scratch (using git mv)
- Add alias to preserve table name in database
- Update 10 downstream references in models_scratch directory

The model file is now core_finance_arr_official_scratch.sql but the database 
table remains core_finance_arr_official due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `core_finance_arr_official`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `core_finance_arr_official` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 21:02:00 EST 2025  
**Command**: migrate-model-to-scratch core_finance_arr_official  
**Status**: ✅ Success - Ready to commit
