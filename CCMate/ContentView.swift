import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            
            StatsView()
                .padding()
            
            HourlyChartView()
                .padding(.horizontal)
                .padding(.bottom)
            
            Divider()
            
            FooterView()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CCMate")
                    .font(.headline)
                Text("Claude Code Usage Tracker")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: appState.isTracking ? "record.circle.fill" : "record.circle")
                .foregroundColor(appState.isTracking ? .green : .gray)
                .font(.title2)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatCard(
                    title: "Today's Usage",
                    value: appState.dailyStats.formattedTime,
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Sessions",
                    value: "\(appState.dailyStats.sessionsCount)",
                    icon: "square.stack.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Avg. Session",
                    value: appState.dailyStats.averageSessionLength,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                StatCard(
                    title: "Last Active",
                    value: formatTime(appState.dailyStats.lastUpdated),
                    icon: "clock.arrow.circlepath",
                    color: .purple
                )
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct HourlyChartView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly Activity")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<24, id: \.self) { hour in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 8, height: barHeight(for: hour))
                        
                        if hour % 6 == 0 {
                            Text("\(hour)")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        } else {
                            Text("")
                                .font(.system(size: 8))
                        }
                    }
                }
            }
            .frame(height: 60)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    func barHeight(for hour: Int) -> CGFloat {
        let maxActivity = appState.dailyStats.hourlyActivity.max() ?? 1
        let activity = appState.dailyStats.hourlyActivity[hour]
        guard maxActivity > 0 else { return 0 }
        return CGFloat(activity) / CGFloat(maxActivity) * 40
    }
}

struct FooterView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            Button("Preferences") {
                
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 280, height: 320)
}