# Quick Start: Creating Issues from Templates

This guide helps you quickly create GitHub issues from the 35 prepared templates.

## TL;DR - Fastest Method

```bash
# 1. Install GitHub CLI (one-time setup)
brew install gh

# 2. Login to GitHub (one-time setup)
gh auth login

# 3. Run the script (creates all 35 issues)
./scripts/create-github-issues.sh
```

That's it! The script will create all 35 issues automatically.

## What You Get

**35 detailed GitHub issues** covering:
- 🔴 4 critical bugs to fix immediately
- 🟡 10 important improvements
- 🟢 21 enhancements and nice-to-haves

## Before You Run the Script

### Check Prerequisites

```bash
# Check if gh is installed
which gh

# Check if you're authenticated
gh auth status

# Preview what will be created
ls -1 .github/ISSUES/[0-9]*.md | wc -l
# Should show: 35
```

### Quick Preview

```bash
# See the first few issues
head -20 .github/ISSUES/01-tle-parsing-error-handling.md
head -20 .github/ISSUES/02-inconsistent-physical-constants.md
```

## Running the Script

### Interactive Mode (Recommended)

```bash
./scripts/create-github-issues.sh
```

The script will:
1. Show you all templates it found
2. Ask for confirmation before creating
3. Create each issue with progress updates
4. Show summary of created issues

**Sample output:**
```
GitHub Issues Creation Script
Repository: mvdmakesthings/Ephemeris
Issues directory: .github/ISSUES

Found issue files:
  - .github/ISSUES/01-tle-parsing-error-handling.md
  - .github/ISSUES/02-inconsistent-physical-constants.md
  - ...

Total issues to create: 35

Do you want to create all these issues on GitHub? (y/N) y

Creating issues...

⚠ Creating issue: Add proper error handling for TLE parsing
✓ Created: Add proper error handling for TLE parsing

...

========================================
Issue Creation Complete
========================================
Created: 35
Failed:  0
Total:   35

View created issues at:
https://github.com/mvdmakesthings/Ephemeris/issues
```

## Alternative Methods

### Method 2: Create Specific Issues

```bash
# Create just the high-priority issues
for issue in 01 02 29 30; do
    gh issue create \
        --repo mvdmakesthings/Ephemeris \
        --body-file .github/ISSUES/${issue}-*.md \
        --title "$(grep '^title:' .github/ISSUES/${issue}-*.md | sed 's/title: //' | tr -d '"')"
done
```

### Method 3: Manual Creation

If you prefer doing it manually:

1. Go to: https://github.com/mvdmakesthings/Ephemeris/issues/new
2. Open: `.github/ISSUES/01-tle-parsing-error-handling.md`
3. Copy title (from line 2): `Add proper error handling for TLE parsing`
4. Copy content (everything after the `---`)
5. Add labels: `bug`, `high-priority`, `enhancement`
6. Click "Submit new issue"
7. Repeat for remaining 34 issues

## After Creating Issues

### Organize with Labels

Issues are pre-tagged with labels:
- `high-priority` - Tackle these first (4 issues)
- `good-first-issue` - Great for new contributors (9 issues)
- `bug` - Fixes for broken functionality
- `enhancement` - New features
- `documentation` - Documentation improvements
- `testing` - Test coverage improvements

### Create a Project Board

Track progress with GitHub Projects:

1. Go to: https://github.com/mvdmakesthings/Ephemeris/projects
2. Click "New project"
3. Choose "Board" template
4. Add columns: To Do, In Progress, Done
5. Add all issues to "To Do"

### Create Milestones

Group issues by phase:

```
Milestone: v1.0 - Critical Fixes
- Issue #01, #02, #29, #30

Milestone: v1.1 - Code Quality  
- Issue #03, #04, #07, #08, #09

Milestone: v1.2 - Testing
- Issue #15, #16, #14

Milestone: v2.0 - Distribution
- Issue #34, #22, #35
```

## Recommended Starting Points

### If You Have 1 Hour
Start with quick wins:
- #07: Fix typo (5 min)
- #08: Remove unused file (5 min)
- #13: Change var to let (5 min)

### If You Have 1 Day
Tackle a critical issue:
- #29: Fix Earth radius (2-3 hours)
- #30: Add bounds checking (4-6 hours)

### If You Have 1 Week
Make significant impact:
- #01: TLE error handling (2 days)
- #02: Physical constants (1 day)
- #03: Remove debug prints (4 hours)
- #04: Magic numbers (1 day)

## Need Help?

### Documentation
- Read: `.github/ISSUES/CODE_REVIEW_SUMMARY.md` for overview
- Read: `.github/ISSUES/ROADMAP.md` for phased plan
- Read: `.github/ISSUES/USAGE_GUIDE.md` for detailed guide

### Script Issues

**Script not found:**
```bash
chmod +x scripts/create-github-issues.sh
```

**gh not found:**
```bash
# macOS
brew install gh

# Linux
# See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
```

**Not authenticated:**
```bash
gh auth login
# Follow the prompts
```

**Rate limit hit:**
```bash
# Wait 1 hour or create issues manually
# Script includes 1-second delays to avoid rate limiting
```

## Verification

After running the script:

```bash
# Check created issues
gh issue list --repo mvdmakesthings/Ephemeris --limit 50

# Should see 35 new issues
```

Visit: https://github.com/mvdmakesthings/Ephemeris/issues

You should see all 35 issues created!

## What's Next?

1. ✅ **Issues created** - You're here!
2. ⬜ **Prioritize** - Review and assign priorities
3. ⬜ **Assign** - Assign to yourself or team members  
4. ⬜ **Track** - Set up project board
5. ⬜ **Start coding** - Pick an issue and start!

---

**Good luck improving Ephemeris!** 🚀

Any questions? Open a GitHub Discussion or comment on the relevant issue.
