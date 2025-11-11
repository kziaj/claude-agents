# Migration Report: core_fct_zuora_arr → core_fct_zuora_arr_scratch

Generated: November 10, 2025 4:00 PM

**Domain Separation**: Only updated references within scratch directory (domain separation) to maintain proper domain boundaries.
Models in other directories (verified/scratch) will continue to reference the appropriate version.

## Downstream References Updated (X files in scratch directory (domain separation))

- **models/scratch/marts/mart_revenue_summary.sql**: Updated X references
- **models/scratch/marts/mart_arr_analysis.sql**: Updated X references  
- **models/scratch/marts/mart_zuora_metrics.sql**: Updated X references

## Summary

### Files Changed
- **Renamed**: `models/scratch/core/core_fct_zuora_arr.sql` → `models/scratch/core/core_fct_zuora_arr_scratch.sql`
- **Alias Management**: Added alias='core_fct_zuora_arr'
- **Original File**: Removed after successful migration

### Model Configuration
```yaml
# New model configuration in core_fct_zuora_arr_scratch
alias: 'core_fct_zuora_arr'
```

### Reference Updates
All downstream models in scratch directory now reference:
```sql
{{ ref('core_fct_zuora_arr_scratch') }}
```

Instead of:
```sql  
{{ ref('core_fct_zuora_arr') }}
```

### Domain Separation Maintained
- **Scratch models**: Now reference `core_fct_zuora_arr_scratch`
- **Verified models**: Still reference `core_fct_zuora_arr` (verified version)
- **External BI tools**: Continue to work with table name `core_fct_zuora_arr` via alias

## Next Steps

1. **Test the Migration**:
   ```bash
   cd ~/carta/ds-dbt
   dbt compile --select core_fct_zuora_arr_scratch
   dbt run --select core_fct_zuora_arr_scratch
   ```

2. **Validate Downstream Models**:
   ```bash
   dbt run --select +core_fct_zuora_arr_scratch
   ```

3. **Check for Any Missed References**:
   ```bash
   grep -r "ref.*core_fct_zuora_arr[^_]" models/scratch/ --include="*.sql"
   ```

4. **Commit Changes**:
   ```bash
   git add .
   git commit -m "Migrate core_fct_zuora_arr to scratch naming convention
   
   - Rename: core_fct_zuora_arr → core_fct_zuora_arr_scratch
   - Add alias to preserve original table name
   - Update downstream references in scratch directory only
   
   Part of domain migration to verified/ directory"
   ```

## Validation Checklist

- [ ] New model compiles successfully
- [ ] New model runs without errors  
- [ ] All downstream models in scratch still work
- [ ] No remaining references to old model name in scratch
- [ ] Model produces same results as before
- [ ] Alias allows external tools to continue working
- [ ] Verified models still reference clean verified version

---

**Migration completed**: November 10, 2025 4:00 PM  
**Command**: migrate-model-to-scratch core_fct_zuora_arr  
**Status**: ✅ Success