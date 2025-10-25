# Speech Mastery App - Skeleton Implementation Summary

## Status: PLAN COMPLETE - Ready for Implementation

This document provides a complete specification of all skeleton files to be created, with detailed comments and integration hooks for optional features.

---

## ✅ COMPLETED FILES

### Documentation
- [x] `README.md` - Project overview and getting started
- [x] `docs/API_CONTRACT.md` - Complete REST API specification
- [x] `docs/DATABASE_SCHEMA.md` - PostgreSQL schema with optional feature tables
- [x] `docs/ARCHITECTURE.md` - System architecture and design patterns
- [x] `docs/OPTIONAL_FEATURES_ROADMAP.md` - Premium features implementation plan
- [x] `docs/DEVELOPMENT_GUIDE.md` - Setup, workflow, and troubleshooting

### iOS Models
- [x] `ios/SpeechMastery/Models/Recording.swift` - Recording data model with metadata
- [x] `ios/SpeechMastery/Models/AudioSettings.swift` - Audio quality configuration
- [x] `ios/SpeechMastery/Models/AnalysisResult.swift` - Comprehensive analysis result
- [x] `ios/SpeechMastery/Models/Report.swift` - Daily aggregated report

---

## 📋 REMAINING FILES TO CREATE

### iOS Services Layer (7 files)

#### 1. AudioRecordingService.swift
**Purpose**: Manages AVFoundation audio recording lifecycle
**Key Methods**:
```swift
- startRecording(with settings: AudioSettings) -> Result<Void, RecordingError>
- stopRecording() -> Result<Recording, RecordingError>
- pauseRecording()
- resumeRecording()
- requestMicrophonePermission() async -> Bool
- getCurrentRecordingDuration() -> TimeInterval
```

**Hooks for Optional Features**:
- Live Guardian Mode: Real-time audio buffer access
- Voice Command Training: Exercise-specific recording configurations
- Simulation Arena: Scenario-tagged recordings

#### 2. AudioStorageService.swift
**Purpose**: Local persistence (UserDefaults + Files)
**Key Methods**:
```swift
- saveRecording(_ recording: Recording, audioData: Data) async throws
- loadAllRecordings() -> [Recording]
- loadRecording(id: UUID) -> Recording?
- deleteRecording(id: UUID) throws
- getAudioData(for recording: Recording) -> Data?
- updateRecordingMetadata(_ recording: Recording) throws
```

**Features**:
- NSFileProtectionComplete encryption
- UserDefaults for metadata
- File system for audio blobs

#### 3. APIService.swift
**Purpose**: HTTP client for backend communication
**Key Methods**:
```swift
- uploadRecording(_ recording: Recording) async throws -> AnalysisResult
- fetchReport(for date: Date) async throws -> Report
- listRecordings() async throws -> [Recording]
- deleteRecording(id: UUID) async throws
// OPTIONAL FEATURE: Premium endpoints
// - fetchCEOComparison(recordingID: UUID) async throws -> [CEOComparison]
// - startLiveGuardianSession() async throws -> UUID
// - fetchSimulationScenarios() async throws -> [Scenario]
```

**Configuration**:
- Base URL: localhost or device IP
- Single-user token authentication
- Multipart form-data for uploads

#### 4. PrivacyManager.swift
**Purpose**: Handle permissions and visual indicators
**Key Methods**:
```swift
- requestMicrophonePermission() async -> Bool
- getMicrophonePermissionStatus() -> AVAudioSession.RecordPermission
- showRecordingIndicator(in view: some View) -> some View
- hideRecordingIndicator()
// OPTIONAL FEATURE: Watch notifications
// - sendPrivacyAlertToWatch()
```

#### 5. AutoDeletionService.swift
**Purpose**: Background task for 7-day cleanup
**Key Methods**:
```swift
- scheduleAutoDeletion()
- performCleanup() async
- getRecordingsEligibleForDeletion() -> [Recording]
- deleteExpiredRecordings() async throws
```

