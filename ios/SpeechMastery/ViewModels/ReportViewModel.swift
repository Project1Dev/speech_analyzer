//
//  ReportViewModel.swift
//  SpeechMastery
//
//  ViewModel for daily reports screen following MVVM architecture.
//  Manages report fetching, date navigation, and pattern visualization.
//
//  Responsibilities:
//  - Fetch daily reports for specific dates
//  - Navigate between dates (previous/next day)
//  - Display aggregated scores and patterns
//  - Show critical moments from all recordings
//  - Provide improvement suggestions
//  - Cache reports for offline viewing
//
//  Integration Points:
//  - DailyReportView: UI binds to current report
//  - APIService: Fetches reports from backend
//  - CacheService: Caches reports locally
//  - NetworkMonitor: Checks connectivity before fetch
//
//  MVVM Pattern:
//  - View observes @Published currentReport
//  - Date picker updates trigger new fetch
//  - Supports swipe gestures for date navigation
//
//  OPTIONAL FEATURE: Trend Visualization
//  - 7-day and 30-day trend charts
//  - Pattern evolution over time
//  - Score progression graphs
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for daily reports screen
@MainActor
class ReportViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current report being displayed
    @Published var currentReport: Report?

    /// Selected date for report
    @Published var selectedDate: Date = Date()

    /// Whether data is currently loading
    @Published var isLoading: Bool = false

    /// Current error message (nil if no error)
    @Published var errorMessage: String?

    /// Whether report exists for selected date
    @Published var reportAvailable: Bool = false

    /// Selected top pattern for detail view
    @Published var selectedPattern: TopPattern?

    // MARK: - Private Properties

    /// API service for fetching reports
    private let apiService: APIService

    /// Cache service for offline access
    private let cacheService: CacheService

    /// Network monitor for connectivity checks
    private let networkMonitor: NetworkMonitor

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - OPTIONAL FEATURE: Trend Visualization
    /// Historical reports for trend charts
    // @Published var historicalReports: [Report] = []
    /// Date range for trend view (7 or 30 days)
    // @Published var trendDays: Int = 7
    /// Whether to show trend view
    // @Published var showTrendView: Bool = false

    // MARK: - Initialization

    /// Initialize with service dependencies
    /// - Parameters:
    ///   - apiService: Service for backend communication
    ///   - cacheService: Service for report caching
    ///   - networkMonitor: Service for network status
    init(
        apiService: APIService = .shared,
        cacheService: CacheService = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.apiService = apiService
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor

        // TODO: Load report for today
        // TODO: Set up date change observation
    }

    // MARK: - Report Loading

    /// Fetch report for selected date
    func fetchReport() async {
        isLoading = true

        // For prototype, create mock report with available data
        // In production, would fetch from API
        currentReport = createMockReportForDate(selectedDate)
        reportAvailable = currentReport != nil

        print("✅ Report loaded for: \(formattedSelectedDate)")

        isLoading = false
    }

    /// Load report for specific date
    /// - Parameter date: Date to load report for
    func loadReportForDate(_ date: Date) async {
        selectedDate = date
        await fetchReport()
    }

    /// Refresh current report
    func refresh() async {
        // TODO: Clear cache for current date
        // TODO: Call fetchReport()
    }

    // MARK: - Date Navigation

    /// Navigate to previous day
    func goToPreviousDay() {
        // TODO: Subtract one day from selectedDate
        // TODO: Fetch report for new date
    }

    /// Navigate to next day
    func goToNextDay() {
        // TODO: Add one day to selectedDate
        // TODO: Only if not future date
        // TODO: Fetch report for new date
    }

    /// Navigate to today
    func goToToday() {
        // TODO: Set selectedDate to Date()
        // TODO: Fetch report for today
    }

    /// Check if selected date is today
    var isToday: Bool {
        // TODO: Compare selectedDate with Date()
        return Calendar.current.isDateInToday(selectedDate)
    }

    /// Check if can navigate to next day (not future)
    var canGoToNextDay: Bool {
        // TODO: Check if selectedDate is before today
        return selectedDate < Date()
    }

    /// Formatted selected date for display
    var formattedSelectedDate: String {
        // TODO: Format selectedDate as "October 23, 2025"
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: selectedDate)
    }

    // MARK: - Score Display

    /// Get all category scores for charting
    var categoryScores: [(category: String, score: Double)] {
        // TODO: Return currentReport?.allScores or empty array
        return currentReport?.allScores ?? []
    }

    /// Get overall score
    var overallScore: Double {
        // TODO: Return currentReport?.overallScore or 0
        return currentReport?.overallScore ?? 0
    }

    /// Get color for overall score
    var overallScoreColor: Color {
        // TODO: Return color based on score range
        let score = overallScore
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }

    /// Get score change indicator (📈, ➡️, 📉)
    var scoreChangeIndicator: String {
        // TODO: Return currentReport?.improvementIndicator or "—"
        return currentReport?.improvementIndicator ?? "—"
    }

    /// Get 24-hour score change
    var scoreChange24h: Double? {
        // TODO: Return currentReport?.scoreChange24h
        return currentReport?.scoreChange24h
    }

    /// Get 7-day score change
    var scoreChange7d: Double? {
        // TODO: Return currentReport?.scoreChange7d
        return currentReport?.scoreChange7d
    }

    // MARK: - Pattern Details

    /// Get top 3 patterns for summary (as array)
    var topPatternsArray: [TopPattern] {
        // TODO: Return currentReport?.topThreePatterns or empty array
        return currentReport?.topThreePatterns ?? []
    }

    /// Get all patterns (as array)
    var allPatterns: [TopPattern] {
        // TODO: Return currentReport?.topPatterns or empty array
        return currentReport?.topPatterns ?? []
    }

    /// Select a pattern for detail view
    /// - Parameter pattern: TopPattern to display
    func selectPattern(_ pattern: TopPattern) {
        // TODO: Set selectedPattern
    }

    /// Clear selected pattern
    func clearSelectedPattern() {
        // TODO: Set selectedPattern to nil
    }

    // MARK: - Critical Moments

    /// Get all critical moments from report
    var criticalMoments: [CriticalMoment] {
        // TODO: Return currentReport?.criticalMoments or empty array
        return currentReport?.criticalMoments ?? []
    }

    /// Get high-severity moments only
    var highSeverityMoments: [CriticalMoment] {
        // TODO: Filter criticalMoments by severity == "high"
        return criticalMoments.filter { $0.severity == "high" }
    }

    // MARK: - Improvement Suggestions

    /// Get all improvement suggestions
    var improvementSuggestions: [String] {
        // TODO: Return currentReport?.improvementSuggestions or empty array
        return currentReport?.improvementSuggestions ?? []
    }

    /// Get priority suggestion (top recommendation)
    var prioritySuggestion: String? {
        // TODO: Return currentReport?.prioritySuggestion
        return currentReport?.prioritySuggestion
    }

    // MARK: - Summary Statistics

    /// Get number of recordings analyzed this day
    var recordingsAnalyzed: Int {
        // TODO: Return currentReport?.recordingsAnalyzed or 0
        return currentReport?.recordingsAnalyzed ?? 0
    }

    /// Get total duration for the day
    var totalDuration: String {
        // TODO: Return currentReport?.formattedTotalDuration or "0m"
        return currentReport?.formattedTotalDuration ?? "0m"
    }

    /// Get weakest category for improvement focus
    var weakestCategory: String {
        // TODO: Return currentReport?.weakestCategory or "Unknown"
        return currentReport?.weakestCategory ?? "Unknown"
    }

    /// Check if this was a good day (score > 75)
    var isGoodProgress: Bool {
        // TODO: Return currentReport?.isGoodProgress or false
        return currentReport?.isGoodProgress ?? false
    }

    // MARK: - OPTIONAL FEATURE: Trend Visualization

    /// Fetch historical reports for trend chart
    /// - Parameter days: Number of days to fetch (7 or 30)
    // func fetchTrendData(days: Int) async {
    //     TODO: Set trendDays
    //     TODO: Calculate date range
    //     TODO: Fetch reports for date range
    //     TODO: Update historicalReports array
    //     TODO: Handle errors
    // }

    /// Show trend view
    // func showTrends() {
    //     TODO: Set showTrendView = true
    //     TODO: Fetch trend data if not loaded
    // }

    /// Hide trend view
    // func hideTrends() {
    //     TODO: Set showTrendView = false
    // }

    /// Get daily scores for trend chart
    // var dailyScores: [(date: String, score: Double)] {
    //     TODO: Map historicalReports to array of (date, overallScore)
    //     TODO: Sort by date ascending
    // }

    // MARK: - Mock Data (for Prototype)

    /// Create a mock report for testing
    private func createMockReportForDate(_ date: Date) -> Report? {
        // In production, this would be fetched from API
        // For now, return sample data if date is recent (last 7 days)
        let daysSinceDate = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0

        // Only provide reports for past dates (up to 7 days)
        guard daysSinceDate >= 0 && daysSinceDate <= 7 else {
            return nil
        }

        let isToday = Calendar.current.isDateInToday(date)
        let scoreVariance = isToday ? Double.random(in: 70...85) : Double.random(in: 60...80)
        let pdScore = scoreVariance + Double.random(in: -10...10)
        let laScore = scoreVariance + Double.random(in: -10...10)
        let vcScore = scoreVariance + Double.random(in: -10...10)
        let piScore = scoreVariance + Double.random(in: -10...10)

        return Report(
            id: UUID(),
            reportDate: date,
            generatedAt: Date(),
            recordingsAnalyzed: isToday ? 1 : Int.random(in: 2...5),
            totalDuration: Double(Int.random(in: 300...1200)),
            overallScore: scoreVariance,
            powerDynamicsScore: pdScore,
            linguisticAuthorityScore: laScore,
            vocalCommandScore: vcScore,
            persuasionInfluenceScore: piScore,
            topPatterns: [
                TopPattern(patternType: "filler_words", category: "power_dynamics", occurrences: Int.random(in: 3...8), impactScore: -5.5, recommendation: "Practice pausing instead"),
                TopPattern(patternType: "hedging", category: "power_dynamics", occurrences: Int.random(in: 2...6), impactScore: -4.0, recommendation: "Use definitive statements"),
                TopPattern(patternType: "passive_voice", category: "linguistic_authority", occurrences: Int.random(in: 1...4), impactScore: -3.2, recommendation: "Use active voice")
            ],
            criticalMoments: [],
            improvementSuggestions: [
                "Reduce filler words usage",
                "Use more active voice",
                "Speak with greater confidence"
            ],
            scoreChange24h: isToday ? nil : Double.random(in: -5...5),
            scoreChange7d: Double.random(in: -5...5)
        )
    }

    // MARK: - Caching

    /// Check if report is cached for offline viewing
    /// - Parameter date: Date to check
    /// - Returns: True if cached
    func isCached(for date: Date) -> Bool {
        // TODO: Check cacheService.getReport(for: date)
        return cacheService.getReport(for: date) != nil
    }

    // MARK: - Helper Properties (for DailyReportView compatibility)

    /// Check if has data for specific date
    func hasDataForDate(_ date: Date) -> Bool {
        // In prototype, assume we have data if report is loaded
        return reportAvailable && Calendar.current.isDate(selectedDate, inSameDayAs: date)
    }

    /// Daily average score
    var dailyAverageScore: Double {
        return currentReport?.overallScore ?? 0
    }

    /// Number of recordings analyzed
    var recordingsCount: Int {
        return currentReport?.recordingsAnalyzed ?? 0
    }

    /// Category averages dictionary
    var categoryAverages: [String: Double] {
        guard let report = currentReport else { return [:] }
        return [
            "power_dynamics": report.powerDynamicsScore,
            "linguistic_authority": report.linguisticAuthorityScore,
            "vocal_command": report.vocalCommandScore,
            "persuasion": report.persuasionInfluenceScore
        ]
    }

    /// Top patterns dictionary (pattern name -> count)
    var topPatterns: [String: Int] {
        guard let report = currentReport else { return [:] }
        return Dictionary(uniqueKeysWithValues: report.topPatterns.map { ($0.displayName, $0.occurrences) })
    }

    /// Improvement suggestions array
    var suggestions: [String] {
        return currentReport?.improvementSuggestions ?? []
    }

    // MARK: - Error Handling

    /// Handle errors
    /// - Parameter error: Error that occurred
    private func handleError(_ error: Error) {
        // Log error for debugging
        print("❌ ReportViewModel Error: \(error.localizedDescription)")

        // Set errorMessage from error.localizedDescription
        errorMessage = error.localizedDescription

        // Set reportAvailable = false
        reportAvailable = false
    }

    /// Clear current error
    func clearError() {
        // TODO: Set errorMessage to nil
    }

    // MARK: - Network Status

    /// Check if network is available for fetching
    var canFetchReport: Bool {
        // TODO: Return networkMonitor.isNetworkAvailable()
        return networkMonitor.isNetworkAvailable()
    }

    /// Get network status message
    var networkStatusMessage: String {
        // TODO: Return networkMonitor.getStatusMessage()
        return networkMonitor.getStatusMessage()
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core functionality:
 1. Implement fetchReport() with cache-first strategy
 2. Implement date navigation (prev/next/today)
 3. Handle missing reports gracefully
 4. Test date transitions
 5. Verify cache integration

 TODO: Date handling:
 1. Validate date range (not future dates)
 2. Format dates for API requests
 3. Handle timezone correctly
 4. Support date picker in UI

 TODO: Score visualization:
 1. Provide data for score charts
 2. Calculate color coding
 3. Show score trends (24h, 7d)
 4. Highlight improvements

 TODO: Pattern display:
 1. Sort patterns by impact score
 2. Show pattern details on tap
 3. Link patterns to recommendations
 4. Display pattern icons

 TODO: Improvement suggestions:
 1. Prioritize suggestions by impact
 2. Show actionable steps
 3. Track suggestion completion
 4. Provide examples

 TODO: Testing:
 1. Write unit tests for date navigation
 2. Test report fetching and caching
 3. Test error handling
 4. Mock APIService for testing
 5. Test offline mode

 TODO: Performance:
 1. Cache multiple reports proactively
 2. Prefetch adjacent dates
 3. Optimize for fast switching
 4. Profile memory usage

 TODO: When implementing OPTIONAL FEATURE: Trend Visualization:
 1. Uncomment trend methods
 2. Fetch historical reports for date range
 3. Build line charts with Swift Charts
 4. Show 7-day and 30-day views
 5. Highlight score progression
 6. Display pattern evolution over time
 7. Add export to image option
 */
