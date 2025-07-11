import SwiftUI

@main
struct CCMateApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .frame(width: 280, height: 320)
                .environmentObject(appState)
        } label: {
            Label("CCMate", systemImage: "chart.bar.fill")
                .labelStyle(.iconOnly)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var dailyStats = DailyStats()
    @Published var isTracking = false
    
    private let fileWatcher = ClaudeFileWatcher()
    private let dataReader = ClaudeDataReader.shared
    private var refreshTimer: Timer?
    
    init() {
        startTracking()
    }
    
    func startTracking() {
        isTracking = true
        
        // Set up file watcher
        fileWatcher.onDataChanged = { [weak self] stats in
            self?.dailyStats = stats
        }
        fileWatcher.startWatching()
        
        // Also refresh periodically (every 30 seconds) to update relative times
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.loadCurrentStats()
            }
        }
        
        // Initial load
        loadCurrentStats()
    }
    
    func stopTracking() {
        isTracking = false
        fileWatcher.stopWatching()
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func loadCurrentStats() {
        let entries = dataReader.readTodayUsage()
        dailyStats = dataReader.calculateDailyStats(from: entries)
    }
}

struct DailyStats {
    var totalUsageTime: TimeInterval = 0
    var sessions: Int = 0
    var averageSessionLength: TimeInterval = 0
    var lastActive: Date = Date()
    var hourlyActivity: [Int] = Array(repeating: 0, count: 24)
    
    var totalMinutes: Int {
        Int(totalUsageTime / 60)
    }
    
    var sessionsCount: Int {
        sessions
    }
    
    var lastUpdated: Date {
        lastActive
    }
    
    var formattedTime: String {
        let hours = Int(totalUsageTime) / 3600
        let minutes = (Int(totalUsageTime) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
    
    var averageSessionLengthFormatted: String {
        guard sessions > 0 else { return "0m" }
        let avgMinutes = Int(averageSessionLength / 60)
        if avgMinutes >= 60 {
            let hours = avgMinutes / 60
            let mins = avgMinutes % 60
            return String(format: "%dh %dm", hours, mins)
        }
        return "\(avgMinutes)m"
    }
}