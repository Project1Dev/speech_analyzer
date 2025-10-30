# iOS App Implementation Plan

**Project**: Speech Mastery iOS App
**Goal**: Complete MVP - Record → Upload → Display Analysis Pipeline
**Status**: Phase 1 (Core Services) - Ready to Start

---

## Current Status Summary

### ✅ Completed (UI & Architecture)
- [x] All 6 Views (ContentView, RecordingView, AnalysisResultView, RecordingsListView, DailyReportView, SettingsView)
- [x] All 4 Models (Recording, AnalysisResult, Report, AudioSettings)
- [x] MVVM architecture properly structured
- [x] AudioRecordingService (90% complete - working)
- [x] AudioStorageService (90% complete - working)
- [x] PrivacyManager (85% complete - mostly working)
- [x] Constants and FeatureFlags configuration
- [x] XcodeGen project configuration

### 🔨 In Progress (Needs Completion)
- [ ] APIService - fetch endpoints (40% complete)
- [ ] RecordingViewModel - backend integration
- [ ] AnalysisViewModel - backend integration
- [ ] RecordingsListViewModel - backend sync

### ⏳ Not Started
- [ ] NetworkMonitor (15% - skeleton only)
- [ ] CacheService (20% - skeleton only)
- [ ] AutoDeletionService (15% - skeleton only)
- [ ] SettingsViewModel (20% - skeleton only)
- [ ] End-to-end testing
- [ ] Error handling polish

---

## Phase 1: Core Services - MVP Critical Path

**Goal**: Complete backend integration so iOS app can record → upload → display analysis

**Estimated Time**: 6-8 hours
**Priority**: P0 (Critical for MVP)

---

### 1.1 APIService Completion

**Priority**: P0 | **Complexity**: Medium | **Time**: 2-3 hours

#### Task 1.1.1: Review Current APIService Implementation
- [ ] Open `ios/SpeechMastery/Services/APIService.swift`
- [ ] Review `uploadForAnalysis()` method (already implemented)
- [ ] Review `buildMultipartRequest()` helper (already implemented)
- [ ] Review `checkHealth()` method (already implemented)
- [ ] Identify missing methods: `fetchAnalysis()`, `fetchRecordings()`, `deleteRecording()`
- [ ] Note authentication header setup (already working)

**Success Criteria**: Understand current implementation

**Files**: `ios/SpeechMastery/Services/APIService.swift`

---

#### Task 1.1.2: Implement fetchAnalysis(recordingId:)
- [ ] Open `ios/SpeechMastery/Services/APIService.swift`
- [ ] Add method signature: `func fetchAnalysis(recordingId: UUID) async throws -> AnalysisResult`
- [ ] Build URL: `baseURL + "/api/v1/recordings/\(recordingId)/analysis"`
- [ ] Create GET request with auth header
- [ ] Set timeout: 10 seconds
- [ ] Decode response to `AnalysisResult`
- [ ] Add error handling for:
  - 404 Not Found (analysis not ready)
  - 401 Unauthorized
  - Network errors
  - Decode errors
- [ ] Add logging for debugging

**Success Criteria**: Method compiles and can be called

**Files Modified**: `ios/SpeechMastery/Services/APIService.swift`

**Code Structure**:
```swift
func fetchAnalysis(recordingId: UUID) async throws -> AnalysisResult {
    let url = URL(string: "\(API.baseURL)/api/v1/recordings/\(recordingId)/analysis")!
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "GET"
    request.setValue("Bearer \(API.authToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
        throw APIError.httpError(statusCode: httpResponse.statusCode)
    }

    return try decoder.decode(AnalysisResult.self, from: data)
}
```

---

#### Task 1.1.3: Implement fetchRecordings()
- [ ] Add method signature: `func fetchRecordings(skip: Int = 0, limit: Int = 50) async throws -> [Recording]`
- [ ] Build URL: `baseURL + "/api/v1/recordings?skip=\(skip)&limit=\(limit)"`
- [ ] Create GET request with auth header
- [ ] Decode response (note: backend returns `{recordings: [...], total: X}`)
- [ ] Map backend recording format to iOS Recording model
- [ ] Handle pagination parameters
- [ ] Add error handling

**Success Criteria**: Can fetch list of recordings from backend

**Files Modified**: `ios/SpeechMastery/Services/APIService.swift`

**Note**: Backend response format needs to be mapped:
```json
{
  "recordings": [...],
  "total": 10
}
```

---

#### Task 1.1.4: Implement deleteRecording(id:)
- [ ] Add method signature: `func deleteRecording(id: UUID) async throws`
- [ ] Build URL: `baseURL + "/api/v1/recordings/\(id)"`
- [ ] Create DELETE request with auth header
- [ ] Check for 200 or 204 status code
- [ ] Add error handling for:
  - 404 Not Found
  - 403 Forbidden (wrong user)
  - Network errors
- [ ] Add logging

**Success Criteria**: Can delete recording from backend

**Files Modified**: `ios/SpeechMastery/Services/APIService.swift`

---

