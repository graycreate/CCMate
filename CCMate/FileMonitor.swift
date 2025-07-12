import Foundation

final class FileMonitor: @unchecked Sendable {
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "com.ccmate.filemonitor", attributes: .concurrent)
    private var lastModificationDate: Date?
    
    var onFileChanged: (() -> Void)?
    
    func startMonitoring(path: String) {
        stopMonitoring()
        
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("Failed to open file for monitoring: \(path)")
            return
        }
        
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend],
            queue: queue
        )
        
        source?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            // Check if file was actually modified (debounce rapid events)
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            let modificationDate = attributes?[.modificationDate] as? Date
            
            if let modificationDate = modificationDate,
               modificationDate != self.lastModificationDate {
                self.lastModificationDate = modificationDate
                
                DispatchQueue.main.async {
                    self.onFileChanged?()
                }
            }
        }
        
        source?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        
        source?.resume()
    }
    
    func stopMonitoring() {
        source?.cancel()
        source = nil
    }
    
    deinit {
        stopMonitoring()
    }
}

@MainActor
class ClaudeFileWatcher {
    private let fileMonitor = FileMonitor()
    private let directoryMonitor = FileMonitor()
    private let reader = ClaudeDataReader.shared
    private var isMonitoring = false
    
    var onDataChanged: ((DailyStats) -> Void)?
    
    func startWatching() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Monitor the specific usage file
        let usageFilePath = reader.getTodayUsageFilePath()
        if FileManager.default.fileExists(atPath: usageFilePath.path) {
            fileMonitor.onFileChanged = { [weak self] in
                self?.handleFileChange()
            }
            fileMonitor.startMonitoring(path: usageFilePath.path)
        }
        
        // Also monitor the Claude config directory for new files
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("claude")
            .path
        
        if FileManager.default.fileExists(atPath: configPath) {
            directoryMonitor.onFileChanged = { [weak self] in
                self?.checkForNewUsageFile()
            }
            directoryMonitor.startMonitoring(path: configPath)
        }
        
        // Initial data load
        handleFileChange()
    }
    
    func stopWatching() {
        isMonitoring = false
        fileMonitor.stopMonitoring()
        directoryMonitor.stopMonitoring()
    }
    
    private func handleFileChange() {
        let entries = reader.readTodayUsage()
        let stats = reader.calculateDailyStats(from: entries)
        
        DispatchQueue.main.async {
            self.onDataChanged?(stats)
        }
    }
    
    private func checkForNewUsageFile() {
        let usageFilePath = reader.getTodayUsageFilePath()
        if FileManager.default.fileExists(atPath: usageFilePath.path) {
            // Switch monitoring to the new file
            fileMonitor.stopMonitoring()
            fileMonitor.startMonitoring(path: usageFilePath.path)
            handleFileChange()
        }
    }
}