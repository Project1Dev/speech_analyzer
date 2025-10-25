//
//  AudioStorageService.swift
//  SpeechMastery
//
//  Manages local persistence of recordings using UserDefaults and FileManager.
//  Handles CRUD operations for Recording models and audio file management.
//
//  Responsibilities:
//  - Save/load Recording metadata to/from UserDefaults
//  - Manage audio files in Documents directory with encryption
//  - Provide file size calculations and storage statistics
//  - Handle soft deletion and cleanup
//  - Support batch operations for efficiency
//
//  Integration Points:
//  - RecordingsListViewModel: Loads all recordings for library view
//  - AudioRecordingService: Saves new recordings after capture
//  - AutoDeletionService: Queries recordings for cleanup
//  - APIService: Marks recordings as uploaded after sync
//
//  Storage Strategy:
//  - Metadata: UserDefaults (lightweight, fast access)
//  - Audio files: Documents/recordings/ (encrypted with NSFileProtectionComplete)
//  - Max retention: 7 days (enforced by AutoDeletionService)
//
//  OPTIONAL FEATURE: Cloud Sync
//  - Can be extended to support iCloud backup
//  - NSUbiquitousKeyValueStore for metadata sync
//  - iCloud Drive for audio file backup
//

import Foundation
import Combine

/// Service for local storage of recordings and audio files
class AudioStorageService: ObservableObject {

    // MARK: - Published Properties

    /// All stored recordings (excluding soft-deleted)
    @Published var recordings: [Recording] = []

    /// Total storage used by recordings (bytes)
    @Published var totalStorageUsed: Int64 = 0

    // MARK: - Private Properties

    /// UserDefaults key for storing recordings array
    private let recordingsKey = "stored_recordings"

    /// UserDefaults instance
    private let userDefaults: UserDefaults

    /// FileManager instance
    private let fileManager: FileManager

