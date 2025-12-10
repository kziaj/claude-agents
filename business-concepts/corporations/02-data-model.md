# Corporations: Data Model

**Verified Models Reference**: Maps corporation business concepts to actual data warehouse tables.

---

## 🗂️ Model Layers Overview

```
SOURCE (raw_cartaweb_*, raw_salesforce_*)
   ↓
BASE (base_cartaweb_*, base_salesforce_*)
   ↓  
TRANSFORM (transform_corporations_*, transform_cartaweb_*)
   ↓
CORE (core_dim_corporations*, core_fct_corporations*, core_historical_*)
   ↓
MART (mart_dim_corporations*, mart_fct_corporations*)
```

---

## 🏢 Corporation Data Models

### `core_dim_corporations`
**Schema**: `dbt_verified_core`  
**Grain**: One row per corporation (company)  
**Source**: `transform_cartaweb_corporations_issuing_entities`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `corporation_id` | NUMBER | Corporation ID (primary key) |
| `corporation_uuid` | VARCHAR | UUID identifier |
| `legal_name` | VARCHAR | Legal name of company |
| `dba` | VARCHAR | "Doing Business As" name |
| `legal_entity_type` | VARCHAR | C-Corp, S-Corp, LLC, etc. |
| `state_of_incorporation` | VARCHAR | US state where incorporated |
| `incorporation_date` | DATE | Date of incorporation |
| `go_live_at` | TIMESTAMP | When company went live on Carta |
| `hq_country` | VARCHAR | Headquarters country |
| `industry` | VARCHAR | Industry classification |
| `industry_broad` | VARCHAR | Broad industry category |
| `is_active` | BOOLEAN | Currently active company |
| `is_archived` | BOOLEAN | Archived/inactive |
| `is_void` | BOOLEAN | Soft deleted |
| `is_public` | BOOLEAN | Publicly traded |
| `is_transfer_agent` | BOOLEAN | Uses Carta as transfer agent |
| `currency` | VARCHAR | Reporting currency |
| `has_llc_waterfall` | BOOLEAN | **LLC flag** (stored here!) |
| `has_409a` | BOOLEAN | Has 409A valuation feature |
| `has_waterfall` | BOOLEAN | Has liquidation waterfall feature |
| `active_features` | VARCHAR | Comma-separated active features |
| `created_at` | TIMESTAMP | Record creation time |
| `modified_at` | TIMESTAMP | Last modified time |

**Example Row**:
```json
{
  "corporation_id": 123456,
  "corporation_uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "legal_name": "StartupCo, Inc.",
  "dba": "StartupCo",
  "legal_entity_type": "Delaware C-Corp",
  "state_of_incorporation": "Delaware",
  "incorporation_date": "2020-01-15",
  "industry": "Software",
  "industry_broad": "Technology",
  "is_active": true,
  "is_archived": false,
  "has_llc_waterfall": false,
  "has_409a": true,
  "currency": "USD"
}
```

**Important Notes**:
- **LLC companies** are identified by `has_llc_waterfall = TRUE` in this table
- Use `is_active = TRUE` and `is_void = FALSE` for active companies
- `is_archived = TRUE` indicates iceboxed/inactive companies

---

## 💳 Subscription Data Models

### `core_dim_corporations_subscriptions`
**Schema**: `dbt_verified_core`  
**Grain**: One row per subscription  
**Clustered By**: `subscription_id`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `subscription_id` | VARCHAR | Subscription ID (primary key) |
| `corporation_id` | NUMBER | **Foreign key to corporation** |
| `parent_subscription_id` | VARCHAR | Parent subscription (for add-ons) |
| `product` | VARCHAR | Product name (CapTable, Valuations, etc.) |
| `type` | VARCHAR | Subscription type |
| `package_type` | VARCHAR | Package tier (Scale, Growth, Starter, Custom) |
| `customer_type` | VARCHAR | Customer classification |
| `pricing_strategy` | VARCHAR | How pricing is calculated |
| `created` | TIMESTAMP | Subscription creation time |
| `modified` | TIMESTAMP | Last modified time |
| `activation_date` | DATE | When subscription became active |
| `deactivation_date` | DATE | When subscription was deactivated |
| `renewal_date` | DATE | Next renewal date |
| `next_charge_date` | DATE | Next billing date |
| `contract_signed_at` | TIMESTAMP | Contract signature date |
| `starting_arr_dollars` | FLOAT | Starting ARR |
| `current_arr_dollars` | FLOAT | Current ARR |
| `renewal_arr_dollars` | FLOAT | ARR at renewal |
| `escalator_arr_dollars` | FLOAT | Escalator amount |
| `escalator_percent` | FLOAT | Escalator percentage |
| `current_threshold_ct` | NUMBER | Current stakeholder count |
| `starting_tier` | VARCHAR | Starting pricing tier |
| `current_tier` | VARCHAR | Current pricing tier |
| `renewal_tier` | VARCHAR | Renewal pricing tier |
| `is_active` | BOOLEAN | Currently active |
| `is_paying` | BOOLEAN | Paying customer |
| `is_auto_renew` | BOOLEAN | Auto-renewal enabled |
| `is_discounted` | BOOLEAN | Has discount applied |
| `features` | VARCHAR | Active features list |
| `tier_specs` | VARCHAR | Pricing tier specifications |

