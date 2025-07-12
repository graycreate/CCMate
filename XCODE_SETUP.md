# Xcode Setup Instructions

## Adding New Files to Xcode Project

To complete the Claude data integration, you need to add the following new Swift files to your Xcode project:

1. **Open CCMate.xcodeproj** in Xcode

2. **Add the new files to the project:**
   - Right-click on the "CCMate" folder in the project navigator
   - Select "Add Files to CCMate..."
   - Select these files:
     - `ClaudeDataReader.swift`
     - `FileMonitor.swift`
   - Make sure "Copy items if needed" is unchecked (files are already in place)
   - Make sure "CCMate" target is checked
   - Click "Add"

3. **Build and Run:**
   - Select your Mac as the build target
   - Press Cmd+R to build and run
   - The app should appear in your menu bar

## Testing the Integration

1. The app will now read actual Claude usage data from `~/.config/claude/usage_YYYY-MM-DD.jsonl`
2. If you haven't used Claude Code today, you'll see a "No Claude usage detected today" message
3. Start using Claude Code and the stats will update automatically
4. The app monitors the usage file in real-time and updates when new entries are added

## Troubleshooting

- If you see build errors about missing files, make sure you added both new Swift files to the project
- If the app can't read Claude data, check that the entitlements file was updated correctly
- The app requires macOS 15.0+ (Sequoia) to run

## Next Steps

After testing, you can merge the feature branch:
```bash
git checkout main
git merge feature/claude-data-integration
```