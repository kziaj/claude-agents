# Cross-Reference: How Business Domains Connect

**Understanding**: How Investor Services, Corporations, and LLC data intersect.

---

## 🔗 System Integration Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CARTA PLATFORM                            │
├─────────────────────┬──────────────────┬────────────────────────┤
│  INVESTOR SERVICES  │   CORPORATIONS   │         LLC            │
│   (Firms & Funds)   │   (Companies)    │   (Member Units)       │
├─────────────────────┴──────────────────┴────────────────────────┤
│                    BILLING & REVENUE                             │
│               (Zuora + Salesforce + NetSuite)                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🏦 How the Domains Relate

### **Investor Services → Corporations**
**Relationship**: Funds INVEST IN Companies (M:N)

**Business Flow**:
```
VC Firm (Investor Services)
  ↓ (manages)
Fund I
  ↓ (invests in)
Portfolio Company (Corporation)
  ↓ (issues)
Preferred Stock to Fund I
```

**Data Connection**:
```sql
-- Find all companies a fund has invested in
SELECT 
    firm.name AS firm_name,
    fund.name AS fund_name,
    issuer.issuer_name AS portfolio_company,
    issuer.carta_entity_id AS corporation_id,
    asset.cost_basis AS investment_amount
FROM base_fund_admin_firms firm
INNER JOIN base_fund_admin_funds fund
    ON firm.id = fund.firm_id
INNER JOIN base_fund_admin_general_ledger_asset_records asset
    ON fund.id = asset.fund_id
INNER JOIN transform_fund_admin_general_ledger_issuers_with_entity_links issuer
    ON asset.issuer_id = issuer.issuer_id
WHERE issuer.carta_entity_id IS NOT NULL
    AND firm.is_deleted = FALSE
    AND fund.is_deleted = FALSE
```

**Key Linking Table**: `transform_fund_admin_general_ledger_issuers_with_entity_links`
- `issuer_id` → Fund Admin issuer (portfolio company)
- `carta_entity_id` → Corporation ID in CartaWeb

---

### **Corporations → LLC**
**Relationship**: LLC is a CORPORATION TYPE (1:1 with flag)

**Business Logic**:
- LLCs are stored in the same `core_dim_corporations` table
- Identified by `has_llc_waterfall = TRUE` flag
- LLC-specific models filter on this flag

**Data Pattern**:
```sql
-- All companies (including LLCs)
SELECT * FROM core_dim_corporations WHERE is_void = FALSE

-- Only LLCs
SELECT * FROM core_dim_corporations WHERE has_llc_waterfall = TRUE

-- Only Corporations (non-LLC)
SELECT * FROM core_dim_corporations WHERE has_llc_waterfall = FALSE
```

**LLC-Specific Models**:
- `core_dim_zuora_llc_products` - LLC product subscriptions
- `core_historical_llc_arr_decomp_detailed` - LLC ARR tracking
- Both reference `core_dim_corporations` filtered by `has_llc_waterfall = TRUE`

---

## 💰 Billing System Integration

### Three Billing Hierarchies

**1. Investor Services Billing**:
```
Salesforce Account (firm.sfdc_id)
  ↓ (has)
Salesforce Entities (fund_ids.salesforce_entity_id)
  ↓ (tracked in)
Zuora Subscriptions
  ↓ (generates)
ARR by Entity: core_fct_zuora_arr_by_salesforce_entity
ARR by Firm: core_historical_zuora_arr
```

**2. Corporation Billing**:
```
Corporation (corporation_id)
  ↓ (has)
Subscriptions (core_dim_corporations_subscriptions)
  ↓ (generates)
ARR: core_historical_corporations_subscription_arr
```

**3. LLC Billing** (subset of Corporation):
```
Corporation with has_llc_waterfall = TRUE
  ↓ (has)
LLC Products (core_dim_zuora_llc_products)
  ↓ (generates)
LLC ARR: core_historical_llc_arr_decomp_detailed
```

---

## 🔑 Key Foreign Keys & Identifiers

### Investor Services
| Field | Links To | Purpose |
|-------|----------|---------|
| `firm.id` | Fund Admin firm ID | Primary key for firms |
| `firm.sfdc_id` | Salesforce Account ID | Billing connection |
| `firm.carta_id` | CartaWeb Organization ID | Platform integration |
| `fund.firm_id` | `firm.id` | Fund → Firm relationship |
| `fund.id` | Fund Admin fund ID | Primary key for funds |
| `fund_ids.salesforce_entity_id` | Salesforce Entity ID | Entity-level billing |

### Corporations
| Field | Links To | Purpose |
|-------|----------|---------|
| `corporation_id` | Corporation primary key | Main identifier |
| `corporation_uuid` | UUID for corporation | Alternative identifier |
| `subscription.corporation_id` | `corporation_id` | Subscription → Corp |
| `has_llc_waterfall` | Boolean flag | Identifies LLCs |