#### Task 1.1.5: Define APIError Enum
- [ ] Create comprehensive error enum:
  - `invalidURL`
  - `invalidResponse`
  - `httpError(statusCode: Int)`
  - `decodingError(Error)`
  - `encodingError(Error)`
  - `networkError(Error)`
  - `unauthorized`
  - `notFound`
  - `serverError`
- [ ] Add `LocalizedError` conformance for user-friendly messages
- [ ] Add error descriptions for each case

**Success Criteria**: Errors are typed and user-friendly

**Files Modified**: `ios/SpeechMastery/Services/APIService.swift`

**Code Structure**:
```swift
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to parse server response"
        case .networkError:
            return "Network connection failed"
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error occurred"
        }
    }
}
```

---

#### Task 1.1.6: Add Request Retry Logic
- [ ] Create helper method: `func performRequest<T: Decodable>(_ request: URLRequest, retries: Int = 3) async throws -> T`
- [ ] Implement exponential backoff (1s, 2s, 4s)
- [ ] Retry on network errors only (not 4xx errors)
- [ ] Log retry attempts
- [ ] Return error after max retries

**Success Criteria**: Network failures retry automatically

**Files Modified**: `ios/SpeechMastery/Services/APIService.swift`

---

#### Task 1.1.7: Update Constants for Dual-VM Setup
- [ ] Open `ios/SpeechMastery/Utilities/Constants.swift`
- [ ] Verify `baseURL` is set to Linux VM IP (from backend/show_api_url.sh)
- [ ] Update if needed: `static let baseURL = "http://192.168.244.129:8000"`
- [ ] Add comment about dual-VM setup
- [ ] Document how to find Linux VM IP

**Success Criteria**: Constants configured for dual-VM environment

**Files Modified**: `ios/SpeechMastery/Utilities/Constants.swift`

---

### 1.2 NetworkMonitor Implementation

**Priority**: P0 | **Complexity**: Low | **Time**: 1-2 hours

#### Task 1.2.1: Review Current NetworkMonitor Skeleton
- [ ] Open `ios/SpeechMastery/Services/NetworkMonitor.swift`
- [ ] Review published properties (isConnected, connectionType, isExpensive, isConstrained)
- [ ] Note that NWPathMonitor is imported but not used
- [ ] Identify TODO comments

**Success Criteria**: Understand current skeleton

**Files**: `ios/SpeechMastery/Services/NetworkMonitor.swift`

---

#### Task 1.2.2: Implement startMonitoring()
- [ ] Create `private let monitor = NWPathMonitor()`
- [ ] Create `private let queue = DispatchQueue(label: "NetworkMonitor")`
- [ ] Implement `startMonitoring()`:
  - Set monitor.pathUpdateHandler callback
  - Update published properties on main thread
  - Start monitor on background queue
- [ ] Update `isConnected` based on path.status
- [ ] Update `connectionType` (WiFi, cellular, wired, other)
- [ ] Update `isExpensive` based on path.isExpensive
- [ ] Update `isConstrained` based on path.isConstrained

**Success Criteria**: Monitor detects network changes

**Files Modified**: `ios/SpeechMastery/Services/NetworkMonitor.swift`

**Code Structure**:
```swift
private let monitor = NWPathMonitor()
private let queue = DispatchQueue(label: "com.speechmastery.networkmonitor")

func startMonitoring() {
    monitor.pathUpdateHandler = { [weak self] path in
        DispatchQueue.main.async {
            self?.isConnected = path.status == .satisfied
            self?.isExpensive = path.isExpensive
            self?.isConstrained = path.isConstrained

            if path.usesInterfaceType(.wifi) {
                self?.connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                self?.connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                self?.connectionType = .wired
            } else {
                self?.connectionType = .other
            }
        }
    }
    monitor.start(queue: queue)
}
```

---

#### Task 1.2.3: Implement stopMonitoring()
- [ ] Implement `stopMonitoring()` method
- [ ] Call `monitor.cancel()`
- [ ] Reset published properties to defaults
- [ ] Add guard to prevent double-stop

**Success Criteria**: Can stop monitoring cleanly

**Files Modified**: `ios/SpeechMastery/Services/NetworkMonitor.swift`

---

#### Task 1.2.4: Add ConnectionType Enum
- [ ] Define enum: `enum ConnectionType: String { case wifi, cellular, wired, other, none }`
- [ ] Add computed property for user-friendly description
- [ ] Update `@Published var connectionType`

**Success Criteria**: Connection type properly categorized

**Files Modified**: `ios/SpeechMastery/Services/NetworkMonitor.swift`

---

#### Task 1.2.5: Add Initialization
- [ ] Make NetworkMonitor a singleton: `static let shared = NetworkMonitor()`
- [ ] Add `private init()` to prevent external instantiation
- [ ] Auto-start monitoring in init (or require explicit call)
- [ ] Add deinit to stop monitoring

**Success Criteria**: NetworkMonitor ready to use

**Files Modified**: `ios/SpeechMastery/Services/NetworkMonitor.swift`

---

#### Task 1.2.6: Test Network Monitoring
- [ ] Run app on simulator
- [ ] Check initial connection status
- [ ] Turn off WiFi in Mac settings → verify `isConnected = false`
- [ ] Turn on WiFi → verify `isConnected = true`
- [ ] Print connection type to console
- [ ] Verify updates happen in real-time

