#!/usr/bin/env swift

import Foundation

// Create sample Claude usage data for testing
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

let fileManager = FileManager.default
let claudeConfigPath = fileManager.homeDirectoryForCurrentUser
    .appendingPathComponent(".config")
    .appendingPathComponent("claude")

// Create directory if needed
try? fileManager.createDirectory(at: claudeConfigPath, withIntermediateDirectories: true)

// Create today's usage file
let todayFormatter = DateFormatter()
todayFormatter.dateFormat = "yyyy-MM-dd"
let todayString = todayFormatter.string(from: Date())
let usageFilePath = claudeConfigPath.appendingPathComponent("usage_\(todayString).jsonl")

// Generate sample data
var sampleData = ""
let baseTime = Date().addingTimeInterval(-3600 * 3) // Start 3 hours ago

for i in 0..<20 {
    let timestamp = baseTime.addingTimeInterval(Double(i * 300)) // Every 5 minutes
    let entry = [
        "timestamp": dateFormatter.string(from: timestamp),
        "model": "claude-3-5-sonnet-20241022",
        "input_tokens": Int.random(in: 100...1000),
        "output_tokens": Int.random(in: 200...2000),
        "cache_creation_input_tokens": 0,
        "cache_read_input_tokens": Int.random(in: 0...500),
        "cost": Double.random(in: 0.01...0.10)
    ] as [String : Any]
    
    if let jsonData = try? JSONSerialization.data(withJSONObject: entry),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        sampleData += jsonString + "\n"
    }
}

// Write to file
try sampleData.write(to: usageFilePath, atomically: true, encoding: .utf8)
print("Sample data created at: \(usageFilePath.path)")
print("Run CCMate now to see the usage statistics!")