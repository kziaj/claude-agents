# Migration Report: base_zuora_rate_plan_charge → base_zuora_rate_plan_charge_scratch
Generated: Mon Nov 10 20:57:18 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 4 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (4 files)

- **models/models_scratch//core/zuora/core_fct_zuora_quantity_details.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_dim_zuora_subscriptions.sql**: Updated 1 references
- **models/models_scratch//core/zuora/core_fct_zuora_invoice_details.sql**: Updated 1 references
- **models/models_scratch//core/zuora/intermediate/llc_decomp/core_fct_zuora_arr_escalator_llc.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/base/base_zuora/base_zuora_rate_plan_charge.sql` → `models/models_scratch/base/base_zuora/base_zuora_rate_plan_charge_scratch.sql` (using git mv)
- **Alias Added**: `alias='base_zuora_rate_plan_charge'` (preserves table name in database)
- **References Updated**: 4 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='base_zuora_rate_plan_charge'
    ...
) }}
```

The alias ensures that:
- The model file is named: `base_zuora_rate_plan_charge_scratch.sql`
- The database table is still: `base_zuora_rate_plan_charge`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('base_zuora_rate_plan_charge_scratch') }}
```

Instead of:
```sql  
{{ ref('base_zuora_rate_plan_charge') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*base_zuora_rate_plan_charge" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select base_zuora_rate_plan_charge+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select base_zuora_rate_plan_charge_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select base_zuora_rate_plan_charge_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select base_zuora_rate_plan_charge_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate base_zuora_rate_plan_charge to scratch naming convention

- Rename: base_zuora_rate_plan_charge → base_zuora_rate_plan_charge_scratch (using git mv)
- Add alias to preserve table name in database
- Update 4 downstream references in models_scratch directory

The model file is now base_zuora_rate_plan_charge_scratch.sql but the database 
table remains base_zuora_rate_plan_charge due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `base_zuora_rate_plan_charge`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `base_zuora_rate_plan_charge` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 20:58:01 EST 2025  
**Command**: migrate-model-to-scratch base_zuora_rate_plan_charge  
**Status**: ✅ Success - Ready to commit