**Success Criteria**: Network status reflects reality

---

### 1.3 AnalysisViewModel Backend Integration

**Priority**: P0 | **Complexity**: Medium | **Time**: 2-3 hours

#### Task 1.3.1: Review Current AnalysisViewModel
- [ ] Open `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`
- [ ] Review `uploadForAnalysis()` method (partially implemented)
- [ ] Review `loadAnalysis()` method (needs backend call)
- [ ] Review published properties: `analysisResult`, `isLoading`, `error`
- [ ] Identify integration points

**Success Criteria**: Understand current state

**Files**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

---

#### Task 1.3.2: Complete uploadForAnalysis()
- [ ] Locate `uploadForAnalysis(recording: Recording)` method
- [ ] Add error handling with try-catch
- [ ] Set `isLoading = true` at start
- [ ] Set `isLoading = false` in defer block
- [ ] Call `APIService.shared.uploadForAnalysis(recording: recording)`
- [ ] Handle response:
  - If immediate analysis: store in `analysisResult`
  - If async (returns recording ID): poll for result
- [ ] Update `error` on failure
- [ ] Add loading progress if possible

**Success Criteria**: Upload initiates and handles response

**Files Modified**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

---

#### Task 1.3.3: Implement loadAnalysis(recordingId:)
- [ ] Locate or create `loadAnalysis(recordingId: UUID)` method
- [ ] Set `isLoading = true`
- [ ] Call `APIService.shared.fetchAnalysis(recordingId: recordingId)`
- [ ] Store result in `@Published var analysisResult: AnalysisResult?`
- [ ] Handle errors:
  - 404 → "Analysis not ready yet"
  - Network error → "Connection failed"
  - Other → Generic error
- [ ] Set `isLoading = false`
- [ ] Update `error` message if needed

**Success Criteria**: Can fetch and display analysis

**Files Modified**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

---

#### Task 1.3.4: Add Polling for Async Analysis
- [ ] Create method: `pollForAnalysis(recordingId: UUID, maxAttempts: Int = 20)`
- [ ] Poll every 3 seconds
- [ ] Call `fetchAnalysis()` each iteration
- [ ] If 404, wait and retry
- [ ] If 200, store result and stop polling
- [ ] If max attempts reached, show timeout error
- [ ] Add `@Published var uploadProgress: Double?` for UI

**Success Criteria**: Can wait for backend to complete analysis

**Files Modified**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

**Code Structure**:
```swift
func pollForAnalysis(recordingId: UUID, maxAttempts: Int = 20) async {
    for attempt in 1...maxAttempts {
        do {
            let result = try await APIService.shared.fetchAnalysis(recordingId: recordingId)
            await MainActor.run {
                self.analysisResult = result
                self.isLoading = false
            }
            return
        } catch APIError.notFound {
            // Analysis not ready yet, wait and retry
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            continue
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch analysis: \(error.localizedDescription)"
                self.isLoading = false
            }
            return
        }
    }

    // Max attempts reached
    await MainActor.run {
        self.error = "Analysis timeout - please try again later"
        self.isLoading = false
    }
}
```

---

#### Task 1.3.5: Add Upload Consent Flow
- [ ] Review `requestUploadConsent()` method (already implemented?)
- [ ] Ensure it checks `PrivacyManager.shared.getUploadConsent()`
- [ ] If consent not granted, show consent sheet
- [ ] Only proceed with upload after consent
- [ ] Store consent in UserDefaults

**Success Criteria**: User must consent before upload

**Files Modified**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

---

#### Task 1.3.6: Handle Network Offline State
- [ ] Check `NetworkMonitor.shared.isConnected` before upload
- [ ] If offline, show error: "No internet connection"
- [ ] Save recording for later upload
- [ ] Add "Retry" button to error state
- [ ] Queue failed uploads for automatic retry when online

**Success Criteria**: Graceful offline handling

**Files Modified**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

---

### 1.4 RecordingsListViewModel Backend Integration

**Priority**: P0 | **Complexity**: Medium | **Time**: 2 hours

#### Task 1.4.1: Review Current RecordingsListViewModel
- [ ] Open `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`
- [ ] Review `loadRecordings()` (loads from local storage)
- [ ] Review `syncWithBackend()` (needs implementation)
- [ ] Review `uploadRecording()` (needs backend call)
- [ ] Identify what needs backend integration

**Success Criteria**: Understand current implementation

**Files**: `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`

---

#### Task 1.4.2: Implement syncWithBackend()
- [ ] Locate `syncWithBackend()` method
- [ ] Check network status first
- [ ] Fetch recordings from backend: `APIService.shared.fetchRecordings()`
- [ ] Compare with local recordings
- [ ] Merge: keep recordings that exist on backend OR locally
- [ ] Update `uploaded` flag for synced recordings
- [ ] Store updated recordings locally
- [ ] Update UI
- [ ] Handle errors gracefully

**Success Criteria**: Local and server data synced

**Files Modified**: `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`

---

