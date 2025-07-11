# Claude Usage Data Source Guide

## Overview

CCSeva retrieves Claude Code usage data through the `ccusage` npm package. This data comes from JSONL format files stored locally by the Claude application.

## Data Storage Locations

Claude stores usage data in the following locations (in order of priority):

1. **Environment variable path**: `$CLAUDE_CONFIG_DIR` (supports comma-separated multiple paths)
2. **XDG config directory**: `$XDG_CONFIG_HOME/claude` or `~/.config/claude`
3. **Legacy path**: `~/.claude`

Actual data files are located at:
```
<claude_config_dir>/projects/**/*.jsonl
```

## Data File Format

Claude uses **JSONL (JSON Lines)** format to store data, where each line is an independent JSON object:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0",
  "message": {
    "usage": {
      "input_tokens": 1000,          // Input token count
      "output_tokens": 500,          // Output token count
      "cache_creation_input_tokens": 25,  // Cache creation tokens
      "cache_read_input_tokens": 10      // Cache read tokens
    },
    "model": "claude-sonnet-4-20250514",  // Model used
    "id": "msg_unique_id",               // Message unique identifier
    "content": [{ "text": "..." }]       // Message content
  },
  "costUSD": 0.01,                      // Pre-calculated cost (USD)
  "requestId": "req_unique_id",         // Request unique identifier
  "isApiErrorMessage": false            // Whether it's an error message
}
```

## Data Acquisition Process

### 1. File Discovery
```typescript
// ccusage scans all .jsonl files in the project directory
const files = glob.sync('**/*.jsonl', {
  cwd: projectDir,
  absolute: true
});
```

### 2. Data Parsing
```typescript
// Read JSONL file line by line
const lines = fs.readFileSync(file, 'utf-8').split('\n');
for (const line of lines) {
  if (line.trim()) {
    const data = JSON.parse(line);
    // Validate and process data...
  }
}
```

### 3. Data Deduplication
- Uses `message.id + requestId` combination as unique identifier
- Prevents duplicate counting of the same usage records

### 4. Cost Calculation

Cost calculation has three modes:

1. **auto** (default): Prioritizes pre-calculated `costUSD`, calculates from tokens if not available
2. **calculate**: Always calculates based on token count and model pricing
3. **display**: Only shows pre-calculated costs

Calculation formula:
```
Cost = (input tokens × input price) + (output tokens × output price) + cache costs
```

### 5. Sessions and Blocks

- **Session blocks**: 5-hour billing cycles (Claude's billing model)
- **Session identification**: Detects session boundaries through time intervals
- **Active sessions**: Currently ongoing sessions are specially marked

## Swift Implementation Key Points

To implement similar functionality in Swift:

### 1. Find Claude Configuration Directory
```swift
func findClaudeConfigDir() -> URL? {
    // Check environment variable
    if let envPath = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"] {
        return URL(fileURLWithPath: envPath)
    }
    
    // Check XDG config
    if let xdgConfig = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
        return URL(fileURLWithPath: xdgConfig).appendingPathComponent("claude")
    }
    
    // Check default locations
    let homeDir = FileManager.default.homeDirectoryForCurrentUser
    let configDir = homeDir.appendingPathComponent(".config/claude")
    let legacyDir = homeDir.appendingPathComponent(".claude")
    
    if FileManager.default.fileExists(atPath: configDir.path) {
        return configDir
    } else if FileManager.default.fileExists(atPath: legacyDir.path) {
        return legacyDir
    }
    
    return nil
}
```

### 2. Read JSONL Files
```swift
func readJSONLFile(at url: URL) -> [UsageEntry] {
    guard let content = try? String(contentsOf: url) else { return [] }
    
    return content.split(separator: "\n")
        .compactMap { line -> UsageEntry? in
            guard let data = line.data(using: .utf8),
                  let json = try? JSONDecoder().decode(UsageData.self, from: data) else {
                return nil
            }
            return UsageEntry(from: json)
        }
}
```

### 3. Monitor File Changes
```swift
class ClaudeDataMonitor {
    private var fileWatcher: DispatchSourceFileSystemObject?
    
    func startMonitoring(directory: URL) {
        let fd = open(directory.path, O_EVTONLY)
        guard fd != -1 else { return }
        
        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: .main
        )
        
        fileWatcher?.setEventHandler { [weak self] in
            self?.handleFileChange()
        }
        
        fileWatcher?.resume()
    }
}
```

### 4. Data Models
```swift
struct UsageData: Codable {
    let timestamp: Date
    let version: String
    let message: Message
    let costUSD: Double?
    let requestId: String
    let isApiErrorMessage: Bool
    
    struct Message: Codable {
        let usage: Usage
        let model: String
        let id: String
        let content: [Content]
    }
    
    struct Usage: Codable {
        let inputTokens: Int
        let outputTokens: Int
        let cacheCreationInputTokens: Int?
        let cacheReadInputTokens: Int?
    }
}
```

## Key Findings

1. **Local data**: All data is stored locally, no network requests needed
2. **Real-time updates**: Claude writes new JSONL lines immediately after each use
3. **Complete history**: Contains all historical usage records for detailed analysis
4. **Model identification**: Can distinguish between different Claude model usage
5. **Transparent costs**: Includes pre-calculated cost information

This information provides a clear data acquisition path for CCMate's Swift implementation.