### Cross-Domain Links
| From | To | Via | Purpose |
|------|-----|-----|---------|
| Fund | Corporation | `issuer.carta_entity_id` | Fund investments |
| Firm | Salesforce | `firm.sfdc_id` | Billing |
| Corporation | Salesforce | (entity mapping) | Billing |

---

## 📊 ARR Comparison Across Domains

### ARR Grain Differences

| Domain | Model | Grain | Key Field |
|--------|-------|-------|-----------|
| **Investor Services (Firm)** | `core_historical_zuora_arr` | Firm + Date | `salesforce_account_id` |
| **Investor Services (Entity)** | `core_fct_zuora_arr_by_salesforce_entity` | Entity + Date | `salesforce_entity_id` |
| **Corporation** | `core_historical_corporations_subscription_arr` | Corporation + Date | `corporation_id` |
| **LLC** | `core_historical_llc_arr_decomp_detailed` | Corporation + Date | `corporation_id` (filtered) |

### ARR Query Patterns

**Get total Carta ARR across all domains**:
```sql
WITH investor_services AS (
    SELECT 
        'Investor Services' AS domain,
        SUM(arr_dollars) AS arr
    FROM core_historical_zuora_arr
    WHERE as_of_date = CURRENT_DATE - 1
),
corporations AS (
    SELECT 
        'Corporations' AS domain,
        SUM(arr_cumulative) AS arr
    FROM core_historical_corporations_subscription_arr
    WHERE as_of_date = CURRENT_DATE - 1
        AND has_llc_waterfall = FALSE  -- Exclude LLCs
),
llc AS (
    SELECT 
        'LLC' AS domain,
        SUM(arr_dollars) AS arr
    FROM core_historical_llc_arr_decomp_detailed
    WHERE as_of_date = CURRENT_DATE - 1
)
SELECT * FROM investor_services
UNION ALL
SELECT * FROM corporations
UNION ALL
SELECT * FROM llc
```

**Output**:
```
domain              | arr
Investor Services   | 150,000,000
Corporations        | 450,000,000
LLC                 | 25,000,000
TOTAL CARTA ARR:    | 625,000,000
```

---

## 🎯 Common Cross-Domain Queries

### Find which funds invested in a specific company
```sql
-- Given a corporation, find all funds that invested
SELECT 
    corp.legal_name AS portfolio_company,
    firm.name AS investor_firm,
    fund.name AS investor_fund,
    fund.entity_type_name AS fund_type,
    asset.cost_basis AS investment_amount,
    asset.shares_outstanding
FROM core_dim_corporations corp
INNER JOIN transform_fund_admin_general_ledger_issuers_with_entity_links issuer
    ON corp.corporation_id = issuer.carta_entity_id
INNER JOIN base_fund_admin_general_ledger_asset_records asset
    ON issuer.issuer_id = asset.issuer_id
INNER JOIN base_fund_admin_funds fund
    ON asset.fund_id = fund.id
INNER JOIN base_fund_admin_firms firm
    ON fund.firm_id = firm.id
WHERE corp.legal_name = 'Stripe, Inc.'
    AND firm.is_deleted = FALSE
    AND fund.is_deleted = FALSE
ORDER BY asset.cost_basis DESC
```

### Compare firm ARR vs fund ARR
```sql
-- Firm-level ARR should equal sum of entity-level ARR
WITH firm_arr AS (
    SELECT 
        salesforce_account_id,
        SUM(arr_dollars) AS firm_total_arr
    FROM core_historical_zuora_arr
    WHERE as_of_date = CURRENT_DATE - 1
    GROUP BY 1
),
entity_arr AS (
    SELECT 
        salesforce_account_id,
        SUM(arr_dollars) AS entity_total_arr
    FROM core_fct_zuora_arr_by_salesforce_entity
    WHERE as_of_date = CURRENT_DATE - 1
    GROUP BY 1
)
SELECT 
    firm.name AS firm_name,
    fa.firm_total_arr,
    ea.entity_total_arr,
    fa.firm_total_arr - ea.entity_total_arr AS difference
FROM base_fund_admin_firms firm
INNER JOIN firm_arr fa ON firm.sfdc_id = fa.salesforce_account_id
INNER JOIN entity_arr ea ON firm.sfdc_id = ea.salesforce_account_id
WHERE ABS(fa.firm_total_arr - ea.entity_total_arr) > 100
ORDER BY ABS(difference) DESC
```