#### Task 1.4.3: Implement uploadRecording()
- [ ] Locate or create `uploadRecording(_ recording: Recording)`
- [ ] Check if already uploaded (skip if `recording.uploaded == true`)
- [ ] Call `APIService.shared.uploadForAnalysis(recording: recording)`
- [ ] Update recording with `uploaded = true` and `serverRecordingID`
- [ ] Save updated recording locally
- [ ] Handle errors (network, server, etc.)
- [ ] Add retry logic

**Success Criteria**: Can upload individual recording

**Files Modified**: `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`

---

#### Task 1.4.4: Add Auto-Upload for New Recordings
- [ ] Subscribe to AudioStorageService for new recordings
- [ ] When new recording saved, automatically upload if:
  - User has granted upload consent
  - Network is connected
  - WiFiOnlyUploads is false OR connection is WiFi
- [ ] Show upload progress in UI
- [ ] Handle upload failures by queuing for retry

**Success Criteria**: New recordings auto-upload

**Files Modified**: `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`

---

#### Task 1.4.5: Implement Delete with Backend Sync
- [ ] Update `confirmDelete()` method
- [ ] If recording is uploaded, also delete from backend
- [ ] Call `APIService.shared.deleteRecording(id: recording.serverRecordingID)`
- [ ] Delete locally regardless of backend success
- [ ] Handle errors (show warning if backend delete fails)

**Success Criteria**: Delete syncs with backend

**Files Modified**: `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`

---

#### Task 1.4.6: Add Sync Status Indicators
- [ ] Add `@Published var isSyncing: Bool = false`
- [ ] Add `@Published var lastSyncTime: Date?`
- [ ] Update these during sync operations
- [ ] Show in UI (e.g., "Last synced 2 minutes ago")
- [ ] Add pull-to-refresh for manual sync

**Success Criteria**: User can see sync status

**Files Modified**: `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`

---

## Phase 2: Support Services

**Goal**: Complete CacheService, AutoDeletionService, SettingsViewModel
**Estimated Time**: 4-5 hours
**Priority**: P1 (Important for robustness)

---

### 2.1 CacheService Implementation

**Priority**: P1 | **Complexity**: Medium | **Time**: 1.5-2 hours

#### Task 2.1.1: Review CacheService Skeleton
- [ ] Open `ios/SpeechMastery/Services/CacheService.swift`
- [ ] Review current structure (skeleton only)
- [ ] Identify missing methods

**Success Criteria**: Understand what needs to be built

**Files**: `ios/SpeechMastery/Services/CacheService.swift`

---

#### Task 2.1.2: Set Up Cache Directory
- [ ] Create cache directory in Documents/Cache/
- [ ] Add method: `private func getCacheDirectory() -> URL`
- [ ] Create directory if it doesn't exist
- [ ] Return URL to cache directory

**Success Criteria**: Cache directory exists

**Files Modified**: `ios/SpeechMastery/Services/CacheService.swift`

---

#### Task 2.1.3: Implement NSCache for In-Memory Caching
- [ ] Create `private let memoryCache = NSCache<NSString, AnalysisResult>()`
- [ ] Set cache limits: `memoryCache.countLimit = 50`
- [ ] Set cache size: `memoryCache.totalCostLimit = 100 * 1024 * 1024` (100MB)
- [ ] Add eviction policy (LRU automatic with NSCache)

**Success Criteria**: In-memory cache configured

**Files Modified**: `ios/SpeechMastery/Services/CacheService.swift`

---

#### Task 2.1.4: Implement cacheAnalysis()
- [ ] Create method: `func cacheAnalysis(_ analysis: AnalysisResult, forRecordingId id: UUID)`
- [ ] Store in memory cache: `memoryCache.setObject(analysis, forKey: id.uuidString as NSString)`
- [ ] Also write to disk as JSON file in cache directory
- [ ] Use `JSONEncoder` to encode
- [ ] Write to file: `cacheDirectory/\(id).json`
- [ ] Handle encoding errors

**Success Criteria**: Analysis cached in memory and disk

**Files Modified**: `ios/SpeechMastery/Services/CacheService.swift`

---

#### Task 2.1.5: Implement getCachedAnalysis()
- [ ] Create method: `func getCachedAnalysis(forRecordingId id: UUID) -> AnalysisResult?`
- [ ] First check memory cache
- [ ] If found, return immediately
- [ ] If not in memory, check disk cache
- [ ] Read file from disk, decode JSON
- [ ] If successful, add to memory cache and return
- [ ] Return nil if not found

**Success Criteria**: Can retrieve cached analysis

**Files Modified**: `ios/SpeechMastery/Services/CacheService.swift`

---

#### Task 2.1.6: Implement clearCache()
- [ ] Create method: `func clearCache()`
- [ ] Remove all objects from memory cache
- [ ] Delete all files in cache directory
- [ ] Update published cache size to 0
- [ ] Log cache clear action

**Success Criteria**: Cache can be cleared

**Files Modified**: `ios/SpeechMastery/Services/CacheService.swift`

---

#### Task 2.1.7: Implement Cache Size Tracking
- [ ] Add `@Published var currentCacheSize: Int64 = 0`
- [ ] Create method: `func calculateCacheSize() -> Int64`
- [ ] Sum file sizes in cache directory
- [ ] Update published property
- [ ] Call on app launch and after cache operations