**Example Row**:
```json
{
  "subscription_id": "sub_abc123",
  "corporation_id": 123456,
  "product": "CapTable",
  "package_type": "Scale",
  "pricing_strategy": "stakeholder_based",
  "activation_date": "2020-02-01",
  "current_arr_dollars": 15000.00,
  "current_threshold_ct": 250,
  "current_tier": "Tier_3",
  "is_active": true,
  "is_paying": true,
  "features": "cap_table,409a,waterfall"
}
```

**Important Notes**:
- One corporation can have multiple subscriptions (different products)
- `parent_subscription_id` links add-ons to main subscriptions
- Pricing tiers typically based on stakeholder count or features

---

## 💰 ARR Tracking Models

### `core_historical_corporations_subscription_arr`
**Schema**: `dbt_verified_core`  
**Grain**: One row per **corporation** per day  
**Clustered By**: `as_of_date`, `corporation_id`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `_pk` | VARCHAR | Surrogate key (date + corp + product) |
| `as_of_date` | DATE | Date of ARR snapshot |
| `corporation_id` | NUMBER | **Corporation ID** |
| `product` | VARCHAR | Product type (CapTable, Valuations, etc.) |
| `arr_cumulative` | FLOAT | Cumulative ARR total |
| `renewal_arr_dollars` | FLOAT | ARR at renewal |
| `finance_arr_dollars` | FLOAT | Finance-reported ARR |
| `override_arr_dollars` | FLOAT | Manual override ARR |
| `gross_arr_dollars` | FLOAT | Gross ARR before adjustments |
| `escalator_arr_dollars` | FLOAT | Escalator amount |
| `arr_delta_day` | FLOAT | Day-over-day ARR change |
| `is_active_today` | BOOLEAN | Active on this date |
| `active_from_date` | DATE | When became active |
| `go_live_date` | DATE | Go-live date |
| `onboarding_start_date` | DATE | Onboarding start |
| `is_churned` | BOOLEAN | Has churned |
| `churn_date` | DATE | Date of churn |
| `is_date_of_churn` | BOOLEAN | Is this the churn date |
| `is_date_of_recovery` | BOOLEAN | Is this a recovery date |
| `is_launch` | BOOLEAN | Launch date flag |
| `is_last_day_of_month` | BOOLEAN | Month-end flag |
| `is_last_day_of_quarter` | BOOLEAN | Quarter-end flag |
| `is_last_day_of_year` | BOOLEAN | Year-end flag |
| `segment` | VARCHAR | Customer segment |
| `ct_stakeholders` | NUMBER | Stakeholder count |
| `ct_adjusted_stakeholders` | NUMBER | Adjusted stakeholder count |
| `ct_employees` | NUMBER | Employee count |
| `ct_features` | NUMBER | Feature count |
| `in_icebox` | BOOLEAN | Is iceboxed |
| `icebox_reason` | VARCHAR | Icebox reason |
| `launch_status` | VARCHAR | Launch status |
| `created_at` | TIMESTAMP | Record creation |
| `modified_at` | TIMESTAMP | Last modified |

**Use**: **Corporation-level** ARR tracking for all Carta products.

**Example**:
```sql
SELECT 
    as_of_date,
    corporation_id,
    product,
    arr_cumulative,
    is_churned
FROM core_historical_corporations_subscription_arr
WHERE corporation_id = 123456
    AND as_of_date = '2024-12-31'
ORDER BY product
```

**Output**:
```
as_of_date   | corporation_id | product      | arr_cumulative | is_churned
2024-12-31   | 123456        | CapTable     | 15000.00      | false
2024-12-31   | 123456        | Valuations   | 8000.00       | false
2024-12-31   | 123456        | Compliance   | 5000.00       | false
```

---

## 🎯 Key Relationships

```
Corporation (corporation_id)
  ↓ (1:N)
Subscriptions (corporation_id FK)
  ↓ (1:N)
ARR History (by date)
```

```
Salesforce Entity (salesforce_entity_id)
  ↓ (1:1)
Corporation (via entity mapping)
  ↓ (1:N)
Subscriptions
```

---

## 🔗 Join Patterns

