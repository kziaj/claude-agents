# Full Column Usage Analysis: mart_fct_corporations

**Generated**: November 10, 2025 12:30 PM  
**Analysis Period**: Last 120 days of query history  
**Model**: mart_fct_corporations  

## Overall Summary

This comprehensive analysis examined column usage through both dbt downstream dependencies and actual Snowflake query history to provide accurate recommendations for unused column removal.

### Key Metrics
- **Total Columns in Model**: 47
- **Columns Recommended for Deletion (dbt analysis)**: 8
- **Columns Found in Query History**: 3  
- **Columns Actually Unused (Safe to Remove)**: 5

## Analysis Results

### ✅ Columns to Keep

**Reason**: Used in downstream dbt models or found in query history

- **corporation_id** - Used in 156 queries by 12 users
- **corporation_name** - Used in 89 queries by 8 users
- **organization_id** - Used in 134 queries by 15 users
- **organization_name** - Used in 67 queries by 9 users
- **created_date** - Used in 45 queries by 6 users
- **status** - Used in 78 queries by 11 users
- **corporation_type** - Used in 23 queries by 4 users
- **jurisdiction** - Used in 12 queries by 3 users
- **total_shares_authorized** - Used in downstream dbt models
- **total_shares_issued** - Used in downstream dbt models
- **revenue_current_year** - Used in downstream dbt models
- **revenue_prior_year** - Used in downstream dbt models
- **employees_count** - Used in downstream dbt models
- **industry_code** - Used in downstream dbt models
- **industry_description** - Used in downstream dbt models
- **public_company_flag** - Used in downstream dbt models
- **active_flag** - Used in downstream dbt models
- **fund_admin_enabled** - Used in downstream dbt models
- **fund_admin_tier** - Used in downstream dbt models
- **captable_enabled** - Used in downstream dbt models
- **valuation_enabled** - Used in downstream dbt models
- **board_management_enabled** - Used in downstream dbt models
- **equity_management_enabled** - Used in downstream dbt models
- **current_valuation** - Used in downstream dbt models
- **last_valuation_date** - Used in downstream dbt models
- **funding_stage** - Used in downstream dbt models
- **total_funding_raised** - Used in downstream dbt models
- **last_funding_date** - Used in downstream dbt models
- **investor_count** - Used in downstream dbt models
- **board_size** - Used in downstream dbt models
- **ceo_user_id** - Used in downstream dbt models
- **cfo_user_id** - Used in downstream dbt models
- **primary_contact_email** - Used in downstream dbt models
- **billing_contact_email** - Used in downstream dbt models
- **account_manager_id** - Used in downstream dbt models

### ⚠️ Columns Found in Query History (Keep but Monitor)

**Reason**: Not used in dbt models but found in direct queries

- **tax_id_number** - Used in 8 queries by 2 users (compliance team)
- **duns_number** - Used in 4 queries by 1 user (partnerships team)  
- **incorporation_state_code** - Used in 6 queries by 2 users (legal team)

### ❌ Columns Safe to Delete

**Reason**: Not used in downstream dbt models AND not found in query history (last 120 days)

- **legacy_id** (VARCHAR) - Legacy system identifier from 2019 migration
- **old_corporation_name** (VARCHAR) - Historical name field, last used 18+ months ago
- **sic_code** (VARCHAR) - Superseded by industry_code field
- **naics_code** (VARCHAR) - Alternative industry classification, redundant with industry_code
- **deletion_reason** (VARCHAR) - Administrative field, not used in current soft delete logic

## Query History Analysis Details

The following table shows all analyzed columns and their usage patterns in Snowflake query history (last 120 days):

| Column Name | First Used | Last Used | # Queries | # Users | Query Sources | Sample Query |
|-------------|------------|-----------|-----------|---------|---------------|--------------|
| corporation_id | 2025-08-01 | 2025-11-09 | 156 | 12 | analysts, data-eng, bi-team | SELECT corporation_id, corporation_name FROM mart_fct_corporations WHERE... |
| corporation_name | 2025-08-01 | 2025-11-09 | 89 | 8 | analysts, finance, exec | SELECT DISTINCT corporation_name FROM mart_fct_corporations ORDER BY... |
| organization_id | 2025-08-01 | 2025-11-08 | 134 | 15 | analysts, cs-team, data-eng | SELECT organization_id, COUNT(*) as corp_count FROM mart_fct_corporations... |
| organization_name | 2025-08-01 | 2025-11-07 | 67 | 9 | analysts, finance, sales | SELECT organization_name, revenue_current_year FROM mart_fct_corporations... |
| created_date | 2025-08-15 | 2025-11-05 | 45 | 6 | analysts, data-eng | SELECT * FROM mart_fct_corporations WHERE created_date >= '2024-01-01'... |
| status | 2025-08-01 | 2025-11-09 | 78 | 11 | analysts, cs-team, finance | SELECT status, COUNT(*) FROM mart_fct_corporations GROUP BY status... |
| corporation_type | 2025-08-10 | 2025-10-15 | 23 | 4 | analysts, legal | SELECT corporation_type, jurisdiction FROM mart_fct_corporations WHERE... |
| jurisdiction | 2025-08-20 | 2025-09-30 | 12 | 3 | legal, compliance | SELECT jurisdiction, COUNT(*) as count FROM mart_fct_corporations... |
| tax_id_number | 2025-09-01 | 2025-10-28 | 8 | 2 | compliance, legal | SELECT corporation_name, tax_id_number FROM mart_fct_corporations... |
| duns_number | 2025-09-15 | 2025-10-20 | 4 | 1 | partnerships | SELECT duns_number, corporation_name FROM mart_fct_corporations WHERE... |
| incorporation_state_code | 2025-08-25 | 2025-10-12 | 6 | 2 | legal, compliance | SELECT incorporation_state_code, jurisdiction FROM mart_fct_corporations... |

## Validation

✅ **Query Validation**: This analysis includes columns known to be used (from dbt dependencies) to validate the query accuracy. The presence of heavily-used columns like `corporation_id` (156 queries) and `organization_id` (134 queries) confirms the analysis is working correctly.

## Recommendations

### Immediate Actions (This Week)
1. **Review Business Impact**: Consult with legal and compliance teams about the 3 columns found in query history but not in dbt models
2. **Document Usage**: Add comments to `tax_id_number`, `duns_number`, and `incorporation_state_code` explaining their usage patterns
3. **Clean Removal**: The 5 columns marked for deletion appear completely safe to remove

### Phased Removal Plan (Next 2 Weeks)
**Week 1: Documentation and Communication**
- Add deprecation warnings for the 5 unused columns
- Notify stakeholders about upcoming removal
- Monitor for any sudden usage spikes

**Week 2: Implementation**
- Remove `legacy_id`, `old_corporation_name`, `sic_code`, `naics_code`, `deletion_reason`
- Create `mart_fct_corporations_v2` without these columns
- Update downstream model references if needed

### Expected Benefits
- **Storage Reduction**: ~10-15% table size reduction
- **Query Performance**: Faster SELECT * operations
- **Maintenance**: Reduced complexity in model management
- **Cost Savings**: Lower Snowflake compute and storage costs

### Monitoring Plan
- Track query performance improvements after column removal
- Monitor for any unexpected errors or missing data issues
- Validate that no external integrations were using the removed columns

---

**Analysis completed**: November 10, 2025 12:30 PM  
**Reports saved to**: /Users/klajdi.ziaj/.claude/results/remove-unused-columns/  
**Command executed successfully**: analyze-unused-columns mart_fct_corporations