**Success Criteria**: Cache size visible

**Files Modified**: `ios/SpeechMastery/Services/CacheService.swift`

---

#### Task 2.1.8: Add Cache Expiration
- [ ] Add expiration time: 7 days
- [ ] Store timestamp in cache file metadata
- [ ] In `getCachedAnalysis()`, check file age
- [ ] If expired, delete file and return nil
- [ ] Add method: `func cleanExpiredCache()`

**Success Criteria**: Old cache files auto-expire

**Files Modified**: `ios/SpeechMastery/Services/CacheService.swift`

---

### 2.2 AutoDeletionService Implementation

**Priority**: P1 | **Complexity**: Medium | **Time**: 2-3 hours

#### Task 2.2.1: Review AutoDeletionService Skeleton
- [ ] Open `ios/SpeechMastery/Services/AutoDeletionService.swift`
- [ ] Review published properties
- [ ] Identify TODO comments

**Success Criteria**: Understand current structure

**Files**: `ios/SpeechMastery/Services/AutoDeletionService.swift`

---

#### Task 2.2.2: Implement Initialization
- [ ] Make singleton: `static let shared = AutoDeletionService()`
- [ ] Inject AudioStorageService dependency
- [ ] Load settings from UserDefaults (retentionDays, isEnabled)
- [ ] Set up Combine subscriptions

**Success Criteria**: Service initialized

**Files Modified**: `ios/SpeechMastery/Services/AutoDeletionService.swift`

---

#### Task 2.2.3: Implement performCleanup()
- [ ] Create method: `func performCleanup()`
- [ ] Load all recordings from AudioStorageService
- [ ] Filter recordings where `shouldBeDeleted()` returns true
- [ ] Delete each old recording:
  - Delete audio file from disk
  - Remove from AudioStorageService
- [ ] Update `@Published var totalRecordingsDeleted`
- [ ] Update `@Published var lastCleanupTime`
- [ ] Log cleanup results

**Success Criteria**: Old recordings deleted

**Files Modified**: `ios/SpeechMastery/Services/AutoDeletionService.swift`

---

#### Task 2.2.4: Schedule Background Task
- [ ] Import `BackgroundTasks`
- [ ] Register task identifier: `com.speechmastery.cleanup`
- [ ] Add task identifier to Info.plist under `BGTaskSchedulerPermittedIdentifiers`
- [ ] Register task handler in init:
  ```swift
  BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.speechmastery.cleanup", using: nil) { task in
      self.handleCleanupTask(task: task as! BGAppRefreshTask)
  }
  ```
- [ ] Schedule task daily: `scheduleCleanupTask()`

**Success Criteria**: Background task registered

**Files Modified**:
- `ios/SpeechMastery/Services/AutoDeletionService.swift`
- `ios/SpeechMastery/Info.plist`

---

#### Task 2.2.5: Implement Background Task Handler
- [ ] Create method: `private func handleCleanupTask(task: BGAppRefreshTask)`
- [ ] Perform cleanup in background
- [ ] Call `performCleanup()`
- [ ] Set `task.expirationHandler` for cleanup cancellation
- [ ] Mark task as completed: `task.setTaskCompleted(success: true)`
- [ ] Schedule next task

**Success Criteria**: Task runs in background

**Files Modified**: `ios/SpeechMastery/Services/AutoDeletionService.swift`

---

#### Task 2.2.6: Implement Manual Cleanup Trigger
- [ ] Create method: `func triggerManualCleanup()`
- [ ] Call `performCleanup()` immediately
- [ ] Show result to user (count of deleted recordings)
- [ ] Update UI

**Success Criteria**: User can trigger cleanup manually

**Files Modified**: `ios/SpeechMastery/Services/AutoDeletionService.swift`

---

#### Task 2.2.7: Add Pending Deletion Count
- [ ] Implement `@Published var pendingDeletionCount: Int`
- [ ] Create method: `func updatePendingDeletionCount()`
- [ ] Count recordings where `shouldBeDeleted()` is true
- [ ] Update published property
- [ ] Call periodically (every time app enters foreground)

**Success Criteria**: User can see pending deletions

**Files Modified**: `ios/SpeechMastery/Services/AutoDeletionService.swift`

---

### 2.3 SettingsViewModel Implementation

**Priority**: P1 | **Complexity**: Low | **Time**: 1-2 hours

#### Task 2.3.1: Review SettingsViewModel Skeleton
- [ ] Open `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`
- [ ] Review published properties
- [ ] Identify TODO methods

**Success Criteria**: Understand current state

**Files**: `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`

---

#### Task 2.3.2: Implement loadSettings()
- [ ] Create method: `func loadSettings()`
- [ ] Load from UserDefaults:
  - `audioQuality`: AudioSettings.loadUserDefault()
  - `uploadConsentGranted`: PrivacyManager.shared.getUploadConsent()
  - `wiFiOnlyUploads`: UserDefaults bool
  - `autoDeleteEnabled`: UserDefaults bool
  - `retentionDays`: UserDefaults int
- [ ] Update @Published properties
- [ ] Call in init()

