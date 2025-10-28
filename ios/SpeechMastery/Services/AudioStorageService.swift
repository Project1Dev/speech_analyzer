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

        // Ensure recordings directory exists
        try? ensureRecordingsDirectoryExists()

        // Load recordings from UserDefaults
        self.recordings = loadFromUserDefaults()

        // Calculate total storage used
        self.totalStorageUsed = calculateTotalStorageUsed()

        print("💾 AudioStorageService initialized with \(recordings.count) recordings")
    }

    // MARK: - CRUD Operations

    /// Save a new recording
    /// - Parameter recording: Recording to save
    /// - Throws: StorageError if save fails
    func saveRecording(_ recording: Recording) throws {
        // Append to recordings array
        recordings.append(recording)

        // Persist to UserDefaults
        try persistToUserDefaults()

        // Update total storage
        totalStorageUsed = calculateTotalStorageUsed()

        print("💾 Saved recording: \(recording.id)")
    }

    /// Load all recordings (excluding soft-deleted)
    /// - Returns: Array of active recordings
    func loadRecordings() -> [Recording] {
        // Load from UserDefaults
        var allRecordings = loadFromUserDefaults()

        // Filter out soft-deleted
        allRecordings = allRecordings.filter { $0.deletedAt == nil }

        // Sort by recordedAt descending (newest first)
        allRecordings.sort { $0.createdAt > $1.createdAt }

        // Update published property
        DispatchQueue.main.async {
            self.recordings = allRecordings
        }

        return allRecordings
    }

    /// Get a specific recording by ID
    /// - Parameter id: Recording UUID
    /// - Returns: Recording if found, nil otherwise
    func getRecording(by id: UUID) -> Recording? {
        return recordings.first { $0.id == id }
    }

    /// Update an existing recording
    /// - Parameter recording: Recording with updated data
    /// - Throws: StorageError if recording not found
    func updateRecording(_ recording: Recording) throws {
        guard let index = recordings.firstIndex(where: { $0.id == recording.id }) else {
            throw StorageError.recordingNotFound
        }

        // Replace with updated version
        recordings[index] = recording

        // Persist to UserDefaults
        try persistToUserDefaults()

        print("💾 Updated recording: \(recording.id)")
    }

    /// Soft delete a recording (sets deletedAt timestamp)
    /// - Parameter id: Recording UUID to delete
    /// - Throws: StorageError if recording not found
    func deleteRecording(by id: UUID) throws {
        guard var recording = getRecording(by: id) else {
            throw StorageError.recordingNotFound
        }

        // Set deletedAt to current time
        recording.deletedAt = Date()

        // Update in storage
        try updateRecording(recording)

        // Reload recordings (will filter out deleted)
        _ = loadRecordings()

        print("🗑️ Soft deleted recording: \(id)")
    }

    /// Permanently delete a recording and its audio file
    /// - Parameter id: Recording UUID to permanently delete
    /// - Throws: StorageError if deletion fails
    func permanentlyDeleteRecording(by id: UUID) throws {
        guard let recording = getRecording(by: id) else {
            throw StorageError.recordingNotFound
        }

        // Delete audio file from disk
        let fileURL = getFileURL(for: recording)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }

        // Remove from recordings array
        recordings.removeAll { $0.id == id }

        // Persist to UserDefaults
        try persistToUserDefaults()

        // Update total storage
        totalStorageUsed = calculateTotalStorageUsed()

        print("🗑️ Permanently deleted recording: \(id)")
    }

    // MARK: - File Management

    /// Check if audio file exists for a recording
    /// - Parameter recording: Recording to check
    /// - Returns: True if file exists
    func audioFileExists(for recording: Recording) -> Bool {
        let fileURL = getFileURL(for: recording)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Get file URL for a recording
    /// - Parameter recording: Recording to get URL for
    /// - Returns: Full file URL
    func getFileURL(for recording: Recording) -> URL {
        return recordingsDirectoryURL.appendingPathComponent(recording.filePath)
    }

    /// Get actual file size for a recording
    /// - Parameter recording: Recording to check
    /// - Returns: File size in bytes, or 0 if file doesn't exist
    func getFileSize(for recording: Recording) -> Int64 {
        let fileURL = getFileURL(for: recording)

        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }

        return fileSize
    }

    /// Get audio data for a recording
    /// - Parameter recording: Recording to get data for
    /// - Returns: Audio file data, or nil if file doesn't exist
    func getAudioData(for recording: Recording) -> Data? {
        let fileURL = getFileURL(for: recording)
        return try? Data(contentsOf: fileURL)
    }

    /// Calculate total storage used by all recordings
    /// - Returns: Total bytes used
    func calculateTotalStorageUsed() -> Int64 {
        let total = recordings.reduce(0) { sum, recording in
            sum + getFileSize(for: recording)
        }

        DispatchQueue.main.async {
            self.totalStorageUsed = total
        }

        return total
    }

    /// Ensure recordings directory exists with proper encryption
    private func ensureRecordingsDirectoryExists() throws {
        let url = recordingsDirectoryURL

        // Check if directory exists
        if !fileManager.fileExists(atPath: url.path) {
            // Create directory with encryption
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete]
            )
            print("📁 Created recordings directory with encryption")
        }
    }

    // MARK: - Batch Operations

    /// Get all recordings pending upload
    /// - Returns: Array of recordings where uploaded == false
    func getRecordingsPendingUpload() -> [Recording] {
        return recordings
            .filter { $0.deletedAt == nil && !$0.uploaded }
            .sorted { $0.createdAt < $1.createdAt } // Oldest first
    }

    /// Get all recordings eligible for auto-deletion
    /// - Returns: Array of recordings past autoDeleteAt
    func getRecordingsPendingDeletion() -> [Recording] {
        let now = Date()
        return recordings.filter { recording in
            return now >= recording.autoDeleteAt
        }
    }

    /// Mark recording as uploaded
    /// - Parameters:
    ///   - id: Recording UUID
    ///   - serverRecordingID: Server-assigned ID
    /// - Throws: StorageError if recording not found
    func markAsUploaded(id: UUID, serverRecordingID: UUID) throws {
        guard var recording = getRecording(by: id) else {
            throw StorageError.recordingNotFound
        }

        recording.uploaded = true
        recording.serverRecordingID = serverRecordingID

        try updateRecording(recording)

        print("✅ Marked recording as uploaded: \(id)")
    }

    /// Mark recording as analyzed
    /// - Parameters:
    ///   - id: Recording UUID
    ///   - analysisID: Server-assigned analysis ID
    /// - Throws: StorageError if recording not found
    func markAsAnalyzed(id: UUID, analysisID: UUID) throws {
        guard var recording = getRecording(by: id) else {
            throw StorageError.recordingNotFound
        }

        recording.analyzed = true
        recording.analysisID = analysisID

        try updateRecording(recording)

        print("✅ Marked recording as analyzed: \(id)")
    }

    // MARK: - Storage Statistics

    /// Get storage statistics for UI display
    /// - Returns: StorageStats with counts and sizes
    func getStorageStats() -> StorageStats {
        let totalRecordings = recordings.count
        let pendingUpload = getRecordingsPendingUpload().count
        let analyzedCount = recordings.filter { $0.analyzed }.count
        let totalSize = calculateTotalStorageUsed()

        return StorageStats(
            totalRecordings: totalRecordings,
            pendingUpload: pendingUpload,
            analyzedCount: analyzedCount,
            totalSizeBytes: totalSize
        )
    }

    // MARK: - Private Helper Methods

    /// Persist recordings array to UserDefaults
    private func persistToUserDefaults() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(recordings)
            userDefaults.set(data, forKey: recordingsKey)
        } catch {
            throw StorageError.persistenceFailed(error.localizedDescription)
        }
    }

    /// Load recordings array from UserDefaults
    private func loadFromUserDefaults() -> [Recording] {
        guard let data = userDefaults.data(forKey: recordingsKey) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode([Recording].self, from: data)
        } catch {
            print("⚠️ Failed to decode recordings: \(error.localizedDescription)")
            return []
        }
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
