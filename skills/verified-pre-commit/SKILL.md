# Verified Model Pre-Commit Checklist

This skill provides a comprehensive checklist for validating models before committing to `models_verified/` directory.

## When to Use This Skill

Use this checklist **every time** you:
- Create a new model in `models_verified/`
- Migrate a model from `models_scratch/` to `models_verified/`
- Refactor an existing verified model
- Before pushing a PR with verified model changes

## Complete Pre-Commit Workflow

Run these checks **in order** before committing. Each check catches different issues.

---

### Step 1: Syntax & Style Validation

```bash
validate-verified-standards
```

**What it checks:**
- ✅ No `alias=` configs in verified models
- ✅ No `SELECT *` in verified models
- ✅ All `.sql` files have matching `.yml` files
- ✅ All models have `description:` field
- ✅ YAML `name:` fields match filenames
- ✅ No orphaned `.yml` files
- ✅ `dbt parse` compiles without errors

**Common failures:**
- Copied config blocks from scratch models (with alias)
- Lazy SELECT * from CTEs
- Forgot to create YAML file
- Missing model/column descriptions

**Fix time:** 5-10 minutes

---

### Step 2: Layer Dependency Validation

```bash
validate-layer-dependencies
```

**What it checks:**
- ✅ Mart models only reference core layer (not transform)
- ✅ Core models don't reference marts (backward dependency)
- ✅ Transform models don't reference core/mart (backward dependency)
- ✅ Layer hierarchy is respected: base → transform → core → mart

**Common failures:**
- Mart model directly references `transform_*` instead of `core_*`
- Core model accidentally references a mart
- Backwards dependencies in the DAG

**Fix time:** 10-20 minutes (may require refactoring)

---

### Step 3: Verified Reference Validation

```bash
check-verified-references
```

**What it checks:**
- ✅ Verified models don't reference scratch models
- ✅ All dependencies exist in `models_verified/`
- ✅ No `_scratch` suffixes in `ref()` calls

**Common failures:**
- Referenced an upstream model that's still in scratch
- Forgot to migrate dependencies first
- Typo in ref() call includes _scratch suffix

**Fix time:** 15-30 minutes (may require migrating upstream models)

---

### Step 4: Pre-Commit Hooks

```bash
poetry run pre-commit run check-model-has-description --files models/models_verified/path/to/model.sql

poetry run pre-commit run check-model-has-tests-by-name --files models/models_verified/path/to/model.sql

poetry run pre-commit run check-model-has-tests-by-group --files models/models_verified/path/to/model.sql
```

**What it checks:**
- ✅ All models have descriptions (required by CI)
- ✅ Transform models have `not_null` tests on unique_key
- ✅ Transform models have uniqueness tests (unique or unique_combination_of_columns)

**Common failures:**
- Missing `description: ''` fields in YAML
- Transform model without tests on unique_key
- Tests defined but not on the right column

**Fix time:** 5-10 minutes

---

### Step 5: Compilation & Build Test

```bash
poetry run dbt parse

poetry run dbt build -m <model_name>
```

**What it checks:**
- ✅ Model compiles without SQL errors
- ✅ Model runs successfully
- ✅ All tests pass
- ✅ No runtime errors

**Common failures:**
- Typo in SQL syntax
- Invalid ref() call (model doesn't exist)
- Failed test (duplicate PK, null values)
- Permission errors

**Fix time:** 10-30 minutes

---

### Step 6: Data Validation (If Migrating from Scratch)

```bash
compare-model-data <scratch_model> <verified_model>
```

**What it checks:**
- ✅ Row counts match within threshold
- ✅ Key columns have same distinct counts
- ✅ Sample data matches between versions

**Common failures:**
- Logic changed during refactor
- New filter conditions introduced
- Upstream dependencies changed

**Fix time:** 30-60 minutes (may require investigation)

---

## Quick Reference: All Commands

```bash
# 1. Syntax & style
validate-verified-standards

# 2. Layer dependencies
validate-layer-dependencies

# 3. Verified references
check-verified-references

# 4. Pre-commit hooks (run on changed files)
poetry run pre-commit run check-model-has-description --files <files>
poetry run pre-commit run check-model-has-tests-by-name --files <files>

# 5. Compilation & build
poetry run dbt parse
poetry run dbt build -m <model_name>

# 6. Data validation (optional, for migrations)
compare-model-data <scratch_model> <verified_model>
```

---

## Fast Track: Run All Validation at Once

```bash
# Create a script: verify-all.sh
validate-verified-standards && \
validate-layer-dependencies && \
check-verified-references && \
poetry run dbt parse && \
echo "✅ All validation checks passed!"
```

---

## Troubleshooting Common Issues

### Issue: "Model references scratch model"
**Cause:** Upstream dependency not migrated  
**Fix:** Migrate the upstream model to verified first, or find a verified alternative

### Issue: "Mart references transform layer"
**Cause:** Direct dependency on transform model  
**Fix:** Create or use existing core model as intermediary

### Issue: "Missing description"
**Cause:** YAML file incomplete  
**Fix:** Add `description: ''` field to model and all columns

### Issue: "Test failures"
**Cause:** Data quality issues (duplicates, nulls)  
**Fix:** Investigate data, fix logic, or adjust grain

---

## Best Practices

1. **Run checks incrementally** - Don't wait until the end to validate
2. **Fix in order** - Syntax issues first, then dependencies, then tests
3. **Automate where possible** - Create shell aliases or scripts
4. **Test locally** - Always run `dbt build` before pushing
5. **Document changes** - Update YAML descriptions as you refactor

---

## CI/CD Integration

These checks mirror the CI pipeline. Running them locally **before pushing** prevents:
- ❌ Failed CI checks (wastes time)
- ❌ Blocked PRs (delays merge)
- ❌ Rework cycles (frustration)

**Time saved:** 1-2 hours per PR by catching issues early

---

## Related Tools

- `validate-verified-standards` - Command for syntax/style checks
- `validate-layer-dependencies` - Command for layer hierarchy validation
- `check-verified-references` - Command for verified/scratch separation
- `compare-model-data` - Command for data validation
- `dbt-refactor-agent` - Agent for automated refactoring to standards

---

**Last updated:** 2025-12-05
