# Contributing to CCMate

Thank you for your interest in contributing to CCMate! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to be respectful and constructive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/graycreate/CCMate/issues)
2. If not, create a new issue using the bug report template
3. Include as much detail as possible:
   - Steps to reproduce
   - Expected vs actual behavior
   - System information
   - Screenshots if applicable

### Suggesting Features

1. Check if the feature has already been suggested
2. Create a new issue using the feature request template
3. Explain the use case and benefits
4. Include mockups or examples if possible

### Contributing Code

#### Setup Development Environment

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/CCMate.git
   cd CCMate
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. Open in Xcode:
   ```bash
   open CCMate.xcodeproj
   ```

#### Development Workflow

1. Make your changes
2. Add/update tests as needed
3. Run tests locally:
   ```bash
   ./scripts/verify-ci.sh
   ```
4. Ensure SwiftLint passes:
   ```bash
   swiftlint
   ```
5. Commit with descriptive messages:
   ```bash
   git commit -m "feat: add new feature"
   ```

#### Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions or changes
- `chore:` Build process or auxiliary tool changes

Examples:
```
feat: add weekly usage statistics view
fix: correct timezone handling in hourly chart
docs: update README with new features
test: add unit tests for FileMonitor
```

#### Pull Request Process

1. Update documentation for any new features
2. Add tests for new functionality
3. Ensure all tests pass
4. Update README.md if needed
5. Submit a pull request:
   - Use the PR template
   - Reference any related issues
   - Include screenshots for UI changes
   - Ensure CI checks pass

### Code Style

#### Swift Style Guide

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint rules defined in `.swiftlint.yml`
- Prefer clarity over brevity
- Use meaningful variable and function names

#### Examples

```swift
// Good
func calculateDailyUsageStatistics(from entries: [ClaudeUsageEntry]) -> DailyStats {
    // Implementation
}

// Bad
func calcStats(e: [Entry]) -> Stats {
    // Implementation
}
```

### Testing Guidelines

#### Unit Tests

- Test one thing per test method
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Mock external dependencies

```swift
func test_calculateDailyStats_withEmptyEntries_returnsZeroStats() {
    // Arrange
    let entries: [ClaudeUsageEntry] = []
    
    // Act
    let stats = reader.calculateDailyStats(from: entries)
    
    // Assert
    XCTAssertEqual(stats.sessions, 0)
    XCTAssertEqual(stats.totalUsageTime, 0)
}
```

#### Integration Tests

- Test real interactions between components
- Use test fixtures for consistent data
- Clean up after tests

### Documentation

#### Code Documentation

Use Swift documentation comments:

```swift
/// Calculates daily usage statistics from Claude usage entries.
/// - Parameter entries: Array of usage entries to process
/// - Returns: Aggregated daily statistics
/// - Note: Entries are grouped into sessions based on 5-minute gaps
func calculateDailyStats(from entries: [ClaudeUsageEntry]) -> DailyStats {
    // Implementation
}
```

#### README Updates

Update README.md when:
- Adding new features
- Changing requirements
- Modifying installation steps

### Performance Considerations

- Avoid blocking the main thread
- Use efficient data structures
- Profile performance for large datasets
- Cache expensive calculations

### Security

- Never commit secrets or API keys
- Use secure coding practices
- Validate all inputs
- Follow principle of least privilege

## Getting Help

- Check [documentation](docs/) first
- Search existing issues
- Ask in discussions
- Contact maintainers

## Recognition

Contributors will be:
- Listed in the README
- Mentioned in release notes
- Given credit in commit messages

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue for any questions about contributing!