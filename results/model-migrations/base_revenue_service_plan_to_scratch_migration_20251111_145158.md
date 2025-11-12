# Migration Report: base_revenue_service_plan → base_revenue_service_plan_scratch
Generated: Tue Nov 11 14:51:17 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 9 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (9 files)

- **models/models_scratch//core/subscriptions/core_dim_subscription_tiers.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/core_fct_subscription_active_features.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/core_dim_subscription_charges.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/v2_legacy/core_subscriptions_subscription_v2.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/core_dim_subscription_payment_windows.sql**: Updated 3 references
- **models/models_scratch//core/subscriptions/core_dim_subscriptions.sql**: Updated 1 references
- **models/models_scratch//core/corporations/core_corporation_features.sql**: Updated 1 references
- **models/models_scratch//core/onboarding/core_onboarding_records.sql**: Updated 1 references
- **models/models_scratch//base/base_subscriptions/base_revenue_service_features.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/base/base_subscriptions/base_revenue_service_plan.sql` → `models/models_scratch/base/base_subscriptions/base_revenue_service_plan_scratch.sql` (using git mv)
- **Alias Added**: `alias='base_revenue_service_plan'` (preserves table name in database)
- **References Updated**: 9 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='base_revenue_service_plan'
    ...
) }}
```

The alias ensures that:
- The model file is named: `base_revenue_service_plan_scratch.sql`
- The database table is still: `base_revenue_service_plan`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('base_revenue_service_plan_scratch') }}
```

Instead of:
```sql  
{{ ref('base_revenue_service_plan') }}
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
grep -r "ref.*base_revenue_service_plan" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select base_revenue_service_plan+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select base_revenue_service_plan_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select base_revenue_service_plan_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select base_revenue_service_plan_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate base_revenue_service_plan to scratch naming convention

- Rename: base_revenue_service_plan → base_revenue_service_plan_scratch (using git mv)
- Add alias to preserve table name in database
- Update 9 downstream references in models_scratch directory

The model file is now base_revenue_service_plan_scratch.sql but the database 
table remains base_revenue_service_plan due to the alias configuration."
```

## Validation Checklist

- [ ] Compilation status: ✅ SUCCESS (already checked)
- [ ] Grep and dbt list show no remaining refs to `base_revenue_service_plan`
- [ ] If compilation failed: dependent models migrated or error is expected
- [ ] (Optional) Model runs without errors: `dbt run -m base_revenue_service_plan_scratch --defer`
- [ ] Database table is still named `base_revenue_service_plan` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Tue Nov 11 14:51:58 EST 2025  
**Command**: migrate-model-to-scratch base_revenue_service_plan  
**Status**: ✅ Success - Ready to commit
