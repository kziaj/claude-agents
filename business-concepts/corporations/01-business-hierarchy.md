# Corporations: Business Hierarchy

**Domain**: Private companies managing equity, cap tables, and stakeholders

---

## 📊 Visual Hierarchy

```
CORPORATION (Company)
  │
  ├─ SUBSCRIPTION (Billing/Products)
  │    ├─ Product (Cap Table, Liquidity, 409A)
  │    ├─ Tier (Scale, Growth, Starter, Custom)
  │    ├─ Features (waterfall, tender offer, etc.)
  │    └─ ARR (annual recurring revenue)
  │
  ├─ STAKEHOLDERS (Equity Holders)
  │    ├─ Founders
  │    ├─ Employees
  │    ├─ Investors (VCs, Angels)
  │    └─ Advisors/Board
  │
  ├─ EQUITY TYPES
  │    ├─ Common Stock (founders, employees)
  │    ├─ Preferred Stock (investors)
  │    ├─ Stock Options (ISO, NSO)
  │    ├─ RSUs (Restricted Stock Units)
  │    └─ Warrants
  │
  └─ CAP TABLE (Ownership View)
       └─ Consolidated view of all ownership
```

---

## 🏢 Core Concepts

### 1. Corporation (Company)
**What it is**: A private company using Carta to manage equity.

**Types**:
- **C-Corporation**: Standard structure, double taxation, can issue preferred stock
- **S-Corporation**: Pass-through taxation, limited shareholders
- **LLC**: (tracked as corporation with `has_llc_waterfall = true`)

**Key attributes**:
- Legal name
- State of incorporation
- Industry
- Stage (seed, Series A, B, C, etc.)

---

### 2. Subscription
**What it is**: The company's Carta billing plan.

**Components**:
- **Product**: Cap Table, Liquidity, 409A Valuations, etc.
- **Tier**: Scale, Growth, Starter, Custom
- **Features**: Specific capabilities enabled
- **Pricing**: Typically based on stakeholder count

**Example**:
```
Acme Corp Subscription:
├─ Product: Cap Table + Liquidity
├─ Tier: Growth
├─ ARR: $12,000/year
├─ Threshold: 150 stakeholders
└─ Features: waterfall, 409a, tender_offer
```

---

### 3. Stakeholders
**Who they are**: Anyone with an equity stake in the company.

**Types**:
| Type | Description | Typical Equity |
|------|-------------|----------------|
| **Founders** | Started the company | Common stock (large %) |
| **Employees** | Work for the company | Stock options, RSUs |
| **Investors** | Provided capital | Preferred stock |
| **Advisors** | Provide guidance | Small option grants |
| **Board Members** | Governance role | May have equity |

---

### 4. Equity Types

#### Common Stock
- **Who gets it**: Founders, employees (after option exercise)
- **Rights**: Voting, dividends (if paid)
- **Liquidation**: Last in line (after preferred)

#### Preferred Stock
- **Who gets it**: VC/angel investors
- **Rights**: Liquidation preference, anti-dilution, voting
- **Series**: A, B, C, etc. (each funding round)

#### Stock Options (ISO/NSO)
- **Who gets them**: Employees
- **What they are**: Right to buy stock at strike price
- **ISO vs NSO**: Tax treatment differs
- **Vesting**: Typically 4 years, 1-year cliff

#### RSUs (Restricted Stock Units)
- **Who gets them**: Employees (later-stage companies)
- **What they are**: Promise to deliver shares after vesting
- **Tax**: Taxed at vesting (not at grant)

---

### 5. Cap Table
**What it is**: The complete ownership breakdown showing who owns what %.

**Shows**:
- Current ownership %
- Fully diluted ownership %
- Vesting schedules
- Liquidation preferences
- Waterfall analysis (who gets paid in exit scenarios)

**Example**:
```
Acme Corp Cap Table:
├─ Alice (Founder): 35% (3.5M common shares)
├─ Bob (Founder): 25% (2.5M common shares)
├─ Sequoia (Series A): 20% (2M preferred shares)
├─ Employees (vested options): 15% (1.5M options)
└─ Option Pool (unvested): 5% (500K reserved)
```

---

## 🔗 Relationships & Cardinality

| Parent | Child | Relationship |
|--------|-------|--------------|
| **1 Corporation** | **N Subscriptions** | One corp has subscription history |
| **1 Corporation** | **N Stakeholders** | One corp has many equity holders |
| **1 Corporation** | **1 Active Subscription** | One current billing plan |
| **1 Subscription** | **N Features** | One plan includes many features |

---

## 💼 Real-World Example

**Company**: "StartupCo, Inc."

**Basic Info**:
- Incorporated: Delaware C-Corp
- Founded: 2020
- Industry: SaaS
- Stage: Series B

**Subscription**:
- Tier: Scale
- ARR: $24,000/year
- Products: Cap Table + 409A + Liquidity
- Stakeholder count: 250

**Cap Table**:
```
Total Shares Outstanding: 10M

├─ Founders (Common): 40%
│   ├─ Alice: 25% (2.5M shares)
│   └─ Bob: 15% (1.5M shares)
│
├─ Investors (Preferred): 40%
│   ├─ Series A (Sequoia): 20% (2M shares, $10M)
│   └─ Series B (a16z): 20% (2M shares, $30M)
│
├─ Employees (Options/Common): 15%
│   ├─ Vested: 10% (1M shares)
│   └─ Unvested: 5% (500K options)
│
└─ Option Pool (Reserved): 5% (500K)
```

**Liquidation Waterfall** (Exit at $100M):
```
1. Series B gets $30M (1x preference)
2. Series A gets $10M (1x preference)
3. Remaining $60M split pro-rata by ownership %
```

---

## 📌 Key Takeaways

1. **Corporation = The company** using Carta
2. **Subscription = Billing plan** for Carta services
3. **Stakeholders = All equity holders** (founders, employees, investors)
4. **Cap Table = The consolidated view** of ownership
5. **Preferred Stock = Investor equity** with special rights
6. **Options/RSUs = Employee compensation** with vesting
