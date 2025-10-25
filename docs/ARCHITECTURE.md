# System Architecture

## Overview

Speech Mastery App follows a **client-server architecture** with clear separation of concerns:

- **iOS Client**: SwiftUI-based mobile app for recording and visualization
- **Backend Server**: FastAPI-based REST API for AI-powered analysis
- **Database**: PostgreSQL for persistent storage
- **AI Services**: Abstract interfaces for transcription and NLP

## High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                   iOS App (SwiftUI)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  Views   │→ │ViewModels│→ │ Services │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│                                    ↓                 │
│                            ┌───────────────┐        │
│                            │ Local Storage │        │
│                            │(UserDefaults  │        │
│                            │  + Files)     │        │
│                            └───────────────┘        │
└──────────────────────┬──────────────────────────────┘
                       │ HTTPS REST API
                       ↓
┌─────────────────────────────────────────────────────┐
│              FastAPI Backend Server                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │   API    │→ │ Services │→ │   AI     │          │
│  │ Endpoints│  │  Layer   │  │ Engines  │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│                       ↓               ↓              │
│              ┌─────────────┐  ┌──────────┐         │
│              │ PostgreSQL  │  │  File    │         │
│              │   Database  │  │ Storage  │         │
│              └─────────────┘  └──────────┘         │
└─────────────────────────────────────────────────────┘
```

## iOS Application Architecture

### Pattern: MVVM (Model-View-ViewModel)

```
┌─────────────────────────────────────────┐
│              SwiftUI Views               │
│  (User Interface & User Interactions)    │
└──────────────────┬──────────────────────┘
                   │ Bindings (@Published)
                   ↓
┌─────────────────────────────────────────┐
│            ViewModels                    │
│  (Presentation Logic & State Management) │
└──────────────────┬──────────────────────┘
                   │ Business Logic Calls
                   ↓
┌─────────────────────────────────────────┐
│             Services                     │
│  (Business Logic & External Integration) │
└──────────────────┬──────────────────────┘
                   │ Data Operations
                   ↓
┌─────────────────────────────────────────┐
│        Models & Local Storage            │
│     (Data Structures & Persistence)      │
└─────────────────────────────────────────┘
```

### Key Components

#### 1. Models
- **Purpose**: Data structures representing domain entities
- **Examples**: `Recording`, `AnalysisResult`, `Report`, `AudioSettings`
- **Characteristics**:
  - Codable for JSON serialization
  - Identifiable for SwiftUI lists
  - Value types (structs) for immutability

#### 2. Services
- **AudioRecordingService**: Manages AVFoundation recording lifecycle
- **AudioStorageService**: Handles local file persistence and UserDefaults metadata
- **APIService**: HTTP client for backend communication
- **PrivacyManager**: Microphone permissions and visual indicators
- **AutoDeletionService**: Background task for 7-day cleanup

#### 3. ViewModels
- **Purpose**: Bridge between Views and Services
- **Responsibilities**:
  - Expose @Published properties for UI binding
  - Handle user actions and coordinate service calls
  - Manage view-specific state and loading indicators
  - Error handling and user feedback
- **Lifecycle**: ObservableObject, instantiated per view or shared via @EnvironmentObject

#### 4. Views
- **RecordingView**: Audio capture interface with visual indicator
- **RecordingsListView**: Library of past recordings
- **AnalysisResultView**: Detailed analysis display with scores
- **DailyReportView**: Aggregated daily insights
- **Premium Views**: Placeholders for future features (commented as optional)

### Data Flow Example: Recording & Analysis

```
User taps Record Button
        ↓
RecordingView triggers action
        ↓
RecordingViewModel.startRecording()
        ↓
AudioRecordingService.startRecording()
        ↓
AVAudioRecorder begins capture
        ↓
User taps Stop Button
        ↓
RecordingViewModel.stopRecording()
        ↓
AudioRecordingService saves to file
        ↓
AudioStorageService.saveMetadata()
        ↓
UserDefaults + File system updated
        ↓
User taps Analyze
        ↓
AnalysisViewModel.uploadForAnalysis()
        ↓
APIService.uploadRecording()
        ↓
Backend analyzes (see Backend section)
        ↓
AnalysisViewModel receives response
        ↓
AnalysisResultView displays scores & moments
```

### Privacy & Security

- **Encryption**: NSFileProtectionComplete for audio files
- **Permissions**: AVAudioSession.requestRecordPermission() with explanatory alerts
- **Indicators**: Persistent red badge during recording
- **Manual Review**: Users can play back and delete before upload
- **Auto-Deletion**: Background task runs daily to remove 7-day-old recordings

---

## Backend Architecture

### Pattern: Layered Architecture

```
┌─────────────────────────────────────────┐
│          API Layer (FastAPI)             │
│    (Request Handling & Validation)       │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────┐
│         Service Layer                    │
│   (Business Logic & Orchestration)       │
└──────────────────┬──────────────────────┘
                   │
          ┌────────┴────────┐
          ↓                 ↓
