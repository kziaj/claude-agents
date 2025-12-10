# Investor Services: Business Hierarchy

**Domain**: Venture capital, private equity, family offices managing investment funds

---

## 📊 Visual Hierarchy

```
FIRM (Investment Organization)
  │
  ├─ Management Company (operational entity)
  │
  └─ FUNDS (Investment Vehicles)
       │
       ├─ Fund I (2020)
       │    ├─ GP (General Partner) ──── 1-5% capital, full control
       │    └─ LPs (Limited Partners) ── 95-99% capital, no control
       │         ├─ Pension Fund A
       │         ├─ Family Office B
       │         └─ Endowment C
       │
       ├─ Fund II (2023)
       │    ├─ GP
       │    └─ LPs
       │
       ├─ Opportunity Fund
       │    ├─ GP
       │    └─ LPs
       │
       └─ SPVs (Special Purpose Vehicles)
            └─ Deal-specific mini-funds
```

---

## 🏢 Entity Definitions

### 1. Firm
**What it is**: The top-level investment organization. The brand.

**Examples**:
- Sequoia Capital
- Andreessen Horowitz (a16z)
- First Round Capital

**What it does**:
- Hires staff
- Manages multiple funds
- Builds brand and sourcing network
- Provides operational support

**In the car analogy**: The car dealership

---

### 2. Management Company
**What it is**: The legal entity that employs people and runs operations.

**Examples**:
- "Sequoia Capital Management, LLC"
- "Andreessen Horowitz Management, LLC"

**What it does**:
- Pays salaries
- Holds office leases
- Manages day-to-day operations
- Often holds GP's economics

**In the car analogy**: The dealership's back office

---

### 3. Fund
**What it is**: A pooled investment vehicle (legal partnership) that invests in companies.

**Examples**:
- "Sequoia Capital Fund I, L.P."
- "a16z Crypto Fund II"
- "First Round Capital III"

**Structure**: Each fund is a partnership between:
- **GP (General Partner)**: The manager
- **LPs (Limited Partners)**: The investors

**Lifecycle**:
1. **Fundraising** (6-18 months): Raise commitments from LPs
2. **Investment Period** (3-5 years): Deploy capital into companies
3. **Harvesting** (5-10+ years): Exit investments, distribute returns
4. **Wind Down**: Final distributions, fund closes

**In the car analogy**: The car itself

---

### 4. GP (General Partner)
**What it is**: The manager of the fund. Makes all investment decisions.

**Role**:
- **Control**: Full decision-making power
- **Capital**: Contributes 1-5% of fund capital (skin in the game)
- **Compensation**: Management fees (2%) + carried interest (20% of profits)
- **Liability**: Unlimited liability (rare in practice due to LP structures)

**Example**:
- "Sequoia GP I, LLC" manages "Sequoia Fund I, L.P."

**Key Point**: GP and LP are **counterparts within the fund**, not in a vertical hierarchy.

**In the car analogy**: The driver (holds the steering wheel)

---

### 5. LP (Limited Partner)
**What it is**: An investor in the fund. Provides capital but has no control.

**Types**:
- **Institutions**: Pension funds, endowments, insurance companies
- **Family Offices**: Wealthy families managing their own capital
- **Individuals**: High-net-worth investors, fund-of-funds

**Role**:
- **Capital**: Contributes 95-99% of fund capital
- **Control**: No control over investment decisions
- **Liability**: Limited to their commitment amount
- **Returns**: Receive distributions when portfolio companies exit

**Commitment Structure**:
```
LP commits: $10M to Fund I
├─ Capital Call 1 (Year 1): $2M → LP wires $2M
├─ Capital Call 2 (Year 2): $3M → LP wires $3M
├─ Capital Call 3 (Year 3): $2M → LP wires $2M
└─ Remaining: $3M uncommitted
```