    /// Recordings directory URL (Documents/recordings/)
    private var recordingsDirectoryURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("recordings")
    }

    // MARK: - Singleton

    /// Shared instance for global access
    static let shared = AudioStorageService()

    // MARK: - Initialization

    /// Initialize with custom UserDefaults (useful for testing)
    /// - Parameter userDefaults: UserDefaults instance to use
    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager

        // TODO: Ensure recordings directory exists
        // TODO: Load recordings from UserDefaults
        // TODO: Calculate total storage used
    }

    // MARK: - CRUD Operations

    /// Save a new recording
    /// - Parameter recording: Recording to save
    /// - Throws: StorageError if save fails
    func saveRecording(_ recording: Recording) throws {
        // TODO: Append to recordings array
        // TODO: Persist to UserDefaults
        // TODO: Update totalStorageUsed
        // TODO: Post notification for UI refresh
    }

    /// Load all recordings (excluding soft-deleted)
    /// - Returns: Array of active recordings
    func loadRecordings() -> [Recording] {
        // TODO: Load from UserDefaults
        // TODO: Decode JSON to [Recording]
        // TODO: Filter out soft-deleted (deletedAt != nil)
        // TODO: Sort by recordedAt descending
        // TODO: Update recordings property
        // TODO: Return array
        return []
    }

    /// Get a specific recording by ID
    /// - Parameter id: Recording UUID
    /// - Returns: Recording if found, nil otherwise
    func getRecording(by id: UUID) -> Recording? {
        // TODO: Search recordings array for matching ID
        return nil
    }

    /// Update an existing recording
    /// - Parameter recording: Recording with updated data
    /// - Throws: StorageError if recording not found
    func updateRecording(_ recording: Recording) throws {
        // TODO: Find index of recording in array
        // TODO: Replace with updated version
        // TODO: Persist to UserDefaults
        // TODO: Update recordings property
    }

    /// Soft delete a recording (sets deletedAt timestamp)
    /// - Parameter id: Recording UUID to delete
    /// - Throws: StorageError if recording not found
    func deleteRecording(by id: UUID) throws {
        // TODO: Find recording by ID
        // TODO: Set deletedAt to current time
        // TODO: Update in storage
        // TODO: Reload recordings (will filter out deleted)
    }

    /// Permanently delete a recording and its audio file
    /// - Parameter id: Recording UUID to permanently delete
    /// - Throws: StorageError if deletion fails
    func permanentlyDeleteRecording(by id: UUID) throws {
        // TODO: Find recording by ID
        // TODO: Delete audio file from disk
        // TODO: Remove from recordings array
        // TODO: Persist to UserDefaults
        // TODO: Update totalStorageUsed
    }

    // MARK: - File Management

    /// Check if audio file exists for a recording
    /// - Parameter recording: Recording to check
    /// - Returns: True if file exists
    func audioFileExists(for recording: Recording) -> Bool {
        // TODO: Get file URL from recording.filePath
        // TODO: Check fileManager.fileExists
        return false
    }

    /// Get file URL for a recording
    /// - Parameter recording: Recording to get URL for
    /// - Returns: Full file URL
    func getFileURL(for recording: Recording) -> URL {
        // TODO: Combine recordingsDirectoryURL with recording.filePath
        return recordingsDirectoryURL.appendingPathComponent(recording.filePath)
    }

    /// Get actual file size for a recording
    /// - Parameter recording: Recording to check
    /// - Returns: File size in bytes, or 0 if file doesn't exist
    func getFileSize(for recording: Recording) -> Int64 {
        // TODO: Get file URL
        // TODO: Get file attributes
        // TODO: Return file size
        return 0
    }

    /// Calculate total storage used by all recordings
    /// - Returns: Total bytes used
    func calculateTotalStorageUsed() -> Int64 {
        // TODO: Iterate through all recordings
        // TODO: Sum up file sizes
        // TODO: Update totalStorageUsed property
        // TODO: Return total
        return 0
    }

    /// Ensure recordings directory exists with proper encryption
    private func ensureRecordingsDirectoryExists() throws {
        // TODO: Check if directory exists
        // TODO: Create if needed with attributes
        // TODO: Set NSFileProtectionComplete for encryption
    }

    // MARK: - Batch Operations

    /// Get all recordings pending upload
    /// - Returns: Array of recordings where uploaded == false
    func getRecordingsPendingUpload() -> [Recording] {
        // TODO: Filter recordings where uploaded == false
        // TODO: Exclude soft-deleted
        // TODO: Sort by recordedAt ascending (oldest first)
        return []
    }

    /// Get all recordings eligible for auto-deletion
    /// - Returns: Array of recordings past autoDeleteAt
    func getRecordingsPendingDeletion() -> [Recording] {
        // TODO: Filter recordings where Date() >= autoDeleteAt
        // TODO: Return array
        return []
    }

    /// Mark recording as uploaded
    /// - Parameters:
    ///   - id: Recording UUID
    ///   - serverRecordingID: Server-assigned ID
    /// - Throws: StorageError if recording not found
    func markAsUploaded(id: UUID, serverRecordingID: UUID) throws {
        // TODO: Find recording by ID
        // TODO: Update uploaded = true
        // TODO: Update serverRecordingID
        // TODO: Persist changes
    }

    /// Mark recording as analyzed
    /// - Parameters:
    ///   - id: Recording UUID
    ///   - analysisID: Server-assigned analysis ID
    /// - Throws: StorageError if recording not found
    func markAsAnalyzed(id: UUID, analysisID: UUID) throws {
        // TODO: Find recording by ID
        // TODO: Update analyzed = true
        // TODO: Update analysisID
        // TODO: Persist changes
    }

    // MARK: - Storage Statistics

    /// Get storage statistics for UI display
    /// - Returns: StorageStats with counts and sizes
    func getStorageStats() -> StorageStats {
        // TODO: Count total recordings
        // TODO: Count pending upload
        // TODO: Count analyzed
        // TODO: Calculate total size
        // TODO: Return stats struct
        return StorageStats(
            totalRecordings: 0,
            pendingUpload: 0,
            analyzedCount: 0,
            totalSizeBytes: 0
        )
    }

    // MARK: - Private Helper Methods

    /// Persist recordings array to UserDefaults
    private func persistToUserDefaults() throws {
        // TODO: Encode recordings to JSON
        // TODO: Save to UserDefaults with recordingsKey
        // TODO: Throw error if encoding fails
    }

    /// Load recordings array from UserDefaults
    private func loadFromUserDefaults() -> [Recording] {
        // TODO: Get data from UserDefaults
        // TODO: Decode JSON to [Recording]
        // TODO: Return empty array if not found
        return []
    }

    // MARK: - OPTIONAL FEATURE: Cloud Sync

    /// Enable iCloud backup for recordings
    // func enableCloudBackup() {
    //     TODO: Configure NSUbiquitousKeyValueStore
    //     TODO: Enable iCloud Drive entitlement
    //     TODO: Sync metadata to iCloud
    //     TODO: Upload audio files to iCloud Drive
    // }

    /// Download recordings from iCloud
    // func syncFromCloud() async throws -> [Recording] {
    //     TODO: Fetch metadata from NSUbiquitousKeyValueStore
    //     TODO: Download missing audio files
    //     TODO: Merge with local recordings
    //     TODO: Resolve conflicts (keep newer version)
    // }

    // MARK: - Error Handling

    /// Storage errors
    enum StorageError: LocalizedError {
        case recordingNotFound
        case persistenceFailed(String)
        case fileNotFound
        case directoryCreationFailed
        case insufficientStorage

        var errorDescription: String? {
            switch self {
            case .recordingNotFound:
                return "Recording not found in storage."
            case .persistenceFailed(let reason):
                return "Failed to save recordings: \(reason)"
            case .fileNotFound:
                return "Audio file not found on disk."
            case .directoryCreationFailed:
                return "Failed to create recordings directory."
            case .insufficientStorage:
                return "Insufficient device storage available."
            }
        }
    }
}

