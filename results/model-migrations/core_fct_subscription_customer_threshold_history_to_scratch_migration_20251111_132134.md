# Migration Report: core_fct_subscription_customer_threshold_history → core_fct_subscription_customer_threshold_history_scratch
Generated: Tue Nov 11 13:20:52 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 21 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (21 files)

- **models/models_scratch//staging/ds_showroom/ds_showroom_fundraising.sql**: Updated 2 references
- **models/models_scratch//core/catalyst/core_catalyst_companies.sql**: Updated 1 references
- **models/models_scratch//core/valuations/core_valuations_company_growth_metrics.sql**: Updated 1 references
- **models/models_scratch//core/compliance/ta_2/core_compliance_ta2_stakeholders.sql**: Updated 1 references
- **models/models_scratch//core/compliance/ta_2/core_compliance_ta2_stakeholders_incremental.sql**: Updated 1 references
- **models/models_scratch//core/nps/core_delighted_survey_responses.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/core_dim_subscription_tiers.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/v2_legacy/core_projected_charges_v2.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/intermediate/core_fct_subscription_arr__2tiers_joined.sql**: Updated 1 references
- **models/models_scratch//core/subscriptions/core_dim_subscriptions.sql**: Updated 1 references
- **models/models_scratch//core/corporations/core_issuers_pm.sql**: Updated 1 references
- **models/models_scratch//core/corporations/core_stakeholder_information.sql**: Updated 1 references
- **models/models_scratch//core/corporations/legal_entity_status.sql**: Updated 1 references
- **models/models_scratch//core/corporations/core_companies.sql**: Updated 1 references
- **models/models_scratch//core/onboarding/core_onboarding_records_daily_history.sql**: Updated 1 references
- **models/models_scratch//core/onboarding/v2/core_onboarding_status_v2.sql**: Updated 1 references
- **models/models_scratch//core/onboarding/core_launch_account_activity.sql**: Updated 1 references
- **models/models_scratch//marts/corporations/mart_dim_corporations.sql**: Updated 1 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporations/mart_fct_corporations__4a_stakeholder_count.sql**: Updated 1 references
- **models/models_scratch//marts/revenue/intermediate/fct_corporations/mart_fct_corporations__4b_stakeholder_joined.sql**: Updated 1 references
- **models/models_scratch//tingono/intermediate/intermediate_core_catalyst_companies_2_year_historical_1.sql**: Updated 1 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history.sql` → `models/models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history_scratch.sql` (using git mv)
- **Alias Added**: `alias='core_fct_subscription_customer_threshold_history'` (preserves table name in database)
- **References Updated**: 21 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='core_fct_subscription_customer_threshold_history'
    ...
) }}
```

The alias ensures that:
- The model file is named: `core_fct_subscription_customer_threshold_history_scratch.sql`
- The database table is still: `core_fct_subscription_customer_threshold_history`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('core_fct_subscription_customer_threshold_history_scratch') }}
```

Instead of:
```sql  
{{ ref('core_fct_subscription_customer_threshold_history') }}
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
grep -r "ref.*core_fct_subscription_customer_threshold_history" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select core_fct_subscription_customer_threshold_history+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select core_fct_subscription_customer_threshold_history_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select core_fct_subscription_customer_threshold_history_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select core_fct_subscription_customer_threshold_history_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate core_fct_subscription_customer_threshold_history to scratch naming convention

- Rename: core_fct_subscription_customer_threshold_history → core_fct_subscription_customer_threshold_history_scratch (using git mv)
- Add alias to preserve table name in database
- Update 21 downstream references in models_scratch directory

The model file is now core_fct_subscription_customer_threshold_history_scratch.sql but the database 
table remains core_fct_subscription_customer_threshold_history due to the alias configuration."
```

## Validation Checklist

- [ ] Compilation status: ✅ SUCCESS (already checked)
- [ ] Grep and dbt list show no remaining refs to `core_fct_subscription_customer_threshold_history`
- [ ] If compilation failed: dependent models migrated or error is expected
- [ ] (Optional) Model runs without errors: `dbt run -m core_fct_subscription_customer_threshold_history_scratch --defer`
- [ ] Database table is still named `core_fct_subscription_customer_threshold_history` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Tue Nov 11 13:21:34 EST 2025  
**Command**: migrate-model-to-scratch core_fct_subscription_customer_threshold_history  
**Status**: ✅ Success - Ready to commit
