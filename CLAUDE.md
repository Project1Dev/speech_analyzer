# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Speech Mastery App is an iOS-based personal AI speech coach with server-backed analysis. It analyzes speech patterns to detect filler words, hedging, passive voice, and provides personalized feedback for communication improvement.

**Architecture**: Client-server with iOS app (SwiftUI) + FastAPI backend + PostgreSQL database

## Development Commands

### Backend Development

```bash
# Start all services (PostgreSQL, Redis, FastAPI)
docker-compose up -d

# Run backend with hot reload (after docker-compose is up)
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run database migrations
cd backend
alembic upgrade head

# Create new migration
alembic revision --autogenerate -m "description"

# Run tests
cd backend
pytest

# Run tests with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_api/test_analyze.py
```

### iOS Development

```bash
# Open iOS project
open ios/SpeechMastery/SpeechMastery.xcodeproj

# Run tests (command line)
xcodebuild test \
  -project ios/SpeechMastery/SpeechMastery.xcodeproj \
  -scheme SpeechMastery \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Docker Services

```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild containers
docker-compose up -d --build

# Check service health
docker-compose ps
```

Services available at:
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Database: localhost:5432
- pgAdmin: http://localhost:5050

## Dual-VM Development Setup

This project uses a **dual-VM development workflow**:

- **Linux VM**: Backend development (FastAPI, PostgreSQL, Docker)
- **macOS VM**: iOS app development (Xcode, Simulator)

Both VMs run on the same host machine and communicate via host networking.

### Why Dual-VM?

iOS builds via GitHub Actions were problematic (code signing, slow builds, cluttered commit history). Building iOS locally on macOS VM provides:
- Faster iteration cycles
- Native Xcode environment
- Easier debugging with Simulator
- No CI/CD complexity for iOS

Backend continues to use GitHub Actions for testing (pytest on multiple Python versions).

### Development Workflow

**Typical cycle:**
1. **Linux VM**: Make backend changes, test with pytest
2. **Linux VM**: Commit and push to GitHub
3. **macOS VM**: Pull latest changes
4. **macOS VM**: Build iOS app, test integration with backend
5. **macOS VM**: Commit iOS changes, push to GitHub
6. **Linux VM**: Pull if needed

### Network Configuration

**Backend accessibility from iOS app:**

1. **On Linux VM**: Docker services already bind to `0.0.0.0` (see docker-compose.yml)
2. **Find Linux VM IP**:
   ```bash
   # On Linux VM
   ip addr show | grep "inet " | grep -v 127.0.0.1
   # Or use helper script
   cd backend && ./show_api_url.sh
   ```
3. **Configure iOS app**: Update `ios/SpeechMastery/Utilities/Constants.swift` with Linux VM IP
4. **Test connectivity**:
   ```bash
   # From macOS VM
   curl http://<linux-vm-ip>:8000/health
   ```

**Port requirements:**
- Port 8000: FastAPI backend
- Port 5432: PostgreSQL (if iOS needs direct DB access)

### macOS VM Setup

See `docs/MACOS_VM_SETUP.md` for detailed instructions on:
- Installing Xcode and XcodeGen
- Cloning repository
- Generating Xcode project with `xcodegen generate`
- Configuring API endpoint
- Running iOS Simulator

### Git Workflow

**Best practices:**
- Commit frequently on each VM
- Use clear commit messages indicating which component changed
- Push after completing logical units of work
- Pull on other VM before starting new work
- Avoid editing same files simultaneously on both VMs

**Branch strategy:**
- `master`: Main development branch
- Feature branches: Create when working on major features
- Always test integration before merging

### CI/CD Strategy

- **Backend**: GitHub Actions runs pytest on push (see `.github/workflows/test-backend.yml`)
- **iOS**: No CI/CD - built locally on macOS VM
- **Integration tests**: Manual testing between iOS app and backend

### Troubleshooting

**iOS can't reach backend:**
- Check firewall on Linux VM: `sudo ufw status`
- Verify backend is running: `docker-compose ps`
- Check Linux VM IP hasn't changed
- Test with curl from macOS VM

**Git conflicts:**
- Usually happen when editing same files on both VMs
- Pull before starting work to minimize conflicts
- Use `git stash` if you need to pull with uncommitted changes

## Architecture Overview

### iOS App (MVVM Pattern)

The iOS app follows strict MVVM separation:

**Data Flow**: View → ViewModel → Service → Storage/API

- **Models**: Data structures (Recording, AnalysisResult, Report). All are Codable and Identifiable structs.
- **Services**: Business logic layer
  - AudioRecordingService: Manages AVFoundation recording
  - AudioStorageService: Local file persistence and UserDefaults
  - APIService: HTTP client for backend communication
  - PrivacyManager: Microphone permissions
  - AutoDeletionService: 7-day cleanup
- **ViewModels**: Bridge between Views and Services, expose @Published properties for UI binding
- **Views**: SwiftUI components (RecordingView, AnalysisResultView, DailyReportView)

### Backend (Layered Architecture)

**Request Flow**: API Layer → Service Layer → AI Engines/Data Layer

- **API Layer** (`app/api/`): FastAPI routes, request validation (Pydantic), authentication
- **Service Layer** (`app/services/`):
  - AnalysisEngine: Orchestrates analysis pipeline
  - Analyzer Services: PowerDynamicsAnalyzer, LinguisticAuthorityAnalyzer, VocalCommandAnalyzer, PersuasionAnalyzer
  - TranscriptionService: Abstract interface for speech-to-text
  - NLPService: Abstract interface for text analysis
  - ReportGenerator: Daily aggregation
- **Data Layer** (`app/models/`, `app/core/`): SQLAlchemy ORM, database connection pool, Alembic migrations

### Analysis Pipeline

```
Audio Upload → Save temp file → Transcribe → Parallel Analysis (4 analyzers)
→ Aggregate scores → Calculate critical moments → Store PostgreSQL → Return JSON
```

**Key Design**: AI services use abstract interfaces to allow easy swapping of implementations (Whisper, spaCy, etc.)

## Important File Locations

### Backend Structure
```
backend/
├── app/
│   ├── main.py                 # FastAPI app entry point
│   ├── api/                    # API endpoints (TODO: not yet created)
│   ├── services/               # Business logic and analyzers
│   │   ├── power_dynamics_analyzer.py
│   │   ├── linguistic_authority_analyzer.py
│   │   ├── vocal_command_analyzer.py
│   │   └── persuasion_influence_analyzer.py
│   ├── models/                 # SQLAlchemy models
│   ├── schemas/                # Pydantic schemas
│   └── core/                   # Config, database, logging
├── alembic/                    # Database migrations
└── tests/                      # Pytest test suite
```

### iOS Structure
```
ios/SpeechMastery/
├── Models/                     # Data structures
├── Services/                   # Business logic
├── ViewModels/                 # MVVM view models
├── Views/                      # SwiftUI views
└── Utilities/                  # Constants, helpers
```

## Current State

This is a **BASE PROTOTYPE** in early development stage:

- ✅ Docker environment configured (docker-compose.yml)
- ✅ Basic FastAPI app structure (app/main.py)
- ✅ Four analyzer service skeletons created
- ⚠️ Most implementation is TODO - API endpoints, database models, iOS app need to be built

**Authentication**: Single-user mode with hardcoded token `SINGLE_USER_DEV_TOKEN_12345`

## Key Technical Decisions

1. **Abstract AI Interfaces**: TranscriptionService and NLPService are generic interfaces to enable easy swapping of AI providers
2. **Synchronous Processing**: Base prototype uses blocking analysis (simple, debuggable). Async processing with Celery is an optional future feature.
3. **Privacy-First**: NSFileProtectionComplete encryption, 7-day auto-deletion, manual review before upload
4. **MVVM on iOS**: Strict separation ensures testability and clear data flow
5. **Layered Backend**: API → Service → Data layer separation for maintainability

## Environment Configuration

Backend environment variables (`.env`):
- `DATABASE_URL`: PostgreSQL connection string
- `SINGLE_USER_TOKEN`: Auth token for prototype
- `UPLOAD_DIR`: File storage location
- `TRANSCRIPTION_SERVICE`: Which transcription provider (mock/whisper/etc)
- `NLP_SERVICE`: Which NLP provider (mock/spacy/etc)
- Feature flags: `ENABLE_CEO_VOICE`, `ENABLE_LIVE_GUARDIAN`, etc.

iOS API configuration (`ios/SpeechMastery/Utilities/Constants.swift`):
- For simulator: `http://localhost:8000`
- For physical device: Use Mac's local IP (find with `ifconfig | grep "inet " | grep -v 127.0.0.1`)