**Implementation**:
- Uses BGTaskScheduler for background execution
- Runs daily at midnight
- Logs deletion events

#### 6. CacheService.swift (NEW)
**Purpose**: Caching layer for API responses
**Key Methods**:
```swift
- cacheAnalysisResult(_ result: AnalysisResult)
- getCachedAnalysisResult(for recordingID: UUID) -> AnalysisResult?
- cacheReport(_ report: Report)
- getCachedReport(for date: Date) -> Report?
- clearCache()
```

#### 7. NetworkMonitor.swift (NEW)
**Purpose**: Monitor network connectivity
**Key Methods**:
```swift
- startMonitoring()
- stopMonitoring()
- isConnected: Bool { get }
```

**Usage**: Disable upload button when offline

---

### iOS ViewModels Layer (5 files)

#### 1. RecordingViewModel.swift
**MVVM bridge for RecordingView**
**@Published Properties**:
```swift
- isRecording: Bool
- currentDuration: TimeInterval
- recordingState: RecordingState (idle, recording, paused, stopped)
- audioSettings: AudioSettings
- error: Error?
- showingPermissionAlert: Bool
```

**Methods**:
```swift
- startRecording()
- stopRecording()
- pauseRecording()
- resumeRecording()
- changeAudioSettings(_ settings: AudioSettings)
```

#### 2. RecordingsListViewModel.swift
**Manages library of recordings**
**@Published Properties**:
```swift
- recordings: [Recording]
- isLoading: Bool
- selectedRecording: Recording?
- searchText: String
- filterOption: FilterOption
```

**Methods**:
```swift
- loadRecordings()
- deleteRecording(_ recording: Recording)
- uploadRecording(_ recording: Recording)
- searchRecordings(query: String)
- sortRecordings(by: SortOption)
```

#### 3. AnalysisViewModel.swift
**Manages analysis results display**
**@Published Properties**:
```swift
- analysisResult: AnalysisResult?
- isLoading: Bool
- error: Error?
```

**Methods**:
```swift
- loadAnalysisResult(for recordingID: UUID)
- retryAnalysis()
```

#### 4. ReportViewModel.swift
**Manages daily reports**
**@Published Properties**:
```swift
- currentReport: Report?
- selectedDate: Date
- isLoading: Bool
- availableDates: [Date]
```

**Methods**:
```swift
- loadReport(for date: Date)
- navigateToPreviousDay()
- navigateToNextDay()
- refreshReport()
```

#### 5. SettingsViewModel.swift
**Manages app settings**
**@Published Properties**:
```swift
- audioSettings: AudioSettings
- notificationsEnabled: Bool
- autoDeletionEnabled: Bool
```

**Methods**:
```swift
- saveAudioSettings(_ settings: AudioSettings)
- toggleNotifications()
- resetToDefaults()
```

---

### iOS Views Layer (20+ files)

#### Core Views (8 files)
1. `SpeechMasteryApp.swift` - App entry point with @main
2. `MainTabView.swift` - Tab bar navigation (Record, Library, Reports, Settings)

