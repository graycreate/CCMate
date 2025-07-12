import XCTest
@testable import CCMate

final class FileMonitorTests: XCTestCase {
    var fileMonitor: FileMonitor!
    var testFilePath: String!
    var expectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        fileMonitor = FileMonitor()
        
        // Create a temporary test file
        let tempDir = NSTemporaryDirectory()
        testFilePath = (tempDir as NSString).appendingPathComponent("test_file_\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: testFilePath, contents: "Initial content".data(using: .utf8))
    }
    
    override func tearDown() {
        fileMonitor.stopMonitoring()
        fileMonitor = nil
        
        // Clean up test file
        try? FileManager.default.removeItem(atPath: testFilePath)
        testFilePath = nil
        
        super.tearDown()
    }
    
    func testFileChangeDetection() throws {
        // Given
        expectation = XCTestExpectation(description: "File change detected")
        var changeDetected = false
        
        fileMonitor.onFileChanged = { [weak self] in
            changeDetected = true
            self?.expectation?.fulfill()
        }
        
        // When
        fileMonitor.startMonitoring(path: testFilePath)
        
        // Modify the file after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? "Modified content".write(toFile: self.testFilePath, atomically: true, encoding: .utf8)
        }
        
        // Then
        wait(for: [expectation!], timeout: 2.0)
        XCTAssertTrue(changeDetected, "File change should have been detected")
    }
    
    func testStopMonitoring() throws {
        // Given
        expectation = XCTestExpectation(description: "No file change detected after stop")
        expectation?.isInverted = true
        
        fileMonitor.onFileChanged = { [weak self] in
            self?.expectation?.fulfill()
        }
        
        // When
        fileMonitor.startMonitoring(path: testFilePath)
        fileMonitor.stopMonitoring()
        
        // Modify the file after stopping
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? "Modified after stop".write(toFile: self.testFilePath, atomically: true, encoding: .utf8)
        }
        
        // Then
        wait(for: [expectation!], timeout: 1.0)
        // Test passes if no change was detected (inverted expectation)
    }
    
    func testMonitoringNonExistentFile() {
        // Given
        let nonExistentPath = "/tmp/non_existent_file_\(UUID().uuidString).txt"
        
        // When
        fileMonitor.startMonitoring(path: nonExistentPath)
        
        // Then
        // Should not crash, just fail silently
        XCTAssertTrue(true, "Monitoring non-existent file should not crash")
    }
    
    func testMultipleFileChanges() throws {
        // Given
        expectation = XCTestExpectation(description: "Multiple file changes detected")
        expectation?.expectedFulfillmentCount = 3
        var changeCount = 0
        
        fileMonitor.onFileChanged = { [weak self] in
            changeCount += 1
            self?.expectation?.fulfill()
        }
        
        // When
        fileMonitor.startMonitoring(path: testFilePath)
        
        // Make multiple changes
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                try? "Change \(i)".write(toFile: self.testFilePath, atomically: true, encoding: .utf8)
            }
        }
        
        // Then
        wait(for: [expectation!], timeout: 3.0)
        XCTAssertEqual(changeCount, 3, "Should detect all file changes")
    }
}

// MARK: - ClaudeFileWatcher Tests

final class ClaudeFileWatcherTests: XCTestCase {
    var fileWatcher: ClaudeFileWatcher!
    var testConfigDir: URL!
    var expectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        fileWatcher = ClaudeFileWatcher()
        
        // Create temporary Claude config directory
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        testConfigDir = tempDir.appendingPathComponent(".config").appendingPathComponent("claude")
        try? FileManager.default.createDirectory(at: testConfigDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        fileWatcher.stopWatching()
        fileWatcher = nil
        
        // Clean up test directory
        try? FileManager.default.removeItem(at: testConfigDir)
        testConfigDir = nil
        
        super.tearDown()
    }
    
    func testDataChangeCallback() throws {
        // Given
        expectation = XCTestExpectation(description: "Data change callback triggered")
        var receivedStats: DailyStats?
        
        fileWatcher.onDataChanged = { stats in
            receivedStats = stats
            self.expectation?.fulfill()
        }
        
        // Create a test usage file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "usage_\(dateFormatter.string(from: Date())).jsonl"
        let testFile = testConfigDir.appendingPathComponent(fileName)
        
        let testData = """
        {"timestamp":"2025-07-12T10:00:00.000+0000","model":"claude-3-opus-20240229","input_tokens":100,"output_tokens":200,"cache_creation_input_tokens":0,"cache_read_input_tokens":50,"cost":0.01}
        """
        try testData.write(to: testFile, atomically: true, encoding: .utf8)
        
        // When
        fileWatcher.startWatching()
        
        // Then
        wait(for: [expectation!], timeout: 2.0)
        XCTAssertNotNil(receivedStats, "Should receive stats update")
    }
}