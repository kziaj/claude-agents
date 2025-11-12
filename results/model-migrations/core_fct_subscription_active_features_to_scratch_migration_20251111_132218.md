# Migration Report: core_fct_subscription_active_features → core_fct_subscription_active_features_scratch
Generated: Tue Nov 11 13:21:35 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 16 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (16 files)

- **models/models_scratch//core/subscriptions/core_fct_subscription_feature_change_history.sql**: Updated 2 references
- **models/models_scratch//core/subscriptions/v1_legacy/core_subscription_arr.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/intermediate/core_fct_subscription_arr__5product.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/core_dim_subscriptions.sql**: Updated 1 references
- **models/models_scratch//core/corporations/core_active_features.sql**: Updated 1 references
- **models/models_scratch//core/marketo/marketo_active_customer_segments.sql**: Updated 1 references
- **models/models_scratch//census_read/census_iterable_user_properties.sql**: Updated 1 references
- **models/models_scratch//census_read/census_iterable_primary_company.sql**: Updated 1 references
- **models/models_scratch//marts/corporations/product_engagement_score/intermediate/int_corp_pes_active_features.sql**: Updated 1 references
- **models/models_scratch//marts/corporations/product_engagement_score/intermediate/int_corp_pes_active_features_monthly.sql**: Updated 3 references
- **models/models_scratch//marts/corporations/mart_fct_captable_access_history.sql**: Updated 1 references
- **models/models_scratch//marts/corporations/mart_dim_corporation_features.sql**: Updated 1 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporation_buckets/without_overrides/mart_corporations_delta_upsell_without_overrides.sql**: Updated 1 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporation_buckets/arr_with_overrides/mart_corporations_delta_upsell.sql**: Updated 1 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporations/mart_fct_corporations__5salesforce_joined.sql**: Updated 1 references
- **models/models_scratch//tingono/intermediate/intermediate_core_catalyst_companies_2_year_historical_2.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/core/subscriptions/core_fct_subscription_active_features.sql` → `models/models_scratch/core/subscriptions/core_fct_subscription_active_features_scratch.sql` (using git mv)
- **Alias Added**: `alias='core_fct_subscription_active_features'` (preserves table name in database)
- **References Updated**: 16 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='core_fct_subscription_active_features'
    ...
) }}
```

The alias ensures that:
- The model file is named: `core_fct_subscription_active_features_scratch.sql`
- The database table is still: `core_fct_subscription_active_features`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('core_fct_subscription_active_features_scratch') }}
```

Instead of:
```sql  
{{ ref('core_fct_subscription_active_features') }}
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
grep -r "ref.*core_fct_subscription_active_features" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select core_fct_subscription_active_features+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select core_fct_subscription_active_features_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select core_fct_subscription_active_features_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select core_fct_subscription_active_features_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate core_fct_subscription_active_features to scratch naming convention

- Rename: core_fct_subscription_active_features → core_fct_subscription_active_features_scratch (using git mv)
- Add alias to preserve table name in database
- Update 16 downstream references in models_scratch directory

The model file is now core_fct_subscription_active_features_scratch.sql but the database 
table remains core_fct_subscription_active_features due to the alias configuration."
```

## Validation Checklist

- [ ] Compilation status: ✅ SUCCESS (already checked)
- [ ] Grep and dbt list show no remaining refs to `core_fct_subscription_active_features`
- [ ] If compilation failed: dependent models migrated or error is expected
- [ ] (Optional) Model runs without errors: `dbt run -m core_fct_subscription_active_features_scratch --defer`
- [ ] Database table is still named `core_fct_subscription_active_features` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Tue Nov 11 13:22:18 EST 2025  
**Command**: migrate-model-to-scratch core_fct_subscription_active_features  
**Status**: ✅ Success - Ready to commit
