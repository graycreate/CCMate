# CCMate MVP 开发计划

## MVP 目标

构建一个轻量级的 macOS 菜单栏应用，实时监控 Claude Code 的使用情况，包含两个核心功能：
1. **Daily 标签页**：展示当天的实时使用详情
2. **Analytics 标签页**：展示使用统计和趋势

## 技术架构

### 核心组件
- **数据层**：ClaudeDataReader - 读取和解析 JSONL 文件
- **监控层**：FileMonitor - 监控文件变化，实时更新
- **UI 层**：SwiftUI 实现的两个标签页
- **菜单栏**：显示当前使用百分比

### 数据流
```
Claude JSONL 文件 → FileMonitor → ClaudeDataReader → DataModel → UI更新
```

## 开发阶段

### 第一阶段：数据基础设施（2天）

#### 1.1 实现 ClaudeDataReader
```swift
class ClaudeDataReader {
    // 查找 Claude 配置目录
    func findClaudeConfigDirectory() -> URL?
    
    // 扫描所有 JSONL 文件
    func scanJSONLFiles(in directory: URL) -> [URL]
    
    // 解析单个 JSONL 文件
    func parseJSONLFile(at url: URL) -> [UsageEntry]
    
    // 聚合今日数据
    func getTodayUsage() -> DailyUsage
    
    // 获取历史数据
    func getHistoricalUsage(days: Int) -> [DailyUsage]
}
```

#### 1.2 定义数据模型
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
    let hourlyDistribution: [Int] // 24小时分布
}

struct SessionBlock {
    let startTime: Date
    let endTime: Date
    let tokensUsed: Int
    let cost: Double
    let isActive: Bool
}
```

### 第二阶段：UI 实现（3天）

#### 2.1 Daily 标签页
显示内容：
- 今日使用概览卡片
  - 总 Token 使用量和百分比
  - 总成本
  - 活跃会话数
  - 最后更新时间
- 会话时间线
  - 5小时会话块可视化
  - 当前活跃会话高亮
- 小时分布图
  - 24小时使用分布柱状图

#### 2.2 Analytics 标签页
显示内容：
- 7天使用趋势图
  - Token 使用量折线图
  - 成本趋势
- 使用统计
  - 平均每日使用量
  - 峰值使用时段
  - 使用速率（tokens/小时）
- 模型使用分布
  - 不同模型的使用占比

#### 2.3 TabView 实现
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

### 第三阶段：实时监控（2天）

#### 3.1 文件监控器
```swift
class FileMonitor {
    private var fileWatcher: DispatchSourceFileSystemObject?
    
    func startMonitoring(directory: URL, onChange: @escaping () -> Void)
    func stopMonitoring()
}
```

#### 3.2 菜单栏更新
- 每30秒更新一次
- 显示使用百分比
- 颜色编码：绿色(<70%)、黄色(70-90%)、红色(>90%)

### 第四阶段：完善和优化（1天）

#### 4.1 性能优化
- 实现增量数据读取
- 添加数据缓存
- 优化大文件解析

#### 4.2 用户体验
- 添加加载状态
- 错误处理和提示
- 数据刷新动画

## UI 设计规范

### 遵循 Apple Human Interface Guidelines

#### 设计原则
- **清晰性**：使用 SF Pro 字体，适当的字号和对比度
- **一致性**：使用系统标准控件和颜色
- **直观性**：信息层级分明，重要信息突出
- **原生感**：使用 macOS 标准间距和布局

#### 视觉风格
- **背景**：使用 `NSColor.windowBackgroundColor`
- **卡片**：使用 `NSVisualEffectView` 实现毛玻璃效果
- **强调色**：使用系统 accent color
- **图表**：使用 Swift Charts 框架

### Daily 标签页设计

#### 布局结构
```swift
VStack(spacing: 16) {
    // 顶部标题区
    HStack {
        Text("Today's Usage")
            .font(.largeTitle)
        Spacer()
        Text(Date(), style: .date)
            .foregroundColor(.secondary)
    }
    
    // 统计卡片组
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
    
    // 会话时间线
    GroupBox("Session Timeline") {
        SessionTimelineView()
    }
    
    // 小时分布图表
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

#### 组件设计
- **StatCard**: 使用 `GroupBox` 样式，包含 SF Symbol 图标
- **进度指示**: 使用 `ProgressView` 或 `Gauge`（macOS 13+）
- **图表**: 使用 Swift Charts 的 `BarMark` 和 `LineMark`

### Analytics 标签页设计

#### 布局结构
```swift
VStack(spacing: 16) {
    // 趋势图表
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
    
    // 统计信息
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
    
    // 模型使用分布
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

### 颜色方案

#### 自适应颜色（支持深色模式）
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

#### 使用状态颜色
- **正常 (<70%)**: `systemGreen`
- **警告 (70-90%)**: `systemYellow`
- **危险 (>90%)**: `systemRed`

### 动画和过渡

- **数据更新**: 使用 `withAnimation(.easeInOut(duration: 0.3))`
- **图表动画**: Chart 自带的默认动画
- **进度变化**: 平滑过渡，避免跳动

### 响应式设计

- **最小窗口尺寸**: 600x500
- **内容自适应**: 使用 `GeometryReader` 响应窗口变化
- **紧凑模式**: 窗口较小时隐藏次要信息

## 实现优先级

### 必须实现（MVP）
1. ✅ 读取 Claude JSONL 文件
2. ✅ 解析使用数据
3. ✅ Daily 标签页基础功能
4. ✅ Analytics 标签页基础功能
5. ✅ 菜单栏百分比显示
6. ✅ 30秒自动刷新

### 可选功能（后续版本）
- 自定义 token 限额
- 使用预警通知
- 数据导出功能
- 深色模式切换
- 偏好设置面板

## 开发时间表

| 阶段 | 任务 | 预计时间 | 完成标准 |
|------|------|----------|----------|
| 1 | 数据基础设施 | 2天 | 能正确读取和解析 Claude 数据 |
| 2 | UI 实现 | 3天 | 两个标签页功能完整 |
| 3 | 实时监控 | 2天 | 数据自动更新，菜单栏显示正常 |
| 4 | 完善优化 | 1天 | 性能良好，用户体验流畅 |

**总计：8天完成 MVP**

## 成功标准

1. **功能完整**：能准确显示 Claude 使用数据
2. **实时更新**：30秒内反映最新使用情况
3. **性能良好**：内存占用 <50MB，CPU 使用率 <5%
4. **用户友好**：界面清晰，信息一目了然

## 下一步行动

1. 开始实现 ClaudeDataReader 类
2. 创建数据模型结构
3. 设计 UI 组件
4. 集成文件监控
5. 测试和优化