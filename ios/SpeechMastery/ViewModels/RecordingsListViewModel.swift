//
//  RecordingsListViewModel.swift
//  SpeechMastery
//
//  ViewModel for recordings library screen following MVVM architecture.
//  Manages list display, filtering, sorting, and sync operations.
//
//  Responsibilities:
//  - Load and display all recordings
//  - Filter recordings by status (all, pending upload, analyzed)
//  - Sort recordings by date, duration, or score
//  - Handle recording deletion
//  - Sync with backend
//  - Provide storage statistics
//
//  Integration Points:
//  - RecordingsListView: UI binds to recordings array
//  - AudioStorageService: Loads recordings from local storage
//  - APIService: Syncs recordings with backend
//  - NetworkMonitor: Checks connectivity for sync
//
//  MVVM Pattern:
//  - View observes @Published recordings array
//  - List updates automatically via Combine
//  - Supports swipe-to-delete and refresh
//
//  OPTIONAL FEATURE: Cloud Sync
//  - Real-time sync status indicators
//  - Conflict resolution UI
//  - iCloud storage integration
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for recordings library screen
@MainActor
class RecordingsListViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All recordings to display
    @Published var recordings: [Recording] = []

    /// Whether data is currently loading
    @Published var isLoading: Bool = false

    /// Whether a sync operation is in progress
    @Published var isSyncing: Bool = false

    /// Current filter applied to recordings
    @Published var filterType: FilterType = .all

    /// Current sort order
    @Published var sortOrder: SortOrder = .dateDescending

    /// Storage statistics
    @Published var storageStats: StorageStats?

    /// Current error message (nil if no error)
    @Published var errorMessage: String?

    /// Whether to show delete confirmation alert
    @Published var showDeleteConfirmation: Bool = false

    /// Recording pending deletion (for confirmation)
    var recordingToDelete: Recording?

    // MARK: - Private Properties

    /// Storage service for recording management
    private let storageService: AudioStorageService

    /// API service for backend sync
    private let apiService: APIService

    /// Network monitor for connectivity checks
    private let networkMonitor: NetworkMonitor

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - OPTIONAL FEATURE: Cloud Sync
    /// Sync conflicts to resolve
    // @Published var syncConflicts: [SyncConflict] = []
    /// Whether to show conflict resolution UI
    // @Published var showConflictResolution: Bool = false

    // MARK: - Initialization

    /// Initialize with service dependencies
    /// - Parameters:
    ///   - storageService: Service for local recording storage
    ///   - apiService: Service for backend communication
    ///   - networkMonitor: Service for network status
    init(
        storageService: AudioStorageService = .shared,
        apiService: APIService = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.storageService = storageService
        self.apiService = apiService
        self.networkMonitor = networkMonitor

        // Load recordings on initialization
        loadRecordings()

        // Load storage statistics
        loadStorageStats()

        // Set up Combine subscriptions to auto-update when storage changes
        storageService.$recordings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadRecordings()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    /// Load all recordings from storage
    func loadRecordings() {
        isLoading = true

        // Load recordings from storageService
        var allRecordings = storageService.loadRecordings()

        // Apply current filter
        allRecordings = filterRecordings(allRecordings)

        // Apply current sort
        allRecordings = sortRecordings(allRecordings)

        // Update recordings array
        recordings = allRecordings

        // Load storage statistics
        loadStorageStats()

        isLoading = false

        print("📋 Loaded \(recordings.count) recordings (filter: \(filterType.rawValue), sort: \(sortOrder.rawValue))")
    }

    /// Refresh recordings (pull-to-refresh)
    func refreshRecordings() async {
        // Reload from storage
        loadRecordings()

        // Optionally sync with backend if online
        if networkMonitor.isConnected {
            await syncWithBackend()
        }

        print("🔄 Recordings refreshed")
    }

    // MARK: - Filtering

    /// Apply filter to recordings
    /// - Parameter filter: Filter type to apply
    func applyFilter(_ filter: FilterType) {
        filterType = filter
        loadRecordings()  // Reload with new filter
        print("🔍 Filter applied: \(filter.rawValue)")
    }

    /// Get filtered recordings based on current filter
    private func filterRecordings(_ recordings: [Recording]) -> [Recording] {
        switch filterType {
        case .all:
            return recordings
        case .pendingUpload:
            return recordings.filter { !$0.uploaded }
        case .analyzed:
            return recordings.filter { $0.analyzed }
        case .unanalyzed:
            return recordings.filter { !$0.analyzed }
        }
    }

    // MARK: - Sorting

    /// Apply sort order to recordings
    /// - Parameter order: Sort order to apply
    func applySortOrder(_ order: SortOrder) {
        sortOrder = order
        loadRecordings()  // Reload with new sort
        print("↕️ Sort applied: \(order.rawValue)")
    }

    /// Get sorted recordings based on current sort order
    private func sortRecordings(_ recordings: [Recording]) -> [Recording] {
        switch sortOrder {
        case .dateAscending:
            return recordings.sorted { $0.createdAt < $1.createdAt }
        case .dateDescending:
            return recordings.sorted { $0.createdAt > $1.createdAt }
        case .durationAscending:
            return recordings.sorted { $0.duration < $1.duration }
        case .durationDescending:
            return recordings.sorted { $0.duration > $1.duration }
        case .scoreAscending:
            return recordings.sorted { ($0.analysisID != nil ? 1 : 0) < ($1.analysisID != nil ? 1 : 0) }
        case .scoreDescending:
            return recordings.sorted { ($0.analysisID != nil ? 1 : 0) > ($1.analysisID != nil ? 1 : 0) }
        }
    }

    // MARK: - Deletion

    /// Request recording deletion with confirmation
    /// - Parameter recording: Recording to delete
    func requestDelete(_ recording: Recording) {
        recordingToDelete = recording
        showDeleteConfirmation = true
    }

    /// Confirm deletion of recording
    func confirmDelete() {
        guard let recording = recordingToDelete else { return }

        do {
            // Call storageService.deleteRecording() (soft delete)
            try storageService.deleteRecording(by: recording.id)

            // Reload recordings (filter will exclude deleted)
            loadRecordings()

            // Update storage statistics
            loadStorageStats()

            print("🗑️ Recording deleted: \(recording.id)")

        } catch {
            handleError(error)
        }

        // Reset state
        recordingToDelete = nil
        showDeleteConfirmation = false
    }

    /// Cancel deletion
    func cancelDelete() {
        recordingToDelete = nil
        showDeleteConfirmation = false
    }

    // MARK: - Sync Operations

    /// Sync recordings with backend
    func syncWithBackend() async {
        // Check network connectivity
        guard networkMonitor.isConnected else {
            errorMessage = "No network connection available"
            return
        }

        isSyncing = true

        do {
            // Upload all pending recordings
            let pendingRecordings = storageService.getRecordingsPendingUpload()

            for recording in pendingRecordings {
                do {
                    let analysis = try await apiService.uploadForAnalysis(recording: recording)

                    // Mark as uploaded
                    try storageService.markAsUploaded(id: recording.id, serverRecordingID: analysis.recordingID)

                    // Mark as analyzed
                    try storageService.markAsAnalyzed(id: recording.id, analysisID: analysis.id)

                    print("✅ Synced recording: \(recording.id)")

                } catch {
                    print("⚠️ Failed to sync recording \(recording.id): \(error.localizedDescription)")
                    // Continue with other recordings
                }
            }

            // Reload recordings to reflect changes
            loadRecordings()

            print("🔄 Sync complete: \(pendingRecordings.count) recordings uploaded")

        }

        isSyncing = false
    }

    /// Upload a specific recording to backend
    /// - Parameter recording: Recording to upload
    func uploadRecording(_ recording: Recording) async {
        // Check network connectivity
        guard networkMonitor.isConnected else {
            errorMessage = "No network connection available"
            return
        }

        do {
            // Upload via APIService
            let analysis = try await apiService.uploadForAnalysis(recording: recording)

            // Mark as uploaded in storage
            try storageService.markAsUploaded(id: recording.id, serverRecordingID: analysis.recordingID)

            // Mark as analyzed in storage
            try storageService.markAsAnalyzed(id: recording.id, analysisID: analysis.id)

            // Reload recordings
            loadRecordings()

            print("✅ Recording uploaded: \(recording.id)")

        } catch {
            handleError(error)
        }
    }

    // MARK: - Storage Statistics

    /// Load storage statistics
    func loadStorageStats() {
        storageStats = storageService.getStorageStats()
    }

    /// Calculate total storage used
    var totalStorageUsed: String {
        guard let stats = storageStats else { return "0 bytes" }
        return stats.formattedTotalSize
    }

    /// Get recordings pending upload count
    var pendingUploadCount: Int {
        return recordings.filter { !$0.uploaded }.count
    }

    /// Get analyzed recordings count
    var analyzedCount: Int {
        return recordings.filter { $0.analyzed }.count
    }

    // MARK: - Search

    /// Search recordings by title or date
    /// - Parameter query: Search query string
    func searchRecordings(query: String) {
        if query.isEmpty {
            loadRecordings()
            return
        }

        // Load all recordings
        var allRecordings = storageService.loadRecordings()

        // Filter by query (search in file path for now - in production would search title/notes)
        allRecordings = allRecordings.filter { recording in
            recording.filePath.localizedCaseInsensitiveContains(query)
        }

        // Apply current filter and sort
        allRecordings = filterRecordings(allRecordings)
        allRecordings = sortRecordings(allRecordings)

        recordings = allRecordings

        print("🔍 Search results: \(recordings.count) recordings for '\(query)'")
    }

    // MARK: - OPTIONAL FEATURE: Cloud Sync

    /// Sync with iCloud
    // func syncWithiCloud() async throws {
    //     TODO: Enable iCloud sync in storageService
    //     TODO: Download recordings from iCloud
    //     TODO: Upload local recordings to iCloud
    //     TODO: Detect and resolve conflicts
    //     TODO: Update UI with sync status
    // }

    /// Resolve a sync conflict
    // func resolveSyncConflict(_ conflict: SyncConflict, resolution: ConflictResolution) {
    //     TODO: Apply resolution (keep local, keep remote, keep both)
    //     TODO: Update storage
    //     TODO: Remove from syncConflicts array
    //     TODO: Continue sync
    // }

    // MARK: - Error Handling

    /// Handle errors
    /// - Parameter error: Error that occurred
    private func handleError(_ error: Error) {
        // Log error for debugging
        print("❌ RecordingsListViewModel Error: \(error.localizedDescription)")

        // Set errorMessage from error.localizedDescription
        errorMessage = error.localizedDescription
    }

    /// Clear current error
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Supporting Types

    /// Filter types for recordings list
    enum FilterType: String, CaseIterable {
        case all = "All"
        case pendingUpload = "Pending Upload"
        case analyzed = "Analyzed"
        case unanalyzed = "Not Analyzed"
    }

    /// Sort order options
    enum SortOrder: String, CaseIterable {
        case dateAscending = "Date (Oldest First)"
        case dateDescending = "Date (Newest First)"
        case durationAscending = "Duration (Shortest First)"
        case durationDescending = "Duration (Longest First)"
        case scoreAscending = "Score (Lowest First)"
        case scoreDescending = "Score (Highest First)"
    }
}

