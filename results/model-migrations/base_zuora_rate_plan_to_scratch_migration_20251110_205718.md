# Migration Report: base_zuora_rate_plan → base_zuora_rate_plan_scratch
Generated: Mon Nov 10 20:56:36 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 1 files with text references
- **dbt list**: Found 1 files with dependency references

## Downstream References Updated (1 files)

- **models/models_scratch//core/zuora/core_dim_zuora_subscriptions.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/base/base_zuora/base_zuora_rate_plan.sql` → `models/models_scratch/base/base_zuora/base_zuora_rate_plan_scratch.sql` (using git mv)
- **Alias Added**: `alias='base_zuora_rate_plan'` (preserves table name in database)
- **References Updated**: 1 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='base_zuora_rate_plan'
    ...
) }}
```

The alias ensures that:
- The model file is named: `base_zuora_rate_plan_scratch.sql`
- The database table is still: `base_zuora_rate_plan`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('base_zuora_rate_plan_scratch') }}
```

Instead of:
```sql  
{{ ref('base_zuora_rate_plan') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*base_zuora_rate_plan" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select base_zuora_rate_plan+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select base_zuora_rate_plan_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select base_zuora_rate_plan_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select base_zuora_rate_plan_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate base_zuora_rate_plan to scratch naming convention

- Rename: base_zuora_rate_plan → base_zuora_rate_plan_scratch (using git mv)
- Add alias to preserve table name in database
- Update 1 downstream references in models_scratch directory

The model file is now base_zuora_rate_plan_scratch.sql but the database 
table remains base_zuora_rate_plan due to the alias configuration."
```

## Validation Checklist

- [ ] Grep and dbt list show no remaining refs to `base_zuora_rate_plan`
- [ ] Model compiles successfully
- [ ] Model runs without errors  
- [ ] All downstream models compile and run
- [ ] Database table is still named `base_zuora_rate_plan` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Mon Nov 10 20:57:18 EST 2025  
**Command**: migrate-model-to-scratch base_zuora_rate_plan  
**Status**: ✅ Success - Ready to commit
