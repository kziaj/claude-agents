# LLC ARR Organic Expansion - Project Prompts

**Project:** Add organic raw expansion to LLC ARR decomposition  
**Jira Ticket:** [DA-4049](https://carta1.atlassian.net/browse/DA-4049)  
**GitHub PR:** [#8938](https://github.com/carta/ds-dbt/pull/8938)  
**Date:** November 3, 2025

---

## Initial Context Setting

### Prompt 1: DataHub MCP Model Search
```
can you use on the datahub mcp to give me models that have been updated aka Always Use Current + dbt Models
```

**Context:** Initial request to use DataHub MCP tool to find models with "Always Use Current" metadata.

---

## Main Analysis & Query Development

### Prompt 2: ARR Decomposition Analysis Request
```
[Detailed prompt about analyzing ARR decomposition for LLC products]

Key requirements:
- Account: 0014T00000Oz7gQQAR
- Date: 2025-07-02
- Expected organic_raw: $2,750 (from ARR Delta $4,132.5 - Escalator $1,382.5)
- Goal: Write SQL query to derive organic_raw from UpdateProduct events
```

**Context:** Main project prompt requesting analysis of organic expansion calculation from Zuora UpdateProduct events.

---

### Prompt 3: Source-Based Query Request
```
no I mean from the source, so I see update_product_charges cte so basically similar to the core_fct_zuora_arr_escalator_llc model
```

**Context:** Requested to build query from source data following the escalator model pattern (using snapshot consolidation).

---

### Prompt 4: Executable Query Request
```
give me an executable query so I can paste in snowflake.
```

**Context:** Needed a complete, runnable SQL query for Snowflake testing.

---

### Prompt 5: Remove Hard-Coded Values
```
also nothing should be hard coded here. other than the salesforce account id and subsidiary, dont hard code dates
```

**Context:** Ensure query is dynamic and doesn't rely on hardcoded date values.

---

### Prompt 6: Date Matching Investigation
```
I need the dates to match. please investigate
```

**Context:** Query returned dates that didn't match the mart table - needed to fix date logic to use snapshot `charge_added_date` instead of `effective_start_date`.

---

### Prompt 7: Filter First-Time Subscriptions
```
all of these charges are the first time that they actually have the subscription...how can we dynamically remove this?
```

**Context:** Query was including initial subscription setups - needed to filter out charges without prior ARR history.

---

### Prompt 8: Make Universal to All Accounts
```
perfect, remove the constraint on the specific account and make this universal to all accounts now.
```

**Context:** Remove account-specific filters to make query work for all LLC accounts.

---

### Prompt 9: Filter Zero Values & Validate Against Mart
```
I just want values that <> 0 also can you please double check to make sure all results match here select top 100 * from prod_db.dbt_mart.mart_arr_zuora_delta_expansion_detailed_llc where arr_delta_day != 0
```

**Context:** Add non-zero filter and validate query results match existing mart data.

---

## dbt Model Creation

### Prompt 10: Create dbt Model
```
cool now I need you to write a dbt model and yml similar to core_fct_zuora_subscription_discount_history_llc and core_fct_zuora_arr_escalator_llc...General Expansion...first make sure that this matches what we are doing, then write the query.
```

**Context:** Convert validated SQL query into a dbt model following existing LLC decomposition model patterns.

---

### Prompt 11: Keep Current Calculation
```
lets keep the current calculation
```

**Context:** Confirmation to keep `UpdateProduct ARR - Pre-Update ARR` calculation (not quantity-based calculation).

---

### Prompt 12: Create YAML with Tests
```
create the yml for this too if you havent with proper testing
```

**Context:** Request to create schema YAML file with not_null and unique tests.

---

## Mart Integration & Deployment

### Prompt 13: Add to Mart & Create PR
```
now we want to add an arr_delta_organic_raw_expansion column to our delta expansion detailed llc. reference this model. After you do this, make sure you run and test the new model and the expansion detailed model, then create a branch and create a ticket and create a github PR with just the new model, the new yml and the updated expansino detailed llc model.
```

**Context:** 
1. Add `arr_delta_organic_raw_expansion` column to mart
2. Test both models
3. Create git branch
4. Create Jira ticket
5. Create GitHub PR with only the 3 changed files

---

## Code Review & Quality Checks

### Prompt 14: Fix NULL Handling Inconsistency
```
⚠️ Logical Inconsistency in NULL Handling (Severity 7)

There's a contradictory NULL handling pattern in the organic_calculation CTE that could lead to incorrect calculations or confusion:

Line 170: Uses COALESCE(pre.pre_update_arr, 0) which converts NULL to 0
Line 180: Filters out records where pre.pre_update_arr IS NOT NULL

This creates a logical contradiction:
- The COALESCE suggests the code should handle NULLs by treating them as 0
- The IS NOT NULL filter excludes those same NULL records
```

**Context:** Identified redundant COALESCE that contradicted the NULL filter - removed for clarity.

---

### Prompt 15: Grain Check Request
```
did you grain check the expansion detailed?
```

**Context:** Request to verify grain integrity:
- Check for duplicate rows at grain level
- Verify join cardinality between models
- Validate that components sum to total ARR delta

---

## Jira Organization

### Prompt 16: Link to Parent Epic
```
also add the new ticket that you created under LLC Expansion Decomp in jira https://carta1.atlassian.net/jira/software/c/projects/DA/boards/618?assignee=712020%3Ad854e6e9-479b-4c73-904f-619c1c36a188&selectedIssue=DA-3393
```

**Context:** Link DA-4049 to parent task DA-3393 (LLC Expansion Decomp).

---

### Prompt 17: Share Jira Link
```
share thee link with me
```

**Context:** Request Jira ticket URL for easy access.

---

## Documentation

### Prompt 18: Document All Prompts
```
Perfect, now I need you to give me all of my prompts in a new [Image #1] folder I created inside .claude in my local folder. I need you do document all of my prompts that I have gave you in a md with the md name regarding the project. I am going to store all project related prompts here.
```

**Context:** Create markdown documentation of all prompts for future reference in `/Users/klajdi.ziaj/.claude/Image #1/` directory.

---

## Key Learnings & Patterns

### Technical Patterns Established
1. **Snapshot Consolidation:** Use LAG window functions to identify gaps and group continuous charge periods
2. **Date Matching:** Use snapshot `charge_added_date + 1` to match mart's `as_of_date` convention
3. **First-Time Filter:** Exclude charges with `pre_update_arr IS NULL` to filter out initial subscriptions
4. **Non-Zero Filter:** Only include records where calculated expansion != 0
5. **Product Rollup:** Always include both product-level and "All LLC Products" aggregations

### dbt Model Conventions
1. Follow existing LLC decomposition model patterns (escalator, discount)
2. Use `{{ dbt_utils.generate_surrogate_key() }}` for primary keys
3. Include comprehensive YAML documentation with tests
4. Use `--defer --state artifacts/snowflake_prod_run` for development
5. Run both `dbt run` and `dbt test` before committing

### Git & PR Workflow
1. Branch naming: `th/{ticket-id}/{kebab-case-description}`
2. Commit messages: `[TICKET-ID] Description` with Claude attribution
3. PR labels: `cc-product-development` for new features
4. Include test results in PR description
5. Only commit the specific files changed (not everything)

---

## Files Modified

1. **New:** `models/models_scratch/core/zuora/intermediate/llc_decomp/core_fct_zuora_arr_organic_expansion_llc.sql`
2. **New:** `models/models_scratch/core/zuora/intermediate/llc_decomp/core_fct_zuora_arr_organic_expansion_llc.yml`
3. **Updated:** `models/models_scratch/marts/revenue/intermediate/zuora_buckets/mart_arr_zuora_delta_expansion_detailed_llc.sql`

---

## Validation Results

### Model Tests (All Passed ✅)
- `core_fct_zuora_arr_organic_expansion_llc`: 9/9 tests passed
- `mart_arr_zuora_delta_expansion_detailed_llc`: 3/3 tests passed

### Grain Check (All Passed ✅)
- Organic expansion model: 0 duplicate grain violations
- Mart model: 0 duplicate grain violations
- Join cardinality: Clean 1:1 or 0:1 (max 1 organic match per mart row)

### Data Validation (Passed ✅)
- Total rows in mart: 7,710
- Rows with organic expansion: 1,269
- Formula validation: `Escalator + Organic + Discount = Total ARR Delta` (within floating point precision)
