import Foundation

struct ClaudeUsageEntry: Codable {
    let timestamp: String
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int
    let cacheReadInputTokens: Int
    let cost: Double
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case model
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
        case cost
    }
}

class ClaudeDataReader {
    @MainActor
    static let shared = ClaudeDataReader()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private let fileManager = FileManager.default
    
    private var claudeConfigPath: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("claude")
    }
    
    func getTodayUsageFilePath() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        let filePath = claudeConfigPath.appendingPathComponent("usage_\(todayString).jsonl")
        print("Looking for Claude usage file at: \(filePath.path)")
        return filePath
    }
    
    func readTodayUsage() -> [ClaudeUsageEntry] {
        // First try today's file
        let todayFilePath = getTodayUsageFilePath()
        if fileManager.fileExists(atPath: todayFilePath.path) {
            return readUsageFile(at: todayFilePath)
        }
        
        // If today's file doesn't exist, try to find the most recent usage file
        // This handles timezone differences where the file might be from "yesterday" in local time
        if let mostRecentFile = findMostRecentUsageFile() {
            print("Today's file not found, using most recent: \(mostRecentFile.lastPathComponent)")
            return readUsageFile(at: mostRecentFile)
        }
        
        print("No Claude usage files found")
        return []
    }
    
    private func findMostRecentUsageFile() -> URL? {
        guard fileManager.fileExists(atPath: claudeConfigPath.path) else {
            return nil
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: claudeConfigPath, includingPropertiesForKeys: [.contentModificationDateKey])
            let usageFiles = files.filter { $0.lastPathComponent.hasPrefix("usage_") && $0.pathExtension == "jsonl" }
            
            // Sort by modification date, most recent first
            let sortedFiles = usageFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return date1 > date2
            }
            
            return sortedFiles.first
        } catch {
            print("Error finding usage files: \(error)")
            return nil
        }
    }
    
    private func readUsageFile(at filePath: URL) -> [ClaudeUsageEntry] {
        print("Reading Claude usage file: \(filePath.path)")
        
        do {
            let content = try String(contentsOf: filePath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
            
            let decoder = JSONDecoder()
            var entries: [ClaudeUsageEntry] = []
            var parseErrors = 0
            
            for (index, line) in lines.enumerated() {
                if let data = line.data(using: .utf8) {
                    do {
                        let entry = try decoder.decode(ClaudeUsageEntry.self, from: data)
                        entries.append(entry)
                    } catch {
                        parseErrors += 1
                        if parseErrors == 1 {
                            print("Warning: Failed to parse line \(index + 1) in Claude usage file: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            if parseErrors > 1 {
                print("Warning: Failed to parse \(parseErrors) lines in Claude usage file")
            }
            
            print("Successfully read \(entries.count) entries from \(filePath.lastPathComponent)")
            return entries
        } catch {
            print("Error reading Claude usage file at \(filePath.path): \(error.localizedDescription)")
            return []
        }
    }
    
    func calculateDailyStats(from entries: [ClaudeUsageEntry]) -> DailyStats {
        guard !entries.isEmpty else {
            return DailyStats()
        }
        
        // Group entries by hour for the chart
        var hourlyActivity = Array(repeating: 0, count: 24)
        var sessions: [(start: Date, end: Date)] = []
        var lastTimestamp: Date?
        var sessionStart: Date?
        let sessionGapThreshold: TimeInterval = 5 * 60 // 5 minutes gap = new session
        
        for entry in entries {
            guard let timestamp = dateFormatter.date(from: entry.timestamp) else { continue }
            
            // Update hourly activity (convert UTC to local time for display)
            let localTimestamp = timestamp // The timestamp is already converted to Date, which respects local timezone
            let hour = Calendar.current.component(.hour, from: localTimestamp)
            if hour >= 0 && hour < 24 {
                hourlyActivity[hour] += 1
            }
            
            // Session detection
            if let last = lastTimestamp {
                let gap = timestamp.timeIntervalSince(last)
                if gap > sessionGapThreshold {
                    // End previous session
                    if let start = sessionStart {
                        sessions.append((start: start, end: last))
                    }
                    sessionStart = timestamp
                }
            } else {
                sessionStart = timestamp
            }
            lastTimestamp = timestamp
        }
        
        // Close the last session
        if let start = sessionStart, let end = lastTimestamp {
            sessions.append((start: start, end: end))
        }
        
        // Calculate total usage time
        let totalUsageTime = sessions.reduce(0) { total, session in
            total + session.end.timeIntervalSince(session.start)
        }
        
        // Calculate average session length
        let avgSessionLength = sessions.isEmpty ? 0 : totalUsageTime / Double(sessions.count)
        
        // Get last active time
        let lastActive = lastTimestamp ?? Date()
        
        return DailyStats(
            totalUsageTime: totalUsageTime,
            sessions: sessions.count,
            averageSessionLength: avgSessionLength,
            lastActive: lastActive,
            hourlyActivity: hourlyActivity
        )
    }
    
    func getHistoricalUsageFiles(days: Int = 30) -> [URL] {
        guard fileManager.fileExists(atPath: claudeConfigPath.path) else {
            return []
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: claudeConfigPath,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            return files.filter { url in
                url.lastPathComponent.hasPrefix("usage_") && 
                url.pathExtension == "jsonl"
            }.sorted { $0.lastPathComponent > $1.lastPathComponent }
            .prefix(days)
            .reversed()
            .map { $0 }
        } catch {
            print("Error reading Claude config directory: \(error)")
            return []
        }
    }
}