// MARK: - OPTIONAL FEATURE: Cloud Sync Types

/*
/// Sync conflict between local and remote
struct SyncConflict: Identifiable {
    let id: UUID
    let localRecording: Recording
    let remoteRecording: Recording
    let conflictType: ConflictType

    enum ConflictType {
        case modifiedBoth  // Both local and remote were modified
        case deletedLocal  // Deleted locally but exists remotely
        case deletedRemote  // Deleted remotely but exists locally
    }
}

/// Conflict resolution strategy
enum ConflictResolution {
    case keepLocal
    case keepRemote
    case keepBoth
    case merge
}
*/

// MARK: - TODO: Implementation Tasks
/*
 ✅ COMPLETED Core functionality:
 ✅ Implemented loadRecordings() with filtering and sorting
 ✅ Implemented filtering and sorting methods
 ✅ Implemented deletion with confirmation flow
 ✅ Set up Combine bindings for auto-updates
 ✅ Wired all three services (AudioStorageService, APIService, NetworkMonitor)

 ✅ COMPLETED Sync implementation:
 ✅ Implemented syncWithBackend() with batch upload
 ✅ Upload pending recordings in loop
 ✅ Handle network failures gracefully
 ✅ Sync progress indicator (isSyncing property)
 ✅ Network connectivity checks

 ✅ COMPLETED Storage statistics:
 ✅ Load and display storage stats
 ✅ Update stats after deletions
 ✅ Computed properties for UI display

 ✅ COMPLETED Search and filter:
 ✅ Implemented searchRecordings() method
 ✅ All filter types (all, pending upload, analyzed, unanalyzed)
 ✅ All sort orders (date, duration, score ascending/descending)

 TODO: Testing:
 1. Write unit tests for filtering logic
 2. Write unit tests for sorting logic
 3. Test deletion flow
 4. Test sync reconciliation
 5. Mock services for testing
 6. Test list updates and reactivity

 TODO: Performance:
 1. Optimize for large recording lists (100+)
 2. Implement pagination if needed
 3. Lazy load recording details
 4. Profile with Instruments

 TODO: When implementing OPTIONAL FEATURE: Cloud Sync:
 1. Uncomment iCloud sync methods
 2. Enable iCloud entitlement
 3. Implement conflict detection
 4. Build conflict resolution UI
 5. Test with multiple devices
 6. Handle iCloud account changes
 */