### Find all Carta customers (across domains)
```sql
WITH is_customers AS (
    SELECT DISTINCT
        firm.name AS customer_name,
        'Investor Services' AS domain,
        firm.id AS identifier
    FROM base_fund_admin_firms firm
    WHERE firm.is_deleted = FALSE
),
corp_customers AS (
    SELECT DISTINCT
        corp.legal_name AS customer_name,
        CASE WHEN corp.has_llc_waterfall THEN 'LLC' ELSE 'Corporation' END AS domain,
        corp.corporation_id AS identifier
    FROM core_dim_corporations corp
    WHERE corp.is_active = TRUE
        AND corp.is_void = FALSE
)
SELECT * FROM is_customers
UNION ALL
SELECT * FROM corp_customers
ORDER BY customer_name
```

---

## 🏗️ Product Overlap

### Products by Domain

| Product | Domain | Table |
|---------|--------|-------|
| **Fund Admin** | Investor Services | `core_historical_zuora_arr` |
| **Tax** | Investor Services | `core_historical_zuora_arr` |
| **KYC** | Investor Services | `core_historical_zuora_arr` |
| **GP Carry** | Investor Services | `core_historical_zuora_arr` |
| **ASC820** | Investor Services | `core_historical_zuora_arr` |
| **CapTable** | Corporations | `core_historical_corporations_subscription_arr` |
| **409A Valuations** | Corporations | `core_historical_corporations_subscription_arr` |
| **ASC718** | Corporations | `core_historical_corporations_subscription_arr` |
| **Waterfall** | Corporations | `core_historical_corporations_subscription_arr` |
| **LLC Waterfall** | LLC | `core_historical_llc_arr_decomp_detailed` |
| **Transfer Agent** | Corporations | `core_historical_corporations_subscription_arr` |

### Product Feature Flags

**Investor Services**:
```sql
SELECT 
    firm.name,
    prod.is_fund_admin_active,
    prod.is_tax_active,
    prod.is_kyc_active,
    prod.is_gp_carry_active
FROM base_fund_admin_firms firm
INNER JOIN core_dim_zuora_investor_services_products prod
    ON firm.sfdc_id = prod.salesforce_account_id
WHERE firm.is_deleted = FALSE
```

**Corporations**:
```sql
SELECT 
    corp.legal_name,
    corp.has_409a,
    corp.has_waterfall,
    corp.has_llc_waterfall,
    corp.has_tender_offer,
    corp.has_asc718
FROM core_dim_corporations corp
WHERE corp.is_active = TRUE
```

---

## 🔄 Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                      CARTA PLATFORM LAYERS                        │
├──────────────────────────────────────────────────────────────────┤
│  APPLICATION LAYER                                                │
│    - CartaWeb (Companies)                                        │
│    - Fund Admin (Firms & Funds)                                  │
│    - Investor Portal (LPs)                                       │
├──────────────────────────────────────────────────────────────────┤
│  BILLING LAYER                                                    │
│    - Salesforce (CRM & Account Management)                       │
│    - Zuora (Subscription Billing)                                │
│    - NetSuite (Accounting)                                       │
├──────────────────────────────────────────────────────────────────┤
│  DATA WAREHOUSE LAYER                                             │
│    - Raw Sources (Fivetran sync)                                 │
│    - Base Models (cleaning)                                      │
│    - Transform Models (business logic)                           │
│    - Core Models (dimensions & facts) ← YOU ARE HERE             │
│    - Mart Models (analytics)                                     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📌 Key Takeaways

### Business Relationships
1. **Funds invest in Companies** - tracked via general ledger asset records
2. **LLCs are a type of Company** - stored in corporation table with flag
3. **All domains bill through Salesforce/Zuora** - unified billing system

### Data Architecture
1. **Separate ARR models per domain** - don't accidentally double-count
2. **Different ARR grains** - firm vs entity vs corporation
3. **Soft deletes everywhere** - always filter on `is_deleted` / `is_void`

### Join Patterns
1. **Firm → Funds**: `fund.firm_id = firm.id`
2. **Fund → Corporations**: `issuer.carta_entity_id = corp.corporation_id`
3. **Firm → Salesforce**: `firm.sfdc_id = salesforce_account_id`
4. **Entity → Salesforce**: `fund_ids.salesforce_entity_id`

### Common Pitfalls
- ❌ Joining firm ARR to entity ARR (double counting)
- ❌ Forgetting to filter `is_void = FALSE` or `is_deleted = FALSE`
- ❌ Using wrong ARR table for analysis grain
- ❌ Assuming LLC is separate domain (it's a corporation type)

---

## 🚀 Next Steps

For detailed domain-specific guidance:
1. **Investor Services**: See `investor-services/` directory
2. **Corporations**: See `corporations/` directory
3. **LLC**: See `llc/` directory

For SQL examples and common queries, check the `03-examples.md` file in each domain directory.
