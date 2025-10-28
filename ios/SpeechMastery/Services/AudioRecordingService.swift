//
//  AudioRecordingService.swift
//  SpeechMastery
//
//  Manages audio recording using AVFoundation framework.
//  Handles recording lifecycle, audio level monitoring, and file management.
//
//  Responsibilities:
//  - Configure and control AVAudioRecorder
//  - Monitor audio levels for visual feedback
//  - Manage recording sessions (start, pause, stop)
//  - Apply AudioSettings configurations
//  - Generate timestamped file paths
//  - Handle recording permissions and errors
//
//  Integration Points:
//  - RecordingViewModel: Called by ViewModel to control recording
//  - PrivacyManager: Checks microphone permissions before recording
//  - AudioSettings: Applies quality settings to AVAudioRecorder
//  - AudioStorageService: Saves completed recordings to storage
//
//  Technical Details:
//  - Uses AVAudioSession for audio routing configuration
//  - Implements AVAudioRecorderDelegate for completion callbacks
//  - Publishes audio level updates for UI meters
//  - Creates files in app's Documents/recordings directory
//
//  OPTIONAL FEATURE: Live Guardian Mode
//  - Can be extended to support real-time audio streaming
//  - Buffer-based processing for live analysis
//  - Low-latency configuration for immediate feedback
//

import Foundation
import AVFoundation
import Combine

