# CCMate Project Plan

## Project Overview

CCMate is a macOS menubar application designed to track and visualize Claude Code usage statistics in real-time. Built with Swift 6.1 and SwiftUI, it provides developers with insights into their coding patterns and productivity when using Claude Code.

## Technology Stack

- **Language**: Swift 6.1
- **UI Framework**: SwiftUI
- **Platform**: macOS 15.0+ (Sequoia)
- **Development Tools**: Xcode 16.3+
- **Architecture**: MVVM with ObservableObject pattern

## Current Implementation (MVP)

### Features Implemented

1. **MenuBar Integration**
   - Uses SwiftUI's `MenuBarExtra` for native menubar presence
   - Custom icon with system image "chart.bar.fill"
   - Window-style popup for better UI flexibility

2. **Real-time Statistics Display**
   - Total daily usage time (hours and minutes)
   - Number of coding sessions
   - Average session length
   - Last active timestamp
   - Hourly activity chart visualization

3. **Automatic Tracking**
   - Timer-based tracking system (updates every minute)
   - Automatic session detection
   - Background tracking capability

4. **User Interface**
   - Clean, native macOS design
   - Dark mode support
   - Responsive layout with stat cards
   - Interactive hourly activity chart
   - Quick access to quit functionality

## Project Structure

```
CCMate/
├── CCMate.xcodeproj/          # Xcode project files
├── CCMate/                    # Main app source
│   ├── CCMateApp.swift        # App entry point and state management
│   ├── ContentView.swift      # Main UI implementation
│   ├── Assets.xcassets/       # App icons and colors
│   └── CCMate.entitlements    # App sandbox settings
├── LICENSE                    # MIT License
├── README.md                  # Project documentation
└── PROJECT_PLAN.md           # This file
```

## Next Steps & Roadmap

### Phase 1: Enhanced Tracking (Next)
- [ ] Detect actual Claude Code process/window activity
- [ ] Implement idle time detection
- [ ] Add session start/stop logic based on Claude Code activity
- [ ] Store statistics persistently using UserDefaults or Core Data

### Phase 2: Advanced Statistics
- [ ] Weekly and monthly views
- [ ] Productivity metrics (lines of code, files edited)
- [ ] Project-based tracking
- [ ] Export functionality (CSV, JSON)

### Phase 3: User Experience
- [ ] Preferences window
- [ ] Customizable tracking settings
- [ ] Notification system for milestones
- [ ] Launch at login option
- [ ] Custom app icon design

### Phase 4: Integration Features
- [ ] Claude Code API integration (if available)
- [ ] Git commit correlation
- [ ] Calendar integration
- [ ] Productivity insights and recommendations

### Phase 5: Distribution
- [ ] Code signing and notarization
- [ ] App Store submission preparation
- [ ] Auto-update functionality
- [ ] User documentation and website

## Technical Considerations

### Current Architecture
- **MVVM Pattern**: Clear separation between view and business logic
- **ObservableObject**: Reactive UI updates with Combine framework
- **Timer-based Updates**: Simple polling mechanism for MVP

### Future Improvements
- **Process Monitoring**: Use `NSWorkspace` notifications to detect Claude Code activity
- **Data Persistence**: Implement Core Data for historical data storage
- **Performance**: Optimize timer usage and consider event-driven updates
- **Testing**: Add unit and UI tests for reliability

## Development Guidelines

1. **Code Style**: Follow Swift API Design Guidelines
2. **Compatibility**: Maintain macOS 15.0+ compatibility
3. **Performance**: Keep menubar app lightweight (<10MB memory usage)
4. **Privacy**: No data collection or network requests without user consent
5. **Accessibility**: Support VoiceOver and other accessibility features

## Current Status

✅ **Completed**:
- Basic menubar app structure
- Real-time usage tracking simulation
- Clean, native UI design
- GitHub repository setup
- MVP functionality

🚧 **In Progress**:
- Actual Claude Code process detection
- Data persistence

📋 **Planned**:
- All features listed in roadmap phases

## Contributing

The project is open source under MIT license. Contributions are welcome following these guidelines:
1. Fork the repository
2. Create a feature branch
3. Follow existing code style
4. Add tests for new features
5. Submit a pull request with clear description

## Contact

Created by Gray for the Claude Code community. For questions or suggestions, please open an issue on GitHub.