# dbt Refactor Tooling Overview

**Last Updated**: 2025-01-13  
**Purpose**: Executive summary of all agents, skills, and commands supporting the dbt refactor initiative

---

## CEO Summary: dbt Refactor Tooling

### AGENTS (6)

**1. dbt-refactor-agent**  
Systematically analyzes models, fixes compliance issues, adds tests/docs, and ensures layer rules are followed to bring models up to production standards for the verified/ directory.

**2. jira-ticket-agent**  
Manages the complete Jira ticket lifecycle (creation, transitions, search) to track all dbt refactor work items and maintain proper project organization throughout the migration.

**3. model-migration-agent**  
Handles complex multi-model operations like bulk renames, version suffix removal, and directory reorganization with dependency analysis to safely migrate large groups of models at once.

**4. pr-agent**  
Analyzes branch changes and creates properly formatted pull requests with descriptions and labels to streamline code review for all dbt refactor work.

**5. snowflake-cortex-agent**  
Builds AI-powered semantic models and conversational agents on top of refactored dbt models to enable natural language queries and advanced analytics capabilities.

**6. snowflake**  
Executes SQL queries for data validation, schema exploration, and quality checks to verify refactored models produce correct results before deployment.

---

### SKILLS (4)

**1. dbt-refactor-standards**  
Reference documentation of layer architecture, naming conventions, and verified/ requirements that all refactored models must follow to meet production quality standards.

**2. timestamp-naming-standards**  
Defines the `_at` suffix convention for timestamp columns in base models to eliminate ambiguity and ensure consistency across all refactored verified/ models.

**3. cortex-ai-platform**  
Comprehensive reference for building AI features on top of refactored models using Snowflake's Cortex capabilities to unlock advanced analytics use cases.

**4. data-quality-validation-patterns**  
Reusable SQL patterns for validating data consistency between scratch/ and verified/ versions during migration to ensure no data quality regressions.

---

### COMMANDS (7)

**1. validate-timestamp-naming**  
Scans base models to detect timestamp columns missing `_at` suffix and prevents violations from reaching production during the refactor migration.

**2. validate-verified-standards**  
Comprehensive pre-commit checker that catches alias configs, SELECT *, missing YAML, and other violations before they block the refactor pipeline.

**3. analyze-unused-columns**  
Identifies unused columns in models through downstream analysis and query history to safely remove technical debt during refactor cleanup.

**4. bulk-model-rename**  
Pattern-based renaming tool that updates SQL files, YAML files, and all downstream references atomically to accelerate large-scale refactor migrations.

**5. compare-model-data**  
Row-by-row comparison between scratch/ and verified/ versions with match percentage reporting to validate zero data quality regression after refactoring.

**6. get-column-lineage**  
Traces column-level upstream/downstream dependencies using Snowflake metadata to understand impact before refactoring or removing columns.

**7. migrate-model-to-scratch**  
Automates the scratch model renaming with `_scratch` suffix and alias management to enable parallel scratch/verified coexistence during gradual migration.

---

## Refactor Workflow: Complete Domain Migration

### Phase 1: Planning & Discovery

1. **jira-ticket-agent** → Creates tickets for the domain refactor work
2. **snowflake** → Explores current domain schemas, tables, and data patterns
3. **dbt-refactor-standards skill** → Reference guide for understanding what standards to meet

### Phase 2: Dependency Analysis

4. **get-column-lineage** → Maps upstream/downstream column dependencies to understand impact
5. **analyze-unused-columns** → Identifies technical debt columns that can be removed during refactor

### Phase 3: Migration Execution

6. **migrate-model-to-scratch** → Renames existing scratch models with `_scratch` suffix and adds aliases
7. **dbt-refactor-agent** → Refactors individual models to meet verified/ standards (fixes SELECT *, adds tests/docs, removes aliases)
8. **model-migration-agent** → Handles any bulk renames or directory reorganizations across the domain
9. **bulk-model-rename** → Executes pattern-based renames if standardizing naming across many models

### Phase 4: Quality Validation

10. **timestamp-naming-standards skill** → Reference for ensuring all base model timestamps use `_at` suffix
11. **validate-timestamp-naming** → Scans base models for timestamp naming violations
12. **validate-verified-standards** → Checks for alias configs, SELECT *, and YAML completeness
13. **data-quality-validation-patterns skill** → Reference for writing data consistency checks
14. **compare-model-data** → Validates scratch vs verified data matches (99%+ threshold)

### Phase 5: Code Review & Deployment

15. **pr-agent** → Creates formatted pull request with all changes and validation results
16. **jira-ticket-agent** → Transitions ticket to "In Review" or "Done" status

### Phase 6: Advanced Features (Optional)

17. **cortex-ai-platform skill** → Reference for building AI capabilities on refactored models
18. **snowflake-cortex-agent** → Creates semantic models and conversational agents for the domain

---

## How They Work Together

**The tools form a complete refactor pipeline: Jira tracks the work, Snowflake explores the domain, lineage/analysis tools identify what to change, migration agents execute the refactoring, validation commands catch errors, data comparison ensures correctness, PR agent packages it for review, and Cortex tools unlock AI features on the clean verified models.**

---

## Key Benefits

### Automation & Speed
- Bulk operations replace manual file-by-file migration
- Validation commands catch errors before CI/CD
- Agents handle repetitive tasks systematically

### Quality Assurance
- Data comparison validates zero regression
- Standards enforcement prevents production issues
- Comprehensive testing at each phase

### Knowledge Preservation
- Skills document institutional knowledge
- Consistent patterns across all migrations
- Clear workflow for new team members

### Measurable Progress
- Jira tracking for executive visibility
- Clear phases with completion criteria
- Quantifiable metrics (99%+ data match)

---

## Success Metrics

**DA-4083 Zuora ARR Migration Results:**
- 5 models migrated to verified/ in 2.5 hours
- 99.19% data match (19.1M of 19.2M rows)
- Zero production incidents
- 1 timestamp violation found and fixed across all 60 base models
- 4 new tooling improvements created from learnings

---

## Related Documentation

- **CLAUDE.md** - Global rules with pre-push validation checklist
- **ds-redshift/CLAUDE.md** - Project-specific dbt development practices
- **~/.claude/agents/** - Individual agent implementation details
- **~/.claude/skills/** - Reference documentation and patterns
- **~/.claude/commands/** - Command-line tool usage and options

---

**Document Owner**: Klajdi Ziaj  
**Review Cycle**: After each major domain migration  
**Feedback**: Update this document with lessons learned from each refactor
