# Release Process

This document describes the release process for CCMate.

## Automated Releases

CCMate uses automated releases based on conventional commits. When changes are pushed to the `main` branch, the auto-release workflow will:

1. Analyze commits since the last release
2. Determine the appropriate version bump (major, minor, or patch)
3. Build and package the application
4. Create a GitHub release with generated release notes
5. Upload the DMG artifact

### Conventional Commits

The version bump is determined by commit messages:

- `BREAKING CHANGE:` or `feat!:` → Major version bump (1.0.0 → 2.0.0)
- `feat:` → Minor version bump (1.0.0 → 1.1.0)
- `fix:`, `docs:`, `chore:`, etc. → Patch version bump (1.0.0 → 1.0.1)

### Example Commit Messages

```bash
# Features (minor bump)
feat: add dark mode support
feat(ui): implement new settings panel

# Fixes (patch bump)
fix: resolve memory leak in file monitor
fix(data): correct timezone handling

# Breaking changes (major bump)
feat!: redesign API structure
fix!: change data format (breaking change)

# Other (patch bump)
docs: update installation guide
chore: update dependencies
refactor: improve code structure
```

## Manual Release Process

For manual releases, you can:

### Option 1: Use the Release Workflow

1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Enter the version number (e.g., 1.2.0)
4. Choose if it's a pre-release
5. Click "Run workflow"

### Option 2: Use the Version Bump Script

1. Run the version bump script:
   ```bash
   ./scripts/bump-version.sh [major|minor|patch|auto]
   ```

2. Review and commit the changes:
   ```bash
   git add -A
   git commit -m "chore: bump version to X.Y.Z"
   git push origin main
   ```

3. The auto-release workflow will create the release

### Option 3: Create a Tag Manually

1. Update version in project files
2. Commit changes
3. Create and push a tag:
   ```bash
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```

## Release Checklist

Before releasing:

- [ ] All tests pass
- [ ] Code is linted (SwiftLint)
- [ ] Documentation is updated
- [ ] CHANGELOG is updated (if manual)
- [ ] Version numbers are consistent across all files

## Release Artifacts

Each release includes:

- **CCMate-X.Y.Z.dmg**: Disk image for macOS installation
- **Release Notes**: Auto-generated from commit messages
- **Source Code**: Automatically included by GitHub

## Post-Release

After a release:

1. Verify the release on GitHub
2. Test the downloaded DMG
3. Update any external documentation
4. Announce the release (if applicable)

## Troubleshooting

### Build Failures

If the release build fails:

1. Check the GitHub Actions logs
2. Ensure Xcode version compatibility
3. Verify code signing settings

### Version Conflicts

If version numbers are inconsistent:

1. Run `./scripts/bump-version.sh` to sync versions
2. Commit and push the fixes
3. Re-run the release workflow

## Security Notes

- Releases are not code-signed by default
- Users may see security warnings when opening the app
- Consider adding notarization for production releases