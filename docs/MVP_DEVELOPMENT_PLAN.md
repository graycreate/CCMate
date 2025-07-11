# CCMate MVP Development Plan

## MVP Goals

Build a lightweight macOS menubar application for real-time Claude Code usage monitoring with two core features:
1. **Daily Tab**: Display real-time usage details for the current day
2. **Analytics Tab**: Show usage statistics and trends

## Technical Architecture

### Core Components
- **Data Layer**: ClaudeDataReader - Read and parse JSONL files
- **Monitoring Layer**: FileMonitor - Monitor file changes for real-time updates
- **UI Layer**: Two tabs implemented with SwiftUI
- **Menubar**: Display current usage percentage

### Data Flow
```
Claude JSONL Files → FileMonitor → ClaudeDataReader → DataModel → UI Updates
```

## Development Phases

### Phase 1: Data Infrastructure (2 days)

#### 1.1 Implement ClaudeDataReader
```swift
class ClaudeDataReader {
    // Find Claude configuration directory
    func findClaudeConfigDirectory() -> URL?
    
    // Scan all JSONL files
    func scanJSONLFiles(in directory: URL) -> [URL]
    
    // Parse single JSONL file
    func parseJSONLFile(at url: URL) -> [UsageEntry]
    
    // Aggregate today's data
    func getTodayUsage() -> DailyUsage
    
    // Get historical data
    func getHistoricalUsage(days: Int) -> [DailyUsage]
}
```

#### 1.2 Define Data Models
```swift
struct UsageEntry {
    let timestamp: Date
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    let cost: Double
    let model: String
    let messageId: String
}

struct DailyUsage {
    let date: Date
    let totalTokens: Int
    let totalCost: Double
    let sessions: [SessionBlock]
    let hourlyDistribution: [Int] // 24-hour distribution
}

struct SessionBlock {
    let startTime: Date
    let endTime: Date
    let tokensUsed: Int
    let cost: Double
    let isActive: Bool
}
```

### Phase 2: UI Implementation (3 days)

#### 2.1 Daily Tab
Display content:
- Today's usage overview cards
  - Total token usage and percentage
  - Total cost
  - Active sessions count
  - Last update time
- Session timeline
  - 5-hour session block visualization
  - Current active session highlighting
- Hourly distribution chart
  - 24-hour usage distribution bar chart

#### 2.2 Analytics Tab
Display content:
- 7-day usage trend chart
  - Token usage line chart
  - Cost trends
- Usage statistics
  - Average daily usage
  - Peak usage hours
  - Usage rate (tokens/hour)
- Model usage distribution
  - Usage percentage by different models

#### 2.3 TabView Implementation
```swift
struct ContentView: View {
    @StateObject private var dataManager = ClaudeDataManager()
    
    var body: some View {
        TabView {
            DailyView()
                .tabItem {
                    Label("Daily", systemImage: "calendar")
                }
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .environmentObject(dataManager)
    }
}
```

### Phase 3: Real-time Monitoring (2 days)

#### 3.1 File Monitor
```swift
class FileMonitor {
    private var fileWatcher: DispatchSourceFileSystemObject?
    
    func startMonitoring(directory: URL, onChange: @escaping () -> Void)
    func stopMonitoring()
}
```

#### 3.2 Menubar Updates
- Update every 30 seconds
- Display usage percentage
- Color coding: Green (<70%), Yellow (70-90%), Red (>90%)

### Phase 4: Refinement and Optimization (1 day)

#### 4.1 Performance Optimization
- Implement incremental data reading
- Add data caching
- Optimize large file parsing

#### 4.2 User Experience
- Add loading states
- Error handling and prompts
- Data refresh animations

## UI Design Guidelines

### Following Apple Human Interface Guidelines

#### Design Principles
- **Clarity**: Use SF Pro font with appropriate sizes and contrast
- **Consistency**: Use system standard controls and colors
- **Intuitiveness**: Clear information hierarchy with prominent key info
- **Native Feel**: Use standard macOS spacing and layout

#### Visual Style
- **Background**: Use `NSColor.windowBackgroundColor`
- **Cards**: Use `NSVisualEffectView` for frosted glass effect
- **Accent Color**: Use system accent color
- **Charts**: Use Swift Charts framework

### Daily Tab Design

