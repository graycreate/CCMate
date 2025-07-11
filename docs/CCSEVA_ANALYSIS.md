# CCSeva Project Analysis Documentation

## Overview

CCSeva is a sophisticated macOS menu bar application built with Electron and React that monitors Claude Code usage in real-time. It provides comprehensive usage analytics, cost tracking, and smart notifications to help users manage their Claude Code token consumption effectively.

## Architecture Overview

### Technology Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| Desktop Framework | Electron | 36.x | Cross-platform desktop app |
| Frontend | React | 19.x | UI framework |
| Language | TypeScript | 5.x | Type-safe development |
| Styling | Tailwind CSS | 3.x | Utility-first CSS |
| UI Components | Radix UI | Latest | Accessible component library |
| Data Source | ccusage | 15.2.0 | Claude Code usage data provider |
| Build Tool | Webpack | 5.x | Module bundling |

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Menu Bar (Tray)                      │
│                    Shows: XX% | $X.XX                       │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    Main Process (main.ts)                   │
├─────────────────────────────────────────────────────────────┤
│  • CCSevaApp (Application Lifecycle)                        │
│  • Services Layer:                                          │
│    - CCUsageService (30s polling, data processing)         │
│    - NotificationService (70%/90% alerts)                  │
│    - SettingsService (preferences management)              │
│    - ResetTimeService (token reset calculations)           │
│    - SessionTracker (5-hour session windows)               │
│  • IPC Handlers (main/renderer communication)              │
└─────────────────────────────────────────────────────────────┘
                               │
                         IPC Channel
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Renderer Process (React App)                │
├─────────────────────────────────────────────────────────────┤
│  • Dashboard (real-time usage display)                     │
│  • Analytics (7-day charts, trends)                        │
│  • Terminal View (raw data display)                        │
│  • Settings Panel (configuration)                          │
└─────────────────────────────────────────────────────────────┘
```

## Core Features

### 1. Real-time Usage Monitoring

- **Update Frequency**: Every 30 seconds
- **Data Points**: Token usage, cost, session information
- **Display Options**: Percentage, cost, or alternating display
- **Visual Indicators**: Color-coded status (green/yellow/red)

### 2. Plan Detection & Management

CCSeva automatically detects the user's Claude plan:

| Plan | Daily Token Limit | Detection Method |
|------|------------------|------------------|
| Pro | 5,000,000 | Usage pattern analysis |
| Max5 | 50,000,000 | Usage pattern analysis |
| Max20 | 200,000,000 | Usage pattern analysis |
| Custom | User-defined | Manual configuration |
| Auto | Dynamic | Automatic detection |

### 3. Session Tracking

- **Session Duration**: 5-hour rolling windows
- **Gap Detection**: Identifies breaks between sessions
- **Active Session**: Highlights current usage period
- **Session Blocks**: Visual representation of usage patterns

### 4. Analytics & Predictions

#### Burn Rate Analysis
- Tokens per hour calculation
- 24-hour and 7-day averages
- Trend detection (increasing/decreasing/stable)
- Velocity classification (slow/moderate/fast/extreme)

#### Predictive Features
- Depletion time estimation
- Recommended daily limits
- On-track status for token reset
- Usage trajectory analysis

### 5. Notification System

Smart notifications at key thresholds:
- **70% Usage**: Warning notification
- **90% Usage**: Critical notification
- **Customizable**: Enable/disable per threshold
- **Native Integration**: macOS notification center

## Data Models

### Core Data Structures

```typescript
interface UsageStats {
  timestamp: number;
  dailyUsage: Record<string, DailyUsage>;
  totalTokensUsed: number;
  totalCost: number;
  tokenLimit: number;
  plan: Plan;
  resetDate: Date;
  sessionBlocks: SessionBlock[];
}

interface DailyUsage {
  date: string;
  tokensUsed: number;
  cost: number;
  sessions: number;
}

interface SessionBlock {
  startTime: Date;
  endTime: Date;
  tokensUsed: number;
  cost: number;
  isActive: boolean;
}

