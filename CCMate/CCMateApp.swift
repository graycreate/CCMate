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

class AppState: ObservableObject {
    @Published var dailyStats = DailyStats()
    @Published var isTracking = false
    
    private var timer: Timer?
    
    init() {
        startTracking()
    }
    
    func startTracking() {
        isTracking = true
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateStats()
        }
        updateStats()
    }
    
    func stopTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil
    }
    
    private func updateStats() {
        dailyStats.totalMinutes += 1
        dailyStats.lastUpdated = Date()
        
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 0 && hour < 24 {
            dailyStats.hourlyActivity[hour] += 1
        }
    }
}

struct DailyStats {
    var totalMinutes: Int = 0
    var sessionsCount: Int = 1
    var lastUpdated: Date = Date()
    var hourlyActivity: [Int] = Array(repeating: 0, count: 24)
    
    var formattedTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%dh %dm", hours, minutes)
    }
    
    var averageSessionLength: String {
        guard sessionsCount > 0 else { return "0m" }
        let average = totalMinutes / sessionsCount
        return "\(average)m"
    }
}