## Testing Approach

### Backend
- Unit tests: Individual analyzer functions
- Integration tests: Full API endpoint flows
- Fixtures: Sample audio, transcripts, expected outputs
- Coverage target: 80%+ for core analysis logic

### iOS
- XCTest for Models, Services, ViewModels
- XCUITest for critical user flows
- SwiftUI canvas for visual verification
- Mock data: Sample recordings and API responses

## Premium Features (Optional, Future)

All marked as `OPTIONAL FEATURE` or `TODO` in comments:
- CEO Voice Synthesis
- Live Guardian Mode (real-time analysis)
- Simulation Arena (roleplay practice)
- Gamification system
- Multi-user JWT authentication

These should integrate through existing architecture without major refactoring.

## API Endpoints (See docs/API_CONTRACT.md)

**Core endpoints**:
- `POST /analyze` - Upload and analyze audio
- `GET /reports/{date}` - Daily aggregated report
- `GET /recordings` - List user recordings
- `DELETE /recordings/{id}` - Remove recording

All requests require: `Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345`

## Common Development Patterns

### Adding a New Analyzer

1. Create class in `backend/app/services/` extending BaseAnalyzer
2. Register in AnalysisEngine
3. Add database columns via Alembic migration
4. Update response schemas
5. Create iOS display view

### Adding an API Endpoint

1. Define Pydantic schemas in `app/schemas/`
2. Create endpoint in `app/api/routes.py`
3. Add tests in `tests/test_api/`
4. Update API_CONTRACT.md
5. Implement iOS APIService method

### Database Schema Changes

1. Edit SQLAlchemy models
2. Run `alembic revision --autogenerate -m "description"`
3. Review generated migration
4. Run `alembic upgrade head`

## Database Schema

PostgreSQL with key tables:
- `users` - Single-user for prototype
- `recordings` - Audio file metadata
- `analysis_results` - Comprehensive speech analysis with JSONB patterns field
- `daily_reports` - Aggregated daily statistics

See `docs/DATABASE_SCHEMA.md` for complete schema.

## Additional Documentation

- `docs/ARCHITECTURE.md` - Detailed system architecture
- `docs/API_CONTRACT.md` - Complete API specification
- `docs/DEVELOPMENT_GUIDE.md` - Setup and workflow guide
- `docs/DATABASE_SCHEMA.md` - Database schema details
- `docs/OPTIONAL_FEATURES_ROADMAP.md` - Premium features plan
