# LLC: Business Hierarchy

**Domain**: Limited Liability Companies - operating businesses with members and membership units

---

## 📊 Visual Hierarchy

```
LLC (Company Entity)
  │
  ├─ MEMBERS (Owners)
  │    ├─ Founders
  │    ├─ Investors (VCs, Angels)
  │    ├─ Employees (with profit interests)
  │    └─ Advisors
  │
  ├─ MEMBERSHIP UNITS (Ownership)
  │    ├─ Class A Units (voting)
  │    ├─ Class B Units (non-voting)
  │    └─ Profit Interests (future upside only)
  │
  ├─ CAPITAL ACCOUNTS (Financial tracking)
  │    ├─ Contributions
  │    ├─ Distributions
  │    └─ Profit/Loss Allocations
  │
  └─ OPERATING AGREEMENT (Governing document)
```

---

## 🏢 Core Concepts

### 1. LLC (Limited Liability Company)
**What it is**: A business entity that combines limited liability with pass-through taxation.

**Key Characteristics**:
- **Limited liability**: Members aren't personally liable for company debts
- **Pass-through taxation**: Profits/losses flow through to members' personal taxes (no entity-level tax)
- **Flexible structure**: Operating agreement defines governance and profit distribution

**Examples**:
- Tech startups choosing LLC over C-corp
- Real estate holding companies
- Professional services firms

**vs C-Corporation**:
| Feature | LLC | C-Corp |
|---------|-----|--------|
| Taxation | Pass-through (K-1) | Double taxation |
| Ownership units | Membership units | Shares |
| Governance | Operating agreement | Bylaws + Board |
| Flexibility | High | More rigid |

---

### 2. Member
**What it is**: An owner of the LLC. Analogous to "shareholder" in a corporation.

**Types**:
- **Founder Members**: Started the company
- **Investor Members**: VCs, angels who invested capital
- **Employee Members**: Employees with equity compensation
- **Advisor Members**: Advisors with small ownership

**Rights**:
- Profit/loss allocations
- Distributions (dividends)
- Voting rights (if applicable)
- Information rights

**Example**:
```
MyStartup, LLC
├─ Alice (Founder Member) - 40% units
├─ Bob (Founder Member) - 30% units
├─ Sequoia (Investor Member) - 20% units
└─ Charlie (Employee Member) - 10% units
```

---

### 3. Membership Units
**What it is**: Units of ownership in the LLC. Analogous to "shares" in a corporation.

**Classes**:
- **Class A**: Full voting rights, full economic rights
- **Class B**: Limited/no voting rights, full economic rights
- **Profit Interests**: No current value, only future upside (for employees)

**Key Differences from Stock**:
- Units represent % ownership
- Can have different economic vs voting rights
- Often illiquid (no public market)

**Example**:
```
Total Outstanding: 1,000,000 units
├─ Alice holds: 400,000 Class A units (40%)
├─ Bob holds: 300,000 Class A units (30%)
├─ Sequoia holds: 200,000 Class A units (20%)
└─ Charlie holds: 100,000 Profit Interest units (10%)
```

---

### 4. Capital Account
**What it is**: Running ledger of each member's economic interest in the LLC.

**Tracks**:
- **Contributions**: Cash or assets member puts into LLC
- **Distributions**: Cash or assets member receives from LLC
- **Allocations**: Share of LLC's profit or loss each period

**Formula**:
```
Capital Account = 
    Initial Contribution
  + Additional Contributions
  - Distributions Received
  + Profit Allocations
  - Loss Allocations
```

**Example**:
```
Alice's Capital Account History:
Year 1: Initial contribution        +$100,000
Year 1: Allocated profit (40%)      +$50,000
Year 2: Allocated profit            +$80,000
Year 2: Distribution received       -$30,000
Year 3: Allocated loss              -$20,000
----------------------------------------------
Current Capital Account Balance:    $180,000
```

---

### 5. Profit Interest
**What it is**: Employee equity compensation giving future upside only (no current value).

**Key Characteristics**:
- **No liquidation preference**: Only get value above current FMV
- **Vesting**: Typically 4-year vest with 1-year cliff
- **Tax advantage**: Can be granted at $0 (no immediate tax)
- **Hurdle**: Only valuable if company grows beyond hurdle value

**vs Traditional Units**:
| Feature | Profit Interest | Regular Units |
|---------|----------------|---------------|
| Current value | $0 | Full FMV |
| Tax at grant | None (if structured properly) | Yes (FMV) |
| Liquidation preference | No | Yes |
| Upside | Future growth only | Full ownership |

