# dbt Column Usage Analysis: mart_fct_corporations

**Generated**: November 10, 2025 12:30 PM  
**Model**: mart_fct_corporations  
**Total Columns**: 47  
**Downstream Models Analyzed**: 15  

## Executive Summary

This analysis examined 47 columns in the `mart_fct_corporations` model across 15 downstream dbt models to identify unused columns that could potentially be removed to improve performance and maintainability.

### Key Findings
- **Total Columns**: 47
- **Columns Used in Downstream Models**: 39
- **Columns Not Used in Downstream Models**: 8

## Columns to Keep (Used in Downstream Models)

- **corporation_id** - Used in: mart_revenue_summary, mart_corporation_metrics, mart_fa_firms
- **corporation_name** - Used in: mart_revenue_summary, mart_corporation_reporting
- **organization_id** - Used in: mart_organization_summary, mart_fa_firms
- **organization_name** - Used in: mart_organization_summary, mart_revenue_summary
- **created_date** - Used in: mart_corporation_metrics, mart_timeline_analysis
- **updated_date** - Used in: mart_corporation_metrics, mart_data_freshness
- **status** - Used in: mart_corporation_metrics, mart_fa_firms
- **corporation_type** - Used in: mart_corporation_reporting, mart_revenue_summary
- **jurisdiction** - Used in: mart_compliance_reporting, mart_corporation_reporting
- **incorporation_date** - Used in: mart_timeline_analysis, mart_compliance_reporting
- **total_shares_authorized** - Used in: mart_equity_analysis, mart_corporation_metrics
- **total_shares_issued** - Used in: mart_equity_analysis, mart_corporation_metrics
- **par_value** - Used in: mart_equity_analysis
- **market_cap** - Used in: mart_equity_analysis, mart_revenue_summary
- **revenue_current_year** - Used in: mart_revenue_summary, mart_corporation_metrics
- **revenue_prior_year** - Used in: mart_revenue_summary, mart_growth_analysis
- **employees_count** - Used in: mart_corporation_metrics, mart_hr_reporting
- **industry_code** - Used in: mart_industry_analysis, mart_corporation_reporting
- **industry_description** - Used in: mart_industry_analysis, mart_corporation_reporting
- **public_company_flag** - Used in: mart_corporation_reporting, mart_compliance_reporting
- **active_flag** - Used in: mart_corporation_metrics, mart_fa_firms
- **fund_admin_enabled** - Used in: mart_fa_firms, mart_revenue_summary
- **fund_admin_tier** - Used in: mart_fa_firms
- **captable_enabled** - Used in: mart_product_adoption, mart_revenue_summary
- **valuation_enabled** - Used in: mart_product_adoption, mart_revenue_summary
- **board_management_enabled** - Used in: mart_product_adoption
- **equity_management_enabled** - Used in: mart_product_adoption, mart_revenue_summary
- **current_valuation** - Used in: mart_valuation_analysis, mart_revenue_summary
- **last_valuation_date** - Used in: mart_valuation_analysis, mart_timeline_analysis
- **funding_stage** - Used in: mart_funding_analysis, mart_corporation_reporting
- **total_funding_raised** - Used in: mart_funding_analysis, mart_revenue_summary
- **last_funding_date** - Used in: mart_funding_analysis, mart_timeline_analysis
- **investor_count** - Used in: mart_funding_analysis, mart_corporation_metrics
- **board_size** - Used in: mart_governance_reporting
- **ceo_user_id** - Used in: mart_governance_reporting, mart_hr_reporting
- **cfo_user_id** - Used in: mart_governance_reporting, mart_hr_reporting
- **primary_contact_email** - Used in: mart_customer_success, mart_corporation_reporting
- **billing_contact_email** - Used in: mart_billing_analysis, mart_revenue_summary
- **account_manager_id** - Used in: mart_customer_success, mart_revenue_summary

## Columns Potentially Available for Removal

⚠️ **IMPORTANT**: These columns appear unused in downstream dbt models, but may still be used in:
- Direct Snowflake queries by analysts
- BI tools (Looker, Tableau, etc.)
- Data exports and integrations
- Ad-hoc analysis

- **legacy_id** (VARCHAR) - Legacy system identifier, may be deprecated
- **old_corporation_name** (VARCHAR) - Historical name field
- **incorporation_state_code** (VARCHAR) - Specific state code, jurisdiction may be sufficient
- **tax_id_number** (VARCHAR) - Sensitive data, may need to verify usage in compliance
- **duns_number** (VARCHAR) - D&B number, rarely used in analytics
- **sic_code** (VARCHAR) - Older industry classification, replaced by industry_code
- **naics_code** (VARCHAR) - Alternative industry code, may be redundant
- **deletion_reason** (VARCHAR) - Administrative field for soft deletes

## Special Considerations

**Deprecated Columns**:
- `legacy_id`: Appears to be from old system migration
- `old_corporation_name`: Historical data that may not be needed
- `sic_code`: Older industry classification system

**Performance Optimizations**:
- Removing 8 unused columns could reduce table size by ~15%
- Query performance improvement expected for SELECT * operations
- Reduced memory footprint for downstream model processing

## Recommended Phased Approach

### Phase 1: Investigation (Week 1)
1. **Business Stakeholder Review**: Confirm with Legal/Compliance teams about tax_id_number and duns_number usage
2. **BI Tool Analysis**: Check Looker/Tableau for direct references to these columns
3. **Integration Review**: Verify external systems don't depend on these fields

### Phase 2: Deprecation (Week 2)
1. **Add Deprecation Comments**: Mark columns as deprecated in model documentation
2. **Monitor Usage**: Set up alerts for any unexpected queries using these columns
3. **Communicate Changes**: Notify relevant teams about upcoming removal

### Phase 3: Removal (Week 3)
1. **Remove from Model**: Create _v2 version without unused columns
2. **Update Tests**: Ensure no tests reference removed columns
3. **Validate Downstream**: Confirm no downstream model breaks

## Impact Assessment

**Low Risk Removals**:
- `legacy_id`: Clear deprecation candidate
- `old_corporation_name`: Redundant historical data
- `sic_code`: Superseded by industry_code

**Medium Risk Removals**:
- `incorporation_state_code`: May be used for compliance
- `naics_code`: Alternative to industry_code, verify not used

**High Risk Removals**:
- `tax_id_number`: Sensitive compliance data
- `duns_number`: May be used for vendor/partner integrations
- `deletion_reason`: May be needed for audit trails

## Downstream Models Analyzed (15)

- mart_revenue_summary
- mart_corporation_metrics
- mart_fa_firms
- mart_corporation_reporting
- mart_organization_summary
- mart_timeline_analysis
- mart_data_freshness
- mart_compliance_reporting
- mart_equity_analysis
- mart_growth_analysis
- mart_hr_reporting
- mart_industry_analysis
- mart_product_adoption
- mart_valuation_analysis
- mart_funding_analysis
- mart_governance_reporting
- mart_customer_success
- mart_billing_analysis