**Success Criteria**: Settings loaded on launch

**Files Modified**: `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`

---

#### Task 2.3.3: Implement saveSettings()
- [ ] Create method: `func saveSettings()`
- [ ] Save to UserDefaults:
  - Save audio quality
  - Save privacy settings
  - Save auto-delete settings
- [ ] Post notification for settings change
- [ ] Log save action

**Success Criteria**: Settings persist

**Files Modified**: `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`

---

#### Task 2.3.4: Implement updateAudioQuality()
- [ ] Create method: `func updateAudioQuality(_ quality: AudioSettings)`
- [ ] Update `@Published var audioQuality`
- [ ] Save to UserDefaults: `quality.saveAsDefault()`
- [ ] Show confirmation to user

**Success Criteria**: Audio quality updates

**Files Modified**: `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`

---

#### Task 2.3.5: Implement Privacy Setting Toggles
- [ ] Create method: `func toggleUploadConsent()`
- [ ] Update PrivacyManager
- [ ] Update `@Published var uploadConsentGranted`
- [ ] Save to UserDefaults
- [ ] Create method: `func toggleWiFiOnlyUploads()`
- [ ] Similar flow for WiFi-only setting

**Success Criteria**: Privacy toggles work

**Files Modified**: `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`

---

#### Task 2.3.6: Implement Storage Management
- [ ] Create method: `func clearCache()`
- [ ] Call `CacheService.shared.clearCache()`
- [ ] Update storage stats
- [ ] Show confirmation
- [ ] Create method: `func deleteAllRecordings()`
- [ ] Show confirmation alert
- [ ] Delete all recordings from AudioStorageService
- [ ] Update stats

**Success Criteria**: Storage management works

**Files Modified**: `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`

---

#### Task 2.3.7: Implement loadStatistics()
- [ ] Create method: `func loadStatistics()`
- [ ] Calculate total recordings: from AudioStorageService
- [ ] Calculate storage used: from AudioStorageService.calculateTotalStorageUsed()
- [ ] Calculate cache size: from CacheService
- [ ] Update @Published properties
- [ ] Call on view appear

**Success Criteria**: Stats displayed correctly

**Files Modified**: `ios/SpeechMastery/ViewModels/SettingsViewModel.swift`

---

## Phase 3: Polish & UX

**Goal**: Loading states, error handling, testing
**Estimated Time**: 4-6 hours
**Priority**: P1 (Important for user experience)

---

### 3.1 Loading States & Progress Indicators

**Priority**: P1 | **Complexity**: Low | **Time**: 1-2 hours

#### Task 3.1.1: Add Upload Progress Indicator
- [ ] Open `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`
- [ ] Add `@Published var uploadProgress: Double = 0.0`
- [ ] Track upload progress in `uploadForAnalysis()`
- [ ] Use URLSession delegate for progress tracking
- [ ] Update UI with progress bar

**Success Criteria**: User sees upload progress

**Files Modified**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

---

#### Task 3.1.2: Add Analysis Status Polling UI
- [ ] Add `@Published var analysisStatus: String = ""`
- [ ] Update status during polling:
  - "Uploading..."
  - "Transcribing audio..."
  - "Analyzing speech patterns..."
  - "Complete!"
- [ ] Show spinner + status text in UI

**Success Criteria**: User sees analysis progress

**Files Modified**: `ios/SpeechMastery/ViewModels/AnalysisViewModel.swift`

---

#### Task 3.1.3: Add Skeleton Loaders
- [ ] Open `ios/SpeechMastery/Views/AnalysisResultView.swift`
- [ ] Add skeleton loading state for scores
- [ ] Add shimmer effect while loading
- [ ] Use `.redacted(reason: .placeholder)` modifier
- [ ] Show skeleton while `isLoading == true`

**Success Criteria**: Nice loading UI

**Files Modified**: `ios/SpeechMastery/Views/AnalysisResultView.swift`

---

#### Task 3.1.4: Add Pull-to-Refresh
- [ ] Open `ios/SpeechMastery/Views/RecordingsListView.swift`
- [ ] Add `.refreshable` modifier to List
- [ ] Call `viewModel.refreshRecordings()` on pull
- [ ] Show loading indicator during refresh

**Success Criteria**: Pull to refresh works

**Files Modified**: `ios/SpeechMastery/Views/RecordingsListView.swift`

---

### 3.2 Comprehensive Error Handling

**Priority**: P1 | **Complexity**: Medium | **Time**: 2-3 hours

#### Task 3.2.1: Create Error Banner Component
- [ ] Create `ios/SpeechMastery/Views/Components/ErrorBanner.swift`
- [ ] Design banner UI (red background, error icon, message, dismiss button)
- [ ] Add animation (slide in from top)
- [ ] Auto-dismiss after 5 seconds
- [ ] Add "Retry" button for network errors

**Success Criteria**: Reusable error banner

**Files Created**: `ios/SpeechMastery/Views/Components/ErrorBanner.swift`

---