### Corporation → Subscriptions
```sql
SELECT 
    corp.legal_name,
    corp.industry,
    sub.product,
    sub.current_arr_dollars,
    sub.is_active
FROM core_dim_corporations corp
INNER JOIN core_dim_corporations_subscriptions sub
    ON corp.corporation_id = sub.corporation_id
WHERE corp.is_active = TRUE
    AND corp.is_void = FALSE
    AND sub.is_active = TRUE
```

### Corporation → ARR (Time-Series)
```sql
SELECT 
    corp.legal_name,
    arr.as_of_date,
    arr.product,
    arr.arr_cumulative
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.as_of_date = '2024-12-31'
    AND corp.is_void = FALSE
ORDER BY arr.arr_cumulative DESC
```

### Find LLC Companies
```sql
SELECT 
    corporation_id,
    legal_name,
    legal_entity_type,
    has_llc_waterfall
FROM core_dim_corporations
WHERE has_llc_waterfall = TRUE
    AND is_active = TRUE
    AND is_void = FALSE
```

### Corporation → Salesforce
```sql
-- Via Salesforce Entity mapping
SELECT 
    corp.corporation_id,
    corp.legal_name,
    se.entity_id AS salesforce_entity_id,
    se.account_id AS salesforce_account_id
FROM core_dim_corporations corp
INNER JOIN base_salesforce_entity se
    ON corp.corporation_id = se.???  -- Need entity linking table
WHERE corp.is_void = FALSE
```

---

## 📌 Important Notes

### Corporation vs Company
- **Corporation** = Database term for issuing entity
- **Company** = User-facing term
- They are synonymous in Carta's data model

### LLC Data Location
- LLC companies are stored in `core_dim_corporations` with `has_llc_waterfall = TRUE`
- There is no separate "LLC" table
- LLC-specific logic is in LLC-specific models that filter on this flag

### Subscription Granularity
- One corporation can have multiple subscriptions (different products)
- ARR is tracked at corporation + product level
- Parent/child subscriptions link add-ons to main products

### Active vs Archived
- `is_active = TRUE`: Currently active, paying customer
- `is_archived = TRUE`: Iceboxed, inactive
- `is_void = TRUE`: Soft deleted, should be filtered out
- Always filter: `WHERE is_void = FALSE`

### Time-Series ARR
- `core_historical_corporations_subscription_arr` has daily snapshots
- Use `is_last_day_of_month = TRUE` for month-end reporting
- `arr_cumulative` is the main ARR field for reporting
- `finance_arr_dollars` is what Finance reports (may differ)

---

## 🚀 Common Queries

### Get all active companies with ARR
```sql
SELECT 
    corp.legal_name,
    corp.industry,
    arr.arr_cumulative AS current_arr,
    arr.ct_stakeholders,
    arr.segment
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND corp.is_active = TRUE
    AND corp.is_void = FALSE
    AND arr.arr_cumulative > 0
ORDER BY arr.arr_cumulative DESC
LIMIT 100
```

### Get subscription details for a company
```sql
SELECT 
    product,
    package_type,
    activation_date,
    current_arr_dollars,
    current_threshold_ct,
    current_tier,
    is_active,
    features
FROM core_dim_corporations_subscriptions
WHERE corporation_id = 123456
    AND is_active = TRUE
ORDER BY current_arr_dollars DESC
```

### Find companies that churned this month
```sql
SELECT 
    corp.legal_name,
    arr.churn_date,
    arr.product,
    arr.arr_cumulative AS arr_at_churn
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.is_date_of_churn = TRUE
    AND DATE_TRUNC('month', arr.churn_date) = DATE_TRUNC('month', CURRENT_DATE)
ORDER BY arr.arr_cumulative DESC
```

### Compare LLC vs non-LLC companies
```sql
SELECT 
    CASE WHEN has_llc_waterfall THEN 'LLC' ELSE 'Corp' END AS entity_type,
    COUNT(DISTINCT corp.corporation_id) AS company_count,
    COUNT(DISTINCT sub.subscription_id) AS subscription_count,
    AVG(sub.current_arr_dollars) AS avg_arr,
    SUM(sub.current_arr_dollars) AS total_arr
FROM core_dim_corporations corp
LEFT JOIN core_dim_corporations_subscriptions sub
    ON corp.corporation_id = sub.corporation_id
    AND sub.is_active = TRUE
WHERE corp.is_active = TRUE
    AND corp.is_void = FALSE
GROUP BY 1
```

---

## 🔄 ARR vs Subscription ARR

**Subscription Table** (`core_dim_corporations_subscriptions`):
- Current state only (latest snapshot)
- Subscription-level details
- Best for: Understanding current subscriptions and configuration

**ARR History** (`core_historical_corporations_subscription_arr`):
- Daily time-series snapshots
- Corporation-level aggregation
- Best for: Trend analysis, churn tracking, historical reporting

**Rule of thumb**:
- Need current subscription details? → Use `core_dim_corporations_subscriptions`
- Need ARR over time? → Use `core_historical_corporations_subscription_arr`
