# Development Guide

Complete setup and development workflow guide for the Speech Mastery App.

## Prerequisites

### Required
- **macOS** 13.0+ (for iOS development)
- **Xcode** 15.0+ with Command Line Tools
- **Docker Desktop** 4.0+ (for backend services)
- **Python** 3.11+
- **Git** 2.40+

### Optional
- **Homebrew** (package manager for macOS)
- **pyenv** (Python version management)
- **Swift-format** (code formatting)

---

## Initial Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd speech_analyzer
```

### 2. Backend Setup

```bash
# Run automated setup script
./scripts/setup_backend.sh

# Or manual setup:
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your configurations
```

**Environment Variables** (`backend/.env`):
```bash
# Database
DATABASE_URL=postgresql://speechuser:password@localhost:5432/speechmastery

# Security (single-user mode)
SINGLE_USER_TOKEN=SINGLE_USER_DEV_TOKEN_12345

# File Storage
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=52428800  # 50MB

# AI Services (placeholders)
TRANSCRIPTION_SERVICE=mock  # or 'whisper', 'assemblyai', etc.
NLP_SERVICE=mock  # or 'spacy', 'huggingface', etc.

# Feature Flags
ENABLE_CEO_VOICE=false
ENABLE_LIVE_GUARDIAN=false
ENABLE_SIMULATION_ARENA=false
ENABLE_GAMIFICATION=false

# Logging
LOG_LEVEL=INFO
```

### 3. Start Backend Services

```bash
# From project root
docker-compose up -d

# Verify services are running
docker-compose ps

# Should show:
# - postgres (port 5432)
# - redis (port 6379)
# - fastapi (port 8000)
```

### 4. Run Database Migrations

```bash
cd backend
source venv/bin/activate

# Run migrations
alembic upgrade head

# Seed single-user data
python scripts/seed_single_user.py
```

### 5. Verify Backend

```bash
# Test health endpoint
curl http://localhost:8000/health

# Expected response:
# {"status": "healthy", "version": "1.0.0"}

# Test authentication
curl -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
     http://localhost:8000/recordings

# Expected: Empty list or test recordings
```

### 6. iOS Project Setup

```bash
# Run automated setup script
./scripts/setup_ios.sh

# Or manual setup:
cd ios/SpeechMastery

# Install dependencies (if using Swift Package Manager)
# Dependencies will be resolved on first Xcode build

# Open project
open SpeechMastery.xcodeproj
```

**Xcode Configuration**:
1. Select development team in Signing & Capabilities
2. Ensure iOS Deployment Target is 16.0+
3. Add microphone permission description to Info.plist:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access to record and analyze your speech.</string>
   ```

### 7. Configure API Endpoint in iOS

Edit `ios/SpeechMastery/Utilities/Constants.swift`:

```swift
struct APIConstants {
    // For simulator, use localhost
    static let baseURL = "http://localhost:8000"

    // For physical device, use your Mac's local IP
    // static let baseURL = "http://192.168.1.XXX:8000"

    static let authToken = "SINGLE_USER_DEV_TOKEN_12345"
}
```

**Finding Your Mac's IP**:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

---

## Development Workflow

### Running the App

#### Backend
```bash
# Terminal 1: Start Docker services
docker-compose up

# Terminal 2: Run FastAPI with hot reload
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### iOS
1. Open `ios/SpeechMastery/SpeechMastery.xcodeproj` in Xcode
2. Select target device/simulator
3. Press Cmd+R to build and run
4. For SwiftUI previews: Cmd+Option+P

### Making Changes

#### Backend Changes
1. Edit Python files in `backend/app/`
2. FastAPI auto-reloads (with `--reload` flag)
3. Run tests: `pytest`
4. Check logs: `docker-compose logs -f fastapi`

#### iOS Changes
1. Edit Swift files in `ios/SpeechMastery/`
2. Xcode automatically rebuilds
3. Use SwiftUI canvas for live previews
4. Run tests: Cmd+U

#### Database Schema Changes
```bash
cd backend

# Create migration
alembic revision --autogenerate -m "Add new column"

# Review generated migration in alembic/versions/

# Apply migration
alembic upgrade head

# Rollback if needed
alembic downgrade -1
```

---

## Testing

### Backend Tests

```bash
cd backend
source venv/bin/activate

# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_api/test_analyze.py

# Run with verbose output
pytest -v

# Run only unit tests (fast)
pytest -m unit

# Run only integration tests
pytest -m integration
```

**Test Structure**:
```
backend/tests/
├── conftest.py              # Shared fixtures
├── test_api/
│   ├── test_analyze.py      # POST /analyze tests
│   └── test_reports.py      # GET /reports tests
├── test_services/
│   ├── test_analysis_engine.py
│   └── test_analyzers.py
└── fixtures/
    ├── sample_audio.wav
    └── mock_responses.py
```

### iOS Tests

```bash
# Command line (from project root)
xcodebuild test \
  -project ios/SpeechMastery/SpeechMastery.xcodeproj \
  -scheme SpeechMastery \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: Cmd+U
