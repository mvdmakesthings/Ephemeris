---
title: "Add automated release process with semantic versioning"
labels: ["ci-cd", "automation", "enhancement"]
---

## Description

The repository lacks an automated release process. Creating releases, generating changelogs, and tagging versions is done manually, which is time-consuming and error-prone.

## Current Behavior

- Manual release creation
- No automated changelog generation
- Inconsistent versioning
- No release automation workflow

**Impact:**
- Time-consuming release process
- Potential for human error
- Inconsistent release notes
- Delayed releases

## Expected Behavior

Automated release process using semantic versioning:

1. Commit with conventional commit message
2. CI automatically determines version bump
3. Changelog generated from commits
4. GitHub release created
5. Tag pushed
6. Optional: Package published

## Proposed Solution

### Step 1: Adopt Conventional Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature (minor version bump)
- `fix`: Bug fix (patch version bump)
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `BREAKING CHANGE`: Breaking change (major version bump)

**Examples:**
```
feat(orbit): add validation for orbital parameters

fix(tle): prevent crash on invalid TLE format

docs(readme): add code examples

BREAKING CHANGE: Orbit initializer now throws errors
```

### Step 2: Add semantic-release

Install semantic-release:

```bash
npm install --save-dev semantic-release
npm install --save-dev @semantic-release/changelog
npm install --save-dev @semantic-release/git
```

Create `.releaserc.json`:

```json
{
  "branches": ["master", "main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/changelog",
      {
        "changelogFile": "CHANGELOG.md"
      }
    ],
    [
      "@semantic-release/github",
      {
        "assets": []
      }
    ],
    [
      "@semantic-release/git",
      {
        "assets": ["CHANGELOG.md", "package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
```

### Step 3: Add GitHub Actions Workflow

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    branches:
      - master
      - main

jobs:
  release:
    runs-on: macos-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: |
          npm install --save-dev semantic-release
          npm install --save-dev @semantic-release/changelog
          npm install --save-dev @semantic-release/git
          
      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: npx semantic-release
```

### Step 4: Alternative - GitHub Actions Only

For simpler approach without Node.js:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Generate Changelog
        id: changelog
        run: |
          # Extract changes since last tag
          PREVIOUS_TAG=$(git describe --abbrev=0 --tags $(git rev-list --tags --skip=1 --max-count=1) 2>/dev/null || echo "")
          if [ -z "$PREVIOUS_TAG" ]; then
            CHANGELOG=$(git log --pretty=format:"- %s" ${{ github.ref_name }})
          else
            CHANGELOG=$(git log --pretty=format:"- %s" ${PREVIOUS_TAG}..${{ github.ref_name }})
          fi
          echo "changelog<<EOF" >> $GITHUB_OUTPUT
          echo "$CHANGELOG" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
          
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref_name }}
          release_name: Release ${{ github.ref_name }}
          body: |
            ## Changes
            ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: false
```

### Step 5: Add Release Script

Create `scripts/release.sh`:

```bash
#!/bin/bash
set -e

# Manual release script for local use
echo "Creating new release..."

# Get current version
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Current version: $CURRENT_VERSION"

# Ask for new version
read -p "Enter new version (e.g., v1.2.3): " NEW_VERSION

# Validate format
if ! [[ "$NEW_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format v1.2.3"
    exit 1
fi

# Generate changelog
echo "Generating changelog..."
git log --pretty=format:"- %s" ${CURRENT_VERSION}..HEAD > /tmp/changelog.txt

# Create tag
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

# Push tag
git push origin "$NEW_VERSION"

echo "✓ Release $NEW_VERSION created!"
echo "  View at: https://github.com/mvdmakesthings/Ephemeris/releases/tag/$NEW_VERSION"
```

## Versioning Strategy

### Semantic Versioning (SemVer)

Format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (e.g., 1.0.0 → 2.0.0)
- **MINOR**: New features, backwards-compatible (e.g., 1.0.0 → 1.1.0)
- **PATCH**: Bug fixes, backwards-compatible (e.g., 1.0.0 → 1.0.1)

### Pre-1.0.0 Versioning

During initial development:
- `0.y.z`: Breaking changes allowed
- Focus on stabilizing API
- Reach 1.0.0 when API is stable

### Release Cadence

- **Patch releases**: As needed for bug fixes
- **Minor releases**: Monthly or when features accumulate
- **Major releases**: When breaking changes necessary

## CHANGELOG Format

Use [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New features not yet released

### Changed
- Changes to existing functionality

### Deprecated
- Features to be removed

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes

## [1.0.0] - 2024-01-15

### Added
- Initial stable release
- TLE parsing
- Orbital calculations
- Position determination

## [0.5.0] - 2024-01-01

### Added
- Beta release
- Core orbital mechanics
```

## Additional Context

- Priority: **Low** - Process improvement
- Effort: **3-4 hours** initial setup
- Maintenance: **Automated** after setup
- Related to: Issue #34 (Swift Package Manager)

## Benefits

1. **Consistency:** Standardized release process
2. **Automation:** Reduces manual work
3. **Transparency:** Clear changelog for users
4. **Traceability:** Git tags linked to releases
5. **Professional:** Shows project maturity

## Acceptance Criteria

- [ ] Release automation workflow added
- [ ] Changelog automatically generated
- [ ] Semantic versioning adopted
- [ ] Tags created automatically
- [ ] GitHub releases created automatically
- [ ] Release notes include changes
- [ ] Documentation updated with versioning policy
- [ ] CHANGELOG.md maintained
