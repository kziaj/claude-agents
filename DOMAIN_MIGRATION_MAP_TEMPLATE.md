# {DOMAIN_NAME} Migration Map

**Project**: {TICKET_ID} - Migrate {DOMAIN_NAME} models to verified/  
**PR**: [#{PR_NUMBER}](https://github.com/carta/ds-dbt/pull/{PR_NUMBER})  
**Status**: 🔄 In Progress | ⏳ Pending | ✅ Complete  
**Last Updated**: {DATE}

---

## How to Use This Template

1. **Copy this file**: `cp DOMAIN_MIGRATION_MAP_TEMPLATE.md {YOUR_DOMAIN}_MIGRATION_MAP.md`
2. **Generate model inventory** (see commands below)
3. **Fill in the tables** with your actual model names
4. **Update status** as you complete each migration
5. **Use for deprecation** - this document tracks which scratch models can be removed once verified models are live

---

## Generating Initial Inventory

```bash
# List all models in your domain directory
find models/models_scratch/{domain} -name "*.sql" -type f

# Count models by layer
echo "Base:" && find models/models_scratch/base/{domain} -name "*.sql" -type f | wc -l
echo "Transform:" && find models/models_scratch/transform/{domain} -name "*.sql" -type f | wc -l
echo "Core:" && find models/models_scratch/core/{domain} -name "*.sql" -type f | wc -l
echo "Mart:" && find models/models_scratch/mart -name "*{domain}*.sql" -type f | wc -l

# Find downstream dependencies for a specific model
rg "ref\('{model_name}'\)" models/ --type sql -l

# Check if models are used in production (Snowflake query history)
snow sql --query "SELECT table_name, COUNT(*) as query_count 
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY 
WHERE table_name ILIKE '%{table_name}%' 
  AND start_time > DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY table_name ORDER BY query_count DESC;" --format JSON
```

---

## Migration Summary

**Consolidation Achievement:**
- **{X} scratch models** → **{Y} verified models** ({Z}% reduction)
- Base: {A} scratch → {B} verified
- Transform: {C} scratch → {D} verified
- Core: {E} scratch → {F} verified
- Mart: {G} scratch → {H} verified

---

## Base Layer Models

| Scratch Model | Verified Model | Status | Notes |
|---------------|----------------|--------|-------|
| base_{domain}_{entity}_scratch | base_{domain}_{entity} | ⏳ Pending | Example: base_salesforce_account |
| base_{domain}_{entity2}_scratch | base_{domain}_{entity2} | 🔄 In Progress | Ephemeral, no table change |
| base_{domain}_{entity3}_scratch | base_{domain}_{entity3} | ✅ Migrated | Updated timestamp columns |

**Pattern**: Base models typically have 1:1 mapping (rarely consolidated)

---

## Transform Layer Models

| Scratch Model | Verified Model | Status | Notes |
|---------------|----------------|--------|-------|
| transform_{domain}_{action}_v2 | transform_{domain}_{action} | ✅ Migrated | {X} rows, removed _v2 suffix |
| transform_{domain}_{action2}_v3 | transform_{domain}_{action2} | ✅ Migrated | {Y} rows, removed _v3 suffix |
| transform_int_{domain}_{helper} | transform_int_{domain}_{helper} | 🔄 In Progress | Intermediate model |

**Pattern**: Remove version suffixes (_v2, _v3), consolidate intermediate models if possible

---

## Snapshot Models

| Scratch Model | Verified Model | Status | Notes |
|---------------|----------------|--------|-------|
| {model}_snapshot_v2 | {model}_snapshot | ⏳ Pending | {X}K rows, historical tracking |

**Pattern**: Snapshots maintain SCD Type 2 history - clone carefully

---

## Core Layer Models

### Direct Core Models

| Scratch Model | Verified Model | Status | Notes |
|---------------|----------------|--------|-------|
| core_fct_{domain}_{metric}_scratch | core_fct_{domain}_{metric} | ✅ Migrated | {X}M rows, added cluster_by |
| core_dim_{domain}_{entity}_scratch | core_dim_{domain}_{entity} | ✅ Migrated | {Y}K rows, dimension table |
| core_fct_{domain}_{metric2}_scratch | N/A - Consolidated | ✅ Migrated | Logic moved to main model |

**Pattern**: Consolidate intermediate core models into main models when possible

### Intermediate Core Models (if any)

List any intermediate models that were consolidated:

**{Subsystem} ({X} models):**
- core_fct_{domain}_{metric}__1{step}_scratch → Consolidated into core_fct_{domain}_{metric}
- core_fct_{domain}_{metric}__2{step}_scratch → Consolidated into core_fct_{domain}_{metric}
- core_fct_{domain}_{metric}__3{step}_scratch → Consolidated into core_fct_{domain}_{metric}

**Status**: ✅ All logic migrated to verified core models

---

## Mart Layer Models

| Scratch Model | Verified Model | Status | Data Validation | Notes |
|---------------|----------------|--------|-----------------|-------|
| mart_fct_{domain}_{metric}_scratch | mart_{domain}_{metric} | ✅ Migrated | 99.X% match ({Y}M rows) | Simplified logic, alias maintains compatibility |
| mart_dim_{domain}_{entity}_scratch | mart_{domain}_{entity} | ✅ Migrated | 100% match ({Z}K rows) | Dimension table |
| mart_{domain}_{report}_scratch | mart_{domain}_{report} | 🔄 In Progress | Not validated yet | Business logic changes needed |

**Pattern**: Validate data match >99% before considering complete

---

## Downstream Dependencies Updated

These scratch models now reference the renamed `_scratch` models (via updated `ref()` calls):

1. **{dependent_model_1}** - Updated {X} references to `{migrated_model}_scratch`
2. **{dependent_model_2}** - Updated {Y} references to `{migrated_model}_scratch`
3. **{dependent_model_3}** - Updated {Z} references to `{migrated_model}_scratch`

**Command to find dependencies:**
```bash
rg "ref\('{model_name}'\)" models/models_scratch/ --type sql -l
```

---

## Deprecation Checklist

### Phase 1: Verified Models in Production
- [ ] All verified base/transform/core/mart models deployed
- [ ] Data validation completed (99%+ match for all models)
- [ ] Snapshots cloned and functional
- [ ] CI/CD passing for all verified models
- [ ] Documentation updated (YAML files complete)

### Phase 2: Consumer Migration (In Progress)
- [ ] Identify all downstream consumers (dbt models + external queries)
- [ ] Update dbt models to reference verified models instead of scratch
- [ ] Test queries against verified models
- [ ] Update dashboards/reports to use verified tables
- [ ] Notify stakeholders of table name changes (if any)

### Phase 3: Scratch Deprecation (Future)
- [ ] Verified models running in production for at least 1 full quarter
- [ ] Zero query activity on scratch tables (check Snowflake query history)
- [ ] All downstream consumers migrated and tested
- [ ] Stakeholder approval from Data Eng leadership
- [ ] Remove scratch models:
  - [ ] {X} base models
  - [ ] {Y} transform models
  - [ ] {Z} core models
  - [ ] {W} mart models

---

## Safe-to-Deprecate Criteria

Before deprecating scratch models, ensure:

1. **Verified models in production** for at least 1 full quarter (90 days)
2. **Zero query activity** on scratch tables:
   ```sql
   SELECT table_name, MAX(start_time) as last_used
   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE table_name IN ('scratch_table_1', 'scratch_table_2')
     AND start_time > DATEADD(day, -90, CURRENT_TIMESTAMP())
   GROUP BY table_name;
   ```
3. **All downstream consumers migrated** (check dbt lineage + manual audit)
4. **Data quality metrics stable** (no anomalies in verified models)
5. **Stakeholder approval** from Data Eng leadership and domain owners
6. **Rollback plan** documented (can always restore from git history)

---

## Migration Timeline

| Phase | Start Date | End Date | Status |
|-------|-----------|----------|--------|
| Planning & Analysis | {DATE} | {DATE} | ✅ Complete |
| Base Models Migration | {DATE} | {DATE} | 🔄 In Progress |
| Transform Models Migration | {DATE} | {DATE} | ⏳ Pending |
| Core Models Migration | {DATE} | {DATE} | ⏳ Pending |
| Mart Models Migration | {DATE} | {DATE} | ⏳ Pending |
| Data Validation | {DATE} | {DATE} | ⏳ Pending |
| Consumer Migration | {DATE} | {DATE} | ⏳ Pending |
| Scratch Deprecation | {DATE} | {DATE} | ⏳ Pending |

---

## Key Decisions & Learnings

**Architecture Changes:**
- {Decision 1}: Why and impact
- {Decision 2}: Why and impact

**Data Quality Issues Found:**
- {Issue 1}: Resolution
- {Issue 2}: Resolution

**Performance Optimizations:**
- {Optimization 1}: Impact
- {Optimization 2}: Impact

**Consolidation Rationale:**
- {Why certain models were combined}
- {What intermediate models were eliminated}

---

## Data Validation Results

| Model | Scratch Rows | Verified Rows | Match % | Notes |
|-------|--------------|---------------|---------|-------|
| {model_1} | {X}M | {Y}M | 99.X% | Minor float precision differences |
| {model_2} | {X}K | {Y}K | 100% | Perfect match |
| {model_3} | {X}M | {Y}M | 98.X% | Timing difference (scratch has 1 more day) |

**Validation Command:**
```bash
compare-model-data SCRATCH_TABLE VERIFIED_TABLE --threshold 99
```

---

## Notes

- **Backward Compatibility**: Scratch mart models use `alias` config to maintain table names during transition
- **Data Differences**: Minor differences are typically due to:
  - Floating-point precision in calculations
  - Timing (scratch may have more recent data)
  - Logic improvements (bug fixes in verified version)
- **Architecture Improvement**: {X}% fewer models with simplified logic
- **Performance**: Cluster_by and other optimizations added to verified models
- **Testing Strategy**: {How you validated correctness}

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Data quality regression | Low | High | Comprehensive validation, 99%+ match threshold |
| Breaking downstream consumers | Medium | High | Alias configs during transition, stakeholder communication |
| Performance degradation | Low | Medium | Cluster_by optimization, query profiling |
| Complex rollback | Low | High | Git history, documented rollback procedure |

---

## Contact & Support

**Migration Lead**: {YOUR_NAME}  
**Ticket**: {TICKET_ID}  
**PR**: {PR_NUMBER}  
**Questions**: #{slack_channel} Slack channel  
**Domain Owner**: {DOMAIN_STAKEHOLDER}

---

## Appendix: Commands Reference

```bash
# Run data validation
compare-model-data {scratch_table} {verified_table} --threshold 99

# Check downstream dependencies
rg "ref\('{model_name}'\)" models/ --type sql -l

# Validate timestamp naming
validate-timestamp-naming --directory models/models_verified/base/{domain}

# Check verified standards compliance
validate-verified-standards

# Compile models
cd ~/carta/ds-dbt && poetry run dbt compile --models {model_name}+

# Run models
poetry run dbt run --models {model_name}+

# Test models
poetry run dbt test --models {model_name}+
```
