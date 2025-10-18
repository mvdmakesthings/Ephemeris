---
title: "Fix SwiftLint enforcement in CI"
labels: ["ci-cd", "code-quality"]
---

## Description

The CI workflow runs SwiftLint but doesn't fail the build when violations are found, due to `|| true` at the end of the command. This means code quality issues are not enforced.

## Current Implementation

**Location:** `.github/workflows/ci.yml` line 139

```yaml
- name: Run SwiftLint
  run: swiftlint lint --reporter github-actions-logging || true
```

The `|| true` ensures the command always exits with success (exit code 0), even when SwiftLint finds violations.

## Impact

- **Code Quality:** Violations are not enforced
- **Inconsistency:** Different developers may have different code styles
- **Technical Debt:** Issues accumulate without visibility
- **False Confidence:** Green CI badge despite code quality issues

## Root Cause

Likely added to prevent CI failures while the codebase had many existing violations. This is a temporary workaround that became permanent.

## Proposed Solution

### Phase 1: Audit Current Violations

Run SwiftLint locally to see current state:

```bash
swiftlint lint --reporter json > swiftlint-results.json
swiftlint lint --reporter summary
```

### Phase 2: Fix or Disable Problematic Rules

Review violations and either:

1. **Fix violations** (preferred for important rules)
2. **Disable rules** in `.swiftlint.yml` (for low-priority or controversial rules)
3. **Add exclusions** for specific files if needed

Example `.swiftlint.yml` updates:
```yaml
# Add to disabled_rules if too many violations
disabled_rules:
  - line_length  # Already disabled
  - trailing_whitespace  # Already disabled
  # Add more if needed temporarily

# Or increase thresholds
line_length:
  warning: 120
  error: 200
  ignores_comments: true
  ignores_urls: true
```

### Phase 3: Enable Enforcement

Remove `|| true` from CI workflow:

```yaml
- name: Run SwiftLint
  run: swiftlint lint --reporter github-actions-logging
```

### Phase 4: Gradual Improvement

After enforcement is enabled, gradually:
1. Re-enable disabled rules one at a time
2. Fix violations in each PR
3. Improve code quality incrementally

## Alternative: Warning-Only Mode

As an intermediate step, fail only on errors but allow warnings:

```yaml
- name: Run SwiftLint
  run: swiftlint lint --reporter github-actions-logging --strict
  continue-on-error: ${{ github.event_name == 'pull_request' }}
```

This approach:
- ✅ Shows warnings in PR reviews
- ✅ Doesn't block merging
- ✅ Gradually improves quality
- ❌ Doesn't enforce standards

## Recommended Approach

**Two-step process:**

### Step 1: Fix Low-Hanging Fruit (Immediate)

```bash
# Auto-fix what can be auto-fixed
swiftlint lint --fix

# Review remaining violations
swiftlint lint

# Fix critical violations manually
# Or disable remaining problematic rules temporarily
```

### Step 2: Enable Enforcement (Next PR)

```yaml
- name: Run SwiftLint
  run: swiftlint lint --reporter github-actions-logging
```

## Current Violations to Address

Based on the codebase review, likely violations:

1. **Force unwrapping** - Multiple instances in TwoLineElement.swift
2. **Force try** - In demo app ViewController.swift
3. **Identifier naming** - Single-letter variables might violate (but many are excluded)
4. **Function body length** - Some orbital calculations are long
5. **Cyclomatic complexity** - Complex conditional logic

Most of these are already disabled in `.swiftlint.yml` or would need fixing via Issues #1 and #12.

## Testing

Before enabling enforcement:

```bash
# Run locally
swiftlint lint

# Ensure exit code is 0
echo $?

# If non-zero, fix violations or adjust config
```

## Related Issues

- Issue #1 (TLE parsing - force unwraps)
- Issue #3 (Remove print statements)
- Issue #12 (Force try in demo app)

## Priority

**Medium** - Important for code quality but not urgent

## Acceptance Criteria

- [ ] Current violations audited and documented
- [ ] Critical violations fixed or rules disabled (with justification)
- [ ] `|| true` removed from CI workflow
- [ ] CI fails appropriately on violations
- [ ] Document which rules are disabled and why
- [ ] Plan created for gradually re-enabling rules
- [ ] All tests and builds still pass

## Migration Notes

This should be done after or in conjunction with:
- Issue #1 (TLE error handling - removes force unwraps)
- Issue #3 (Remove print statements)

This will minimize the number of violations to fix before enforcement.
