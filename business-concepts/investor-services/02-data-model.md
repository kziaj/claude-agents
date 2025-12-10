# Investor Services: Data Model

**Verified Models Reference**: Maps business concepts to actual data warehouse tables.

---

## 🗂️ Model Layers Overview

```
SOURCE (raw_fund_admin_*)
   ↓
BASE (base_fund_admin_*)
   ↓  
TRANSFORM (transform_fund_admin_*)
   ↓
CORE (core_dim_fund_admin_*, core_fct_fund_admin_*)
   ↓
MART (mart_dim_fund_admin_*, mart_fct_fund_admin_*)
```

---

## 🏢 Firm Data Models

### `base_fund_admin_firms`
**Schema**: `dbt_verified_base`  
**Grain**: One row per firm  
**Source**: `fund_admin.fund_admin_firm`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `id` | VARCHAR | Fund Admin firm ID (primary key) |
| `carta_id` | NUMBER | Links to CartaWeb organization (`organization_organizations.id`) |
| `sfdc_id` | VARCHAR | Salesforce Account ID (for billing) |
| `name` | VARCHAR | Firm name (e.g., "Sequoia Capital") |
| `fax_firm_segment` | VARCHAR | Firm segment (growth, standard_venture, etc.) |
| `has_gl_enabled` | BOOLEAN | Has general ledger functionality enabled |
| `is_deleted` | BOOLEAN | Soft delete flag |
| `created_at` | TIMESTAMP | When firm was created |
| `updated_at` | TIMESTAMP | Last modified |

**Example Row**:
```json
{
  "id": "12345",
  "carta_id": 67890,
  "sfdc_id": "001f400000DTWIsAAP",
  "name": "UpWest Labs",
  "fax_firm_segment": "growth",
  "has_gl_enabled": true,
  "is_deleted": false
}
```

---

### `core_dim_fund_admin_firm_ids`
**Schema**: `dbt_verified_core`  
**Purpose**: Unified firm identifiers across systems

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `fund_admin_firm_id` | VARCHAR | Fund Admin ID (primary key) |
| `salesforce_account_id` | VARCHAR | SFDC account ID |
| `carta_organization_id` | NUMBER | CartaWeb organization ID |
| `firm_name` | VARCHAR | Firm name |

**Use**: Join table to connect firm across different systems.

---

### `core_dim_fund_admin_firm_properties`
**Schema**: `dbt_verified_core`  
**Purpose**: Firm attributes and configuration

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `fund_admin_firm_id` | VARCHAR | Firm ID |
| `firm_name` | VARCHAR | Name |
| `firm_segment` | VARCHAR | Segment classification |
| `has_general_ledger` | BOOLEAN | GL enabled |
| `firm_support_email` | VARCHAR | Support contact |
| `carta_internal_email` | VARCHAR | Internal contact |

---

## 💰 Fund Data Models

### `base_fund_admin_funds`
**Schema**: `dbt_verified_base`  
**Grain**: One row per fund/entity  
**Source**: `fund_admin.fund_admin_fund`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `id` | VARCHAR | Fund Admin fund ID (primary key) |
| `carta_id` | VARCHAR | CartaWeb identifier |
| `uuid` | VARCHAR | UUID for fund |
| `firm_id` | VARCHAR | **Foreign key to firm** |
| `name` | VARCHAR | Fund name (e.g., "Sequoia Fund I") |
| `entity_type` | NUMBER | Type of entity (see below) |
| `entity_type_name` | VARCHAR | Human-readable type |
| `legal_structure` | VARCHAR | Legal entity structure |
| `has_gl_enabled` | BOOLEAN | General ledger enabled |
| `currency` | VARCHAR | Reporting currency |
| `is_deleted` | BOOLEAN | Soft delete flag |

**Entity Types**:
| Code | Name | Description |
|------|------|-------------|
| 1 | Fund | Investment fund (main type) |
| 2 | GP | General Partner entity |
| 3 | SPV | Special Purpose Vehicle |
| 4 | Mgt Company | Management Company |
| 5 | SPV | Syndicate SPV (Vauban) |

**Example Row**:
```json
{
  "id": "fund_123",
  "firm_id": "12345",
  "name": "Sequoia Capital Fund I",
  "entity_type": 1,
  "entity_type_name": "Fund",
  "legal_structure": "Delaware LP",
  "currency": "USD",
  "is_deleted": false
}
```

---

### `core_dim_fund_admin_fund_ids`
**Schema**: `dbt_verified_core`  
**Purpose**: Unified fund identifiers

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `fund_admin_fund_id` | VARCHAR | Fund Admin ID (primary key) |
| `salesforce_entity_id` | VARCHAR | SFDC entity ID |
| `fund_name` | VARCHAR | Fund name |
| `firm_id` | VARCHAR | Parent firm ID |
| `entity_type` | VARCHAR | Fund, GP, SPV, etc. |

---

