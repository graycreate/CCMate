import XCTest
@testable import CCMate

final class ClaudeDataReaderTests: XCTestCase {
    var reader: ClaudeDataReader!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        reader = ClaudeDataReader()
        testBundle = Bundle(for: type(of: self))
    }
    
    override func tearDown() {
        reader = nil
        testBundle = nil
        super.tearDown()
    }
    
    func testParseClaudeUsageEntry() throws {
        // Given
        let json = """
        {"timestamp":"2025-07-12T01:30:45.123+0000","model":"claude-3-opus-20240229","input_tokens":1523,"output_tokens":2341,"cache_creation_input_tokens":0,"cache_read_input_tokens":450,"cost":0.143265}
        """
        
        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeUsageEntry.self, from: data)
        
        // Then
        XCTAssertEqual(entry.timestamp, "2025-07-12T01:30:45.123+0000")
        XCTAssertEqual(entry.model, "claude-3-opus-20240229")
        XCTAssertEqual(entry.inputTokens, 1523)
        XCTAssertEqual(entry.outputTokens, 2341)
        XCTAssertEqual(entry.cacheCreationInputTokens, 0)
        XCTAssertEqual(entry.cacheReadInputTokens, 450)
        XCTAssertEqual(entry.cost, 0.143265, accuracy: 0.000001)
    }
    
    func testCalculateDailyStats() throws {
        // Given
        let entries = createTestEntries()
        
        // When
        let stats = reader.calculateDailyStats(from: entries)
        
        // Then
        // Should have 3 sessions (gaps > 5 minutes between groups)
        XCTAssertEqual(stats.sessions, 3)
        
        // Total usage time should be sum of session durations
        XCTAssertGreaterThan(stats.totalUsageTime, 0)
        
        // Average session length should be total time / number of sessions
        XCTAssertEqual(stats.averageSessionLength, stats.totalUsageTime / 3, accuracy: 0.1)
        
        // Hourly activity should have entries for hours 1, 2, 3, and 4 (UTC)
        XCTAssertEqual(stats.hourlyActivity[1], 3) // 3 entries in hour 1
        XCTAssertEqual(stats.hourlyActivity[2], 2) // 2 entries in hour 2
        XCTAssertEqual(stats.hourlyActivity[3], 1) // 1 entry in hour 3
        XCTAssertEqual(stats.hourlyActivity[4], 2) // 2 entries in hour 4
    }
    
    func testCalculateDailyStatsWithEmptyEntries() {
        // Given
        let entries: [ClaudeUsageEntry] = []
        
        // When
        let stats = reader.calculateDailyStats(from: entries)
        
        // Then
        XCTAssertEqual(stats.sessions, 0)
        XCTAssertEqual(stats.totalUsageTime, 0)
        XCTAssertEqual(stats.averageSessionLength, 0)
        XCTAssertEqual(stats.hourlyActivity.reduce(0, +), 0)
    }
    
    func testSessionDetection() {
        // Given
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        // Create entries with specific gaps
        let baseTime = Date()
        let entries = [
            // Session 1: 3 entries within 5 minutes
            createEntry(at: baseTime),
            createEntry(at: baseTime.addingTimeInterval(60)), // 1 minute later
            createEntry(at: baseTime.addingTimeInterval(180)), // 3 minutes later
            
            // Session 2: After 10 minute gap
            createEntry(at: baseTime.addingTimeInterval(780)), // 13 minutes later
            createEntry(at: baseTime.addingTimeInterval(840)), // 14 minutes later
            
            // Session 3: After 30 minute gap
            createEntry(at: baseTime.addingTimeInterval(2640)), // 44 minutes later
        ]
        
        // When
        let stats = reader.calculateDailyStats(from: entries)
        
        // Then
        XCTAssertEqual(stats.sessions, 3, "Should detect 3 separate sessions")
    }
    
    // MARK: - Helper Methods
    
    private func createTestEntries() -> [ClaudeUsageEntry] {
        return [
            ClaudeUsageEntry(
                timestamp: "2025-07-12T01:30:45.123+0000",
                model: "claude-3-opus-20240229",
                inputTokens: 1523,
                outputTokens: 2341,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 450,
                cost: 0.143265
            ),
            ClaudeUsageEntry(
                timestamp: "2025-07-12T01:35:12.456+0000",
                model: "claude-3-opus-20240229",
                inputTokens: 892,
                outputTokens: 1567,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 325,
                cost: 0.089745
            ),
            ClaudeUsageEntry(
                timestamp: "2025-07-12T01:36:23.789+0000",
                model: "claude-3-opus-20240229",
                inputTokens: 2145,
                outputTokens: 3210,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 678,
                cost: 0.198450
            ),
            ClaudeUsageEntry(
                timestamp: "2025-07-12T02:45:10.111+0000",
                model: "claude-3-opus-20240229",
                inputTokens: 567,
                outputTokens: 890,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 210,
                cost: 0.054123
            ),
            ClaudeUsageEntry(
                timestamp: "2025-07-12T02:47:30.222+0000",
                model: "claude-3-opus-20240229",
                inputTokens: 3456,
                outputTokens: 4567,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 1234,
                cost: 0.285690
            ),
            ClaudeUsageEntry(
                timestamp: "2025-07-12T03:15:45.333+0000",
                model: "claude-3-opus-20240229",
                inputTokens: 789,
                outputTokens: 1234,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 345,
                cost: 0.072456
            ),
            ClaudeUsageEntry(
                timestamp: "2025-07-12T04:20:00.444+0000",
                model: "claude-3-5-sonnet-20241022",
                inputTokens: 2341,
                outputTokens: 3456,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 890,
                cost: 0.067890
            ),
            ClaudeUsageEntry(
                timestamp: "2025-07-12T04:22:15.555+0000",
                model: "claude-3-5-sonnet-20241022",
                inputTokens: 1234,
                outputTokens: 2345,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 567,
                cost: 0.043210
            )
        ]
    }
    
    private func createEntry(at date: Date) -> ClaudeUsageEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return ClaudeUsageEntry(
            timestamp: formatter.string(from: date),
            model: "claude-3-opus-20240229",
            inputTokens: 1000,
            outputTokens: 2000,
            cacheCreationInputTokens: 0,
            cacheReadInputTokens: 500,
            cost: 0.1
        )
    }
}