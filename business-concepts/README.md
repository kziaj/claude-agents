# Carta Business Concepts & Data Model Reference

**Purpose**: Comprehensive guide to Carta's business domains and their data models for new employees.

**Last Updated**: December 2025

---

## 📚 Documentation Structure

### [Investor Services](./investor-services/) (Firms & Funds)
Everything about venture capital firms, funds, LPs, GPs, and how they invest.
- Business hierarchy: Firm → Funds → LPs/GPs → Portfolio Companies
- Data models: `base_fund_admin_*`, `core_dim_fund_admin_*`, `core_historical_zuora_arr`
- ARR tracking at firm and entity (fund) level

### [LLC](./llc/) (Limited Liability Companies)
How LLCs work as operating companies with members and units.
- Business hierarchy: LLC → Members → Membership Units → Capital Accounts
- Data models: `core_dim_zuora_llc_products`, `core_historical_llc_arr_decomp_detailed`
- Pass-through taxation and profit allocation

### [Corporations](./corporations/) (Companies / Cap Tables)
Private companies managing equity and stakeholders.
- Business hierarchy: Corporation → Subscriptions → Employees/Founders/Investors → Cap Table
- Data models: `core_dim_corporations`, `core_dim_corporations_subscriptions`, `core_historical_corporations_subscription_arr`
- Equity management and billing

### [Cross-Reference](./cross-reference.md)
How these three areas connect:
- Funds invest in Corporations (M:N relationship)
- Billing through Zuora/Salesforce
- Product overlap and integration points

---

## 🎯 Quick Reference

### Three Main Business Lines

| Area | What They Do | Primary Customer |
|------|-------------|-----------------|
| **Investor Services** | Manage funds, track investments, LPs, capital calls | VC firms, PE firms, family offices |
| **LLC** | Manage LLC cap tables, member allocations, distributions | Companies structured as LLCs |
| **Corporations** | Manage equity, cap tables, 409A, options, RSUs | Private companies (C-corps, S-corps) |

### Data Warehouse Key Schemas

| Schema | Purpose |
|--------|---------|
| `dbt_verified_base` | Clean, standardized source data |
| `dbt_verified_transform` | Business logic and transformations |
| `dbt_verified_core` | Core dimensional and fact tables |
| `dbt_verified_mart` | Analytics-ready aggregations |

---

## 🚀 Getting Started

1. **Read the business hierarchy** for each area to understand concepts
2. **Review the data models** to see how concepts map to tables
3. **Try the example queries** to see real data in action
4. **Check cross-reference** to understand integration points

---

## 💡 Common Questions

**Q: Is a "Firm" the same as an "Account"?**  
A: In Salesforce/billing, yes. A Firm has a `salesforce_account_id` for billing.

**Q: What's the difference between Fund and Entity?**  
A: A "Fund" is one type of "Entity." Entities also include GPs, SPVs, Management Companies.

**Q: Where is LLC data stored?**  
A: LLC products are tracked in Zuora (`core_dim_zuora_llc_products`). LLC cap tables are in Corporation tables with `has_llc_waterfall = true`.

**Q: How do I find ARR?**  
- Firm-level: `core_historical_zuora_arr` (by `salesforce_account_id`)
- Fund-level: `core_fct_zuora_arr_by_salesforce_entity` (by `salesforce_entity_id`)
- Corp-level: `core_historical_corporations_subscription_arr` (by `corporation_id`)

---

## 📖 Related Resources

- **dbt Project**: `~/carta/ds-dbt`
- **CLAUDE.md**: Project-specific dbt guidance
- **DataHub**: [https://datahub.carta.com](Internal link placeholder)
- **Confluence**: Product documentation (link to internal docs)

---

## ✏️ Contributing

Found something unclear or outdated? This documentation lives in `~/.claude/business-concepts/`.

Update the relevant markdown files and commit to your local setup.
