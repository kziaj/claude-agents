# TODO List

## dbt / Data Warehouse

- [x] Fix Pigment override logic in verified corporation ARR models (DA-4196)
  - Fixed $2M+ daily variance by correcting join from (corporation_id, product) to payment_window_pks
  - Aligned NULL checks with scratch baseline (check join key vs value field)
  - PR #9238 - Validated 551,948 rows across 4 time periods, 100% match achieved
  - Status: Production-validated, ready to merge

- [ ] Finish data warehouse migration for Zuora and Corporations ARR
  - Move remaining models from scratch to verified
  - Validate data consistency
  - Migrate risk factor and risk score models to scratch

- [x] Clean up Zuora ARR with Trevor
  - Review product groupings
  - Address edge cases and overrides

- [x] Add churn date tracking to verified Zuora ARR models (DA-4177)
  - Added churn fields to `transform_temporal_zuora_arr` and `core_historical_zuora_arr`
  - PR #9182 - Performance optimized with data integrity fixes

- [x] Create Zuora product dimension models (DA-4181)
  - Created `core_dim_zuora_llc_products` (6 products)
  - Created `core_dim_zuora_investor_services_products` (13 products)
  - PR #9189 - Following `core_dim_corporations_products` pattern

- [ ] Capdesk integration in subs 2.0 (DA-4166)

- [ ] Accelex integration in zuora billing and revenue (DA-4167)

## BI / Analytics

- [ ] Start BI migration for Zuora and Corporations ARR
  - Update Looker/Tableau dashboards to reference verified models
  - Test performance and validate metrics

## Team Collaboration

- [ ] Create Pigment view for Navan data for Monty
- [ ] LLC decomp entities for Monty
- [ ] Load ARR validity dates into Pigment for strategic finance (Monty)
  - Include next renewal date for ARR tracking
  - Set valid_to as NULL for active accounts (ongoing subscriptions)
  - Set valid_to as renewal/end date for accounts with known end dates

- [x] Create documentation template for Sam
  - Created `subscription_arr_domain_overview.md` covering Corporations, LLC, and Investor Services

- [ ] Create Snowflake Cortex semantic model for Joshua for all revpro models

- [x] CSM Agent V3 - Complete semantic model overhaul (Dec 5)
  - Created 6 semantic models covering 3 product lines (Corporations, LLC, Investor Services)
  - Resolved 2 critical deployment blockers
  - Validated all schemas against actual Snowflake tables
  - Fixed 4 schema mismatches (table names, column mappings, RISK_LEVEL values)
  - 95% complete - ready for deployment after dbt work

- [x] Schedule demo calls with Sam

---

*Last updated: 2025-12-11*