#### Layout Structure
```swift
VStack(spacing: 16) {
    // Top title area
    HStack {
        Text("Today's Usage")
            .font(.largeTitle)
        Spacer()
        Text(Date(), style: .date)
            .foregroundColor(.secondary)
    }
    
    // Statistics card group
    HStack(spacing: 12) {
        StatCard(title: "Tokens", 
                value: "2.5M", 
                subtitle: "of 5M",
                progress: 0.5,
                systemImage: "doc.text")
        
        StatCard(title: "Cost", 
                value: "$15.00",
                systemImage: "dollarsign.circle")
        
        StatCard(title: "Sessions", 
                value: "3",
                systemImage: "clock")
    }
    
    // Session timeline
    GroupBox("Session Timeline") {
        SessionTimelineView()
    }
    
    // Hourly distribution chart
    GroupBox("Hourly Distribution") {
        Chart(hourlyData) { item in
            BarMark(
                x: .value("Hour", item.hour),
                y: .value("Tokens", item.tokens)
            )
        }
        .frame(height: 120)
    }
}
.padding()
```

#### Component Design
- **StatCard**: Use `GroupBox` style with SF Symbol icons
- **Progress Indicators**: Use `ProgressView` or `Gauge` (macOS 13+)
- **Charts**: Use Swift Charts' `BarMark` and `LineMark`

### Analytics Tab Design

#### Layout Structure
```swift
VStack(spacing: 16) {
    // Trend chart
    GroupBox("7-Day Usage Trend") {
        Chart(weeklyData) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Tokens", item.tokens)
            )
            .foregroundStyle(.blue)
            
            AreaMark(
                x: .value("Date", item.date),
                y: .value("Tokens", item.tokens)
            )
            .foregroundStyle(.blue.opacity(0.1))
        }
        .frame(height: 200)
    }
    
    // Statistics info
    GroupBox("Statistics") {
        VStack(alignment: .leading, spacing: 8) {
            Label("Average Daily: 3.2M tokens", 
                  systemImage: "chart.bar")
            Label("Peak Hour: 14:00-15:00", 
                  systemImage: "clock.arrow.circlepath")
            Label("Burn Rate: 125k tokens/hour", 
                  systemImage: "flame")
        }
        .font(.system(.body, design: .rounded))
    }
    
    // Model usage distribution
    GroupBox("Model Usage") {
        VStack(spacing: 8) {
            ModelUsageRow(model: "Claude 3 Sonnet", 
                         percentage: 0.75)
            ModelUsageRow(model: "Claude 3 Opus", 
                         percentage: 0.25)
        }
    }
}
.padding()
```

### Color Scheme

#### Adaptive Colors (Dark Mode Support)
```swift
extension Color {
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let primaryText = Color(NSColor.labelColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    static let successGreen = Color(NSColor.systemGreen)
    static let warningYellow = Color(NSColor.systemYellow)
    static let dangerRed = Color(NSColor.systemRed)
}
```

#### Usage Status Colors
- **Normal (<70%)**: `systemGreen`
- **Warning (70-90%)**: `systemYellow`
- **Danger (>90%)**: `systemRed`

### Animations and Transitions

- **Data Updates**: Use `withAnimation(.easeInOut(duration: 0.3))`
- **Chart Animations**: Default Chart animations
- **Progress Changes**: Smooth transitions to avoid jumping

### Responsive Design

- **Minimum Window Size**: 600x500
- **Content Adaptation**: Use `GeometryReader` to respond to window changes
- **Compact Mode**: Hide secondary info when window is small

## Implementation Priority

### Must Have (MVP)
1. ✅ Read Claude JSONL files
2. ✅ Parse usage data
3. ✅ Daily tab basic functionality
4. ✅ Analytics tab basic functionality
5. ✅ Menubar percentage display
6. ✅ 30-second auto refresh

### Optional Features (Future Versions)
- Custom token limits
- Usage warning notifications
- Data export functionality
- Dark mode toggle
- Preferences panel

## Development Timeline

| Phase | Task | Estimated Time | Completion Criteria |
|-------|------|----------------|---------------------|
| 1 | Data Infrastructure | 2 days | Correctly read and parse Claude data |
| 2 | UI Implementation | 3 days | Both tabs fully functional |
| 3 | Real-time Monitoring | 2 days | Auto data updates, menubar display working |
| 4 | Refinement & Optimization | 1 day | Good performance, smooth UX |

**Total: 8 days to complete MVP**

## Success Criteria

1. **Feature Complete**: Accurately displays Claude usage data
2. **Real-time Updates**: Reflects latest usage within 30 seconds
3. **Good Performance**: Memory usage <50MB, CPU usage <5%
4. **User Friendly**: Clear interface, information at a glance

## Next Steps

1. Start implementing ClaudeDataReader class
2. Create data model structures
3. Design UI components
4. Integrate file monitoring
5. Test and optimize