### `core_dim_fund_admin_fund_properties`
**Schema**: `dbt_verified_core`  
**Purpose**: Fund attributes and configuration

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `fund_admin_fund_id` | VARCHAR | Fund ID |
| `fund_name` | VARCHAR | Name |
| `entity_type_name` | VARCHAR | Fund/GP/SPV/Mgt Co |
| `legal_structure` | VARCHAR | Legal entity type |
| `domicile_country` | VARCHAR | Country of domicile |
| `vintage_year` | NUMBER | Fund vintage |
| `has_general_ledger` | BOOLEAN | GL enabled |
| `fund_size_usd` | NUMBER | Total fund size |

---

## 💵 ARR Tracking Models

### `core_historical_zuora_arr`
**Schema**: `dbt_verified_core`  
**Grain**: One row per **firm** per day  
**Clustered By**: `as_of_date`, `salesforce_account_id`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `as_of_date` | DATE | Date of ARR snapshot |
| `salesforce_account_id` | VARCHAR | **Firm-level account ID** |
| `_pk` | VARCHAR | Surrogate key (date + account) |
| `product` | VARCHAR | Product type (Fund Admin, Tax, etc.) |
| `subsidiary` | VARCHAR | Carta subsidiary |
| `arr_dollars` | FLOAT | Annual recurring revenue |
| `is_churned` | BOOLEAN | Whether account has churned |
| `churn_date` | DATE | Date of churn if applicable |

**Use**: **Firm-level** ARR aggregation across all products.

**Example**:
```sql
SELECT 
    as_of_date,
    salesforce_account_id,
    product,
    arr_dollars
FROM core_historical_zuora_arr
WHERE salesforce_account_id = '001f400000DTWIsAAP'
    AND as_of_date = '2024-12-31'
```

---

### `core_fct_zuora_arr_by_salesforce_entity`
**Schema**: `dbt_scratch`  
**Grain**: One row per **entity** (fund) per day  
**Clustered By**: `as_of_date`, `salesforce_entity_id`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `as_of_date` | DATE | Date of ARR snapshot |
| `salesforce_account_id` | VARCHAR | Parent firm account ID |
| `salesforce_entity_id` | VARCHAR | **Entity (fund) ID** |
| `entity_type` | VARCHAR | Fund/GP/SPV/Mgt Co |
| `_pk` | VARCHAR | Surrogate key (date + account + entity) |
| `product` | VARCHAR | Product type |
| `subsidiary` | VARCHAR | Carta subsidiary |
| `arr_dollars` | FLOAT | Entity-level ARR |
| `rate_plan_names` | VARCHAR | Comma-separated rate plans |
| `subscription_ids` | VARCHAR | Comma-separated subscription IDs |

**Use**: **Entity-level** (individual fund) ARR tracking.

**Example**:
```sql
-- Get all funds for a firm
SELECT 
    as_of_date,
    salesforce_entity_id,
    entity_type,
    arr_dollars
FROM core_fct_zuora_arr_by_salesforce_entity
WHERE salesforce_account_id = '001f400000DTWIsAAP'
    AND as_of_date = '2024-12-31'
ORDER BY arr_dollars DESC
```

**Output**:
```
as_of_date   | salesforce_entity_id | entity_type | arr_dollars
2024-12-31   | a2X1234567890       | Fund        | 500000
2024-12-31   | a2Y9876543210       | Fund        | 350000
2024-12-31   | a2Z1122334455       | GP          | 50000
```

---

### `core_dim_zuora_investor_services_products`
**Schema**: `dbt_verified_core`  
**Grain**: One row per **firm** (latest snapshot)

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `salesforce_account_id` | VARCHAR | Firm account ID (primary key) |
| `all_products_arr_dollars` | FLOAT | Total IS ARR |
| `fund_admin_arr_dollars` | FLOAT | Fund Admin product ARR |
| `tax_arr_dollars` | FLOAT | Tax product ARR |
| `kyc_arr_dollars` | FLOAT | KYC product ARR |
| `gp_carry_arr_dollars` | FLOAT | GP Carry product ARR |
| `asc820_arr_dollars` | FLOAT | ASC820 product ARR |
| `is_fund_admin_active` | BOOLEAN | Has active Fund Admin |
| `is_fund_admin_churned` | BOOLEAN | Fund Admin churned |
| `fund_admin_churn_date` | DATE | When Fund Admin churned |

**Use**: Product-level ARR breakdown by firm.

---

## 📊 Portfolio & Investment Models

### `transform_fund_admin_general_ledger_issuers_with_entity_links`
**Schema**: `dbt_verified_transform`  
**Purpose**: Portfolio companies (issuers) that funds invest in

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `issuer_id` | VARCHAR | Issuer ID from general ledger |
| `carta_entity_id` | VARCHAR | **Links to corporation ID** |
| `issuer_name` | VARCHAR | Portfolio company name |
| `fund_id` | VARCHAR | Fund that holds investment |

**Use**: Connect funds to portfolio companies they invest in.

---

### `base_fund_admin_general_ledger_asset_records`
**Schema**: `dbt_verified_base`  
**Purpose**: Individual investment positions

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `id` | VARCHAR | Asset record ID |
| `fund_id` | VARCHAR | Fund holding the asset |
| `issuer_id` | VARCHAR | Portfolio company issuer |
| `asset_class_id` | VARCHAR | Type of asset (equity, debt, etc.) |
| `shares_outstanding` | NUMBER | Number of shares held |
| `cost_basis` | NUMBER | Original investment amount |

