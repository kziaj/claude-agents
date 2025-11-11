# Migration Report: base_zuora_account → base_zuora_account_scratch
Generated: Mon Nov 10 20:50:34 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 9 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (9 files)

- **models/models_scratch//core/catalyst/core_catalyst_llc.sql**: Updated 2 references
- **models/models_scratch//core/zuora/core_fct_zuora_arr_scratch.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_fct_zuora_quantity_details.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_dim_zuora_subscriptions.sql**: Updated 3 references
- **models/models_scratch//core/zuora/revpro/core_fct_zuora_revpro_roll_forward_report.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_fct_zuora_arr_by_rate_plan.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_fct_zuora_invoice_details.sql**: Updated 1 references
- **models/models_scratch//core/zuora/intermediate/core_dim_zuora_accounts__mark_dupes.sql**: Updated 2 references
- **models/models_scratch//core/zuora/core_fct_zuora_arr_by_salesforce_entity.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/base/base_zuora/base_zuora_account.sql` → `models/models_scratch/base/base_zuora/base_zuora_account_scratch.sql` (using git mv)
- **Alias Added**: `alias='base_zuora_account'` (preserves table name in database)
- **References Updated**: 9 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='base_zuora_account'
    ...
) }}
```

The alias ensures that:
- The model file is named: `base_zuora_account_scratch.sql`
- The database table is still: `base_zuora_account`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('base_zuora_account_scratch') }}
```

Instead of:
```sql  
{{ ref('base_zuora_account') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*base_zuora_account" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select base_zuora_account+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select base_zuora_account_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select base_zuora_account_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select base_zuora_account_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate base_zuora_account to scratch naming convention

- Rename: base_zuora_account → base_zuora_account_scratch (using git mv)
- Add alias to preserve table name in database
- Update 9 downstream references in models_scratch directory

The model file is now base_zuora_account_scratch.sql but the database 
table remains base_zuora_account due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `base_zuora_account`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `base_zuora_account` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 20:51:18 EST 2025  
**Command**: migrate-model-to-scratch base_zuora_account  
**Status**: ✅ Success - Ready to commit