#### Task 3.2.2: Add Error Handling to RecordingView
- [ ] Open `ios/SpeechMastery/Views/RecordingView.swift`
- [ ] Subscribe to `viewModel.errorMessage`
- [ ] Show ErrorBanner when error occurs
- [ ] Handle specific errors:
  - Microphone permission denied → show settings button
  - Storage full → show clear storage button
  - Recording failed → show retry button

**Success Criteria**: Recording errors handled

**Files Modified**: `ios/SpeechMastery/Views/RecordingView.swift`

---

#### Task 3.2.3: Add Error Handling to AnalysisResultView
- [ ] Subscribe to `viewModel.error`
- [ ] Show error if analysis load fails
- [ ] Show "Retry" button
- [ ] Handle offline state → show "No internet" message

**Success Criteria**: Analysis errors handled

**Files Modified**: `ios/SpeechMastery/Views/AnalysisResultView.swift`

---

#### Task 3.2.4: Add Offline Mode Indicator
- [ ] Create banner for offline state
- [ ] Show at top of screen when `NetworkMonitor.shared.isConnected == false`
- [ ] Gray background with "Offline" text
- [ ] Disable upload buttons when offline
- [ ] Show "Recordings will upload when online"

**Success Criteria**: Offline state visible

**Files Modified**: Multiple view files

---

#### Task 3.2.5: Add Failed Upload Queue
- [ ] Create `@Published var failedUploads: [Recording] = []` in RecordingsListViewModel
- [ ] Add recordings to queue on upload failure
- [ ] Show badge on Recordings tab
- [ ] Add "Retry All" button
- [ ] Auto-retry when network comes back online

**Success Criteria**: Failed uploads can be retried

**Files Modified**: `ios/SpeechMastery/ViewModels/RecordingsListViewModel.swift`

---

### 3.3 End-to-End Testing

**Priority**: P1 | **Complexity**: Low | **Time**: 1-2 hours

#### Task 3.3.1: Test Complete Recording Flow
- [ ] Open app on iPhone/Simulator
- [ ] Grant microphone permission
- [ ] Tap Record button
- [ ] Record 30 seconds of speech (include filler words)
- [ ] Stop recording
- [ ] Verify audio file saved
- [ ] Verify file appears in Recordings list

**Success Criteria**: Recording works end-to-end

---

#### Task 3.3.2: Test Upload and Analysis Flow
- [ ] Ensure backend is running (check with `curl http://192.168.244.129:8000/health`)
- [ ] From Recordings list, tap a recording
- [ ] Tap "Analyze" button
- [ ] Verify upload starts (progress bar shows)
- [ ] Wait for analysis (polling happens)
- [ ] Verify analysis results display
- [ ] Check scores, critical moments, transcript

**Success Criteria**: Analysis works end-to-end

---

#### Task 3.3.3: Test Offline Behavior
- [ ] Turn off WiFi on iPhone/Mac
- [ ] Try to upload recording
- [ ] Verify error message shows
- [ ] Verify recording queued for retry
- [ ] Turn WiFi back on
- [ ] Verify upload auto-retries

**Success Criteria**: Offline handling works

---

#### Task 3.3.4: Test Error Scenarios
- [ ] Test: Stop backend, try to upload → verify error
- [ ] Test: Upload invalid file → verify error
- [ ] Test: Upload very large file (> 100MB) → verify rejected
- [ ] Test: Deny microphone permission → verify error + settings button
- [ ] Test: Fill storage completely → verify error

**Success Criteria**: All error cases handled

---

#### Task 3.3.5: Test Settings Persistence
- [ ] Change audio quality in Settings
- [ ] Force quit app
- [ ] Reopen app
- [ ] Verify setting persisted
- [ ] Test: Toggle privacy settings → verify persisted
- [ ] Test: Clear cache → verify cache cleared

**Success Criteria**: Settings persist correctly

---

#### Task 3.3.6: Test Auto-Deletion
- [ ] Create recording with old `recordedAt` date (8 days ago)
- [ ] Trigger cleanup manually in Settings
- [ ] Verify old recording deleted
- [ ] Verify recent recordings kept

**Success Criteria**: Auto-deletion works

---

## Phase 4: Optional Features (Future)

**Goal**: Premium features (CEO Voice, Live Guardian, etc.)
**Estimated Time**: 20+ hours
**Priority**: P3 (Future work)

---

### 4.1 CEO Voice Synthesis

**Priority**: P3 | **Complexity**: Very High | **Time**: 8-10 hours

- [ ] Research text-to-speech APIs (ElevenLabs, Azure TTS)
- [ ] Implement voice cloning workflow
- [ ] Add "Improve This" feature to analysis
- [ ] Generate improved version with CEO voice
- [ ] Add playback UI
- [ ] Handle API costs and limits

**Note**: Requires backend support and external API integration

---

### 4.2 Live Guardian Mode

**Priority**: P3 | **Complexity**: Very High | **Time**: 10-12 hours

- [ ] Implement real-time audio streaming
- [ ] Add real-time transcription (WebSocket)
- [ ] Add real-time filler word detection
- [ ] Show live alerts during recording
- [ ] Add haptic feedback for fillers
- [ ] Optimize for battery usage

**Note**: Requires significant backend changes for real-time processing

---

### 4.3 Simulation Arena

