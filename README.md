# CCMate

Claude Code companion app - A macOS menubar app for tracking daily Claude Code usage statistics.

## Overview

CCMate is a lightweight macOS menubar application that helps you track and visualize your daily Claude Code usage. It provides real-time statistics and insights about your coding sessions, helping you understand your productivity patterns.

## Features

- **Real-time Usage Tracking**: Automatically reads Claude's JSONL log files from `~/.config/claude/`
- **Live Updates**: Monitors file changes and updates statistics in real-time
- **Session Detection**: Intelligently detects coding sessions (5+ minute gaps create new sessions)
- **Daily Statistics**: 
  - Total usage time
  - Number of sessions
  - Average session duration
  - Last active timestamp
- **Hourly Activity Chart**: Visual breakdown of usage throughout the day
- **Native macOS Design**: Clean interface following Apple's Human Interface Guidelines
- **Minimal Resource Usage**: Lightweight app that stays out of your way

## Requirements

- macOS 15.0 (Sequoia) or later
- Xcode 16.3 or later (for building from source)
- Claude Code installed (data is read from `~/.config/claude/usage_*.jsonl`)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/graycreate/CCMate.git
   ```

2. Open the project in Xcode:
   ```bash
   cd CCMate
   open CCMate.xcodeproj
   ```

3. Build and run the project (⌘+R)

## Usage

Once launched, CCMate will appear in your menubar with a bar chart icon. Click on it to view:

- **Today's Usage**: Total time spent using Claude Code today
- **Sessions**: Number of distinct coding sessions
- **Avg. Session**: Average duration of your sessions
- **Last Active**: When you last used Claude Code
- **Hourly Activity**: Bar chart showing usage distribution

The app automatically updates as you use Claude Code, with no manual tracking required. If you haven't used Claude today, it will show a helpful message.

## Development

This project uses:
- Swift 6.1
- SwiftUI
- macOS 15 SDK

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Created by Gray for the Claude Code community.