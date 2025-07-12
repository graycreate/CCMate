# CI/CD Guide for CCMate

This guide explains the continuous integration and deployment setup for CCMate.

## Overview

CCMate uses GitHub Actions for automated building, testing, and releasing. The CI/CD pipeline ensures code quality, security, and reliable releases.

## Workflows

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main`, `develop`, or `feature/**` branches
- Pull requests to `main`
- Manual dispatch

**Jobs:**
- **Build and Test**: Builds the app and runs unit tests
- **Lint**: Runs SwiftLint for code quality
- **Build Release**: Creates release build for main branch
- **Security Scan**: Checks for hardcoded secrets
- **Create Release**: Automatically creates GitHub releases for tags

### 2. Security Workflow (`.github/workflows/security.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main`
- Weekly schedule (Mondays at noon UTC)

**Jobs:**
- **Dependency Check**: Monitors for outdated dependencies
- **Code Quality**: Analyzes code complexity
- **Permissions Audit**: Validates app entitlements

### 3. Release Workflow (`.github/workflows/release.yml`)

**Triggers:**
- Manual dispatch with version input

**Jobs:**
- Creates versioned releases with DMG files
- Generates release notes
- Tags the repository

## Local Development

### Running Tests Locally

```bash
# Run all tests
xcodebuild test \
  -project CCMate.xcodeproj \
  -scheme CCMate \
  -destination "platform=macOS"

# Run specific test
xcodebuild test \
  -project CCMate.xcodeproj \
  -scheme CCMate \
  -destination "platform=macOS" \
  -only-testing:CCMateTests/ClaudeDataReaderTests
```

### Verifying CI Setup

Use the verification script:

```bash
./scripts/verify-ci.sh
```

This script checks:
- Xcode installation
- Project structure
- Workflow syntax
- Build configuration
- Security issues
- Test setup

### SwiftLint

Install SwiftLint:
```bash
brew install swiftlint
```

Run locally:
```bash
swiftlint
```

## Creating a Release

### Automated Release

1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Enter version number (e.g., "1.0.0")
4. Select if pre-release
5. Click "Run workflow"

The workflow will:
- Update version numbers
- Build and archive the app
- Create a DMG installer
- Create GitHub release with notes
- Upload the DMG as release asset

### Manual Release

1. Update version in Xcode project
2. Archive the app:
   ```bash
   xcodebuild archive \
     -project CCMate.xcodeproj \
     -scheme CCMate \
     -archivePath build/CCMate.xcarchive
   ```
3. Create DMG:
   ```bash
   hdiutil create -volname "CCMate" \
     -srcfolder build/CCMate.xcarchive/Products/Applications \
     -ov -format UDZO \
     CCMate.dmg
   ```

## Monitoring CI/CD

### Build Status

Check workflow runs at:
`https://github.com/graycreate/CCMate/actions`

### Badges

The README includes status badges:
- CI build status
- Security scan status
- License
- Platform
- Swift version

### Notifications

Configure GitHub notifications to receive alerts for:
- Failed builds
- Security vulnerabilities
- Successful releases

## Troubleshooting

### Build Failures

1. Check Xcode version compatibility
2. Verify Swift version requirements
3. Check for missing dependencies
4. Review build logs in Actions tab

### Test Failures

1. Run tests locally to reproduce
2. Check for environment differences
3. Verify test data fixtures
4. Review test logs for details

### Security Scan Issues

1. Review flagged code
2. Remove any hardcoded secrets
3. Update dependencies if needed
4. Re-run security workflow

## Best Practices

1. **Always test locally** before pushing
2. **Keep workflows updated** with Xcode/macOS versions
3. **Monitor security alerts** regularly
4. **Document breaking changes** in releases
5. **Use semantic versioning** for releases

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [macOS Code Signing](https://developer.apple.com/documentation/security/code_signing_services)