interface VelocityInfo {
  tokensPerHour: number;
  burnRate24h: number;
  burnRate7d: number;
  trend: 'increasing' | 'decreasing' | 'stable';
  velocity: 'slow' | 'moderate' | 'fast' | 'extreme';
}
```

## Key Implementation Details

### 1. Data Collection

The application uses the `ccusage` npm package which:
- Reads Claude's local usage data files
- Parses session and token information
- Calculates costs based on model pricing
- Provides both real-time and historical data

### 2. Caching Strategy

- **Cache Duration**: 3 seconds
- **Purpose**: Prevents excessive file reads
- **Implementation**: In-memory cache with timestamp validation

### 3. Menu Bar Integration

```typescript
// Menu bar update logic
private updateMenuBar(data: MenuBarData) {
  const { percentage, cost, status } = data;
  
  // Color based on usage
  const color = status === 'critical' ? 'red' : 
                status === 'warning' ? 'yellow' : 'green';
  
  // Display format based on settings
  const display = settings.displayMode === 'percentage' ? `${percentage}%` :
                  settings.displayMode === 'cost' ? `$${cost}` :
                  this.alternateDisplay ? `${percentage}%` : `$${cost}`;
  
  this.tray.setTitle(display);
}
```

### 4. Settings Management

Configuration options stored in Electron's app data:
- Timezone selection
- Reset hour customization
- Plan selection
- Custom token limits
- Display preferences
- Notification settings

## UI/UX Design Patterns

### 1. Visual Design
- **Glass Morphism**: Semi-transparent backgrounds with blur
- **Gradient Accents**: Subtle color gradients for visual interest
- **Dark Theme**: Optimized for reduced eye strain
- **Compact Layout**: 600x600 window optimized for menu bar apps

### 2. Navigation
- **Tab-based**: Clear separation of features
- **Keyboard Shortcuts**: 
  - ⌘R: Refresh data
  - ⌘Q: Quit application
  - ⌘,: Open settings
- **Responsive Updates**: Real-time data refresh without UI flicker

### 3. Data Visualization
- **Line Charts**: 7-day usage trends
- **Bar Charts**: Daily token consumption
- **Progress Bars**: Current usage percentage
- **Session Blocks**: Visual timeline of usage periods

## Build & Distribution

### Build Configuration

```javascript
// electron-builder.yml key settings
productName: "CCSeva"
appId: "com.ccseva.app"
mac:
  category: "public.app-category.developer-tools"
  LSUIElement: true  // Menu bar app
  target:
    - target: dmg
      arch: [x64, arm64]  // Intel & Apple Silicon
```

### Distribution
- **Format**: DMG installer
- **Architecture**: Universal binary (Intel + Apple Silicon)
- **Code Signing**: Configured for notarization
- **Auto-update**: Not implemented in current version

## Critical Dependencies

### ccusage Package

The most critical dependency providing:
- Local Claude usage data access
- Session parsing and analysis
- Cost calculations
- Model-specific pricing information

### Integration Pattern

```typescript
import { getUsageStats } from 'ccusage';

// Fetch usage data
const stats = await getUsageStats({
  timezone: settings.timezone,
  customLimit: settings.customTokenLimit
});

// Process and display
this.processUsageData(stats);
```

## Performance Considerations

1. **Polling Interval**: 30 seconds balances freshness vs. resource usage
2. **Caching**: 3-second cache prevents excessive file I/O
3. **Memory Usage**: Typically under 50MB
4. **CPU Usage**: Minimal, spikes only during data refresh
5. **Background Operation**: Runs efficiently as menu bar app

## Security & Privacy

- **Local Data Only**: No external API calls
- **No Telemetry**: No usage data collection
- **Sandboxed**: Electron security best practices
- **File Access**: Read-only access to Claude's data files

## Lessons for CCMate Implementation

### Key Takeaways

1. **Data Source**: Need Swift equivalent of ccusage functionality
2. **Update Frequency**: 30-second polling is optimal
3. **Session Tracking**: 5-hour windows match Claude's model
4. **Plan Detection**: Pattern-based detection is effective
5. **Caching**: Essential for performance
6. **Menu Bar**: Text-only display is clean and efficient
7. **Analytics**: 7-day window provides useful insights
8. **Notifications**: 70%/90% thresholds are well-balanced

### Architecture Recommendations

For a native Swift implementation:
1. Use `NSWorkspace` for process monitoring
2. Implement `FileWatcher` for Claude data files
3. Use `UserDefaults` for settings persistence
4. Leverage `Charts` framework for visualizations
5. Use `UserNotifications` for alerts
6. Implement `Timer` for periodic updates

This analysis provides a comprehensive understanding of CCSeva's implementation, which can guide the development of CCMate as a native Swift alternative.