┌──────────────────┐  ┌─────────────────┐
│   AI Engines     │  │  Data Layer     │
│ (Analysis Logic) │  │ (ORM & Storage) │
└──────────────────┘  └─────────────────┘
```

### Key Components

#### 1. API Layer (`app/api/`)
- **Purpose**: HTTP request handling and routing
- **Routes**:
  - `POST /analyze`: Upload and analyze audio
  - `GET /reports/{date}`: Fetch daily reports
  - `GET /recordings`: List user recordings
  - `DELETE /recordings/{id}`: Remove recording
- **Responsibilities**:
  - Request validation (Pydantic schemas)
  - Authentication verification (single-user token for prototype)
  - Response formatting
  - Error handling and HTTP status codes

#### 2. Service Layer (`app/services/`)
- **AnalysisEngine**: Orchestrates the complete analysis pipeline
- **TranscriptionService**: Abstract interface for speech-to-text (Whisper, etc.)
- **NLPService**: Abstract interface for text analysis (spaCy, etc.)
- **Analyzer Services**:
  - `PowerDynamicsAnalyzer`: Filler words, hedging, upspeak detection
  - `LinguisticAuthorityAnalyzer`: Passive voice, word economy, precision
  - `VocalCommandAnalyzer`: Pace, rhythm, pause analysis
  - `PersuasionAnalyzer`: Coherence scoring, persuasion keywords
- **ReportGenerator**: Aggregates daily statistics and patterns
- **StorageService**: File handling and database operations

#### 3. Data Layer (`app/models/` & `app/core/`)
- **SQLAlchemy Models**: ORM representations of database tables
- **Pydantic Schemas**: Request/response validation and serialization
- **Database Connection**: Async PostgreSQL connection pool
- **Migrations**: Alembic for schema versioning

#### 4. AI Services (Abstract Interfaces)

**Design Principle**: Generic interfaces allow easy swapping of AI models

```python
# Abstract Transcription Interface
class TranscriptionService:
    async def transcribe(self, audio_path: str) -> TranscriptionResult:
        """
        Convert audio to text with timestamps.

        Implementations:
        - WhisperTranscriptionService (OpenAI Whisper)
        - AssemblyAITranscriptionService
        - GoogleSpeechTranscriptionService
        """
        pass

# Abstract NLP Interface
class NLPService:
    def analyze_text(self, text: str) -> NLPAnalysis:
        """
        Perform linguistic analysis on text.

        Implementations:
        - SpaCyNLPService (spaCy + TextBlob)
        - HuggingFaceNLPService
        - CustomNLPService
        """
        pass
```

### Analysis Pipeline

```
Audio File Upload
        ↓
Save to temporary storage
        ↓
TranscriptionService.transcribe()
        ↓
[Transcript with timestamps]
        ↓
┌───────────────────────────────────┐
│   Parallel Analysis (4 Analyzers) │
│                                   │
│  PowerDynamics  Linguistic  Vocal │
│    Analyzer     Authority Command │
│                 Analyzer  Analyzer│
│                                   │
│          Persuasion               │
│           Analyzer                │
└───────────────┬───────────────────┘
                ↓
     Aggregate Scores & Patterns
                ↓
     Calculate Critical Moments
                ↓
     Store in PostgreSQL
                ↓
     Return JSON Response
```

### Processing Approach

**Base Prototype**: Synchronous processing
- Audio upload blocks until analysis completes
- Simple, easy to debug
- Suitable for prototype with low traffic
- Timeout: 2 minutes per analysis

**OPTIONAL FEATURE: Asynchronous Processing**
```
<!-- When scaling to production:
1. Upload returns immediately with job_id
2. Celery task queue processes analysis
3. Client polls GET /analysis/{job_id} for status
4. Push notification when complete

Benefits:
- Non-blocking uploads
- Horizontal scalability
- Priority queuing for premium users
- Retry logic for failures
-->
```

---

## Data Models

### Recording (iOS & Backend)

```swift
// iOS Model
struct Recording: Identifiable, Codable {
    let id: UUID
    let filePath: String
    let fileSize: Int64
    let duration: Double
    let recordedAt: Date
    let analyzed: Bool
    var analysisResult: AnalysisResult?
    let audioSettings: AudioSettings
}
```

```python
# Backend Model (SQLAlchemy)
class Recording(Base):
    __tablename__ = "recordings"

    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"))
    file_path = Column(String)
    duration = Column(Numeric)
    analyzed = Column(Boolean)
    # ... (see DATABASE_SCHEMA.md for full definition)
```

### AnalysisResult

Comprehensive speech analysis with scores, patterns, and critical moments.
- **Scores**: 0-100 scale for each analysis category
- **Patterns**: JSONB field with detailed metrics (filler counts, WPM, etc.)
- **Critical Moments**: Array of timestamped issues with suggestions

See `DATABASE_SCHEMA.md` for complete structure.

---

## Communication Protocol

### Request Flow

```
iOS App → HTTPS → FastAPI → PostgreSQL
                    ↓
            AI Services (Whisper, spaCy)
                    ↓
            Response JSON → iOS App