```

**Test Structure**:
```
ios/SpeechMasteryTests/
├── ModelTests/
│   ├── RecordingTests.swift
│   └── AnalysisResultTests.swift
├── ServiceTests/
│   ├── AudioRecordingServiceTests.swift
│   └── APIServiceTests.swift
├── ViewModelTests/
│   └── RecordingViewModelTests.swift
└── MockData/
    ├── MockRecordings.swift
    └── MockAPIResponses.swift
```

### Running All Tests

```bash
# From project root
./scripts/run_tests.sh

# This script runs:
# 1. Backend unit tests
# 2. Backend integration tests
# 3. iOS unit tests
# 4. Linting checks
```

---

## Code Quality

### Python (Backend)

```bash
# Linting
ruff check app/

# Formatting
black app/

# Type checking
mypy app/

# All checks
./scripts/check_backend.sh
```

**Pre-commit Hook** (optional):
```bash
pip install pre-commit
pre-commit install

# Now runs automatically on git commit
```

### Swift (iOS)

```bash
# Install swift-format
brew install swift-format

# Format code
swift-format -i -r ios/SpeechMastery/

# Lint
swiftlint lint ios/SpeechMastery/
```

---

## Debugging

### Backend Debugging

**Print Debugging**:
```python
from app.core.logging import logger

logger.info("Processing recording", extra={"recording_id": recording_id})
logger.error("Analysis failed", exc_info=True)
```

**Interactive Debugging**:
```python
# Add breakpoint
import pdb; pdb.set_trace()

# Or with ipdb (install via pip install ipdb)
import ipdb; ipdb.set_trace()
```

**VS Code Launch Config** (`.vscode/launch.json`):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": ["app.main:app", "--reload"],
      "cwd": "${workspaceFolder}/backend",
      "env": {"PYTHONPATH": "${workspaceFolder}/backend"}
    }
  ]
}
```

### iOS Debugging

**Xcode Debugger**:
- Set breakpoints: Click line numbers in Xcode
- View variables: Hover or check Variables pane
- LLDB commands: `po variableName` in console

**SwiftUI View Debugging**:
```swift
.onAppear {
    print("DEBUG: View appeared with state: \(someState)")
}

// Or use custom debug modifier
extension View {
    func debugPrint(_ value: Any) -> some View {
        print("DEBUG:", value)
        return self
    }
}
```

**Network Debugging**:
- Use Charles Proxy or Proxyman
- Or enable detailed URLSession logging:
```swift
let config = URLSessionConfiguration.default
config.protocolClasses = [DebugURLProtocol.self]
```

---

## Common Tasks

### Adding a New API Endpoint

1. **Define Pydantic Schema** (`backend/app/schemas/`):
```python
from pydantic import BaseModel

class NewFeatureRequest(BaseModel):
    param1: str
    param2: int

class NewFeatureResponse(BaseModel):
    result: str
```

2. **Create Endpoint** (`backend/app/api/routes.py`):
```python
@router.post("/new-feature", response_model=NewFeatureResponse)
async def new_feature(
    request: NewFeatureRequest,
    db: AsyncSession = Depends(get_db)
):
    # Implementation
    return NewFeatureResponse(result="success")
```

3. **Add Tests** (`backend/tests/test_api/test_new_feature.py`):
```python
def test_new_feature(client):
    response = client.post("/new-feature", json={
        "param1": "test",
        "param2": 123
    })
    assert response.status_code == 200
    assert response.json()["result"] == "success"
```

4. **Update API Contract** (`docs/API_CONTRACT.md`)

5. **Implement iOS Client** (`ios/SpeechMastery/Services/APIService.swift`)

### Adding a New Speech Analyzer

1. **Create Analyzer Class** (`backend/app/services/new_analyzer.py`):
```python
from app.services.base_analyzer import BaseAnalyzer

class NewPatternAnalyzer(BaseAnalyzer):
    def analyze(self, transcript: str, metadata: dict) -> dict:
        # Analysis logic
        return {
            "score": 75.0,
            "patterns": {...},
            "issues": [...]
        }
```

2. **Register in Analysis Engine** (`backend/app/services/analysis_engine.py`):
```python
self.analyzers.append(NewPatternAnalyzer())
```

3. **Add to Database Schema** (create migration for new columns)

4. **Update Response Models** (`backend/app/schemas/analysis.py`)

5. **Create iOS Display** (`ios/SpeechMastery/Views/Analysis/NewPatternView.swift`)

### Adding a New SwiftUI View

1. **Create View File** (`ios/SpeechMastery/Views/Feature/NewView.swift`):
```swift
import SwiftUI

struct NewView: View {
    @StateObject private var viewModel = NewViewModel()

    var body: some View {
        VStack {
            Text("New Feature")
        }
        .navigationTitle("New Feature")
    }
}

#Preview {
    NewView()
}
```

2. **Create ViewModel** (`ios/SpeechMastery/ViewModels/NewViewModel.swift`)

3. **Add Navigation** (update `MainTabView.swift` or parent view)

