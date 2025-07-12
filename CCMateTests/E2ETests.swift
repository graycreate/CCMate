import XCTest
@testable import CCMate

final class E2ETests: XCTestCase {
    var reader: ClaudeDataReader!
    
    override func setUp() {
        super.setUp()
        reader = ClaudeDataReader()
    }
    
    override func tearDown() {
        reader = nil
        super.tearDown()
    }
    
    /// End-to-end test that compares our calculations with ccusage output
    func testCompareWithCCUsage() throws {
        // Skip this test if running in CI or if ccusage is not installed
        guard isCommandAvailable("ccusage") else {
            throw XCTSkip("ccusage not installed")
        }
        
        // Get ccusage output for today
        let ccusageOutput = try runCCUsageCommand()
        let ccusageStats = try parseCCUsageOutput(ccusageOutput)
        
        // Get our calculations
        let entries = reader.readTodayUsage()
        let ourStats = reader.calculateDailyStats(from: entries)
        
        // Compare key metrics
        if let ccusageToday = ccusageStats.first(where: { $0.date == todayDateString() }) {
            // Compare total cost (allowing for small rounding differences)
            let ourTotalCost = entries.reduce(0) { $0 + $1.cost }
            XCTAssertEqual(ourTotalCost, ccusageToday.cost, accuracy: 0.01,
                          "Total cost should match ccusage within $0.01")
            
            // Compare token counts
            let ourInputTokens = entries.reduce(0) { $0 + $1.inputTokens }
            let ourOutputTokens = entries.reduce(0) { $0 + $1.outputTokens }
            
            XCTAssertEqual(ourInputTokens, ccusageToday.inputTokens,
                          "Input token count should match ccusage")
            XCTAssertEqual(ourOutputTokens, ccusageToday.outputTokens,
                          "Output token count should match ccusage")
        }
    }
    
    /// Test that we correctly handle multiple days of data
    func testHistoricalDataProcessing() throws {
        // Get historical files
        let historicalFiles = reader.getHistoricalUsageFiles(days: 7)
        
        // Process each file and verify data integrity
        for file in historicalFiles {
            let data = try String(contentsOf: file, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            // Verify each line is valid JSON
            for line in lines {
                XCTAssertNoThrow(try JSONSerialization.jsonObject(with: line.data(using: .utf8)!),
                               "Each line should be valid JSON")
            }
        }
    }
    
    /// Test session detection matches expected behavior
    func testSessionDetectionAccuracy() throws {
        // Create test data with known session boundaries
        let testDataPath = createTestDataWithKnownSessions()
        defer { try? FileManager.default.removeItem(at: testDataPath) }
        
        // Process the test data
        let entries = try readTestEntries(from: testDataPath)
        let stats = reader.calculateDailyStats(from: entries)
        
        // Verify session count matches expected
        XCTAssertEqual(stats.sessions, 4, "Should detect exactly 4 sessions based on 5-minute gaps")
    }
    
    /// Integration test with real Claude config directory
    func testRealClaudeConfigIntegration() throws {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("claude")
        
        // Check if Claude config exists
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw XCTSkip("Claude config directory not found")
        }
        
        // Test that we can read actual usage files
        let entries = reader.readTodayUsage()
        
        // If we have entries, verify they're valid
        if !entries.isEmpty {
            for entry in entries {
                // Verify timestamp is parseable
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                XCTAssertNotNil(formatter.date(from: entry.timestamp),
                               "Timestamp should be in valid format")
                
                // Verify model is recognized
                XCTAssertTrue(entry.model.contains("claude"),
                             "Model should be a Claude model")
                
                // Verify token counts are positive
                XCTAssertGreaterThanOrEqual(entry.inputTokens, 0)
                XCTAssertGreaterThanOrEqual(entry.outputTokens, 0)
                
                // Verify cost is reasonable
                XCTAssertGreaterThanOrEqual(entry.cost, 0)
                XCTAssertLessThan(entry.cost, 100, "Single request cost should be less than $100")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isCommandAvailable(_ command: String) -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = [command]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func runCCUsageCommand() throws -> String {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["ccusage", "daily", "--json"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "E2ETests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode ccusage output"])
        }
        
        return output
    }
    
    private func parseCCUsageOutput(_ output: String) throws -> [CCUsageDay] {
        guard let data = output.data(using: .utf8) else {
            throw NSError(domain: "E2ETests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert output to data"])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(CCUsageResult.self, from: data)
        return result.data
    }
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func createTestDataWithKnownSessions() -> URL {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let testFile = tempDir.appendingPathComponent("test_sessions_\(UUID().uuidString).jsonl")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var content = ""
        let baseTime = Date()
        
        // Session 1: 3 entries
        for i in 0..<3 {
            let time = baseTime.addingTimeInterval(Double(i * 120)) // 2 minutes apart
            content += createJSONLine(timestamp: formatter.string(from: time))
        }
        
        // Gap of 10 minutes
        
        // Session 2: 2 entries
        for i in 0..<2 {
            let time = baseTime.addingTimeInterval(900 + Double(i * 60)) // 15 minutes from start
            content += createJSONLine(timestamp: formatter.string(from: time))
        }
        
        // Gap of 20 minutes
        
        // Session 3: 4 entries
        for i in 0..<4 {
            let time = baseTime.addingTimeInterval(2100 + Double(i * 180)) // 35 minutes from start
            content += createJSONLine(timestamp: formatter.string(from: time))
        }
        
        // Gap of 15 minutes
        
        // Session 4: 1 entry
        let finalTime = baseTime.addingTimeInterval(3600) // 1 hour from start
        content += createJSONLine(timestamp: formatter.string(from: finalTime))
        
        try! content.write(to: testFile, atomically: true, encoding: .utf8)
        return testFile
    }
    
    private func createJSONLine(timestamp: String) -> String {
        return """
        {"timestamp":"\(timestamp)","model":"claude-3-opus-20240229","input_tokens":1000,"output_tokens":2000,"cache_creation_input_tokens":0,"cache_read_input_tokens":500,"cost":0.1}
        
        """
    }
    
    private func readTestEntries(from url: URL) throws -> [ClaudeUsageEntry] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        let decoder = JSONDecoder()
        return lines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(ClaudeUsageEntry.self, from: data)
        }
    }
}

// MARK: - CCUsage Output Models

struct CCUsageResult: Codable {
    let data: [CCUsageDay]
    let totals: CCUsageTotals
}

struct CCUsageDay: Codable {
    let date: String
    let inputTokens: Int
    let outputTokens: Int
    let cost: Double
    let modelBreakdowns: [ModelBreakdown]
    
    enum CodingKeys: String, CodingKey {
        case date
        case inputTokens = "input"
        case outputTokens = "output"
        case cost
        case modelBreakdowns
    }
}

struct CCUsageTotals: Codable {
    let input: Int
    let output: Int
    let cost: Double
}

struct ModelBreakdown: Codable {
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cost: Double
}