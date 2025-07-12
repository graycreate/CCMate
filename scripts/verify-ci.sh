#!/bin/bash

# Script to verify CI setup locally before pushing

set -e

echo "🔍 Verifying CI setup for CCMate..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script must be run on macOS${NC}"
    exit 1
fi

echo "1️⃣ Checking Xcode installation..."
if xcodebuild -version &> /dev/null; then
    echo -e "${GREEN}✅ Xcode is installed:${NC}"
    xcodebuild -version
else
    echo -e "${RED}❌ Xcode is not installed${NC}"
    exit 1
fi

echo -e "\n2️⃣ Checking project structure..."
if [ -f "CCMate.xcodeproj/project.pbxproj" ]; then
    echo -e "${GREEN}✅ Xcode project found${NC}"
else
    echo -e "${RED}❌ Xcode project not found${NC}"
    exit 1
fi

echo -e "\n3️⃣ Checking GitHub Actions workflows..."
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        echo -e "${GREEN}✅ Found workflow: $(basename $workflow)${NC}"
        # Validate YAML syntax
        if command -v yq &> /dev/null; then
            yq eval '.' "$workflow" > /dev/null 2>&1 || echo -e "${YELLOW}⚠️  Invalid YAML in $workflow${NC}"
        fi
    fi
done

echo -e "\n4️⃣ Running build test..."
echo "Building in Debug configuration..."
if xcodebuild build \
    -project "CCMate.xcodeproj" \
    -scheme "CCMate" \
    -configuration Debug \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath build/test \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=YES \
    -quiet; then
    echo -e "${GREEN}✅ Build succeeded${NC}"
    rm -rf build/test
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo -e "\n5️⃣ Checking SwiftLint..."
if [ -f ".swiftlint.yml" ]; then
    echo -e "${GREEN}✅ SwiftLint configuration found${NC}"
    if command -v swiftlint &> /dev/null; then
        echo "Running SwiftLint..."
        swiftlint --quiet || echo -e "${YELLOW}⚠️  SwiftLint found issues${NC}"
    else
        echo -e "${YELLOW}⚠️  SwiftLint not installed. Install with: brew install swiftlint${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No SwiftLint configuration found${NC}"
fi

echo -e "\n6️⃣ Checking entitlements..."
if plutil -lint CCMate/CCMate.entitlements &> /dev/null; then
    echo -e "${GREEN}✅ Entitlements file is valid${NC}"
else
    echo -e "${RED}❌ Invalid entitlements file${NC}"
    exit 1
fi

echo -e "\n7️⃣ Checking for secrets..."
# Exclude workflow files and scripts that reference secrets variables
if grep -r "PRIVATE KEY\|SECRET\|PASSWORD\|API_KEY" \
    --exclude-dir=".git" \
    --exclude-dir="build" \
    --exclude-dir=".github" \
    --exclude="*.md" \
    --exclude="*.yml" \
    --exclude="verify-ci.sh" \
    . &> /dev/null; then
    echo -e "${RED}❌ Potential secrets found in code!${NC}"
    grep -r "PRIVATE KEY\|SECRET\|PASSWORD\|API_KEY" \
        --exclude-dir=".git" \
        --exclude-dir="build" \
        --exclude-dir=".github" \
        --exclude="*.md" \
        --exclude="*.yml" \
        --exclude="verify-ci.sh" \
        . || true
else
    echo -e "${GREEN}✅ No hardcoded secrets found${NC}"
fi

echo -e "\n8️⃣ Checking test setup..."
if [ -d "CCMateTests" ]; then
    echo -e "${GREEN}✅ Test directory found${NC}"
    test_count=$(find CCMateTests -name "*Tests.swift" | wc -l)
    echo "   Found $test_count test files"
else
    echo -e "${YELLOW}⚠️  No test directory found${NC}"
fi

echo -e "\n✨ ${GREEN}CI verification complete!${NC}"
echo -e "\nNext steps:"
echo "1. Commit your changes: git add . && git commit -m 'Add CI/CD pipeline'"
echo "2. Push to GitHub: git push origin feature/claude-data-integration"
echo "3. Check GitHub Actions tab for workflow runs"