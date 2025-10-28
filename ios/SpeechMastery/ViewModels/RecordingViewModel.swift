//
//  RecordingViewModel.swift
//  SpeechMastery
//
//  ViewModel for recording screen following MVVM architecture.
//  Manages recording state, audio level visualization, and file management.
//
//  Responsibilities:
//  - Control recording lifecycle (start, pause, resume, stop, cancel)
//  - Publish recording state for UI binding
//  - Handle audio level updates for visual meter
//  - Manage microphone permissions
//  - Save completed recordings to storage
//  - Handle recording errors gracefully
//
//  Integration Points:
//  - RecordingView: UI binds to published properties
//  - AudioRecordingService: Controls actual recording
//  - PrivacyManager: Checks permissions before recording
//  - AudioStorageService: Saves completed recordings
//
//  MVVM Pattern:
//  - View observes @Published properties
//  - User actions call ViewModel methods
//  - ViewModel coordinates services
//  - No direct UIKit dependencies
//
//  OPTIONAL FEATURE: Live Guardian Mode
//  - Real-time feedback during recording
//  - On-screen coaching prompts
//  - Live pattern detection
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for recording screen
@MainActor
class RecordingViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Whether recording is currently active
    @Published var isRecording: Bool = false

    /// Whether recording is paused
    @Published var isPaused: Bool = false

    /// Current recording duration in seconds
    @Published var recordingDuration: TimeInterval = 0

    /// Current audio level (0.0 to 1.0) for visual meter
    @Published var audioLevel: Float = 0

    /// Microphone permission status
    @Published var permissionStatus: PrivacyManager.PermissionStatus = .notDetermined

    /// Current error message (nil if no error)
    @Published var errorMessage: String?

    /// Whether to show permission request alert
    @Published var showPermissionAlert: Bool = false

    /// Most recently completed recording (for navigation to analysis)
    @Published var completedRecording: Recording?

    /// Whether to show error alert
    @Published var showError: Bool = false

    /// Whether upload is in progress
    @Published var isUploading: Bool = false

    /// Analysis result from upload (for navigation to results)
    @Published var analysisResult: AnalysisResult?

    // MARK: - Private Properties

    /// Recording service for audio capture
    private let recordingService: AudioRecordingService

    /// Storage service for saving recordings
    private let storageService: AudioStorageService

    /// Privacy manager for permissions
    private let privacyManager: PrivacyManager

    /// API service for uploading recordings
    private let apiService: APIService

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode
    /// Real-time feedback messages
    // @Published var liveCoachingMessage: String?
    /// Live pattern detections
    // @Published var livePatternDetections: [String] = []
    /// Whether live mode is enabled
    // @Published var isLiveModeEnabled: Bool = false

    // MARK: - Initialization

    /// Initialize with service dependencies
    /// - Parameters:
    ///   - recordingService: Service for audio recording
    ///   - storageService: Service for saving recordings
    ///   - privacyManager: Service for permission management
    ///   - apiService: Service for network communication
    init(
        recordingService: AudioRecordingService = AudioRecordingService(),
        storageService: AudioStorageService = .shared,
        privacyManager: PrivacyManager = .shared,
        apiService: APIService = .shared
    ) {
        self.recordingService = recordingService
        self.storageService = storageService
        self.privacyManager = privacyManager
        self.apiService = apiService

        // Subscribe to recording service published properties
        setupBindings()

        // Check initial permission status
        permissionStatus = privacyManager.checkMicrophonePermission()
    }

    // MARK: - Recording Controls

    /// Start a new recording
    func startRecording() async {
        // Check microphone permission
        let currentStatus = privacyManager.checkMicrophonePermission()

        // Request permission if not granted
        if currentStatus != .granted {
            await requestPermission()
            // Check again after request
            if privacyManager.checkMicrophonePermission() != .granted {
                return
            }
        }

        do {
            // Call recordingService.startRecording()
            try recordingService.startRecording()

            // Show recording indicator
            privacyManager.showRecordingIndicator()

            // Clear any previous errors
            errorMessage = nil

            print("✅ Recording started via ViewModel")

        } catch {
            // Handle errors and show alert
            handleError(error)
        }
    }

    /// Pause the current recording
    func pauseRecording() {
        recordingService.pauseRecording()
        print("⏸️ Recording paused via ViewModel")
    }

    /// Resume a paused recording
    func resumeRecording() {
        recordingService.resumeRecording()
        print("▶️ Recording resumed via ViewModel")
    }

    /// Stop the current recording and save
    func stopRecording() async {
        do {
            // Call recordingService.stopRecording()
            let recording = try recordingService.stopRecording()

            // Save recording to storage service
            try storageService.saveRecording(recording)

            // Set completedRecording for navigation
            completedRecording = recording

            // Hide recording indicator
            privacyManager.hideRecordingIndicator()

            print("✅ Recording saved: \(recording.id)")

        } catch {
            // Handle errors
            handleError(error)
        }
    }

    /// Cancel the current recording without saving
    func cancelRecording() {
        // Call recordingService.cancelRecording()
        recordingService.cancelRecording()

        // Hide recording indicator
        privacyManager.hideRecordingIndicator()

        // Reset UI state
        resetState()

        print("🗑️ Recording cancelled via ViewModel")
    }

    // MARK: - Upload and Analysis

    /// Upload recording for analysis
    /// - Parameter recording: Recording to upload
    func uploadForAnalysis(_ recording: Recording) async {
        isUploading = true

        do {
            // Check network connectivity
            guard await apiService.checkHealth() else {
                throw APIService.APIError.networkUnavailable
            }

            // Upload to backend
            let analysis = try await apiService.uploadForAnalysis(recording: recording)

            // Mark as uploaded in storage
            try storageService.markAsUploaded(id: recording.id, serverRecordingID: analysis.recordingID)

            // Mark as analyzed in storage
            try storageService.markAsAnalyzed(id: recording.id, analysisID: analysis.id)

            // Store analysis result for navigation
            analysisResult = analysis

            isUploading = false

            print("✅ Analysis complete: Overall Score = \(analysis.overallScore)")

        } catch {
            isUploading = false
            handleError(error)
        }
    }

    /// Upload the most recently completed recording
    func uploadCompletedRecording() async {
        guard let recording = completedRecording else {
            errorMessage = "No recording to upload"
            showError = true
            return
        }

        await uploadForAnalysis(recording)
    }

    // MARK: - Permission Handling

    /// Request microphone permission
    func requestPermission() async {
        // Call privacyManager.requestMicrophonePermission()
        let granted = await privacyManager.requestMicrophonePermission()

        // Update permissionStatus
        permissionStatus = privacyManager.checkMicrophonePermission()

        // If denied, show Settings alert
        if !granted {
            showPermissionAlert = true
        }
    }

    /// Open Settings app for permission management
    func openSettings() {
        privacyManager.openPrivacySettings()
    }

    // MARK: - Error Handling

    /// Handle recording errors
    /// - Parameter error: Error that occurred
    private func handleError(_ error: Error) {
        // Log error for debugging
        print("❌ RecordingViewModel Error: \(error.localizedDescription)")

        // Set errorMessage from error.localizedDescription
        errorMessage = error.localizedDescription

        // Show error alert
        showError = true
    }

    /// Clear current error
    func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Audio Settings

    /// Update audio quality settings
    /// - Parameter settings: New audio settings
    func updateAudioSettings(_ settings: AudioSettings) {
        do {
            try recordingService.updateAudioSettings(settings)
            print("🎚️ Audio settings updated via ViewModel")
        } catch {
            handleError(error)
        }
    }

    // MARK: - Formatting Helpers

    /// Format recording duration as MM:SS
    var formattedDuration: String {
        // TODO: Convert recordingDuration to MM:SS format
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Get audio level percentage for UI (0-100)
    var audioLevelPercentage: Int {
        // TODO: Convert audioLevel (0.0-1.0) to percentage
        return Int(audioLevel * 100)
    }

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode

    /// Enable live coaching during recording
    // func enableLiveMode() {
    //     TODO: Set isLiveModeEnabled to true
    //     TODO: Start real-time processing in recording service
    //     TODO: Subscribe to live feedback updates
    // }

    /// Disable live coaching
    // func disableLiveMode() {
    //     TODO: Set isLiveModeEnabled to false
    //     TODO: Stop real-time processing
    //     TODO: Clear live feedback
    // }

    /// Handle real-time pattern detection
    // private func handleLivePattern(_ pattern: String) {
    //     TODO: Add to livePatternDetections array
    //     TODO: Show coaching message
    //     TODO: Provide haptic feedback
    // }

    // MARK: - Private Helpers

    /// Set up Combine subscriptions
    private func setupBindings() {
        // Subscribe to recordingService.isRecording
        recordingService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)

        // Subscribe to recordingService.isPaused
        recordingService.$isPaused
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPaused, on: self)
            .store(in: &cancellables)

        // Subscribe to recordingService.recordingDuration
        recordingService.$recordingDuration
            .receive(on: DispatchQueue.main)
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)

        // Subscribe to recordingService.audioLevel
        recordingService.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)

        print("🔗 ViewModel bindings established")
    }

    /// Reset recording state
    private func resetState() {
        isRecording = false
        isPaused = false
        recordingDuration = 0
        audioLevel = 0
        errorMessage = nil
        showError = false
    }
}