**In the car analogy**: Passengers (provide gas money, don't steer)

---

### 6. SPV (Special Purpose Vehicle)
**What it is**: A single-deal investment vehicle. A mini-fund for one investment.

**When used**:
- **Co-investment opportunities**: LPs want extra allocation in a hot deal
- **Angel syndicates**: Group of angels pool money for one company
- **Overflow allocation**: Main fund is full, but deal room exists

**Example**:
- "Sequoia Stripe SPV, LLC" (just to invest in Stripe)

**Structure**: Same as fund (GP + LPs), but for one investment only.

**In the car analogy**: A rental car for one specific trip

---

### 7. Carry Vehicle
**What it is**: Entity that holds the GP's carried interest (profit share).

**Why separate**:
- **Tax efficiency**: Separate from management company
- **Profit distribution**: Distributes carry to individual partners
- **Clean accounting**: Separates operational costs from investment profits

**Example**:
- "Sequoia Carry I, LLC" receives 20% of Fund I's profits

**How it works**:
```
Fund I exits investment → Profit = $100M
├─ 80% → LPs ($80M distributed to limited partners)
└─ 20% → Carry Vehicle ($20M)
      └─ Distributed to GP partners based on ownership %
```

---

### 8. Feeder Fund
**What it is**: A sub-fund that pools smaller investors into the main fund.

**Why used**:
- **International investors**: Offshore feeder for non-US LPs
- **Retail investors**: Smaller check sizes ($100K vs $5M minimum)
- **Tax structures**: Different tax treatment for different LP types

**Example**:
```
Sequoia Fund I, L.P. (Master Fund)
  ├─ Sequoia Domestic Feeder, L.P. (US investors)
  └─ Sequoia Cayman Feeder, L.P. (International investors)
```

---

### 9. Blocker Corporation
**What it is**: Tax structure entity to "block" certain tax liabilities.

**Why used**:
- **Foreign LPs**: Avoid US tax issues (UBTI/ECI)
- **Tax-exempt LPs**: Pension funds, endowments avoiding unrelated business income

**How it works**:
```
Tax-Exempt LP
  └─ invests in → Blocker Corp
       └─ invests in → Fund
            └─ invests in → Portfolio Companies
```

The blocker "blocks" the tax-exempt LP from direct exposure to operating income.

---

## 🔗 Relationships & Cardinality

| Parent | Child | Relationship | Example |
|--------|-------|--------------|---------|
| **1 Firm** | **N Funds** | One firm manages many funds | Sequoia has Fund I, II, III, Opportunity |
| **1 Fund** | **1 GP** | One fund has one GP entity | Fund I → Sequoia GP I, LLC |
| **1 Fund** | **N LPs** | One fund has many limited partners | Fund I has 50 institutional LPs |
| **1 Fund** | **N Portfolio Companies** | One fund invests in many companies | Fund I invested in Stripe, Airbnb, etc. |
| **1 Firm** | **N SPVs** | One firm creates many SPVs | Sequoia has 20+ SPVs for co-investments |

---

## 🎯 Key Concepts

### Capital Calls & Distributions

**Capital Call**: GP requests LPs send money to fund investments.
```
Fund sends notice: "Capital Call #3 - $2M due by Jan 15"
LP wires $2M → Fund account → GP deploys into portfolio companies
```

**Distribution**: Fund returns money to LPs after exits.
```
Portfolio company exits → Fund receives $50M proceeds
├─ Return of capital: First $40M back to LPs (return their contributions)
└─ Profit: Remaining $10M split 80/20 (LPs/GP carry)
```

### Management Fees vs Carried Interest

**Management Fee** (2% per year):
- Paid by LPs to cover fund operations
- Based on committed capital (early years) or invested capital (later years)
- Example: $100M fund → $2M/year management fee

**Carried Interest** (20% of profits):
- GP's share of investment profits
- Only paid after LPs get their money back (+ preferred return)
- Example: $50M profit → $40M to LPs, $10M to GP

### Preferred Return (Hurdle)
- LPs get their capital back PLUS 8% annual return before GP gets carry
- Aligns interests: GP only profits if LPs profit first

---

## 💼 Real-World Example

**Firm**: Redpoint Ventures

**Structure**:
```
Redpoint Ventures (The Firm)
├─ Redpoint Management, LLC (Management Company)
│   └─ Employs 15 partners, 30 staff
│
├─ Redpoint Fund I, L.P. (2018) - $300M
│   ├─ Redpoint GP I, LLC (GP - 2% capital)
│   └─ 40 LPs (98% capital)
│        ├─ CalPERS (pension fund)
│        ├─ Harvard Endowment
│        └─ Various family offices
│
├─ Redpoint Fund II, L.P. (2021) - $500M
│   ├─ Redpoint GP II, LLC
│   └─ 50 LPs
│
└─ Redpoint SPVs (10+ SPVs)
     ├─ Redpoint Stripe SPV
     ├─ Redpoint Databricks SPV
     └─ etc.
```

**Investment Flow**:
1. Fund I decides to invest $10M in Stripe
2. GP calls capital from LPs
3. LPs wire money to Fund I
4. Fund I wires $10M to Stripe
5. Stripe shares issued to Fund I
6. Years later, Stripe exits
7. Fund I receives proceeds
8. Distributes to LPs (80%) and Carry Vehicle (20%)

---

## 📌 Summary

**Think of it this way**:
- **Firm** = Brand & organization
- **Fund** = The money pool (partnership)
- **GP** = Fund manager (driver)
- **LP** = Fund investors (passengers)
- **SPV** = One-deal mini-fund
- **Management Co** = Operations entity
- **Carry Vehicle** = Profit-sharing entity

**Critical Point**: GP and LP are **partners within the fund**, not a hierarchical relationship. They're counterparts with different roles.