**Example**:
```
Company FMV at grant: $10M
Employee granted profit interests = 5% future upside
Hurdle value: $10M

Exit at $20M:
├─ First $10M → Original members get 100%
└─ Next $10M → Original 95% / Employee 5%
    └─ Employee receives: $500K (5% of $10M growth)

Exit at $50M:
├─ First $10M → Original members
└─ Next $40M → Split 95%/5%
    └─ Employee receives: $2M (5% of $40M growth)
```

---

### 6. Operating Agreement
**What it is**: The LLC's governing legal document. Defines all the rules.

**Key Provisions**:
- **Management structure**: Member-managed vs manager-managed
- **Voting rights**: How decisions are made
- **Profit/loss allocations**: How earnings are split
- **Distribution policy**: When/how cash is distributed
- **Transfer restrictions**: Rules for selling units
- **Dissolution**: What happens if LLC winds down

**Example Clauses**:
- "Profits shall be allocated pro-rata based on membership percentage"
- "No member may transfer units without unanimous consent"
- "Distributions require 75% member vote"

---

## 🔗 Relationships & Cardinality

| Parent | Child | Relationship | Example |
|--------|-------|--------------|---------|
| **1 LLC** | **N Members** | One LLC has many members | MyStartup LLC has 50 members |
| **1 Member** | **N Units** | One member can hold multiple unit types | Alice holds Class A + Profit Interests |
| **1 Member** | **1 Capital Account** | One member has one capital account | Alice's running balance |
| **1 LLC** | **1 Operating Agreement** | One LLC has one governing document | v1.0, amended annually |

---

## 💼 Real-World Example

**Company**: "TechCo, LLC"

**Structure**:
```
TechCo, LLC
├─ Members:
│   ├─ Alice (Founder) - 35% (350,000 Class A units)
│   ├─ Bob (Founder) - 35% (350,000 Class A units)
│   ├─ Sequoia (Investor) - 20% (200,000 Class A units)
│   ├─ Employee Pool - 10% (100,000 Profit Interest units)
│   │   ├─ Charlie - 3%
│   │   ├─ Diana - 2%
│   │   └─ Others - 5%
│
├─ Capital Accounts (Year 3):
│   ├─ Alice: $500K (initial) + $200K (profits) = $700K
│   ├─ Bob: $500K + $200K = $700K
│   ├─ Sequoia: $2M (investment) + $100K (profits) = $2.1M
│   └─ Employees: $0 (profit interests have no capital account value)
│
└─ Operating Agreement:
     ├─ Management: Member-managed (all founders vote)
     ├─ Profit allocation: Pro-rata by ownership %
     ├─ Distributions: Quarterly, subject to cash reserves
     └─ Vesting: 4-year vest, 1-year cliff for profit interests
```

**Financial Flow**:
```
Year 3 Operations:
├─ Revenue: $5M
├─ Expenses: $3M
└─ Profit: $2M

Profit Allocation:
├─ Alice (35%): $700K → Added to capital account
├─ Bob (35%): $700K → Added to capital account
├─ Sequoia (20%): $400K → Added to capital account
└─ Employee Pool (10%): $200K → Split among vested employees

Cash Distribution (50% of profit):
├─ Alice: $350K cash payment
├─ Bob: $350K cash payment
├─ Sequoia: $200K cash payment
└─ Employees: $100K split based on vesting
```

---

## 🆚 LLC vs Corporation

| Aspect | LLC | C-Corporation |
|--------|-----|---------------|
| **Taxation** | Pass-through (K-1) | Double (entity + personal) |
| **Ownership** | Members with units | Shareholders with shares |
| **Financial tracking** | Capital accounts | Equity/retained earnings |
| **Governance** | Operating agreement | Bylaws + board of directors |
| **Employee equity** | Profit interests, units | Stock options, RSUs |
| **Flexibility** | High | Standardized |
| **VC preference** | Less common | Preferred |
| **IPO** | Must convert to C-corp | Ready to go |

---

## 📌 Key Takeaways

1. **LLC = Flexible structure** with pass-through taxation
2. **Members = Owners**, similar to shareholders
3. **Units = Ownership stakes**, like shares but more flexible
4. **Capital Accounts = Financial ledger** for each member
5. **Profit Interests = Employee comp** with tax advantages
6. **Operating Agreement = The rules** governing everything

**Remember**: LLCs are about **flexibility** and **tax efficiency**, but less standardized than corporations.