---

## 🎯 Join Patterns

### Firm → Funds
```sql
SELECT 
    firm.name AS firm_name,
    fund.name AS fund_name,
    fund.entity_type_name
FROM base_fund_admin_firms firm
INNER JOIN base_fund_admin_funds fund
    ON firm.id = fund.firm_id
WHERE firm.is_deleted = FALSE
    AND fund.is_deleted = FALSE
```

### Firm → ARR (Aggregate)
```sql
SELECT 
    firm.name AS firm_name,
    arr.as_of_date,
    SUM(arr.arr_dollars) AS total_firm_arr
FROM base_fund_admin_firms firm
INNER JOIN core_historical_zuora_arr arr
    ON firm.sfdc_id = arr.salesforce_account_id
WHERE arr.as_of_date = '2024-12-31'
GROUP BY 1, 2
```

### Firm → Funds → Entity-Level ARR
```sql
SELECT 
    firm.name AS firm_name,
    fund.name AS fund_name,
    arr.arr_dollars AS fund_arr
FROM base_fund_admin_firms firm
INNER JOIN base_fund_admin_funds fund
    ON firm.id = fund.firm_id
INNER JOIN core_dim_fund_admin_fund_ids fund_ids
    ON fund.id = fund_ids.fund_admin_fund_id
INNER JOIN core_fct_zuora_arr_by_salesforce_entity arr
    ON fund_ids.salesforce_entity_id = arr.salesforce_entity_id
WHERE arr.as_of_date = '2024-12-31'
```

### Fund → Portfolio Companies
```sql
SELECT 
    fund.name AS fund_name,
    issuer.issuer_name AS portfolio_company,
    asset.cost_basis AS investment_amount
FROM base_fund_admin_funds fund
INNER JOIN base_fund_admin_general_ledger_asset_records asset
    ON fund.id = asset.fund_id
INNER JOIN transform_fund_admin_general_ledger_issuers_with_entity_links issuer
    ON asset.issuer_id = issuer.issuer_id
WHERE fund.entity_type = 1  -- Only actual funds
```

---

## 🔑 Key Relationships

```
Firm (firm_id)
  ↓ (1:N)
Funds (firm_id FK)
  ↓ (1:N)
Asset Records (fund_id FK)
  ↓ (N:1)
Issuers → carta_entity_id → Corporations
```

```
Firm (sfdc_id)
  ↓ (1:1)
Salesforce Account (salesforce_account_id)
  ↓ (1:N)
Salesforce Entities (salesforce_entity_id)
  ↓ (1:1)
Funds (via core_dim_fund_admin_fund_ids)
```

---

## 📌 Important Notes

### Firm vs Account
- **Firm** = Business concept
- **Salesforce Account** = Billing concept
- They map 1:1 via `firm.sfdc_id = account.salesforce_account_id`

### Fund vs Entity
- **Fund** = Specific type of entity
- **Entity** = Generic term (Fund, GP, SPV, Mgt Co)
- All funds are entities, but not all entities are funds

### ARR Granularity
- **Firm-level ARR**: `core_historical_zuora_arr` (by `salesforce_account_id`)
- **Entity-level ARR**: `core_fct_zuora_arr_by_salesforce_entity` (by `salesforce_entity_id`)
- Use firm-level for total billing, entity-level for per-fund analysis

### Deleted Records
- Most tables use soft deletes (`is_deleted` flag)
- Always filter `WHERE is_deleted = FALSE` unless specifically analyzing deleted records

---

## 🚀 Common Queries

### Get all firms with their fund count
```sql
SELECT 
    f.name AS firm_name,
    COUNT(DISTINCT fund.id) AS fund_count,
    COUNT(DISTINCT CASE WHEN fund.entity_type = 1 THEN fund.id END) AS actual_funds,
    COUNT(DISTINCT CASE WHEN fund.entity_type = 3 THEN fund.id END) AS spvs
FROM base_fund_admin_firms f
LEFT JOIN base_fund_admin_funds fund
    ON f.id = fund.firm_id
    AND fund.is_deleted = FALSE
WHERE f.is_deleted = FALSE
GROUP BY 1
ORDER BY fund_count DESC
```

### Get latest ARR by product for a firm
```sql
SELECT 
    product,
    arr_dollars
FROM core_dim_zuora_investor_services_products
WHERE salesforce_account_id = '001f400000DTWIsAAP'
```

### Find firms with no active ARR
```sql
SELECT 
    f.name AS firm_name,
    f.sfdc_id
FROM base_fund_admin_firms f
LEFT JOIN core_historical_zuora_arr arr
    ON f.sfdc_id = arr.salesforce_account_id
    AND arr.as_of_date = CURRENT_DATE - 1
WHERE f.is_deleted = FALSE
    AND (arr.arr_dollars IS NULL OR arr.arr_dollars = 0)
```