**Priority**: P3 | **Complexity**: High | **Time**: 6-8 hours

- [ ] Design roleplay scenarios
- [ ] Add AI conversation partner
- [ ] Implement turn-based conversation
- [ ] Add scenario-specific feedback
- [ ] Track progress over sessions

---

### 4.4 Gamification

**Priority**: P3 | **Complexity**: Medium | **Time**: 4-6 hours

- [ ] Design point/badge system
- [ ] Add achievements (milestones)
- [ ] Add leaderboard (single-user for now)
- [ ] Add streaks (consecutive days)
- [ ] Add progress visualization

---

### 4.5 Advanced Visualizations

**Priority**: P3 | **Complexity**: Medium | **Time**: 3-4 hours

- [ ] Add 7-day trend chart (SwiftUI Charts)
- [ ] Add 30-day trend chart
- [ ] Add score distribution histogram
- [ ] Add timeline view for recordings
- [ ] Add pattern frequency graph

---

## Testing Checklist

After completing each phase, verify:

### Phase 1 Checklist (Core Services)
- [ ] APIService: Upload audio file successfully
- [ ] APIService: Fetch analysis results
- [ ] APIService: Fetch recordings list
- [ ] APIService: Delete recording
- [ ] NetworkMonitor: Detects connection status
- [ ] NetworkMonitor: Detects WiFi vs cellular
- [ ] AnalysisViewModel: Upload initiates
- [ ] AnalysisViewModel: Polling works
- [ ] AnalysisViewModel: Results display
- [ ] RecordingsListViewModel: Sync with backend
- [ ] RecordingsListViewModel: Auto-upload new recordings
- [ ] No crashes in console logs

### Phase 2 Checklist (Support Services)
- [ ] CacheService: Analysis cached correctly
- [ ] CacheService: Cache retrieved from disk
- [ ] CacheService: Cache cleared
- [ ] AutoDeletionService: Old recordings deleted
- [ ] AutoDeletionService: Background task registered
- [ ] SettingsViewModel: Settings load correctly
- [ ] SettingsViewModel: Settings persist
- [ ] Storage stats accurate

### Phase 3 Checklist (Polish & UX)
- [ ] Upload progress indicator shows
- [ ] Loading states look good
- [ ] Skeleton loaders work
- [ ] Error banners display
- [ ] Offline indicator shows
- [ ] Failed uploads queue for retry
- [ ] Pull-to-refresh works
- [ ] All error scenarios handled gracefully

---

## Dependencies & Prerequisites

### Required Software
- Xcode 15+
- Swift 5.9+
- iOS 17.0+ (deployment target)
- macOS VM with Xcode
- XcodeGen

### External Frameworks
- SwiftUI (built-in)
- Combine (built-in)
- AVFoundation (built-in)
- Network (built-in, for NWPathMonitor)
- BackgroundTasks (built-in)

### Backend Requirements
- Backend API running on Linux VM
- Linux VM IP address configured in Constants.swift
- Port 8000 accessible from macOS VM

---

## Success Metrics

### MVP Success (Phase 1)
- ✅ Can record audio on iPhone
- ✅ Can upload to backend successfully
- ✅ Receives analysis results from backend
- ✅ Displays scores, critical moments, transcript
- ✅ Network status visible
- ✅ Offline handling works
- ✅ No crashes during normal flow

### Quality Success (Phase 2)
- ✅ Analysis cached for offline viewing
- ✅ Old recordings auto-delete after 7 days
- ✅ Settings persist across app restarts
- ✅ Storage stats accurate
- ✅ Background tasks work

### Polish Success (Phase 3)
- ✅ Loading states smooth and informative
- ✅ All errors handled gracefully
- ✅ Failed uploads retry automatically
- ✅ App feels responsive and professional
- ✅ No confusing error messages

---

## Notes

- **Dual-VM Setup**: Ensure Linux VM IP is correct in Constants.swift before testing
- **Xcode Project**: Regenerate with `xcodegen generate` after pulling changes
- **Networking**: Test both WiFi and cellular connectivity
- **Privacy**: Always request permissions before accessing microphone
- **Background Tasks**: Test on physical device (simulators don't reliably run background tasks)
- **Offline Mode**: Cache is critical for good UX when offline

---

## Common Issues & Troubleshooting

### iOS Can't Reach Backend
- Check Linux VM IP in Constants.swift
- Verify backend is running: `docker-compose ps`
- Test connectivity: `curl http://192.168.244.129:8000/health`
- Check firewall on Linux VM

### Upload Fails Immediately
- Check auth token matches backend
- Check file format (m4a, wav, mp3, aac only)
- Check file size (< 100MB)
- Check network connection

### Analysis Never Completes
- Check backend logs: `docker-compose logs -f backend`
- Verify Whisper is installed and working
- Check for transcription errors in backend logs
- Increase polling timeout if needed

### Background Tasks Don't Run
- Must test on physical device (not simulator)
- Background tasks may be delayed by iOS
- Check BGTaskScheduler registration in Info.plist
- Use Xcode debug: `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.speechmastery.cleanup"]`

---

**Last Updated**: 2025-10-29
**Current Phase**: Phase 1 - Core Services (Ready to Start)