// MARK: - TODO: Implementation Tasks
/*
 ✅ COMPLETED Core functionality:
 ✅ Implemented startRecording() with permission checks
 ✅ Implemented stopRecording() with save logic
 ✅ Implemented pause/resume functionality
 ✅ Added error handling for all recording operations
 ✅ Wired all four services together (AudioRecordingService, AudioStorageService, PrivacyManager, APIService)

 ✅ COMPLETED Combine bindings:
 ✅ Subscribed to AudioRecordingService published properties
 ✅ Forward updates to View via @Published properties
 ✅ Proper cancellable lifecycle management
 ✅ All updates on main thread

 ✅ COMPLETED Permission flow:
 ✅ Implemented requestPermission() with async/await
 ✅ Handled all permission states (granted, denied, restricted, notDetermined)
 ✅ Show appropriate alerts for each state

 ✅ COMPLETED Error handling:
 ✅ Handle recording failures gracefully
 ✅ Show user-friendly error messages
 ✅ Log errors for debugging

 ✅ COMPLETED Upload and Analysis:
 ✅ Implemented uploadForAnalysis() method
 ✅ Network connectivity checking
 ✅ Mark recordings as uploaded/analyzed in storage
 ✅ Store analysis result for navigation

 TODO: Testing:
 1. Write unit tests for state management
 2. Test permission request flows
 3. Test error handling
 4. Mock services for isolated testing
 5. Test Combine subscriptions
 6. Test recording state transitions
 7. Test upload flow

 TODO: When implementing OPTIONAL FEATURE: Live Guardian Mode:
 1. Uncomment live mode properties and methods
 2. Enable real-time processing in AudioRecordingService
 3. Subscribe to live pattern updates
 4. Display coaching messages in RecordingView
 5. Add haptic feedback for patterns
 6. Test latency and performance impact
 */