```

### Authentication

**Prototype**: Single-user mode with hardcoded Bearer token
```
Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345
```

**OPTIONAL FEATURE: Multi-User JWT Authentication**
```
<!-- Production auth flow:
1. User logs in: POST /auth/login → JWT access token
2. Include in requests: Authorization: Bearer <jwt_token>
3. Token expiry: 1 hour, refresh token for renewal
4. Backend validates signature and expiry
-->
```

---

## Scalability Considerations

### Current (Prototype)
- Single server instance
- Synchronous processing
- Local file storage
- Single-user mode

### Future Enhancements

**OPTIONAL FEATURE: Horizontal Scaling**
```
<!-- When scaling:
- Load balancer (nginx) → Multiple FastAPI instances
- Redis for session management
- Celery workers for async processing
- S3/GCS for distributed file storage
- Database read replicas for reporting
- CDN for static assets
-->
```

---

## Error Handling

### iOS
- Try-catch blocks for all service calls
- User-friendly alerts for errors
- Retry logic for network failures
- Graceful degradation (offline mode shows cached data)

### Backend
- FastAPI exception handlers for consistent error responses
- Logging to console (stdout/stderr for Docker)
- Validation errors return 400 with details
- Unhandled exceptions return 500 with sanitized messages

---

## Testing Strategy

### iOS
- **Unit Tests**: XCTest for Models, Services, ViewModels
- **UI Tests**: XCUITest for critical user flows (recording, playback)
- **Preview Tests**: SwiftUI canvas for visual verification
- **Mock Data**: Sample recordings and API responses

### Backend
- **Unit Tests**: Pytest for individual analyzer functions
- **Integration Tests**: TestClient for API endpoint flows
- **Fixtures**: Sample audio files, transcripts, expected outputs
- **Coverage**: Target 80%+ for core analysis logic

---

## Deployment

### Development
```
Docker Compose:
  - PostgreSQL container
  - FastAPI container
  - Redis container (for future Celery)
  - Volume mounts for live code updates
```

### Production (Future)

**OPTIONAL FEATURE: Cloud Deployment**
```
<!-- Deployment strategy:
- FastAPI: AWS ECS / Heroku / Google Cloud Run
- Database: Managed PostgreSQL (RDS / Cloud SQL)
- File Storage: S3 / Google Cloud Storage
- Monitoring: Sentry for errors, Datadog for metrics
- CI/CD: GitHub Actions for automated testing and deployment
-->
```

---

## Security Considerations

- **Data in Transit**: HTTPS/TLS 1.3 for all API communication
- **Data at Rest**: Encrypted PostgreSQL storage, NSFileProtectionComplete for iOS files
- **Authentication**: JWT tokens with short expiry (production)
- **Input Validation**: Pydantic schemas prevent injection attacks
- **File Upload**: Size limits (50MB), type validation, virus scanning (future)
- **Privacy**: Auto-deletion after 7 days, no sharing without explicit consent

---

## Monitoring & Observability

**Base Prototype**: Basic logging to console

**OPTIONAL FEATURE: Production Monitoring**
```
<!-- When deploying to production:
- Structured logging (JSON format)
- Centralized log aggregation (ELK, CloudWatch)
- Performance metrics (response times, analysis duration)
- Error tracking (Sentry)
- Uptime monitoring (Pingdom, UptimeRobot)
- User analytics (Mixpanel, Amplitude) with privacy compliance
-->
```

---

## Technology Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| iOS App | Swift + SwiftUI | 5.9+ |
| Backend | FastAPI | 0.104+ |
| Database | PostgreSQL | 15+ |
| ORM | SQLAlchemy | 2.0+ |
| Migrations | Alembic | Latest |
| Testing (iOS) | XCTest | Xcode 15+ |
| Testing (Backend) | Pytest | 7.0+ |
| Containerization | Docker | 24+ |
| AI (Transcription) | Generic Interface | TBD |
| AI (NLP) | Generic Interface | TBD |

---

## Design Principles

1. **Separation of Concerns**: Clear boundaries between layers
2. **Dependency Injection**: Services injected into ViewModels/Endpoints
3. **Abstract Interfaces**: Easy swapping of AI services
4. **Immutability**: Prefer value types (structs) in Swift
5. **Async/Await**: Modern concurrency in Swift and Python
6. **Type Safety**: Leverage Swift's type system and Pydantic validation
7. **Privacy by Design**: Minimal data collection, encryption, auto-deletion
8. **Testability**: Mock interfaces for all external dependencies

---

## Extension Points for Optional Features

All premium features should integrate through existing architecture:

- **CEO Voice Synthesis**: New analyzer service + API endpoint
- **Live Guardian Mode**: WebSocket endpoint + real-time processing
- **Simulation Arena**: New database table + scenario management service
- **Gamification**: XP calculation service + achievement system
- **Additional Analyzers**: Implement same interface, add to pipeline

See `OPTIONAL_FEATURES_ROADMAP.md` for detailed implementation guides.