4. **Write Tests** (`ios/SpeechMasteryTests/ViewModelTests/NewViewModelTests.swift`)

---

## Troubleshooting

### Backend Won't Start

**Issue**: Port 8000 already in use
```bash
# Find process using port
lsof -i :8000

# Kill process
kill -9 <PID>
```

**Issue**: Database connection failed
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### iOS Build Fails

**Issue**: "No such module" error
- Clean build folder: Cmd+Shift+K
- Reset package cache: File → Packages → Reset Package Caches

**Issue**: Simulator not found
- Open Xcode → Window → Devices and Simulators
- Add new simulator if needed

**Issue**: Microphone permission denied
- Simulator: Reset privacy settings in simulator menu
- Device: Settings → Privacy → Microphone → Allow app

### Analysis Returns Errors

**Issue**: "Transcription service unavailable"
- Check `TRANSCRIPTION_SERVICE` in `.env`
- Verify mock service is configured
- Check API keys if using external service

**Issue**: "NLP analysis failed"
- Verify `NLP_SERVICE` in `.env`
- Check model files are downloaded (for local services)
- Review error logs: `docker-compose logs fastapi`

---

## Performance Optimization

### Backend
- Use database indexes for frequent queries
- Cache analysis results in Redis (future)
- Optimize spaCy pipeline (disable unused components)
- Profile with `cProfile` for bottlenecks

### iOS
- Use lazy loading for recording lists
- Compress audio before upload
- Cache API responses locally
- Optimize SwiftUI view updates with `@State` vs `@Published`

---

## Deployment

### Local Production-Like Environment

```bash
# Use production docker-compose
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# With production environment variables
cp .env.prod.example .env.prod
docker-compose --env-file .env.prod up -d
```

### Backend Deployment (Future)

**OPTIONAL FEATURE: Production Deployment**
```bash
<!-- When deploying to production:

# Build Docker image
docker build -t speechmastery-backend:latest backend/

# Push to registry
docker tag speechmastery-backend:latest <registry>/speechmastery:latest
docker push <registry>/speechmastery:latest

# Deploy to cloud (example for AWS ECS)
ecs-cli compose --file docker-compose.prod.yml up

# Or use Heroku
heroku container:push web -a speechmastery-api
heroku container:release web -a speechmastery-api
-->
```

### iOS Deployment

**TestFlight (Beta)**:
1. Archive: Product → Archive in Xcode
2. Upload to App Store Connect
3. Submit for TestFlight review
4. Invite beta testers

**App Store (Production)**:
1. Increment version and build number
2. Archive and upload
3. Submit for App Store review
4. Release when approved

---

## Resources

### Documentation
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [SQLAlchemy Docs](https://docs.sqlalchemy.org/)
- [AVFoundation Guide](https://developer.apple.com/av-foundation/)

### Internal Docs
- [API Contract](./API_CONTRACT.md)
- [Database Schema](./DATABASE_SCHEMA.md)
- [Architecture](./ARCHITECTURE.md)
- [Optional Features Roadmap](./OPTIONAL_FEATURES_ROADMAP.md)

---

## Getting Help

### Common Commands Reference

```bash
# Backend
docker-compose up -d        # Start services
docker-compose down         # Stop services
docker-compose logs -f      # View logs
alembic upgrade head        # Run migrations
pytest                      # Run tests

# iOS
xcodebuild -list           # List schemes
xcodebuild clean build     # Clean build
xcodebuild test            # Run tests

# Git
git status                 # Check changes
git add .                  # Stage all changes
git commit -m "message"    # Commit
git push                   # Push to remote
```

### Debug Checklist

- [ ] Docker services running? (`docker-compose ps`)
- [ ] Environment variables set? (`.env` file exists)
- [ ] Database migrated? (`alembic upgrade head`)
- [ ] iOS permissions granted? (Microphone access)
- [ ] Correct API endpoint? (localhost vs device IP)
- [ ] Auth token matches? (iOS Constants.swift vs backend .env)
- [ ] Logs checked? (Xcode console & `docker-compose logs`)

---

## Contributing Guidelines

### Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch
- `feature/*`: New features
- `bugfix/*`: Bug fixes

### Commit Messages
```
feat: Add CEO voice synthesis endpoint
fix: Resolve recording permission crash
docs: Update API contract with new endpoint
test: Add unit tests for power dynamics analyzer
refactor: Extract analysis scoring logic
```

### Pull Request Process
1. Create feature branch from `develop`
2. Implement changes with tests
3. Run `./scripts/run_tests.sh`
4. Update documentation if needed
5. Submit PR with clear description
6. Address review feedback
7. Merge when approved

---

## Next Steps

After completing setup:
1. ✅ Run all tests to verify installation
2. ✅ Record a test audio clip in iOS app
3. ✅ Upload for analysis and view results
4. ✅ Explore the codebase and documentation
5. ✅ Pick a task from the project board
6. ✅ Start implementing!

For questions or issues, refer to the troubleshooting section or check internal documentation.
