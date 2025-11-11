# Base LLC Models Deprecation - Session Context

## Session Date
November 5, 2025

## Objective
Identify and deprecate unused base_llc models with zero downstream dependencies to reduce maintenance overhead and improve dbt build performance.

## Analysis Performed

### 1. Initial Base Model Survey
Identified top directories with most base models:
- **base_cartaweb**: 600 models
- **base_fivetran/base_google_sheets**: 103 models
- **base_fund_admin**: 65 models
- **base_llc**: 44 models
- **base_salesforce**: 43 models

### 2. Downstream Dependency Analysis
Analyzed all 44 base_llc models for downstream dependencies using `artifacts/snowflake_prod_run/manifest.json`:

**Top models by downstream dependencies:**
1. base_llc_entity: 61
2. base_llc_account: 57
3. base_llc_interest_issuer: 50
4. base_llc_interest: 44
5. base_llc_interest_type: 41

**Models with ZERO downstream dependencies:**
1. base_llc_correction_audit_record: 0
2. base_llc_data_room_folder: 0
3. base_llc_interest_holder_tax_id: 0

### 3. Usage Validation via Snowflake
Queried Snowflake to verify no recent usage:

```sql
-- Checked ACCESS_HISTORY for last 6 months
SELECT 
    obj.value:objectName::STRING as table_name,
    MAX(query_start_time) as last_access_time,
    COUNT(DISTINCT query_id) as query_count,
    COUNT(DISTINCT user_name) as unique_users
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY,
    LATERAL FLATTEN(input => base_objects_accessed) obj
WHERE obj.value:objectDomain::STRING = 'Table'
    AND (obj.value:objectName::STRING ILIKE '%BASE_LLC_CORRECTION_AUDIT_RECORD'
         OR obj.value:objectName::STRING ILIKE '%BASE_LLC_DATA_ROOM_FOLDER'
         OR obj.value:objectName::STRING ILIKE '%BASE_LLC_INTEREST_HOLDER_TAX_ID')
    AND query_start_time >= DATEADD(month, -6, CURRENT_TIMESTAMP())
GROUP BY obj.value:objectName::STRING;
```

**Result:** Zero queries found for all 3 models in the last 6 months.

## Actions Taken

### 1. Jira Ticket Created
- **Ticket ID:** DA-4064
- **Title:** Deprecate unused base_llc models with zero downstream dependencies
- **Link:** https://carta1.atlassian.net/browse/DA-4064

### 2. Git Workflow
```bash
# Created feature branch
git switch -c th/da-4064/deprecate-unused-base-llc-models

# Removed unused models
git rm models/models_scratch/base/base_llc/base_llc_correction_audit_record.sql
git rm models/models_scratch/base/base_llc/base_llc_data_room_folder.sql
git rm models/models_scratch/base/base_llc/base_llc_interest_holder_tax_id.sql

# Committed changes
git commit -m "[DA-4064] Deprecate unused base_llc models with zero downstream dependencies"

# Pushed to remote
git push -u origin th/da-4064/deprecate-unused-base-llc-models
```

### 3. Pull Request Created
- **PR:** https://github.com/carta/ds-dbt/pull/8965
- **Title:** [DA-4064] Deprecate unused base_llc models with zero downstream dependencies
- **Label:** cc-product-development

## Validation Summary

| Model | Downstream Dependencies | Query Access (6 months) | Status |
|-------|------------------------|------------------------|--------|
| base_llc_correction_audit_record | 0 | 0 | ✅ Removed |
| base_llc_data_room_folder | 0 | 0 | ✅ Removed |
| base_llc_interest_holder_tax_id | 0 | 0 | ✅ Removed |

## Impact
- **Reduced model count:** 3 models removed from base_llc (44 → 41)
- **Build time improvement:** Marginally faster dbt builds
- **Maintenance reduction:** Fewer models to maintain and update
- **No breaking changes:** Zero downstream dependencies confirmed

## Tools Used
1. **Python script** - Analyzed manifest.json for downstream dependencies
2. **Snowflake CLI** - Queried ACCESS_HISTORY for usage validation
3. **Git** - Version control and branching
4. **GitHub CLI (gh)** - Pull request creation
5. **Atlassian CLI (acli)** - Jira ticket creation

## Key Learnings
1. Always validate both downstream dependencies AND actual query usage before deprecating models
2. Use manifest.json child_map for efficient dependency analysis
3. Snowflake ACCESS_HISTORY is more reliable than QUERY_HISTORY for table usage validation
4. Models can exist in codebase with zero usage for extended periods

## Next Steps
- [ ] Wait for PR review
- [ ] Merge PR after approval
- [ ] Monitor production builds post-merge
- [ ] Consider running similar analysis on other base model directories
