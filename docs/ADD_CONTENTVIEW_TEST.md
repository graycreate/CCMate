# Adding ContentViewTests to the Project

A new test file `ContentViewTests.swift` has been created to address Copilot's review comment about testing the empty-state view. This file needs to be added to the Xcode project.

## Steps to Add the Test File

1. Open `CCMate.xcodeproj` in Xcode
2. In the project navigator, right-click on the `CCMateTests` folder
3. Select "Add Files to CCMate..."
4. Navigate to and select `CCMateTests/ContentViewTests.swift`
5. Ensure "CCMateTests" is checked in the target membership
6. Click "Add"

## What the Test Covers

The `ContentViewTests.swift` file includes:

- **testEmptyStateViewAppearsWhenNoData**: Verifies that the empty state view logic triggers when there's no usage data
- **testEmptyStateViewHiddenWhenDataExists**: Verifies that the empty state is hidden when data is present
- **testEmptyStateConditions**: Tests various edge cases for the empty state logic

## Optional: Snapshot Testing

The test file also includes commented-out snapshot test examples that can be enabled if you add the SnapshotTesting library to your project. This would allow visual regression testing of the UI states.

## Running the Tests

After adding the file to Xcode:
```bash
xcodebuild test -project CCMate.xcodeproj -scheme CCMate -destination "platform=macOS"
```

Or run them directly in Xcode with ⌘+U.