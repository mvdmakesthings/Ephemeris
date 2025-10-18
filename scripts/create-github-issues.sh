#!/bin/bash

# Script to create GitHub issues from markdown files in .github/ISSUES/
# Requires: GitHub CLI (gh) installed and authenticated

set -e

ISSUES_DIR=".github/ISSUES"
REPO="mvdmakesthings/Ephemeris"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitHub Issues Creation Script${NC}"
echo "Repository: $REPO"
echo "Issues directory: $ISSUES_DIR"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Function to extract frontmatter from markdown
extract_frontmatter() {
    local file="$1"
    local field="$2"
    
    # Extract YAML frontmatter value
    awk -v field="$field" '
        BEGIN { in_frontmatter=0 }
        /^---$/ { in_frontmatter = !in_frontmatter; next }
        in_frontmatter && $0 ~ "^"field":" { 
            gsub("^"field": *", "")
            gsub(/^["'\'']/, "")
            gsub(/["'\''"]\s*$/, "")
            print
            exit
        }
    ' "$file"
}

# Function to extract body (content after frontmatter)
extract_body() {
    local file="$1"
    
    awk '
        BEGIN { in_frontmatter=0; frontmatter_count=0 }
        /^---$/ { 
            frontmatter_count++
            if (frontmatter_count == 2) {
                in_frontmatter=0
                next
            }
            in_frontmatter=1
            next
        }
        !in_frontmatter && frontmatter_count >= 2 { print }
    ' "$file"
}

# Find all issue markdown files (excluding README and summary)
issue_files=$(find "$ISSUES_DIR" -name "*.md" ! -name "README.md" ! -name "CODE_REVIEW_SUMMARY.md" | sort)

if [ -z "$issue_files" ]; then
    echo -e "${RED}No issue files found in $ISSUES_DIR${NC}"
    exit 1
fi

echo "Found issue files:"
echo "$issue_files" | sed 's/^/  - /'
echo ""

# Count files
issue_count=$(echo "$issue_files" | wc -l | tr -d ' ')
echo "Total issues to create: $issue_count"
echo ""

read -p "Do you want to create all these issues on GitHub? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Creating issues..."
echo ""

created_count=0
failed_count=0

# Process each issue file
while IFS= read -r file; do
    filename=$(basename "$file")
    
    # Extract metadata
    title=$(extract_frontmatter "$file" "title")
    labels=$(extract_frontmatter "$file" "labels")
    body=$(extract_body "$file")
    
    # Skip if no title
    if [ -z "$title" ]; then
        echo -e "${YELLOW}⚠ Skipping $filename (no title found)${NC}"
        ((failed_count++))
        continue
    fi
    
    echo -e "${YELLOW}Creating issue: $title${NC}"
    
    # Prepare gh command
    gh_cmd="gh issue create --repo $REPO --title \"$title\" --body-file -"
    
    # Add labels if present
    if [ -n "$labels" ]; then
        # Clean up labels (remove brackets and quotes, split by comma)
        clean_labels=$(echo "$labels" | sed 's/[][]//g' | sed 's/"//g' | sed "s/'//g")
        gh_cmd="$gh_cmd --label \"$clean_labels\""
    fi
    
    # Create the issue
    if echo "$body" | eval $gh_cmd > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Created: $title${NC}"
        ((created_count++))
    else
        echo -e "${RED}✗ Failed: $title${NC}"
        ((failed_count++))
    fi
    
    # Small delay to avoid rate limiting
    sleep 1
    
done <<< "$issue_files"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Issue Creation Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Created: ${GREEN}$created_count${NC}"
echo -e "Failed:  ${RED}$failed_count${NC}"
echo -e "Total:   $issue_count"
echo ""

if [ $created_count -gt 0 ]; then
    echo "View created issues at:"
    echo "https://github.com/$REPO/issues"
fi

exit 0
