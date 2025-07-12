#!/bin/bash

# Script to bump version based on conventional commits
# Usage: ./scripts/bump-version.sh [major|minor|patch|auto]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current version from latest tag
get_current_version() {
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "${latest_tag#v}"
}

# Parse semantic version
parse_version() {
    local version=$1
    IFS='.' read -r MAJOR MINOR PATCH <<< "$version"
    echo "$MAJOR $MINOR $PATCH"
}

# Determine version bump type from commits
auto_bump_type() {
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [ -z "$latest_tag" ]; then
        echo "minor"
        return
    fi
    
    # Check for breaking changes
    if git log ${latest_tag}..HEAD --pretty=format:"%s%n%b" | grep -qE "(BREAKING CHANGE|^[a-zA-Z]+!:)"; then
        echo "major"
        return
    fi
    
    # Check for features
    if git log ${latest_tag}..HEAD --pretty=format:"%s" | grep -qE "^feat(\(.*\))?:"; then
        echo "minor"
        return
    fi
    
    # Check for fixes and other changes
    if git log ${latest_tag}..HEAD --pretty=format:"%s" | grep -qE "^(fix|chore|docs|style|refactor|test|perf)(\(.*\))?:"; then
        echo "patch"
        return
    fi
    
    echo "patch"
}

# Bump version
bump_version() {
    local current_version=$1
    local bump_type=$2
    
    read -r major minor patch <<< $(parse_version "$current_version")
    
    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Update version in project files
update_project_version() {
    local version=$1
    
    echo -e "${BLUE}Updating project version to ${version}...${NC}"
    
    # Update Info.plist
    if [ -f "CCMate/Info.plist" ]; then
        plutil -replace CFBundleShortVersionString -string "$version" CCMate/Info.plist
        plutil -replace CFBundleVersion -string "$version" CCMate/Info.plist
        echo -e "${GREEN}✅ Updated Info.plist${NC}"
    fi
    
    # Update AppConstants.swift if exists
    if [ -f "CCMate/AppConstants.swift" ]; then
        sed -i '' "s/static let appVersion = \".*\"/static let appVersion = \"$version\"/" CCMate/AppConstants.swift
        echo -e "${GREEN}✅ Updated AppConstants.swift${NC}"
    fi
    
    # Update package.json if exists (for any web components)
    if [ -f "package.json" ]; then
        sed -i '' "s/\"version\": \".*\"/\"version\": \"$version\"/" package.json
        echo -e "${GREEN}✅ Updated package.json${NC}"
    fi
}

# Main script
main() {
    local bump_type=${1:-auto}
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Not in a git repository${NC}"
        exit 1
    fi
    
    # Get current version
    local current_version=$(get_current_version)
    echo -e "${BLUE}Current version: v${current_version}${NC}"
    
    # Determine bump type
    if [ "$bump_type" = "auto" ]; then
        bump_type=$(auto_bump_type)
        echo -e "${YELLOW}Auto-detected bump type: ${bump_type}${NC}"
    fi
    
    # Validate bump type
    if [[ ! "$bump_type" =~ ^(major|minor|patch)$ ]]; then
        echo -e "${RED}❌ Invalid bump type: $bump_type${NC}"
        echo "Usage: $0 [major|minor|patch|auto]"
        exit 1
    fi
    
    # Calculate new version
    local new_version=$(bump_version "$current_version" "$bump_type")
    echo -e "${BLUE}New version: v${new_version}${NC}"
    
    # Update project files
    update_project_version "$new_version"
    
    # Show what changed
    echo -e "\n${YELLOW}Changes since last release:${NC}"
    git log $(git describe --tags --abbrev=0 2>/dev/null || echo "")..HEAD --oneline
    
    echo -e "\n${GREEN}✨ Version bump complete!${NC}"
    echo -e "Next steps:"
    echo -e "1. Review and commit the changes: ${YELLOW}git add -A && git commit -m \"chore: bump version to ${new_version}\"${NC}"
    echo -e "2. Push to trigger auto-release: ${YELLOW}git push origin main${NC}"
    echo -e "3. Or create a tag manually: ${YELLOW}git tag -a v${new_version} -m \"Release version ${new_version}\" && git push origin v${new_version}${NC}"
}

# Run main function
main "$@"