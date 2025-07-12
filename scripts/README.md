# Scripts Directory

This directory contains utility scripts for the CCMate project.

## Files

### export-options.plist

This file contains export options for creating macOS app archives. It's used by the CI/CD pipeline and release workflows.

**Configuration Notes:**

- `teamID`: Currently empty. To enable code signing, add your Apple Developer Team ID here. You can find this in your Apple Developer account or by running `security find-identity -p codesigning -v` in Terminal.

- `signingStyle`: Set to "automatic" for automatic code signing. Change to "manual" if you need to specify a particular signing certificate.

- The current configuration creates unsigned builds suitable for local development and testing. For production releases with notarization, you'll need to:
  1. Add your Team ID
  2. Ensure proper signing certificates are installed
  3. Enable notarization in the release workflow

### bump-version.sh

A utility script for managing version numbers across the project. Supports semantic versioning with automatic version detection based on conventional commits.

Usage:
```bash
./scripts/bump-version.sh [major|minor|patch|auto]
```

### verify-ci.sh

A local verification script that checks your CI setup before pushing to GitHub. Runs build tests, linting, and security checks locally.

Usage:
```bash
./scripts/verify-ci.sh
```