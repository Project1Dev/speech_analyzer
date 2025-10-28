//
//  AnalysisViewModel.swift
//  SpeechMastery
//
//  ViewModel for analysis screen following MVVM architecture.
//  Manages audio upload, analysis results display, and critical moments navigation.
//
//  Responsibilities:
//  - Upload recordings to backend for analysis
//  - Display upload progress
//  - Load and display analysis results
//  - Navigate through critical moments
//  - Cache analysis results for offline viewing
//  - Handle upload errors and retries
//
//  Integration Points:
//  - AnalysisResultView: UI binds to analysis result
//  - APIService: Uploads recording and fetches analysis
//  - CacheService: Caches results for offline access
//  - NetworkMonitor: Checks connectivity before upload
//  - AudioStorageService: Marks recording as analyzed
//
//  MVVM Pattern:
//  - View observes @Published analysisResult
//  - Upload progress updates in real-time
//  - Supports manual refresh of results
//
//  OPTIONAL FEATURE: CEO Voice Synthesis
//  - Display CEO-style comparisons
//  - Show authority score improvements
//  - Side-by-side text comparison
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for analysis results screen
@MainActor
class AnalysisViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current analysis result being displayed
    @Published var analysisResult: AnalysisResult?

    /// Whether data is currently loading
    @Published var isLoading: Bool = false

    /// Whether upload is in progress
    @Published var isUploading: Bool = false

    /// Upload progress (0.0 to 1.0)
    @Published var uploadProgress: Double = 0

    /// Current error message (nil if no error)
    @Published var errorMessage: String?

    /// Selected critical moment for detail view
    @Published var selectedMoment: CriticalMoment?

    /// Whether to show upload consent dialog
    @Published var showUploadConsent: Bool = false

    // MARK: - Private Properties

    /// API service for upload and fetching
    private let apiService: APIService

    /// Storage service for updating recording status
    private let storageService: AudioStorageService

    /// Network monitor for connectivity checks
    private let networkMonitor: NetworkMonitor

    /// Privacy manager for upload consent
    private let privacyManager: PrivacyManager

    /// Recording being analyzed
    private var currentRecording: Recording?

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - OPTIONAL FEATURE: CEO Voice Synthesis
    /// CEO-style comparisons for transcript
    // @Published var ceoComparisons: [CEOComparison] = []
    /// Whether to show CEO comparisons
    // @Published var showCEOComparisons: Bool = false

    // MARK: - Initialization

    /// Initialize with service dependencies
    /// - Parameters:
    ///   - apiService: Service for backend communication
    ///   - storageService: Service for recording storage
    ///   - networkMonitor: Service for network status
    ///   - privacyManager: Service for privacy management
    init(
        apiService: APIService = .shared,
        storageService: AudioStorageService = .shared,
        networkMonitor: NetworkMonitor = .shared,
        privacyManager: PrivacyManager = .shared
    ) {
        self.apiService = apiService
        self.storageService = storageService
        self.networkMonitor = networkMonitor
        self.privacyManager = privacyManager
    }

    // MARK: - Upload and Analysis

    /// Upload recording for analysis
    /// - Parameter recording: Recording to upload
    func uploadForAnalysis(recording: Recording) async {
        // Store current recording
        currentRecording = recording

        // Check upload consent
        let hasConsent = privacyManager.getUploadConsent()
        if !hasConsent {
            let granted = await requestUploadConsent()
            if !granted {
                errorMessage = "Upload cancelled: consent required"
                return
            }
        }

        // Check network connectivity
        guard networkMonitor.isConnected else {
            errorMessage = "No network connection available"
            return
        }

        // Set isUploading = true
        isUploading = true
        uploadProgress = 0

        do {
            // Simulate progress updates (actual implementation would use URLSessionTaskDelegate)
            uploadProgress = 0.3

            // Upload via APIService
            let analysis = try await apiService.uploadForAnalysis(recording: recording)

            uploadProgress = 1.0

            // Store analysis result when complete
            analysisResult = analysis

            // Mark recording as analyzed in storage
            try storageService.markAsAnalyzed(id: recording.id, analysisID: analysis.id)

            print("✅ Analysis complete: \(analysis.id)")

        } catch {
            handleError(error)
        }

        // Set isUploading = false
        isUploading = false
    }

    /// Load existing analysis result
    /// - Parameter analysisID: Analysis UUID to load
    func loadAnalysis(analysisID: UUID) async {
        isLoading = true

        do {
            // Fetch from API (simplified - cache not implemented yet)
            let analysis = try await apiService.fetchAnalysis(id: analysisID)

            // Update analysisResult property
            analysisResult = analysis

            print("✅ Analysis loaded: \(analysisID)")

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Retry failed upload
    func retryUpload() async {
        guard let recording = currentRecording else {
            errorMessage = "No recording to retry"
            return
        }

        await uploadForAnalysis(recording: recording)
    }

    // MARK: - Critical Moments Navigation

    /// Select a critical moment for detail view
    /// - Parameter moment: CriticalMoment to display
    func selectMoment(_ moment: CriticalMoment) {
        selectedMoment = moment
        print("📍 Selected moment: \(moment.pattern) at \(moment.timestamp)s")
    }

    /// Clear selected moment
    func clearSelectedMoment() {
        selectedMoment = nil
    }

    /// Navigate to next critical moment
    func nextMoment() {
        guard let result = analysisResult,
              !result.criticalMoments.isEmpty else { return }

        if let current = selectedMoment,
           let currentIndex = result.criticalMoments.firstIndex(where: { $0.id == current.id }) {
            // Move to next index (wrap around if at end)
            let nextIndex = (currentIndex + 1) % result.criticalMoments.count
            selectedMoment = result.criticalMoments[nextIndex]
        } else {
            // Select first moment if none selected
            selectedMoment = result.criticalMoments.first
        }
    }

    /// Navigate to previous critical moment
    func previousMoment() {
        guard let result = analysisResult,
              !result.criticalMoments.isEmpty else { return }

        if let current = selectedMoment,
           let currentIndex = result.criticalMoments.firstIndex(where: { $0.id == current.id }) {
            // Move to previous index (wrap around if at start)
            let previousIndex = currentIndex == 0 ? result.criticalMoments.count - 1 : currentIndex - 1
            selectedMoment = result.criticalMoments[previousIndex]
        } else {
            // Select last moment if none selected
            selectedMoment = result.criticalMoments.last
        }
    }

    // MARK: - Score Breakdown

    /// Get all scores for charting
    var allScores: [(category: String, score: Double)] {
        guard let result = analysisResult else { return [] }
        return [
            ("Power Dynamics", result.powerDynamicsScore),
            ("Linguistic Authority", result.linguisticAuthorityScore),
            ("Vocal Command", result.vocalCommandScore),
            ("Persuasion", result.persuasionScore)
        ]
    }

    /// Get color for a score value
    /// - Parameter score: Score value (0-100)
    /// - Returns: Color based on score range
    func colorForScore(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }

    /// Get weakest category for improvement focus
    var weakestCategory: String? {
        let scores = allScores
        return scores.min(by: { $0.score < $1.score })?.category
    }

    /// Get strongest category for positive reinforcement
    var strongestCategory: String? {
        let scores = allScores
        return scores.max(by: { $0.score < $1.score })?.category
    }

    // MARK: - Pattern Details

    /// Get filler words breakdown
    var fillerWordsBreakdown: [String: Int] {
        return analysisResult?.fillerWordsData?.words ?? [:]
    }

    /// Get hedging phrases breakdown
    var hedgingPhrasesBreakdown: [String: Int] {
        return analysisResult?.hedgingData?.phrases ?? [:]
    }

    /// Get filler words per minute
    var fillerWordsPerMinute: Double {
        return analysisResult?.fillerWordsData?.perMinute ?? 0
    }

    /// Get total filler words count
    var fillerWordsCount: Int {
        return analysisResult?.fillerWordsData?.totalCount ?? 0
    }

    /// Get total hedging phrases count
    var hedgingPhrasesCount: Int {
        return analysisResult?.hedgingData?.totalCount ?? 0
    }

    // MARK: - Upload Consent

    /// Request upload consent from user
    func requestUploadConsent() async -> Bool {
        // Check if consent already granted
        if privacyManager.getUploadConsent() {
            return true
        }

        // Show consent dialog via privacyManager
        let granted = await privacyManager.requestUploadConsent()

        return granted
    }

    /// Confirm upload consent
    func confirmUploadConsent() {
        // Set upload consent in privacyManager
        privacyManager.setUploadConsent(true)

        // Set showUploadConsent = false
        showUploadConsent = false

        print("✅ Upload consent granted")
    }

    /// Decline upload consent
    func declineUploadConsent() {
        // Set showUploadConsent = false
        showUploadConsent = false

        // Cancel upload
        errorMessage = "Upload cancelled by user"

        print("❌ Upload consent declined")
    }

    // MARK: - OPTIONAL FEATURE: CEO Voice Synthesis

    /// Fetch CEO-style comparisons for transcript
    // func fetchCEOComparisons() async {
    //     TODO: Get transcript from analysisResult
    //     TODO: Call apiService.fetchCEOComparison()
    //     TODO: Update ceoComparisons array
    //     TODO: Set showCEOComparisons = true
    //     TODO: Handle errors
    // }

    /// Toggle CEO comparisons display
    // func toggleCEOComparisons() {
    //     TODO: Toggle showCEOComparisons
    // }

    // MARK: - Caching

    /// Check if analysis is cached for offline viewing
    /// - Parameter id: Analysis UUID
    /// - Returns: True if cached
    func isCached(analysisID: UUID) -> Bool {
        // Cache not implemented yet for prototype
        return false
    }

    // MARK: - Error Handling

    /// Handle errors
    /// - Parameter error: Error that occurred
    private func handleError(_ error: Error) {
        // Log error for debugging
        print("❌ AnalysisViewModel Error: \(error.localizedDescription)")

        // Set errorMessage from error.localizedDescription
        errorMessage = error.localizedDescription

        // Reset loading states
        isLoading = false
        isUploading = false
        uploadProgress = 0
    }

    /// Clear current error
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Network Status

    /// Check if network is available for upload
    var canUpload: Bool {
        // TODO: Return networkMonitor.isNetworkAvailable()
        return networkMonitor.isNetworkAvailable()
    }

    /// Get network status message
    var networkStatusMessage: String {
        // TODO: Return networkMonitor.getStatusMessage()
        return networkMonitor.getStatusMessage()
    }

    /// Whether should warn about cellular usage
    var shouldWarnAboutCellular: Bool {
        // TODO: Check if on cellular and file is large
        return networkMonitor.isOnCellular() && (currentRecording?.fileSize ?? 0) > 10_000_000  // > 10MB
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core functionality:
 1. Implement uploadForAnalysis() with progress tracking
 2. Implement loadAnalysis() with cache-first strategy
 3. Handle upload errors with retry option
 4. Test progress updates
 5. Verify cache integration

 TODO: Critical moments navigation:
 1. Implement moment selection and navigation
 2. Add keyboard shortcuts for next/previous
 3. Support swipe gestures for navigation
 4. Highlight moment in transcript

 TODO: Upload consent:
 1. Implement consent dialog flow
 2. Show privacy policy link
 3. Remember consent preference
 4. Allow consent revocation

 TODO: Score visualization:
 1. Provide data for score charts
 2. Calculate color coding
 3. Highlight strengths and weaknesses
 4. Show score trends if available

 TODO: Network handling:
 1. Check connectivity before upload
 2. Warn about cellular usage
 3. Queue uploads for Wi-Fi
 4. Handle network errors gracefully

 TODO: Testing:
 1. Write unit tests for upload logic
 2. Test error handling and retries
 3. Test cache integration
 4. Mock APIService for testing
 5. Test progress tracking

 TODO: Performance:
 1. Optimize large file uploads
 2. Implement upload resumption
 3. Compress audio if needed
 4. Profile memory usage

 TODO: When implementing OPTIONAL FEATURE: CEO Voice Synthesis:
 1. Uncomment CEO comparison methods
 2. Fetch comparisons from premium endpoint
 3. Build side-by-side comparison UI
 4. Highlight differences in text
 5. Show authority score improvements
 6. Cache CEO comparisons locally
 */
