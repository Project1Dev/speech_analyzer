//
//  Recording.swift
//  SpeechMastery
//
//  Core data model representing an audio recording with metadata.
//  This model handles both local storage (pre-upload) and server-synced recordings.
//
//  Responsibilities:
//  - Store recording metadata (duration, file path, timestamps)
//  - Track analysis status and link to results
//  - Support UserDefaults persistence and JSON serialization
//  - Provide audio quality settings management
//
//  Integration Points:
//  - AudioStorageService: Saves/loads recordings from UserDefaults
//  - APIService: Uploads recording to backend for analysis
//  - AudioRecordingService: Creates Recording instances after capture
//  - RecordingsListView: Displays recordings in library
//
//  Privacy & Security:
//  - File paths use app's secure container
//  - Includes auto_delete_at for 7-day retention policy
//  - No sensitive user data stored in this model
//

import Foundation

/// Represents an audio recording with metadata and analysis status
struct Recording: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for the recording (UUID)
    let id: UUID

    // MARK: - File Metadata

    /// Relative file path within the app's Documents directory
    /// Example: "recordings/2025-10-23_10-30-45.m4a"
    let filePath: String

    /// File size in bytes
    /// Used for upload progress tracking and storage management
    let fileSize: Int64

    /// Recording duration in seconds
    let duration: Double

    // MARK: - Timestamps

    /// When the recording was created/captured
    let recordedAt: Date

    /// When this Recording object was created (may differ from recordedAt)
    let createdAt: Date

    /// Auto-deletion timestamp (7 days from recordedAt)
    /// Used by AutoDeletionService to clean up old recordings
    let autoDeleteAt: Date

    /// Soft delete timestamp (nil if not deleted)
    var deletedAt: Date?

    // MARK: - Audio Settings

    /// Audio quality settings used for this recording
    /// Contains sample rate, bit rate, format, channels
    let audioSettings: AudioSettings

    // MARK: - Analysis Status

    /// Whether this recording has been analyzed by the backend
    var analyzed: Bool

    /// Server-assigned UUID for the analysis result (nil if not analyzed)
    var analysisID: UUID?

    /// Reference to the full analysis result (loaded separately)
    /// Not persisted in UserDefaults to avoid duplication
    var analysisResult: AnalysisResult?

    // MARK: - Server Sync

    /// Whether this recording has been uploaded to the server
    var uploaded: Bool

    /// Server-assigned recording ID (may differ from local id)
    var serverRecordingID: UUID?

    // MARK: - OPTIONAL FEATURE: Simulation Arena
    /// Reference to simulation scenario if this was a roleplay recording
    // var simulationScenarioID: UUID?
    // var simulationDifficulty: String?  // "easy", "medium", "hard"

    // MARK: - OPTIONAL FEATURE: Voice Command Training
    /// Reference to training exercise if this was a drill
    // var trainingExerciseID: UUID?
    // var exerciseType: String?  // "pace_control", "articulation", "power_pause"

    // MARK: - OPTIONAL FEATURE: Conversational Chess
    /// Indicates if this is a multi-speaker conversation
    // var isConversation: Bool = false
    // var speakerCount: Int?

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode
    /// Session ID for live monitoring sessions
    // var liveGuardianSessionID: UUID?

    // MARK: - Initialization

    /// Create a new Recording instance
    init(
        id: UUID = UUID(),
        filePath: String,
        fileSize: Int64,
        duration: Double,
        recordedAt: Date = Date(),
        createdAt: Date = Date(),
        audioSettings: AudioSettings,
        analyzed: Bool = false,
        analysisID: UUID? = nil,
        uploaded: Bool = false,
        serverRecordingID: UUID? = nil
    ) {
        self.id = id
        self.filePath = filePath
        self.fileSize = fileSize
        self.duration = duration
        self.recordedAt = recordedAt
        self.createdAt = createdAt
        self.autoDeleteAt = Calendar.current.date(byAdding: .day, value: 7, to: recordedAt) ?? recordedAt.addingTimeInterval(7 * 24 * 60 * 60)
        self.audioSettings = audioSettings
        self.analyzed = analyzed
        self.analysisID = analysisID
        self.uploaded = uploaded
        self.serverRecordingID = serverRecordingID
    }

    // MARK: - Helper Methods

    /// Get the full file URL for this recording
    func getFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(filePath)
    }

    /// Check if this recording is eligible for auto-deletion
    var shouldBeDeleted: Bool {
        return Date() >= autoDeleteAt && deletedAt == nil
    }

    /// Check if this recording is pending upload
    var isPendingUpload: Bool {
        return !uploaded && deletedAt == nil
    }

    /// Check if analysis is available
    var hasAnalysis: Bool {
        return analyzed && analysisID != nil
    }

    /// Human-readable file size
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// Human-readable duration
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case id
        case filePath = "file_path"
        case fileSize = "file_size"
        case duration
        case recordedAt = "recorded_at"
        case createdAt = "created_at"
        case autoDeleteAt = "auto_delete_at"
        case deletedAt = "deleted_at"
        case audioSettings = "audio_settings"
        case analyzed
        case analysisID = "analysis_id"
        case uploaded
        case serverRecordingID = "server_recording_id"

        // OPTIONAL FEATURE: Uncomment when implementing
        // case simulationScenarioID = "simulation_scenario_id"
        // case simulationDifficulty = "simulation_difficulty"
        // case trainingExerciseID = "training_exercise_id"
        // case exerciseType = "exercise_type"
        // case isConversation = "is_conversation"
        // case speakerCount = "speaker_count"
        // case liveGuardianSessionID = "live_guardian_session_id"
    }
}

// MARK: - Sample Data for Previews

extension Recording {
    /// Sample recording for SwiftUI previews and testing
    static var sample: Recording {
        Recording(
            id: UUID(),
            filePath: "recordings/2025-10-23_10-30-45.m4a",
            fileSize: 2_048_000,  // ~2MB
            duration: 125.5,  // 2:05
            recordedAt: Date().addingTimeInterval(-3600),  // 1 hour ago
            audioSettings: .standard,
            analyzed: true,
            analysisID: UUID(),
            uploaded: true,
            serverRecordingID: UUID()
        )
    }

    /// Sample unanalyzed recording
    static var sampleUnanalyzed: Recording {
        Recording(
            id: UUID(),
            filePath: "recordings/2025-10-23_14-15-20.m4a",
            fileSize: 1_500_000,
            duration: 90.0,
            recordedAt: Date().addingTimeInterval(-300),  // 5 minutes ago
            audioSettings: .high,
            analyzed: false,
            uploaded: false
        )
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: When implementing full backend integration:
 1. Add sync logic to reconcile local and server IDs
 2. Implement conflict resolution if recording exists both locally and remotely
 3. Add retry logic for failed uploads
 4. Handle server-side recording deletion

 TODO: When implementing optional features:
 1. Uncomment and implement simulation scenario tracking
 2. Add training exercise metadata
 3. Support conversational recordings with speaker diarization
 4. Integrate live guardian session tracking

 TODO: Performance optimizations:
 1. Consider lazy loading of analysisResult to reduce memory usage
 2. Add caching layer for frequently accessed recordings
 3. Implement batch loading for list views
 */