/// Service for managing audio recording with AVFoundation
class AudioRecordingService: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Whether recording is currently active
    @Published var isRecording: Bool = false

    /// Whether recording is paused
    @Published var isPaused: Bool = false

    /// Current recording duration in seconds
    @Published var recordingDuration: TimeInterval = 0

    /// Current audio level (0.0 to 1.0) for visual meter
    @Published var audioLevel: Float = 0

    /// Current recording file path (nil if not recording)
    @Published var currentRecordingPath: String?

    // MARK: - Private Properties

    /// AVAudioRecorder instance
    private var audioRecorder: AVAudioRecorder?

    /// Timer for updating duration and audio levels
    private var levelTimer: Timer?

    /// Audio settings configuration
    private var audioSettings: AudioSettings

    /// Privacy manager for permission checks
    private let privacyManager: PrivacyManager

    /// Start time of current recording
    private var recordingStartTime: Date?

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode
    /// Audio engine for real-time processing
    // private var audioEngine: AVAudioEngine?
    /// Audio tap for live analysis
    // private var audioTap: AVAudioNodeTap?
    /// Real-time analysis buffer
    // private var analysisBuffer: AVAudioPCMBuffer?

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - audioSettings: Audio quality configuration (defaults to standard)
    ///   - privacyManager: Privacy manager for permissions
    init(audioSettings: AudioSettings = .standard, privacyManager: PrivacyManager = .shared) {
        self.audioSettings = audioSettings
        self.privacyManager = privacyManager
        super.init()
    }

    // MARK: - Recording Control

    /// Start a new recording session
    /// - Throws: RecordingError if permissions denied or setup fails
    func startRecording() throws {
        // Check if already recording
        guard !isRecording else {
            throw RecordingError.alreadyRecording
        }

        // Check microphone permissions
        guard privacyManager.hasMicrophonePermission() else {
            throw RecordingError.permissionDenied
        }

        // Configure audio session
        try configureAudioSession()

        // Ensure recordings directory exists
        try ensureRecordingsDirectory()

        // Generate file path
        let filePath = generateFilePath()
        let fileURL = getFileURL(for: filePath)

        // Create audio recorder with settings using AudioSettings helper
        let recorderSettings = audioSettings.toAVSettings()

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: recorderSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true

            // Start recording
            guard audioRecorder?.record() == true else {
                throw RecordingError.recordingFailed("Failed to start AVAudioRecorder")
            }

            // Update state
            recordingStartTime = Date()
            currentRecordingPath = filePath
            isRecording = true
            isPaused = false
            recordingDuration = 0

            // Start level monitoring
            startLevelMonitoring()

            print("✅ Recording started: \(filePath)")

        } catch {
            throw RecordingError.recordingFailed(error.localizedDescription)
        }
    }

    /// Pause the current recording
    func pauseRecording() {
        guard isRecording, !isPaused else { return }

        audioRecorder?.pause()
        stopLevelMonitoring()
        isPaused = true

        print("⏸️ Recording paused")
    }

    /// Resume a paused recording
    func resumeRecording() {
        guard isRecording, isPaused else { return }

        audioRecorder?.record()
        startLevelMonitoring()
        isPaused = false

        print("▶️ Recording resumed")
    }

    /// Stop the current recording and return file information
    /// - Returns: Recording model with metadata
    /// - Throws: RecordingError if stop fails or file is invalid
    func stopRecording() throws -> Recording {
        guard isRecording else {
            throw RecordingError.notRecording
        }

        // Stop level monitoring
        stopLevelMonitoring()

        // Stop audio recorder
        audioRecorder?.stop()

        // Get file information
        guard let filePath = currentRecordingPath else {
            throw RecordingError.fileCreationFailed
        }

        let fileURL = getFileURL(for: filePath)

        // Get file size
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            throw RecordingError.fileCreationFailed
        }

        // Calculate final duration
        let finalDuration = recordingDuration

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Create Recording model
        let recording = Recording(
            id: UUID(),
            filePath: filePath,
            fileSize: fileSize,
            duration: finalDuration,
            recordedAt: recordingStartTime ?? Date(),
            createdAt: Date(),
            audioSettings: audioSettings,
            analyzed: false,
            uploaded: false
        )

        // Reset state
        isRecording = false
        isPaused = false
        recordingDuration = 0
        audioLevel = 0
        currentRecordingPath = nil
        recordingStartTime = nil
        audioRecorder = nil

        print("⏹️ Recording stopped: \(filePath) (\(finalDuration)s, \(fileSize) bytes)")

        return recording
    }

    /// Cancel the current recording and delete file
    func cancelRecording() {
        guard isRecording else { return }

        // Stop monitoring
        stopLevelMonitoring()

        // Stop recorder
        audioRecorder?.stop()

        // Delete file
        if let filePath = currentRecordingPath {
            let fileURL = getFileURL(for: filePath)
            try? FileManager.default.removeItem(at: fileURL)
            print("🗑️ Recording cancelled and deleted: \(filePath)")
        }

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Reset state
        isRecording = false
        isPaused = false
        recordingDuration = 0
        audioLevel = 0
        currentRecordingPath = nil
        recordingStartTime = nil
        audioRecorder = nil
    }

    // MARK: - Audio Configuration

    /// Update audio settings (can only be changed when not recording)
    /// - Parameter settings: New audio quality settings
    /// - Throws: RecordingError if called while recording
    func updateAudioSettings(_ settings: AudioSettings) throws {
        guard !isRecording else {
            throw RecordingError.invalidSettings
        }

        self.audioSettings = settings
        print("🎚️ Audio settings updated: \(settings.qualityDescription)")
    }

    /// Configure AVAudioSession for recording
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()

        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        print("🎤 Audio session configured")
    }

    // MARK: - Level Monitoring

    /// Start monitoring audio levels for visual feedback
    private func startLevelMonitoring() {
        // Create timer that fires every 0.1 seconds
        levelTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(updateMeters),
            userInfo: nil,
            repeats: true
        )
    }

    /// Stop monitoring audio levels
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }

    /// Update audio level from AVAudioRecorder metering
    @objc private func updateMeters() {
        guard let recorder = audioRecorder, isRecording else { return }

        // Update metering
        recorder.updateMeters()

        // Get average power in decibels (-160 to 0)
        let averagePower = recorder.averagePower(forChannel: 0)

        // Convert decibels to 0-1 scale
        // -160 dB = silence, 0 dB = maximum
        // Use -50 dB as minimum threshold for better visual feedback
        let minDb: Float = -50.0
        let normalizedPower = max(0.0, min(1.0, (averagePower - minDb) / (0 - minDb)))

        // Update published property on main thread
        DispatchQueue.main.async {
            self.audioLevel = normalizedPower
        }

        // Update recording duration
        if let startTime = recordingStartTime {
            DispatchQueue.main.async {
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    // MARK: - File Management

    /// Generate unique file path for new recording
    /// - Returns: Relative file path in recordings directory
    private func generateFilePath() -> String {
        // Create timestamp-based filename
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())

        // Get file extension from audio settings
        let fileExtension = audioSettings.format

        // Return relative path
        return "recordings/\(timestamp).\(fileExtension)"
    }

    /// Get full URL for recording file
    /// - Parameter relativePath: Relative path from generateFilePath()
    /// - Returns: Full URL in Documents directory
    private func getFileURL(for relativePath: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(relativePath)
    }

    /// Ensure recordings directory exists
    private func ensureRecordingsDirectory() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsPath = documentsPath.appendingPathComponent("recordings")

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: recordingsPath.path) {
            try FileManager.default.createDirectory(
                at: recordingsPath,
                withIntermediateDirectories: true,
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete]
            )
            print("📁 Created recordings directory with encryption")
        }
    }

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode

    /// Start real-time audio processing for live analysis
    // func startLiveProcessing() throws {
    //     TODO: Initialize AVAudioEngine
    //     TODO: Configure audio tap on input node
    //     TODO: Set up low-latency buffer
    //     TODO: Start engine
    //     TODO: Stream audio chunks to analysis service
    // }

    /// Stop real-time audio processing
    // func stopLiveProcessing() {
    //     TODO: Stop audio engine
    //     TODO: Remove audio tap
    //     TODO: Clean up buffers
    // }

    // MARK: - OPTIONAL FEATURE: Voice Command Training

    /// Start recording with specific training exercise parameters
    // func startTrainingRecording(exerciseID: UUID, exerciseType: String) throws -> Recording {
    //     TODO: Start recording with normal flow
    //     TODO: Attach exercise metadata to Recording
    //     TODO: Return Recording with training context
    // }

    // MARK: - Error Handling

    /// Errors that can occur during recording
    enum RecordingError: LocalizedError {
        case permissionDenied
        case recordingFailed(String)
        case fileCreationFailed
        case alreadyRecording
        case notRecording
        case invalidSettings

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone permission is required to record audio."
            case .recordingFailed(let reason):
                return "Recording failed: \(reason)"
            case .fileCreationFailed:
                return "Failed to create recording file."
            case .alreadyRecording:
                return "A recording is already in progress."
            case .notRecording:
                return "No recording is currently active."
            case .invalidSettings:
                return "Cannot change audio settings while recording."
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {

    /// Called when recording finishes successfully
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("✅ Recording finished successfully")
        } else {
            print("❌ Recording finished with errors")
            // Clean up on failure
            if let filePath = currentRecordingPath {
                let fileURL = getFileURL(for: filePath)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    /// Called when encoding error occurs
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Recording encoding error: \(error?.localizedDescription ?? "Unknown error")")

        // Clean up failed recording
        if let filePath = currentRecordingPath {
            let fileURL = getFileURL(for: filePath)
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Reset state
        DispatchQueue.main.async {
            self.stopLevelMonitoring()
            self.isRecording = false
            self.isPaused = false
            self.currentRecordingPath = nil
        }
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core recording implementation:
 1. Implement startRecording() with full AVFoundation setup
 2. Implement stopRecording() with file metadata extraction
 3. Implement pause/resume functionality
 4. Add audio level monitoring with visual feedback
 5. Test with all AudioSettings presets

 TODO: Permission handling:
 1. Integrate with PrivacyManager for microphone permissions
 2. Handle permission denial gracefully
 3. Prompt user to enable permissions in Settings

 TODO: Error handling:
 1. Handle audio session interruptions (phone calls, etc.)
 2. Handle disk space issues
 3. Handle audio hardware failures
 4. Add comprehensive error logging

 TODO: Testing:
 1. Write unit tests for file path generation
 2. Write tests for audio level conversion
 3. Test pause/resume edge cases
 4. Test cancellation cleanup

 TODO: When implementing OPTIONAL FEATURE: Live Guardian Mode:
 1. Uncomment live processing methods
 2. Set up AVAudioEngine with low-latency configuration
 3. Implement audio tap for real-time buffering
 4. Stream chunks to live analysis service
 5. Test on physical device (simulator has limitations)

 TODO: When implementing OPTIONAL FEATURE: Voice Command Training:
 1. Uncomment training recording method
 2. Add exercise metadata to Recording model
 3. Support target metrics (e.g., "speak at 120 WPM")
 4. Provide real-time feedback during drill
 */