3. **Recording/** (3 files)
   - `RecordingView.swift` - Main recording interface
   - `RecordingIndicatorView.swift` - Red badge visual indicator
   - `AudioWaveformView.swift` - Animated waveform during recording

4. **Library/** (3 files)
   - `RecordingsListView.swift` - List of all recordings
   - `RecordingRowView.swift` - Individual recording row
   - `RecordingDetailView.swift` - Detail view with play/delete/analyze

#### Analysis Views (3 files)
5. **Analysis/** (3 files)
   - `AnalysisResultView.swift` - Full analysis display
   - `ScoreCardView.swift` - Individual score cards with colors
   - `CriticalMomentsView.swift` - Timeline of issues

#### Report Views (3 files)
6. **Reports/** (3 files)
   - `DailyReportView.swift` - Daily report display
   - `PatternRecognitionView.swift` - Top patterns list
   - `ScoreBreakdownView.swift` - Detailed score breakdown

#### Settings Views (2 files)
7. **Settings/** (2 files)
   - `SettingsView.swift` - Main settings screen
   - `AudioQualitySettingsView.swift` - Audio quality picker

#### Premium Views (4 files - PLACEHOLDERS)
8. **Premium/** (4 files)
   - `CEOVoiceSynthesisView.swift` - OPTIONAL FEATURE
   - `LiveGuardianView.swift` - OPTIONAL FEATURE
   - `SimulationArenaView.swift` - OPTIONAL FEATURE
   - `GamificationView.swift` - OPTIONAL FEATURE

All premium views should be stubbed with:
```swift
struct CEOVoiceSynthesisView: View {
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            Text("CEO Voice Synthesis")
                .font(.title)
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // OPTIONAL FEATURE: CEO Voice Synthesis
            // TODO: Implement when feature is enabled
            // - Side-by-side text comparison
            // - Authority score improvement display
            // - Reframing suggestions
        }
        .navigationTitle("CEO Voice Synthesis")
    }
}
```

---

### iOS Utilities Layer (5 files)

1. `Utilities/AudioFileManager.swift` - File operations helper
2. `Utilities/DateFormatter+Extensions.swift` - Date formatting utilities
3. `Utilities/Constants.swift` - API URLs, tokens, config values
4. `Utilities/Logger.swift` - Logging wrapper
5. `Utilities/FeatureFlags.swift` - Optional feature toggles

---

### iOS Testing Layer (8+ files)

1. **ModelTests/** (4 files)
   - `RecordingTests.swift`
   - `AudioSettingsTests.swift`
   - `AnalysisResultTests.swift`
   - `ReportTests.swift`

2. **ServiceTests/** (3 files)
   - `AudioRecordingServiceTests.swift`
   - `APIServiceTests.swift`
   - `AudioStorageServiceTests.swift`

3. **ViewModelTests/** (2 files)
   - `RecordingViewModelTests.swift`
   - `ReportViewModelTests.swift`

4. **MockData/** (3 files)
   - `MockRecordings.swift` - Sample Recording instances
   - `MockAPIResponses.swift` - Mock API JSON responses
   - `MockAudioFiles/sample.m4a` - Sample audio file for testing

---

## Backend Structure (50+ files)

### Backend API Layer (8 files)

1. `backend/app/main.py` - FastAPI app initialization
2. `backend/app/config.py` - Configuration management (env vars, feature flags)
3. `backend/app/api/__init__.py`
4. `backend/app/api/routes.py` - Main router
5. `backend/app/api/analyze.py` - POST /analyze endpoint
6. `backend/app/api/reports.py` - GET /reports endpoint
7. `backend/app/api/recordings.py` - Recording CRUD operations
8. `backend/app/api/health.py` - Health check endpoint

### Backend Premium API Layer (4 files - PLACEHOLDERS)

9. `backend/app/api/premium/__init__.py`
10. `backend/app/api/premium/ceo_voice.py` - OPTIONAL FEATURE
11. `backend/app/api/premium/live_guardian.py` - OPTIONAL FEATURE
12. `backend/app/api/premium/simulation.py` - OPTIONAL FEATURE
13. `backend/app/api/premium/gamification.py` - OPTIONAL FEATURE

### Backend Models Layer (5 files)

14. `backend/app/models/__init__.py`
15. `backend/app/models/recording.py` - Recording SQLAlchemy model
16. `backend/app/models/analysis_result.py` - AnalysisResult model
17. `backend/app/models/report.py` - Report model
18. `backend/app/models/user.py` - User model (single-user)

### Backend Schemas Layer (4 files)

19. `backend/app/schemas/__init__.py`
20. `backend/app/schemas/recording.py` - Pydantic schemas
21. `backend/app/schemas/analysis.py` - Analysis request/response schemas
22. `backend/app/schemas/report.py` - Report schemas

### Backend Services Layer (12 files)

23. `backend/app/services/__init__.py`
24. `backend/app/services/transcription_service.py` - Abstract transcription interface
25. `backend/app/services/nlp_service.py` - Abstract NLP interface
26. `backend/app/services/analysis_engine.py` - Main orchestrator
27. `backend/app/services/power_dynamics_analyzer.py` - Filler/hedging detection
28. `backend/app/services/linguistic_authority_analyzer.py` - Passive voice analysis
29. `backend/app/services/vocal_command_analyzer.py` - Pace/rhythm analysis
30. `backend/app/services/persuasion_analyzer.py` - Coherence scoring
31. `backend/app/services/report_generator.py` - Daily report generation
32. `backend/app/services/storage_service.py` - File/DB storage
33. `backend/app/services/base_analyzer.py` - Abstract analyzer base class
34. `backend/app/services/scoring_service.py` - Score calculation utilities

### Backend Core Layer (4 files)

35. `backend/app/core/__init__.py`
36. `backend/app/core/database.py` - Database connection setup
37. `backend/app/core/security.py` - Auth utilities (single-user token)
38. `backend/app/core/logging.py` - Logging configuration

### Backend Utils Layer (4 files)

39. `backend/app/utils/__init__.py`
40. `backend/app/utils/audio_utils.py` - Audio file handling
41. `backend/app/utils/text_processing.py` - Text cleaning
42. `backend/app/utils/scoring.py` - Score calculation helpers

### Backend Testing Layer (10+ files)

43. `backend/tests/__init__.py`
44. `backend/tests/conftest.py` - Pytest fixtures
45. `backend/tests/test_api/test_analyze.py`
46. `backend/tests/test_api/test_reports.py`
47. `backend/tests/test_api/test_recordings.py`
48. `backend/tests/test_services/test_analysis_engine.py`
49. `backend/tests/test_services/test_power_dynamics_analyzer.py`
50. `backend/tests/test_services/test_linguistic_authority_analyzer.py`
51. `backend/tests/test_services/test_vocal_command_analyzer.py`
52. `backend/tests/test_services/test_persuasion_analyzer.py`
53. `backend/tests/fixtures/mock_responses.py`
54. `backend/tests/fixtures/sample_audio.wav` - Test audio file
55. `backend/tests/fixtures/sample_transcripts.json` - Test transcripts

### Backend Dependencies (2 files)

56. `backend/requirements.txt` - Production dependencies
57. `backend/requirements-dev.txt` - Development dependencies

### Backend Docker (1 file)

58. `backend/Dockerfile` - Backend container image

### Backend Migrations (2 files)

59. `backend/alembic/env.py` - Alembic environment
60. `backend/alembic/versions/001_initial_schema.py` - Initial migration

---

## Docker Configuration (5 files)

1. `docker/docker-compose.yml` - Main compose file (PostgreSQL, Redis, FastAPI)
2. `docker/docker-compose.dev.yml` - Development overrides
3. `docker/docker-compose.prod.yml` - Production overrides (future)
4. `docker/postgres/init.sql` - PostgreSQL initialization
5. `docker/redis/redis.conf` - Redis configuration

---

## Utility Scripts (5 files)

1. `scripts/setup_ios.sh` - iOS project setup script
2. `scripts/setup_backend.sh` - Backend environment setup
3. `scripts/generate_mock_data.py` - Generate test fixtures
4. `scripts/run_tests.sh` - Run all tests (iOS + Backend)
5. `scripts/check_backend.sh` - Lint and format Python code

---

## Implementation Priority

### Phase 1: Foundation (COMPLETED)
- ✅ Documentation files
- ✅ iOS Models

### Phase 2: Core Services (NEXT - Week 1-2)
- ⬜ iOS Services layer (7 files)
- ⬜ iOS Utilities (5 files)
- ⬜ iOS ViewModels (5 files)

### Phase 3: User Interface (Week 3)
- ⬜ iOS Views - Recording & Library (8 files)
- ⬜ iOS Views - Analysis & Reports (6 files)
- ⬜ iOS Views - Settings (2 files)
- ⬜ iOS Premium placeholders (4 files)

### Phase 4: Backend Foundation (Week 4)
- ⬜ Backend core (database, security, logging)
- ⬜ Backend models and schemas
- ⬜ Backend API endpoints (base features)

### Phase 5: Backend Analysis (Week 5)
- ⬜ Abstract service interfaces
- ⬜ Four core analyzers
- ⬜ Analysis engine orchestrator
- ⬜ Report generator

### Phase 6: Integration (Week 6)
- ⬜ Connect iOS to backend
- ⬜ Upload and analysis flow
- ⬜ Report fetching and display
- ⬜ Error handling

### Phase 7: Testing & Polish (Week 7-8)
- ⬜ iOS unit tests
- ⬜ Backend unit and integration tests
- ⬜ Mock data and fixtures
- ⬜ Docker configuration
- ⬜ Utility scripts

### Phase 8: Optional Features (Post-Prototype)
- ⬜ CEO Voice Synthesis
- ⬜ Live Guardian Mode
- ⬜ Simulation Arena
- ⬜ Gamification System
- ⬜ Additional premium features

---

## File Creation Guidelines

### Every File Must Include:

1. **Header Comment Block**:
   ```swift
   //
   //  FileName.swift
   //  SpeechMastery
   //
   //  Purpose: Brief description
   //
   //  Responsibilities:
   //  - Bullet points of what this file does
   //
   //  Integration Points:
   //  - List of other components this interacts with
   //
   //  Technical Details: (if applicable)
   //  - Important implementation notes
   //
   ```

2. **OPTIONAL FEATURE Markers**:
   ```swift
   // OPTIONAL FEATURE: CEO Voice Synthesis
   // TODO: Implement when feature is enabled
   // - Specific implementation task 1
   // - Specific implementation task 2
   ```

3. **TODO Sections**:
   ```swift
   // MARK: - TODO: Implementation Tasks
   /*
    TODO: When implementing X:
    1. Task description
    2. Task description

    TODO: When implementing OPTIONAL FEATURE Y:
    1. Uncomment Y-related code
    2. Implement Y service
    */
   ```

4. **Sample Data** (for models/views):
   ```swift
   // MARK: - Sample Data for Previews
   extension ModelName {
       static var sample: ModelName {
           // Return sample instance
       }
   }
   ```

5. **Integration Hooks**:
   - Commented code showing where optional features integrate
   - Clear markers for future implementation
   - Preserve interface compatibility

---

## Next Steps for Implementation

1. **Run skeleton generation script** (when available):
   ```bash
   ./scripts/generate_skeleton.sh
   ```

2. **Or create files manually** following this specification

3. **Verify structure**:
   ```bash
   tree -L 3 ios/ backend/ docker/ scripts/
   ```

4. **Initialize Xcode project**:
   ```bash
   cd ios/SpeechMastery
   xcodegen generate  # If using XcodeGen
   # Or create manually in Xcode
   ```

5. **Start implementing** following the phase priorities above

---

## Success Criteria

Skeleton is complete when:
- [x] All documentation files created
- [x] All iOS models created with sample data
- [ ] All iOS services created with method stubs
- [ ] All iOS ViewModels created with @Published properties
- [ ] All iOS Views created with placeholder UI
- [ ] All backend files created with function signatures
- [ ] All test files created with skeleton test cases
- [ ] Docker configuration is functional
- [ ] Scripts are executable and documented
- [ ] Every file has comprehensive comments and TODO markers
- [ ] Every OPTIONAL FEATURE is clearly marked
- [ ] README and docs are complete and accurate

---

## Maintenance Notes

- **When adding new features**: Follow existing patterns and comment style
- **When modifying models**: Update both iOS and backend schemas
- **When changing API contract**: Update API_CONTRACT.md documentation
- **When adding optional features**: Mark clearly and update OPTIONAL_FEATURES_ROADMAP.md
- **Keep skeleton synchronized**: If changing architecture, update this document

---

**Document Version**: 1.0
**Last Updated**: 2025-10-23
**Status**: PLAN COMPLETE - Ready for skeleton file creation
