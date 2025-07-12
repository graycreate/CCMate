# Setting Up Tests in Xcode

This guide explains how to add the test target to the CCMate Xcode project.

## Steps to Add Test Target

### 1. Open Xcode Project
```bash
open CCMate.xcodeproj
```

### 2. Add Test Target

1. Select the CCMate project in the navigator
2. Click the "+" button at the bottom of the targets list
3. Choose "macOS" → "Unit Testing Bundle"
4. Name it "CCMateTests"
5. Set:
   - Team: Your development team (or None)
   - Bundle Identifier: `com.ccmate.CCMateTests`
   - Language: Swift
   - Project: CCMate
   - Target to be Tested: CCMate

### 3. Configure Test Target

1. Select the CCMateTests target
2. Go to Build Settings:
   - Set "Swift Language Version" to "Swift 6"
   - Set "macOS Deployment Target" to "15.0"
   - Set "Code Signing" to "Sign to Run Locally"

### 4. Add Test Files

1. Right-click on the CCMateTests group
2. Select "Add Files to CCMate..."
3. Navigate to the CCMateTests folder
4. Select all test files:
   - `ClaudeDataReaderTests.swift`
   - `FileMonitorTests.swift`
   - `E2ETests.swift`
   - `Info.plist`
5. Make sure "CCMateTests" target is checked
6. Click "Add"

### 5. Add Test Fixtures

1. Right-click on the CCMateTests group
2. Create a new group called "Fixtures"
3. Add the fixtures folder:
   - Right-click on Fixtures group
   - "Add Files to CCMate..."
   - Select the `Fixtures` folder
   - Choose "Create folder references"
   - Make sure "CCMateTests" target is checked

### 6. Update Scheme for Testing

1. Click on the scheme selector (next to the run button)
2. Select "Edit Scheme..."
3. Select "Test" from the left sidebar
4. Make sure CCMateTests is enabled
5. Under "Options":
   - Check "Gather coverage data"
   - Set "Code Coverage" to "All Targets"

### 7. Add @testable Import

Ensure your test files can access internal types:

```swift
import XCTest
@testable import CCMate
```

## Running Tests

### From Xcode

1. Press `Cmd+U` to run all tests
2. Or click the diamond icon next to test methods/classes

### From Command Line

```bash
# Run all tests
xcodebuild test \
  -project CCMate.xcodeproj \
  -scheme CCMate \
  -destination "platform=macOS"

# Run with coverage
xcodebuild test \
  -project CCMate.xcodeproj \
  -scheme CCMate \
  -destination "platform=macOS" \
  -enableCodeCoverage YES
```

## Test Organization

### Unit Tests
- `ClaudeDataReaderTests`: Tests for parsing and processing Claude usage data
- `FileMonitorTests`: Tests for file system monitoring

### Integration Tests
- `E2ETests`: End-to-end tests comparing with ccusage output

### Test Fixtures
- `Fixtures/usage_2025-07-12.jsonl`: Sample Claude usage data

## Writing New Tests

### Test Template

```swift
import XCTest
@testable import CCMate

final class MyFeatureTests: XCTestCase {
    var sut: MyFeature! // System Under Test
    
    override func setUp() {
        super.setUp()
        sut = MyFeature()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testExample() throws {
        // Given
        let input = "test"
        
        // When
        let result = sut.process(input)
        
        // Then
        XCTAssertEqual(result, "expected")
    }
}
```

### Best Practices

1. **Use descriptive test names**: `test_whenCondition_shouldExpectedBehavior`
2. **Follow AAA pattern**: Arrange, Act, Assert
3. **Test one thing per test**
4. **Use XCTestExpectation for async tests**
5. **Mock external dependencies**
6. **Keep tests fast and isolated**

## Continuous Integration

Tests run automatically on:
- Every push to GitHub
- Every pull request
- Can be run manually via GitHub Actions

## Troubleshooting

### Tests Not Found

1. Ensure test files are added to the test target
2. Check that test classes inherit from `XCTestCase`
3. Verify test methods start with `test`

### Import Errors

1. Add `@testable import CCMate`
2. Ensure main target has "Enable Testability" = YES (Debug only)
3. Clean build folder: `Cmd+Shift+K`

### Access Level Issues

1. Mark testable properties/methods as `internal` or `public`
2. Use `@testable` import for accessing internal members
3. Consider dependency injection for better testability

## Code Coverage

### View Coverage in Xcode

1. Run tests with `Cmd+U`
2. Open Report Navigator (Cmd+9)
3. Select the test run
4. Click "Coverage" tab

### Generate Coverage Report

```bash
# After running tests with coverage enabled
xcrun llvm-cov export \
  -format="lcov" \
  -instr-profile=path/to/Coverage.profdata \
  path/to/CCMate.app/Contents/MacOS/CCMate \
  > coverage.lcov
```

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Code Coverage](https://developer.apple.com/documentation/xcode/gathering-code-coverage-data)