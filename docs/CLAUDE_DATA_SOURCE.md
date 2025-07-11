# Claude 使用数据来源详解

## 概述

CCSeva 通过 `ccusage` npm 包获取 Claude Code 的使用数据。这些数据来自 Claude 应用程序在本地存储的 JSONL 格式文件。

## 数据存储位置

Claude 将使用数据存储在以下位置（按优先级排序）：

1. **环境变量指定路径**：`$CLAUDE_CONFIG_DIR`（支持逗号分隔的多个路径）
2. **XDG 配置目录**：`$XDG_CONFIG_HOME/claude` 或 `~/.config/claude`
3. **传统路径**：`~/.claude`

实际数据文件位于：
```
<claude_config_dir>/projects/**/*.jsonl
```

## 数据文件格式

Claude 使用 **JSONL（JSON Lines）** 格式存储数据，每行是一个独立的 JSON 对象：

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0",
  "message": {
    "usage": {
      "input_tokens": 1000,          // 输入 token 数
      "output_tokens": 500,          // 输出 token 数
      "cache_creation_input_tokens": 25,  // 缓存创建 token
      "cache_read_input_tokens": 10      // 缓存读取 token
    },
    "model": "claude-sonnet-4-20250514",  // 使用的模型
    "id": "msg_unique_id",               // 消息唯一标识
    "content": [{ "text": "..." }]       // 消息内容
  },
  "costUSD": 0.01,                      // 预计算的成本（美元）
  "requestId": "req_unique_id",         // 请求唯一标识
  "isApiErrorMessage": false            // 是否为错误消息
}
```

## 数据获取流程

### 1. 文件发现
```typescript
// ccusage 扫描项目目录下的所有 .jsonl 文件
const files = glob.sync('**/*.jsonl', {
  cwd: projectDir,
  absolute: true
});
```

### 2. 数据解析
```typescript
// 逐行读取 JSONL 文件
const lines = fs.readFileSync(file, 'utf-8').split('\n');
for (const line of lines) {
  if (line.trim()) {
    const data = JSON.parse(line);
    // 验证和处理数据...
  }
}
```

### 3. 数据去重
- 使用 `message.id + requestId` 组合作为唯一标识
- 防止重复计算相同的使用记录

### 4. 成本计算

成本计算有三种模式：

1. **auto**（默认）：优先使用预计算的 `costUSD`，如果没有则根据 token 计算
2. **calculate**：始终根据 token 数量和模型定价计算
3. **display**：只显示预计算的成本

计算公式：
```
成本 = (输入tokens × 输入单价) + (输出tokens × 输出单价) + 缓存成本
```

### 5. 会话和区块

- **会话区块**：5 小时为一个计费周期（Claude 的计费模型）
- **会话识别**：通过时间间隔检测会话边界
- **实时会话**：当前正在进行的会话会被特别标记

## Swift 实现要点

要在 Swift 中实现类似功能，需要：

### 1. 查找 Claude 配置目录
```swift
func findClaudeConfigDir() -> URL? {
    // 检查环境变量
    if let envPath = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"] {
        return URL(fileURLWithPath: envPath)
    }
    
    // 检查 XDG 配置
    if let xdgConfig = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
        return URL(fileURLWithPath: xdgConfig).appendingPathComponent("claude")
    }
    
    // 检查默认位置
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

### 2. 读取 JSONL 文件
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

### 3. 监控文件变化
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

### 4. 数据模型
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

## 关键发现

1. **本地数据**：所有数据都存储在本地，无需网络请求
2. **实时更新**：Claude 每次使用后立即写入新的 JSONL 行
3. **历史完整**：包含所有历史使用记录，可以进行详细分析
4. **模型识别**：可以区分不同的 Claude 模型使用情况
5. **成本透明**：包含预计算的成本信息

这些信息为 CCMate 的 Swift 实现提供了清晰的数据获取路径。