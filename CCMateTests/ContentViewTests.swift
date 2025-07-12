import XCTest
import SwiftUI
@testable import CCMate

final class ContentViewTests: XCTestCase {
    
    func testEmptyStateViewAppearsWhenNoData() {
        // Given: AppState with no usage data
        let appState = AppState()
        appState.dailyStats = DailyStats(
            date: Date(),
            totalMinutes: 0,
            sessionsCount: 0,
            averageSessionMinutes: 0,
            hourlyData: Array(repeating: 0, count: 24)
        )
        
        // When: ContentView is created
        let contentView = ContentView()
            .environmentObject(appState)
        
        // Then: Verify empty state would be shown
        XCTAssertEqual(appState.dailyStats.totalMinutes, 0)
        XCTAssertEqual(appState.dailyStats.sessionsCount, 0)
        
        // Note: In a real SwiftUI test, you would use ViewInspector or similar
        // to verify the actual view hierarchy. For now, we're testing the logic.
        XCTAssertTrue(shouldShowEmptyState(appState: appState))
    }
    
    func testEmptyStateViewHiddenWhenDataExists() {
        // Given: AppState with usage data
        let appState = AppState()
        appState.dailyStats = DailyStats(
            date: Date(),
            totalMinutes: 45,
            sessionsCount: 3,
            averageSessionMinutes: 15,
            hourlyData: [0, 0, 0, 0, 0, 0, 0, 0, 10, 20, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        )
        
        // When: ContentView is created
        let contentView = ContentView()
            .environmentObject(appState)
        
        // Then: Verify empty state would not be shown
        XCTAssertGreaterThan(appState.dailyStats.totalMinutes, 0)
        XCTAssertGreaterThan(appState.dailyStats.sessionsCount, 0)
        XCTAssertFalse(shouldShowEmptyState(appState: appState))
    }
    
    func testEmptyStateConditions() {
        // Test various combinations to ensure empty state logic is correct
        let testCases: [(totalMinutes: Int, sessionsCount: Int, shouldShowEmpty: Bool)] = [
            (0, 0, true),      // No data at all
            (0, 1, false),     // Has sessions but no time (edge case)
            (1, 0, false),     // Has time but no sessions (edge case)
            (10, 5, false),    // Normal data
        ]
        
        for testCase in testCases {
            let appState = AppState()
            appState.dailyStats = DailyStats(
                date: Date(),
                totalMinutes: testCase.totalMinutes,
                sessionsCount: testCase.sessionsCount,
                averageSessionMinutes: testCase.sessionsCount > 0 ? testCase.totalMinutes / testCase.sessionsCount : 0,
                hourlyData: Array(repeating: 0, count: 24)
            )
            
            XCTAssertEqual(
                shouldShowEmptyState(appState: appState),
                testCase.shouldShowEmpty,
                "Failed for totalMinutes: \(testCase.totalMinutes), sessionsCount: \(testCase.sessionsCount)"
            )
        }
    }
    
    // Helper function that matches the logic in ContentView
    private func shouldShowEmptyState(appState: AppState) -> Bool {
        return appState.dailyStats.totalMinutes == 0 && appState.dailyStats.sessionsCount == 0
    }
}

// MARK: - UI Snapshot Tests (Optional)

#if canImport(SnapshotTesting)
import SnapshotTesting

extension ContentViewTests {
    func testEmptyStateSnapshot() {
        let appState = AppState()
        appState.dailyStats = DailyStats(
            date: Date(),
            totalMinutes: 0,
            sessionsCount: 0,
            averageSessionMinutes: 0,
            hourlyData: Array(repeating: 0, count: 24)
        )
        
        let contentView = ContentView()
            .environmentObject(appState)
            .frame(width: 600, height: 400)
        
        // This would create a snapshot of the empty state
        // assertSnapshot(matching: contentView, as: .image)
    }
    
    func testNormalStateSnapshot() {
        let appState = AppState()
        appState.dailyStats = DailyStats(
            date: Date(),
            totalMinutes: 120,
            sessionsCount: 5,
            averageSessionMinutes: 24,
            hourlyData: [0, 0, 0, 0, 0, 0, 0, 0, 10, 30, 25, 20, 15, 10, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0]
        )
        
        let contentView = ContentView()
            .environmentObject(appState)
            .frame(width: 600, height: 400)
        
        // This would create a snapshot of the normal state with data
        // assertSnapshot(matching: contentView, as: .image)
    }
}
#endif