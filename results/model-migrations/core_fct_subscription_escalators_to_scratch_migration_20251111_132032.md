# Migration Report: core_fct_subscription_escalators → core_fct_subscription_escalators_scratch
Generated: Tue Nov 11 13:18:40 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 2 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (2 files)

- **models/models_scratch//core/subscriptions/core_dim_subscription_payment_windows.sql**: Updated 1 references
- **models/models_scratch//marts/corporations/mart_dim_corporations.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/core/subscriptions/core_fct_subscription_escalators.sql` → `models/models_scratch/core/subscriptions/core_fct_subscription_escalators_scratch.sql` (using git mv)
- **Alias Added**: `alias='core_fct_subscription_escalators'` (preserves table name in database)
- **References Updated**: 2 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='core_fct_subscription_escalators'
    ...
) }}
```

The alias ensures that:
- The model file is named: `core_fct_subscription_escalators_scratch.sql`
- The database table is still: `core_fct_subscription_escalators`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('core_fct_subscription_escalators_scratch') }}
```

Instead of:
```sql  
{{ ref('core_fct_subscription_escalators') }}
```

### Git Status
All changes have been staged with git and are ready to commit.

### Compilation Status
✅ SUCCESS

The model was automatically compiled after migration to validate syntax and references.

## Validation Commands

### 1. Verify no missed references (using both methods):
```bash
# Text search
grep -r "ref.*core_fct_subscription_escalators" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select core_fct_subscription_escalators+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select core_fct_subscription_escalators_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select core_fct_subscription_escalators_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select core_fct_subscription_escalators_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate core_fct_subscription_escalators to scratch naming convention

- Rename: core_fct_subscription_escalators → core_fct_subscription_escalators_scratch (using git mv)
- Add alias to preserve table name in database
- Update 2 downstream references in models_scratch directory

The model file is now core_fct_subscription_escalators_scratch.sql but the database 
table remains core_fct_subscription_escalators due to the alias configuration."
```

## Validation Checklist

- [ ] Compilation status: ✅ SUCCESS (already checked)
- [ ] Grep and dbt list show no remaining refs to `core_fct_subscription_escalators`
- [ ] If compilation failed: dependent models migrated or error is expected
- [ ] (Optional) Model runs without errors: `dbt run -m core_fct_subscription_escalators_scratch --defer`
- [ ] Database table is still named `core_fct_subscription_escalators` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Tue Nov 11 13:20:32 EST 2025  
**Command**: migrate-model-to-scratch core_fct_subscription_escalators  
**Status**: ✅ Success - Ready to commit
