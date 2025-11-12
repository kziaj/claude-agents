# Migration Report: core_dim_subscription_charges → core_dim_subscription_charges_scratch
Generated: Tue Nov 11 13:22:18 EST 2025

## Downstream Reference Discovery

### Dual Verification Results
- **Grep search**: Found 8 files with text references
- **dbt list**: Found 1 files with dependency references

**⚠️  DISCREPANCY DETECTED**: The two methods found different counts. This could indicate:
- Aliased references that grep doesn't catch
- Comments or strings that grep picks up but aren't real refs
- dbt compilation issues

## Downstream References Updated (8 files)

- **models/models_scratch//staging/cartaweb_corporations.sql**: Updated 1 references
- **models/models_scratch//staging/stripe_transactions.sql**: Updated 1 references
- **models/models_scratch//core/catalyst/core_catalyst_companies.sql**: Updated 3 references
- **models/models_scratch//core/subscriptions/core_dim_subscriptions.sql**: Updated 1 references
- **models/models_scratch//core/customer_success/core_customer_success_account_data.sql**: Updated 1 references
- **models/models_scratch//census_read/census_sf_corp.sql**: Updated 1 references
- **models/models_scratch//marts/corporations/mart_dim_corporations.sql**: Updated 1 references
- **models/models_scratch//tingono/intermediate/intermediate_core_catalyst_companies_2_year_historical_3.sql**: Updated 3 references

## Summary

### Files Changed
- **Renamed**: `models/models_scratch/core/subscriptions/core_dim_subscription_charges.sql` → `models/models_scratch/core/subscriptions/core_dim_subscription_charges_scratch.sql` (using git mv)
- **Alias Added**: `alias='core_dim_subscription_charges'` (preserves table name in database)
- **References Updated**: 8 files in models_scratch directory

### Model Configuration
```sql
{{ config(
    alias='core_dim_subscription_charges'
    ...
) }}
```

The alias ensures that:
- The model file is named: `core_dim_subscription_charges_scratch.sql`
- The database table is still: `core_dim_subscription_charges`
- External tools (Looker, etc.) continue to work without changes

### Reference Updates
All downstream models in models_scratch directory now reference:
```sql
{{ ref('core_dim_subscription_charges_scratch') }}
```

Instead of:
```sql  
{{ ref('core_dim_subscription_charges') }}
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
grep -r "ref.*core_dim_subscription_charges" models/ --include="*.sql" | grep -v "_scratch"

# dbt dependency check
poetry run dbt list --select core_dim_subscription_charges+ --resource-type model
```

### 2. Test compilation:
```bash
source .env
poetry run dbt compile --select core_dim_subscription_charges_scratch
```

### 3. Run the model:
```bash
poetry run dbt run --select core_dim_subscription_charges_scratch --defer --state artifacts/snowflake_prod_run
```

### 4. Validate downstream models:
```bash
poetry run dbt build --select core_dim_subscription_charges_scratch+ --defer --state artifacts/snowflake_prod_run
```

### 5. Check git status:
```bash
git status
git diff --staged
```

## Commit Template

```bash
git commit -m "Migrate core_dim_subscription_charges to scratch naming convention

- Rename: core_dim_subscription_charges → core_dim_subscription_charges_scratch (using git mv)
- Add alias to preserve table name in database
- Update 8 downstream references in models_scratch directory

The model file is now core_dim_subscription_charges_scratch.sql but the database 
table remains core_dim_subscription_charges due to the alias configuration."
```

## Validation Checklist

- [ ] Compilation status: ✅ SUCCESS (already checked)
- [ ] Grep and dbt list show no remaining refs to `core_dim_subscription_charges`
- [ ] If compilation failed: dependent models migrated or error is expected
- [ ] (Optional) Model runs without errors: `dbt run -m core_dim_subscription_charges_scratch --defer`
- [ ] Database table is still named `core_dim_subscription_charges` (check with SHOW TABLES)
- [ ] Git diff looks correct (1 rename + config change + ref updates)
- [ ] Ready to commit

---

**Migration completed**: Tue Nov 11 13:23:00 EST 2025  
**Command**: migrate-model-to-scratch core_dim_subscription_charges  
**Status**: ✅ Success - Ready to commit
