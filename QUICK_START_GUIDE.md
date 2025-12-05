# Quick Start Guide: dbt Refactoring with Claude Code Tools

A practical guide for using agents, skills, and commands to systematically refactor dbt models.

**📚 [Back to Main README](./README.md)** | **🔧 [Installation](#setup)** | **📖 [Examples](#real-world-examples)**

---

## Table of Contents

- [Setup](#setup)
- [Your First Migration](#your-first-migration)
- [Common Workflows](#common-workflows)
- [Real-World Examples](#real-world-examples)
- [Troubleshooting](#troubleshooting)
- [Lessons from PR #9012](#lessons-from-pr-9012)
- [Best Practices](#best-practices)

---

## Setup

### Prerequisites

1. **Claude Code** installed and configured
2. **ds-dbt repository** cloned at `~/carta/ds-dbt` or `/Users/klajdi.ziaj/ds-redshift`
3. **Snowflake CLI** configured (`snow` command works)
4. **Poetry** installed for dbt execution
5. **Git** and `gh` CLI for version control

### Installation

```bash
# Clone this repo to your .claude directory
cd ~
git clone git@github.com:kziaj/claude-agents.git .claude

# Verify installation
ls -la ~/.claude/agents/
ls -la ~/.claude/commands/
ls -la ~/.claude/skills/

# Optional: Add commands to PATH
echo 'export PATH="$HOME/.claude/commands:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Test Your Setup

```bash
# Test a command
~/.claude/commands/migrate-model-to-scratch --help

# Test Snowflake connection
snow sql --query "SELECT CURRENT_VERSION();" --format JSON

# Test dbt
cd ~/carta/ds-dbt
poetry run dbt compile --select core_dim_corporations
```

---

## Your First Migration

Let's walk through migrating a single model from scratch to verified.

### Scenario: Migrate `core_fct_revenue_daily`

**Goal:** Move from `models_scratch/core/` to `models_verified/core/` with proper testing and documentation.

### Step 1: Analyze the Model

```plaintext
# In Claude Code, ask:
"Use analyze-unused-columns to review core_fct_revenue_daily 
before migration"
```

**What happens:**
- Command analyzes downstream usage
- Checks 120 days of Snowflake query history
- Generates reports with unused columns

**Review output:**
```bash
# Check reports
cat ~/.claude/results/remove-unused-columns/core_fct_revenue_daily_FULL_COLUMN_ANALYSIS.md
```

### Step 2: Migrate to Scratch Naming

```plaintext
# In Claude Code, ask:
"Use migrate-model-to-scratch to rename core_fct_revenue_daily 
in scratch"
```

**What happens:**
- Renames to `core_fct_revenue_daily_scratch.sql`
- Adds alias config: `alias: 'core_fct_revenue_daily'`
- Updates refs in scratch directory only
- Stages changes in git

**Verify:**
```bash
# Check the renamed file
ls -la models_scratch/core/core_fct_revenue_daily_scratch.sql

# Verify alias config
grep "alias:" models_scratch/core/core_fct_revenue_daily_scratch.sql
```

---

**⚠️ IMPORTANT: 2-PR Strategy for Full Migrations**

When doing a full migration (scratch rename + verified creation), you **MUST** split the work into 2 separate pull requests:

**📋 PR #1 - Scratch Changes (Step 2 above):**
- Rename models in `models_scratch/` with `_scratch` suffix
- Add `alias` config to preserve table names in Snowflake
- Update all refs in `models_scratch/` to point to `_scratch` versions
- Test locally (`dbt run`), commit, and create PR
- **⏸️ Wait for this PR to be reviewed and merged before proceeding**

**📋 PR #2 - Verified Creation (Steps 3-5 below):**
- Create new models in `models_verified/` with proper architecture
- Add tests, documentation, and configs
- Validate data quality between scratch and verified
- Test locally, commit, and create PR

**Why 2 PRs?**
- ✅ **Independent review** - Each PR has clear, focused scope
- ✅ **Easier testing** - Validate scratch changes before building verified
- ✅ **Cleaner rollback** - Can revert one without affecting the other
- ✅ **Better git history** - Clear separation of concerns

---

### Step 3: Create Verified Version with Agent

```plaintext
# In Claude Code, ask:
"Use dbt-refactor-agent to create verified version of 
core_fct_revenue_daily in models_verified/core/ with:
- Proper configs (sort, dist, unique_key)
- Tests (unique, not_null on primary key)
- Documentation in YAML
- Layer compliance validation"
```

**What happens:**
- Agent creates `models_verified/core/core_fct_revenue_daily.sql`
- Creates matching YAML with description and tests
- Validates layer rules (CORE can only reference BASE, TRANSFORM)
- Runs pre-commit hooks to catch issues

### Step 3.5: Run Verified Model Validation

**CRITICAL:** Before proceeding, validate your verified model meets all standards:

```bash
# Quick validation - run all checks at once
validate-verified-standards && \
validate-layer-dependencies && \
check-verified-references && \
poetry run dbt parse
```

**What each check does:**
- `validate-verified-standards` → Checks syntax, style, YAML compliance (no alias, no SELECT *, descriptions)
- `validate-layer-dependencies` → Enforces layer hierarchy (mart → core only, no backwards dependencies)
- `check-verified-references` → Ensures verified models don't reference scratch models
- `poetry run dbt parse` → Validates SQL compiles without errors

**Expected output:**
```
✅ PASS All verified/ standards checks passed
✅ PASS All layer dependencies are valid
✅ PASS All verified models reference other verified models only
```

**If checks fail:** Fix violations before proceeding to data validation. See `~/.claude/skills/verified-pre-commit/SKILL.md` for troubleshooting.

**Time:** ~30 seconds (prevents 1-2 hours of CI failures!)

---

### Step 4: Validate Data Quality

```plaintext
# In Claude Code, ask:
"Use snowflake-agent to validate that scratch and verified versions 
of core_fct_revenue_daily produce identical data"
```

**What it does:**
- Compares row counts
- Validates key columns match
- Checks for data discrepancies

### Step 5: Create Pull Request

```plaintext
# In Claude Code, ask:
"Use pr-agent to create a PR for the core_fct_revenue_daily migration"
```

**What happens:**
- Reviews all changes on branch
- Generates comprehensive PR description
- Adds proper labels
- Includes test plan and validation results

**Time:** ~30-45 minutes total (vs 1-2 hours manual!)

---

## Common Workflows

### Workflow 1: Bulk Rename with Pattern

**Scenario:** Rename 15 models from `core_fct_*` to `transform_revenue_*`

```plaintext
# In Claude Code, ask:
"Use bulk-model-rename to rename all models matching 'core_fct_revenue_*' 
to 'transform_revenue_*' pattern in models_scratch/"
```

**What happens:**
- Finds all matching files (15 models)
- Renames SQL and YAML files
- Updates all refs throughout codebase
- Generates change report

**Time:** ~5 minutes for 15 models

---

### Workflow 2: Complex Multi-Model Migration

**Scenario:** Migrate 7 subscription models with dependencies

```plaintext
# Step 1: Analyze dependencies
"Use model-migration-agent to analyze core_dim_subscriptions and 
identify all dependencies that need to move together"
```

**Agent output:**
- Identifies 6 dependent models
- Maps dependency graph
- Suggests migration order
- Validates no circular dependencies

```plaintext
# Step 2: Create Jira tickets
"Use jira-ticket-agent to create a ticket for migrating the 
7 subscription models to verified/transform/"
```

```plaintext
# Step 3: Execute migration
"Use dbt-refactor-agent to migrate all 7 subscription models 
to verified/transform/corporations/ with:
- Updated refs between models
- Proper layer architecture
- Tests and documentation
- Pre-commit validation"
```

```plaintext
# Step 4: Validate data quality
"Use snowflake-agent to validate all 7 models produce identical data 
between scratch and verified versions"
```

```plaintext
# Step 5: Create PR
"Use pr-agent to create PR for the 7-model subscription migration"
```

**Time:** ~1.5 hours (vs 3-4 hours manual!)

---

### Workflow 3: Single Model Quick Migration

**Scenario:** Quick migration of 1 model, full control

```bash
# Manual approach using commands only

# Step 1: Rename scratch version
~/.claude/commands/migrate-model-to-scratch models_scratch/core/model.sql

# Step 2: Copy to verified
cp models_scratch/core/model_scratch.sql models_verified/core/model.sql

# Step 3: Edit verified version
# - Remove _scratch suffix from refs
# - Add proper configs
# - Create YAML file

# Step 4: Run pre-commit
poetry run pre-commit run check-model-has-description --all-files
poetry run dbt parse

# Step 5: Test locally
poetry run dbt run --models model

# Step 6: Use pr-agent for PR
```

**Time:** ~20-30 minutes

---

## Real-World Examples

### Example 1: PR #9012 - Zuora ARR Migration (43 Models)

**What we did (manual approach):**
```plaintext
1. Manually renamed 43 models to _scratch suffix
2. Pushed without pre-commit validation
3. Got 59 "missing description" failures
4. Fixed with 6 follow-up commits over 2 hours
```

**What we should have done (agent approach):**
```plaintext
1. "Use dbt-refactor-agent to migrate all 43 Zuora ARR models to _scratch 
   naming with proper YAMLs, descriptions, and validation"
2. Agent runs pre-commit hooks locally
3. Single clean commit
4. Push and done
```

**Actual time:** 2 hours 45 minutes  
**Agent time:** 55 minutes  
**Time saved:** 1 hour 50 minutes

📄 [Full Post-Mortem](#lessons-from-pr-9012)

---

### Example 2: Subscription Models Migration (7 Models)

**Scenario:** Move 7 interdependent subscription models to transform layer

**Challenges:**
- Complex dependencies between models
- CORE→CORE violations (prohibited in verified/)
- Need to preserve scratch versions
- ~39 downstream references to update

**Approach with agents:**

```plaintext
# Phase 1: Analysis
"Use model-migration-agent to analyze core_dim_subscriptions and map 
all dependencies"

# Result: 6 dependencies identified, migration plan generated
```

```plaintext
# Phase 2A: Scratch Rename (PR #1)
"Use migrate-model-to-scratch for all 7 subscription models:
- Rename with _scratch suffix
- Add alias configs
- Update refs in scratch directory"

# Result: Scratch versions created, refs updated
```

**Create PR #1, get review, and merge ⏸️**

```plaintext
# Phase 2B: Verified Creation (PR #2)
"Use dbt-refactor-agent to create verified versions of 7 models in
transform/corporations/ with:
- New verified models with transform_ prefix
- Tests and documentation
- Update downstream refs in verified/
- Data quality validation"

# Result: Verified versions created, validated
```

```plaintext
# Phase 3: Final PR
"Use pr-agent to create PR #2 with data validation screenshots"

# Result: Clean PR with comprehensive description
```

**Time:** 2.5 hours (includes 30 min data validation)  
**Manual estimate:** 4-5 hours  
**Time saved:** 2 hours

📄 [Full Plan](./prompt_md/Subscription_Models_Migration_To_Transform.md)

---

### Example 3: Unused Column Removal

**Scenario:** Optimize `core_dim_organizations` by removing unused columns

```bash
# Step 1: Analyze
~/.claude/commands/analyze-unused-columns core_dim_organizations

# Output:
# - 25 total columns
# - 8 unused in dbt models
# - 3 found in query history
# - 5 safe to remove
```

**Review reports:**
```bash
cat ~/.claude/results/remove-unused-columns/core_dim_organizations_FULL_COLUMN_ANALYSIS.md
```

**Remove columns:**
```sql
-- Before (25 columns)
SELECT
  id,
  name,
  unused_column_1,  -- ← Remove
  unused_column_2,  -- ← Remove
  ...

-- After (20 columns)
SELECT
  id,
  name,
  -- 5 columns removed
  ...
```

**Time saved:** 1-2 hours of manual analysis

---

## Troubleshooting

### Issue: "check-model-has-description" fails

**Symptom:**
```
check-model-has-description.........................................Failed
models_verified/transform/model.sql: does not have defined description
```

**Fix:**
1. Create `models_verified/transform/model.yml`
2. Add structure:
```yaml
version: 2
models:
  - name: model
    description: 'Brief description here'
    columns:
      - name: id
        description: ''
```

3. Ensure `name:` field matches SQL filename
4. Re-run: `poetry run pre-commit run check-model-has-description --all-files`

---

### Issue: "dbt-parse" compilation errors

**Symptom:**
```
Compilation Error: Model 'model_name' depends on 'other_model' which was not found
```

**Fix:**
1. Check for typos in `ref()` calls
2. Verify referenced model exists
3. Check YAML `name:` matches filename
4. Run: `poetry run dbt compile --models model_name`

---

### Issue: Downstream references not updated

**Symptom:**
After migration, some models still reference old names

**Fix:**
```bash
# Find remaining old refs
grep -r "ref('old_model_name')" models_verified/

# Update manually or use sed
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('old_model_name')/ref('new_model_name')/g" {} +
```

---

### Issue: Circular dependencies after migration

**Symptom:**
```
Found a cycle: model_a → model_b → model_a
```

**Fix:**
1. Use model-migration-agent to analyze dependencies first
2. Move all interdependent models to same layer (e.g., TRANSFORM)
3. TRANSFORM layer allows multiple sub-layers referencing each other

---

## Lessons from PR #9012

**Context:** November 2024, migrated 43 Zuora ARR models from scratch/ to _scratch naming

### What Went Wrong ❌

#### 1. Skipped Pre-commit Validation Locally
**Mistake:** Pushed without running `check-model-has-description`

**Result:**
- 59 models failed CI with missing descriptions
- 3 fix commits to add descriptions
- 1 hour wasted

**Lesson:** Always run pre-commit hooks locally first

---

#### 2. Didn't Update YAML Files Systematically
**Mistake:** Renamed SQL files but forgot YAMLs

**Result:**
- YAML `name:` fields didn't match SQL filenames
- dbt couldn't find model definitions
- 2 fix commits to rename YAMLs
- 30 minutes wasted

**Lesson:** YAML files are not optional, use agent to handle them

---

#### 3. Forgot Downstream References
**Mistake:** Didn't search for all refs before pushing

**Result:**
- 2 mart models had "node not found" errors
- 1 fix commit to update refs
- 15 minutes wasted

**Lesson:** Use grep to find ALL refs, update systematically

---

#### 4. Left Duplicate Original Files
**Mistake:** Created _scratch versions but didn't delete originals

**Result:**
- "Two resources with identical database representation" error
- 1 fix commit to remove duplicates
- 10 minutes wasted

**Lesson:** Always delete original after creating _scratch version

---

#### 5. Didn't Use dbt-refactor-agent
**Mistake:** Chose manual approach for 43-model migration

**Result:**
- ALL issues above could have been prevented
- 6 total fix commits
- 1.5 hours wasted

**Lesson:** For 5+ models, ALWAYS use dbt-refactor-agent

---

### Time Comparison

| Approach | Time | Commits | CI Failures | Clean? |
|----------|------|---------|-------------|--------|
| **Manual (actual)** | 2h 45m | 7 (1 initial + 6 fixes) | 59 models | ❌ No |
| **Manual + local validation** | 2h 10m | 1 | 0 | ✅ Yes |
| **dbt-refactor-agent** | 55m | 1 | 0 | ✅ Yes |

**Conclusion:** Agent approach saves **1 hour 50 minutes** and prevents all CI failures.

---

### Prevention Checklist

Before pushing ANY dbt model migration, verify:

- [ ] All YAML files created/updated
- [ ] All `name:` fields match SQL filenames
- [ ] All models have `description:` field
- [ ] `poetry run pre-commit run check-model-has-description --all-files` passes
- [ ] `poetry run dbt parse` succeeds
- [ ] `poetry run dbt run --models <affected_models>` succeeds
- [ ] All downstream refs updated and validated
- [ ] Screenshot of successful run taken for PR
- [ ] Original files deleted (if creating _scratch versions)

**If YES to all:** Push confidently with 1 clean commit  
**If NO to any:** Fix it locally first, do NOT push

---

## Best Practices

### 1. Always Start with Analysis

Before any migration:
```plaintext
"Use model-migration-agent to analyze <model_name> and identify 
all dependencies"
```

**Why:** Understand scope before starting, avoid surprises

---

### 2. Use Agents for 5+ Models

**Rule of thumb:**
- 1-3 models → Commands + manual
- 5-10 models → dbt-refactor-agent
- 10+ models → model-migration-agent + dbt-refactor-agent

**Why:** Agents catch 90% of issues upfront, save time

---

### 3. Validate Data Quality

After creating verified versions:
```plaintext
"Use snowflake-agent to validate scratch and verified versions 
of <model_name> produce identical data"
```

**Why:** Catch SQL logic errors before merge

---

### 4. Run Pre-commit Hooks Locally

Before EVERY push:
```bash
poetry run pre-commit run check-model-has-description --all-files
poetry run pre-commit run dbt-parse --all-files
```

**Why:** Prevents 45+ minutes of CI iteration cycles

---

### 5. Test Locally Before Pushing

```bash
# Compile
poetry run dbt compile --models <model>

# Run
poetry run dbt run --models <model>

# Test downstream
poetry run dbt run --models <model>+
```

**Why:** Catch issues in 5 minutes vs 20 minutes in CI

---

### 6. Document as You Go

Use pr-agent to capture:
- What changed
- Why it changed
- How it was validated
- Screenshots of successful runs

**Why:** Helps reviewers, creates knowledge base

---

### 7. Two PRs for Full Migrations

**IMPORTANT:** When doing a full migration (scratch rename + verified creation), always use 2 separate PRs:

**✅ Good - 2 Separate PRs:**
- **PR #1:** Rename models with `_scratch` suffix, add aliases, update refs in `scratch/`
- **Merge PR #1** ⏸️ Wait for review and merge
- **PR #2:** Create models in `verified/` with tests, docs, and data validation

**❌ Bad - Single PR:**
- PR #1: Mix scratch rename + verified creation + everything together
- Result: Massive PR, hard to review, messy rollback

**Why 2 PRs?**
- **Easier review:** Each PR has clear, focused scope (scratch vs verified)
- **Independent testing:** Validate scratch changes work before building verified
- **Cleaner rollback:** Can revert verified without touching scratch
- **Better git history:** Separation of concerns

---

## Quick Reference Card

### Decision Matrix

| Scenario | Tool to Use | Time Est. |
|----------|-------------|-----------|
| Single model migration | migrate-model-to-scratch + manual | 20-30 min |
| 5-10 model migration | dbt-refactor-agent | 45-60 min |
| 10+ model migration | model-migration-agent + dbt-refactor-agent | 1-2 hrs |
| Bulk rename | bulk-model-rename | 5-10 min |
| Remove unused columns | analyze-unused-columns | 10-15 min |
| Data validation | snowflake-agent | 10-20 min |
| Create PR | pr-agent | 5-10 min |
| Jira management | jira-ticket-agent | 10-15 min |

---

### Common Commands

```bash
# Analyze unused columns
~/.claude/commands/analyze-unused-columns model_name

# Migrate to scratch
~/.claude/commands/migrate-model-to-scratch models_scratch/path/to/model.sql

# Bulk rename
~/.claude/commands/bulk-model-rename "old_pattern" "new_pattern"

# Pre-commit validation
poetry run pre-commit run check-model-has-description --all-files
poetry run pre-commit run dbt-parse --all-files

# Local testing
poetry run dbt compile --models model_name
poetry run dbt run --models model_name
poetry run dbt test --models model_name
```

---

### Common Agent Prompts

```plaintext
# Dependency analysis
"Use model-migration-agent to analyze <model> and identify all dependencies"

# Systematic migration
"Use dbt-refactor-agent to migrate <models> to verified/ with tests and docs"

# Data validation
"Use snowflake-agent to validate scratch and verified versions of <model> match"

# PR creation
"Use pr-agent to create PR for <description>"

# Jira management
"Use jira-ticket-agent to create ticket for <description>"
```

---

## Getting Help

### Resources

- 📚 [Main README](./README.md) - Tool reference
- 📂 [Agent Documentation](./agents/) - Detailed agent guides
- 📂 [Command Source](./commands/) - Command implementations
- 📂 [Skills](./skills/) - Reference documentation
- 📁 [Migration Plans](./prompt_md/) - Real migration examples

### Support

- **Questions:** Open an issue on GitHub
- **Bugs:** Include tool name, what you tried, expected vs actual
- **Feature requests:** Describe use case and benefit
- **Slack:** @klajdi for Carta-specific questions

---

**Last Updated:** November 2025  
**Maintained by:** Klajdi Ziaj

🚀 Happy refactoring!
