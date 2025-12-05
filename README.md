# Klajdi's Claude Code Tools for dbt Refactoring

A comprehensive collection of Claude Code agents, skills, and commands designed for systematic dbt model refactoring and migration at Carta.

**📚 [Quick Start Guide](./QUICK_START_GUIDE.md)** | **🔧 [Setup Instructions](#installation)** | **📖 [Lessons Learned](./QUICK_START_GUIDE.md#lessons-from-pr-9012)**

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Agents](#agents)
- [Skills](#skills)
- [Commands](#commands)
- [When to Use What](#when-to-use-what)
- [Contributing](#contributing)

---

## Overview

This repository contains production-tested tools for dbt model migrations, developed through multiple large-scale refactoring projects including:
- ✅ 43-model Zuora ARR migration (PR #9012)
- ✅ 7-model subscription models migration (in progress)
- ✅ Multiple domain-specific refactors

**Key Benefits:**
- ⚡ Reduces migration time by 60-70% (2+ hours → 30-45 minutes)
- ✅ Prevents 90% of common CI failures through upfront validation
- 🎯 Systematic approach with built-in best practices
- 📊 Comprehensive validation and reporting

---

## Installation

### For Claude Code Users

1. **Clone this repository:**
   ```bash
   cd ~
   git clone git@github.com:kziaj/claude-agents.git .claude
   ```

2. **Verify installation:**
   ```bash
   ls -la ~/.claude/agents/
   ls -la ~/.claude/commands/
   ls -la ~/.claude/skills/
   ```

3. **Set up command aliases (optional):**
   ```bash
   echo 'export PATH="$HOME/.claude/commands:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

### For Team Members (Read-Only Access)

If you want to review documentation and examples without installing:

```bash
git clone git@github.com:kziaj/claude-agents.git ~/claude-code-docs
```

---

## Agents

Agents are autonomous multi-step workflows that handle complex tasks end-to-end.

### 1. **dbt-refactor-agent** 
*Best for: Bulk model refactoring (5+ models)*

**Use Cases:**
- Migrating multiple models to production standards
- Adding tests, documentation, and configs systematically
- Catching compliance issues before CI
- Moving models between layers (scratch → verified)

**What It Does:**
- Analyzes models for compliance issues
- Fixes code structure (no SELECT *, proper configs)
- Adds required tests and documentation
- Validates layer architecture rules
- Runs pre-commit hooks

**Example:**
```plaintext
"Use dbt-refactor-agent to migrate the 12 revenue models to verified/ 
with proper tests and documentation"
```

**Time Saved:** 1-2 hours on 5+ model migrations

📄 [Full Documentation](./agents/dbt-refactor-agent.md)

---

### 2. **model-migration-agent**
*Best for: Complex dependency analysis and migration planning*

**Use Cases:**
- Moving models with complex dependency chains
- Understanding migration impact
- Validating circular dependencies
- Cross-domain migrations (corporations → revenue)

**What It Does:**
- Maps full dependency tree
- Identifies circular dependencies
- Analyzes downstream impact
- Suggests migration order
- Validates layer compliance

**Example:**
```plaintext
"Use model-migration-agent to analyze dependencies for moving 
core_dim_corporations to verified/ and plan the migration"
```

**Time Saved:** 30-60 minutes on complex migrations

📄 [Full Documentation](./agents/model-migration-agent.md)

---

### 3. **jira-ticket-agent**
*Best for: Comprehensive Jira workflow automation*

**Use Cases:**
- Creating multiple related tickets for large refactors
- Bulk status transitions (In Progress, Done)
- Searching tickets by complex JQL
- Tracking migration progress

**What It Does:**
- Creates properly formatted tickets
- Transitions tickets through workflow
- Searches with complex JQL queries
- Updates tickets with progress notes
- Links related tickets

**Example:**
```plaintext
"Use jira-ticket-agent to create tickets for each domain migration 
in the verified/ refactor project"
```

**Time Saved:** 15-30 minutes on multi-ticket management

📄 [Full Documentation](./agents/jira-ticket-agent.md)

---

### 4. **pr-agent**
*Best for: Creating well-formatted PRs after refactoring*

**Use Cases:**
- Opening PRs with proper descriptions
- Applying appropriate labels automatically
- Generating test plans
- Creating consistent PR format

**What It Does:**
- Reviews branch changes
- Generates comprehensive PR description
- Adds proper labels (cc-product-development, etc.)
- Includes summary, test plan, impact analysis
- Formats with consistent structure

**Example:**
```plaintext
"Use pr-agent to create a PR for the subscription models migration 
after all validation passes"
```

**Time Saved:** 10-15 minutes on PR creation

📄 [Full Documentation](./agents/pr-agent.md)

---

### 5. **snowflake-agent**
*Best for: Data exploration and validation queries*

**Use Cases:**
- Exploring database schemas
- Validating data quality between versions
- Finding specific records for testing
- Understanding table structures

**What It Does:**
- Executes SELECT queries safely
- Explores information_schema
- Formats results as JSON
- Analyzes query patterns
- Validates data consistency

**Example:**
```plaintext
"Use snowflake-agent to compare row counts and key columns between 
scratch and verified versions of core_dim_subscriptions"
```

**Time Saved:** 10-20 minutes on data validation

📄 [Full Documentation](./agents/snowflake.md)

---

### 6. **snowflake-cortex-agent**
*Best for: Building AI-powered data interfaces*

**Use Cases:**
- Creating natural language interfaces for dbt models
- Building semantic models for Cortex Analyst
- Implementing RAG with Cortex Search
- Setting up conversational agents

**What It Does:**
- Builds Cortex Analyst semantic models
- Creates conversational agents
- Implements RAG patterns
- Generates YAML specifications
- Tests AI SQL functions

**Example:**
```plaintext
"Use snowflake-cortex-agent to create a semantic model for the 
subscription models after migration"
```

**Time Saved:** 1-2 hours on semantic model creation

📄 [Full Documentation](./agents/snowflake-cortex-agent.md)

---

## Skills

Skills are reference documentation that Claude Code uses as context.

### 1. **dbt-refactor-standards**
*4-layer architecture and verified/ standards*

**Contains:**
- BASE → TRANSFORM → CORE → MART layer rules
- Model naming conventions
- Testing requirements
- Documentation standards
- Layer reference restrictions

**When to Reference:** Any verified/ migration or refactoring

📂 [Browse Skill](./skills/dbt-refactor-standards/)

---

### 2. **cortex-ai-platform**
*Snowflake Cortex AI capabilities and patterns*

**Contains:**
- Cortex Analyst setup guides
- Semantic model specifications
- Conversational agent patterns
- RAG implementation examples
- Best practices and gotchas

**When to Reference:** Building AI features on refactored models

📂 [Browse Skill](./skills/cortex-ai-platform/)

---

### 3. **verified-pre-commit** ⭐ NEW
*Complete validation workflow for verified/ models*

**Contains:**
- 6-step pre-commit validation checklist
- All validation commands in one workflow
- Troubleshooting guide for common issues
- Quick reference for all validation checks
- Fast-track script for running all checks

**When to Reference:** Before committing any verified/ model changes

📂 [Browse Skill](./skills/verified-pre-commit/)

---

## Commands

Commands are quick, single-purpose utilities for common tasks.

### 1. **migrate-model-to-scratch**
*Quick single-model rename with _scratch suffix*

**Use When:**
- Preserving scratch version before creating verified version
- Need domain separation (scratch refs scratch)
- Want alias config for Snowflake table names

**Usage:**
```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/model_name.sql
```

**What It Does:**
1. Renames file with `_scratch` suffix
2. Adds alias config to preserve table name
3. Updates internal refs to `_scratch` versions
4. Stages git changes

**Time:** ~30 seconds per model

📄 [Full Documentation](#migrate-model-to-scratch-reference)

---

### 2. **update-yaml-metadata**
*Bulk update metadata fields in YAML files*

**Use When:**
- Resolving merge conflicts in YAML metadata
- Bulk updating downstream/upstream node counts
- Synchronizing metadata across multiple files
- Post-migration metadata cleanup

**Usage:**
```bash
~/.claude/commands/update-yaml-metadata '*_scratch.yml' total_downstream_nodes 301 303
```

**What It Does:**
1. Finds all YAML files matching pattern
2. Updates specified metadata field
3. Validates changes
4. Stages with git

**Time:** ~30 seconds for 10+ files

**Real Example:** Updated 9 YAML files in DA-4090 to resolve merge conflicts after main branch changed metadata values.

📄 [Full Documentation](#update-yaml-metadata-reference)

---

### 3. **bulk-model-rename**
*Pattern-based bulk renaming across many models*

**Use When:**
- Renaming 10+ models with consistent pattern
- Changing prefixes (fct_ → fact_, dim_ → core_)
- Systematic naming convention updates

**Usage:**
```bash
~/.claude/commands/bulk-model-rename "core_*" "transform_corporations_*"
```

**What It Does:**
1. Finds all matching files
2. Applies rename pattern
3. Updates refs throughout codebase
4. Handles YAML files

**Time:** ~2-3 minutes for 20 models

📄 [Full Documentation](#bulk-model-rename-reference)

---

### 4. **analyze-unused-columns**
*Identify unused columns before refactoring*

**Use When:**
- Optimizing models for performance
- Reducing complexity before migration
- Understanding actual column usage

**Usage:**
```bash
~/.claude/commands/analyze-unused-columns model_name
```

**What It Does:**
1. Analyzes downstream references
2. Checks Snowflake query history (120 days)
3. Identifies unused columns
4. Generates detailed reports

**Outputs:**
- `~/.claude/results/remove-unused-columns/{model}_DBT_COLUMN_USAGE.md`
- `~/.claude/results/remove-unused-columns/{model}_FULL_COLUMN_ANALYSIS.md`

**Time:** ~5-10 minutes per model

📄 [Full Documentation](#analyze-unused-columns-reference)

---

## When to Use What

### For Small Changes (1-3 models)

**Recommended Flow:**
1. ✅ `migrate-model-to-scratch` for quick renames
2. ✅ Manually create verified versions
3. ✅ `analyze-unused-columns` to optimize
4. ✅ `pr-agent` to create PR

**Time:** 30-45 minutes

---

### For Medium Changes (5-10 models)

**Recommended Flow (Full Migration - Scratch + Verified):**
1. ✅ Use `migrate-model-to-scratch` or `dbt-refactor-agent` for scratch rename
2. ✅ **Create PR #1** - Merge scratch changes first ⏸️
3. ✅ Use `dbt-refactor-agent` to create verified versions  
4. ✅ `snowflake-agent` for data validation
5. ✅ **Create PR #2** - Verified models with tests & docs

**IMPORTANT:** If doing full migration (scratch + verified), use 2 separate PRs for independent review and cleaner rollback.

**Time:** 45-60 minutes per PR (1.5-2 hours total)

**Why Use Agent:** Catches 90% of issues upfront, prevents CI failures

---

### For Large Changes (10+ models or complex dependencies)

**Recommended Flow (Full Migration - Scratch + Verified):**
1. ✅ `model-migration-agent` to analyze dependencies first
2. ✅ `jira-ticket-agent` to create tracking tickets
3. ✅ `dbt-refactor-agent` for scratch rename
4. ✅ **Create PR #1** - Merge scratch changes ⏸️
5. ✅ `dbt-refactor-agent` for verified creation
6. ✅ `snowflake-agent` for extensive data validation
7. ✅ **Create PR #2** - Merge verified models

**Time:** 1-2 hours per PR (2-3 hours total vs. 3-4 hours manual)

**Why 2 PRs:** Independent review, cleaner rollback, better testing isolation

**Why Use Agents:** Complex migrations need dependency analysis and systematic validation

---

### For Systematic Pattern Changes

**Recommended Flow:**
1. ✅ `bulk-model-rename` for pattern-based renames
2. ✅ `dbt-refactor-agent` to fix any issues
3. ✅ `pr-agent` to create PR

**Time:** 30-45 minutes for 20+ models

---

## Key Lessons from PR #9012 (43-Model Migration)

### ❌ What Went Wrong

**Manual approach without validation:**
- Took 2 hours 45 minutes
- Required 6 fix commits
- 59 models failed `check-model-has-description`
- Missed downstream refs, duplicate files, YAML mismatches

### ✅ What Should Have Been Done

**Use dbt-refactor-agent + local validation:**
- Would take 55 minutes (1 hour 50 minutes saved!)
- Single clean commit
- All issues caught upfront
- Pre-commit hooks pass before push

### 🎯 Key Takeaways

1. **Always run pre-commit hooks locally** - Saves 45+ minutes of CI iterations
2. **YAML files are not optional** - check-model-has-description will fail
3. **For 5+ models, use dbt-refactor-agent** - It's faster and more reliable
4. **Validate after each phase** - Catch issues early
5. **Test locally before pushing** - dbt run, dbt compile, pre-commit

📖 [Read Full Post-Mortem](./QUICK_START_GUIDE.md#lessons-from-pr-9012)

---

## Quick Reference

### Decision Tree

```
How many models?
├─ 1-3 models → Use commands (migrate-model-to-scratch)
├─ 5-10 models → Use dbt-refactor-agent
└─ 10+ models → Use model-migration-agent + dbt-refactor-agent

What's the goal?
├─ Rename with _scratch → migrate-model-to-scratch command
├─ Bulk rename pattern → bulk-model-rename command
├─ Remove unused columns → analyze-unused-columns command
├─ Systematic refactor → dbt-refactor-agent
├─ Analyze dependencies → model-migration-agent
├─ Create PR → pr-agent
├─ Manage Jira → jira-ticket-agent
├─ Query Snowflake → snowflake-agent
└─ Build AI interface → snowflake-cortex-agent
```

---

## Contributing

This is Klajdi's personal collection, but suggestions welcome!

### Adding New Tools

1. Fork this repo
2. Add your agent/skill/command
3. Test on a real migration
4. Document with examples
5. Submit PR with before/after metrics

### Reporting Issues

Open an issue with:
- Tool name and version
- What you tried
- Expected vs actual behavior
- Migration context (# of models, complexity)

---

## Resources

### Internal Documentation
- [dbt Refactor Standards Skill](./skills/dbt-refactor-standards/)
- [Cortex AI Platform Skill](./skills/cortex-ai-platform/)
- [Migration Plans](./prompt_md/)

### External Resources
- [dbt Documentation](https://docs.getdbt.com/)
- [Snowflake Cortex](https://docs.snowflake.com/en/user-guide/snowflake-cortex)
- [Claude Code](https://claude.ai/code)

---

## License

MIT License - See [LICENSE](./LICENSE) for details

---

**Created by:** Klajdi Ziaj  
**Updated:** November 2025  
**Status:** Production-ready and actively maintained

For questions or suggestions: Open an issue or reach out on Slack (@klajdi)