// MARK: - Supporting Types

/// Storage statistics for UI display
struct StorageStats {
    let totalRecordings: Int
    let pendingUpload: Int
    let analyzedCount: Int
    let totalSizeBytes: Int64

    /// Human-readable total size
    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSizeBytes)
    }

    /// Percentage of recordings analyzed
    var analyzedPercentage: Int {
        guard totalRecordings > 0 else { return 0 }
        return (analyzedCount * 100) / totalRecordings
    }

    /// Percentage of recordings uploaded
    var uploadedPercentage: Int {
        guard totalRecordings > 0 else { return 0 }
        let uploaded = totalRecordings - pendingUpload
        return (uploaded * 100) / totalRecordings
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core storage implementation:
 1. Implement saveRecording() with UserDefaults persistence
 2. Implement loadRecordings() with JSON decoding
 3. Implement updateRecording() with error handling
 4. Implement delete operations (soft and permanent)
 5. Add file existence checks before operations

 TODO: File management:
 1. Create recordings directory on first launch
 2. Set NSFileProtectionComplete for encryption
 3. Handle file permission errors
 4. Verify file integrity after save

 TODO: Batch operations:
 1. Implement efficient filtering for pending uploads
 2. Implement auto-deletion query
 3. Add batch update methods for upload status
 4. Optimize storage stats calculation

 TODO: Testing:
 1. Write unit tests for CRUD operations
 2. Test UserDefaults persistence edge cases
 3. Test file deletion cleanup
 4. Test storage calculation accuracy
 5. Mock FileManager for isolated testing

 TODO: Performance optimizations:
 1. Cache recordings array in memory
 2. Use NotificationCenter for change broadcasts
 3. Lazy load file sizes only when needed
 4. Consider CoreData migration for 100+ recordings

 TODO: When implementing OPTIONAL FEATURE: Cloud Sync:
 1. Uncomment cloud sync methods
 2. Enable iCloud entitlement in Xcode
 3. Implement NSUbiquitousKeyValueStore sync
 4. Handle iCloud availability checks
 5. Implement conflict resolution (last-write-wins or manual)
 6. Test with multiple devices
 */
