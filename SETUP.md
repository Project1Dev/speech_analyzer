# Speech Mastery - Complete Setup Guide

This guide covers everything you need to run the app and backend on Linux.

## Table of Contents
1. [Backend Setup (Linux)](#backend-setup-linux)
2. [iOS App Testing](#ios-app-testing)
3. [GitHub Actions for Builds](#github-actions-for-builds)
4. [Testing the Complete Flow](#testing-the-complete-flow)

---

## Backend Setup (Linux)

### ✅ Option A: Run Backend Directly on Linux (Easiest)

#### Prerequisites
```bash
# Install Python 3.9+
python3 --version

# Install pip
python3 -m pip --version

# Install PostgreSQL client (optional, for psql CLI)
sudo apt-get install postgresql-client
```

#### Step 1: Set Up Virtual Environment
```bash
cd backend

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# You should see (venv) prefix in terminal now
```

#### Step 2: Install Dependencies
```bash
# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt

# Verify installation
python -c "import fastapi; print('✅ FastAPI installed')"
```

#### Step 3: Create .env File
```bash
# In backend directory, create .env
cat > .env << 'EOF'
DATABASE_URL=sqlite:///./test.db
REDIS_URL=redis://localhost:6379
SINGLE_USER_TOKEN=SINGLE_USER_DEV_TOKEN_12345
ENVIRONMENT=development
UPLOAD_DIR=./uploads
EOF
```

**Note**: For development, we're using SQLite instead of PostgreSQL. This works offline!

#### Step 4: Run the Backend
```bash
# Still in backend directory with venv activated
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Expected Output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

#### Step 5: Test Backend is Running
```bash
# Open another terminal
curl http://localhost:8000/docs

# OR open browser to:
# http://localhost:8000/docs
```

You should see the **Swagger UI** with all API endpoints!

---

### ✅ Option B: Run with Docker (Single Command)

#### Prerequisites
```bash
# Install Docker
docker --version

# Install Docker Compose
docker-compose --version
```

#### Run Everything
```bash
# From project root
docker-compose up -d

# Check if running
docker-compose ps

# View logs
docker-compose logs -f backend
```

**Services started:**
- Backend: `http://localhost:8000`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
- pgAdmin: `http://localhost:5050`

#### Stop Everything
```bash
docker-compose down
```

---

## iOS App Testing

### ⚠️ Why You Need macOS/Xcode for iOS

iOS apps require Apple's SDK which is **only available on macOS**. You have 3 options:

### Option 1: GitHub Actions (Recommended - Fully Automated)

1. **Push code to GitHub:**
   ```bash
   git add .
   git commit -m "Complete iOS implementation"
   git push origin master
   ```

2. **Watch the build:**
   - Go to https://github.com/YOUR_USERNAME/speech_analyzer
   - Click "Actions" tab
   - You'll see workflows running on macOS automatically

3. **Download the build:**
   - After build completes, click the workflow run
   - Scroll down to "Artifacts"
   - Download `ios-build-artifacts` folder

**What gets built:**
- iOS app for simulator
- Build logs
- Test reports (if tests run)

---

### Option 2: Rent a Mac in the Cloud

Services that provide remote macOS:
- **AWS EC2 Mac instances** (~$10/hour)
- **MacStadium** (monthly plans)
- **MacInCloud** (hourly + monthly)

Then SSH in and build:
```bash
# On the cloud Mac
cd /path/to/project
xcodebuild -scheme SpeechMastery -configuration Debug
```

---

### Option 3: Use iOS Testing Services

Services that let you test iOS apps:
- **BrowserStack Live** - Run on real iOS devices
- **TestFlight** - Apple's beta testing (requires provisioning)
- **Simulator Cloud** - Run simulator in browser

These require building the app first (use GitHub Actions).

---

## GitHub Actions for Builds

### How It Works

GitHub Actions automatically:
1. **Builds on macOS** whenever you push code
2. **Runs tests** automatically
3. **Uploads artifacts** for download
4. **Sends notifications** if build fails

### View Build Status

```bash
# After pushing code
git push origin master

# Go to GitHub
# Repository > Actions tab
```

### Manual Build Trigger

You can trigger builds without pushing:

```bash
# On GitHub, go to Actions > Build iOS App > Run workflow
# Click the green "Run workflow" button
```

### What the Workflows Do

**`build-ios.yml`** (Runs on macOS):
- ✅ Checks out code
- ✅ Builds for simulator
- ✅ Runs unit tests
- ✅ Uploads build artifacts

**`test-backend.yml`** (Runs on Linux):
- ✅ Tests on Python 3.9, 3.10, 3.11
- ✅ Runs with PostgreSQL + Redis
- ✅ Checks code imports
- ✅ Uploads coverage reports

---

## Testing the Complete Flow

### 1️⃣ Start Backend (Linux Terminal 1)

```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2️⃣ Test Backend API (Linux Terminal 2)

```bash
# Test the API docs
curl http://localhost:8000/docs

# List all routes
curl http://localhost:8000/openapi.json | jq '.paths | keys'

# Example: Try an endpoint (if implemented)
curl -X POST http://localhost:8000/analyze \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 3️⃣ Build iOS App (GitHub)

1. Push your code:
   ```bash
   git add .
   git commit -m "Complete implementation"
   git push origin master
   ```

2. Monitor build:
   - Go to GitHub > Actions
   - Watch "Build iOS App" workflow

3. Download artifacts when done

### 4️⃣ Test the Backend API Locally (Optional)

Use a REST client:

**Option A: With curl**
```bash
# Health check
curl http://localhost:8000/health

# API documentation
curl http://localhost:8000/docs

# List endpoints
curl http://localhost:8000/openapi.json
```

**Option B: With Postman**
1. Download Postman
2. Create a new request
3. Set URL: `http://localhost:8000/docs`
4. Test endpoints from Swagger UI

**Option C: With Python**
```python
import requests

BASE_URL = "http://localhost:8000"
TOKEN = "SINGLE_USER_DEV_TOKEN_12345"

headers = {"Authorization": f"Bearer {TOKEN}"}

# Test API
response = requests.get(f"{BASE_URL}/health", headers=headers)
print(response.json())
```

---

## Project Structure Reference

```
speech_analyzer/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI entry point
│   │   ├── api/                 # API endpoints
│   │   ├── services/            # Business logic
│   │   ├── models/              # Database models
│   │   └── schemas/             # Request/response schemas
│   ├── requirements.txt
│   ├── .env                     # Configuration
│   ├── Dockerfile               # Docker image
│   └── venv/                    # Virtual environment
│
├── ios/
│   └── SpeechMastery/
│       ├── Views/               # SwiftUI views (RecordingView, etc.)
│       ├── ViewModels/          # MVVM view models
│       ├── Services/            # API client, storage, etc.
│       ├── Models/              # Data structures
│       └── SpeechMastery.xcodeproj
│
├── docker-compose.yml           # Docker services (PostgreSQL, Redis)
├── .github/workflows/           # GitHub Actions
│   ├── build-ios.yml            # iOS build workflow
│   └── test-backend.yml         # Backend test workflow
└── SETUP.md                     # This file
```

---

## Troubleshooting

### Backend Won't Start

```bash
# Check port is not in use
lsof -i :8000

# Kill process on port 8000 if needed
kill -9 $(lsof -t -i:8000)

# Check Python version
python3 --version  # Should be 3.9+

# Reinstall requirements
pip install --upgrade -r requirements.txt
```

### Can't connect to http://localhost:8000

```bash
# Is the backend actually running?
ps aux | grep uvicorn

# Try with verbose output
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --log-level debug
```

### GitHub Actions Build Failing

1. Check the workflow logs: `GitHub > Actions > [workflow name] > Build step`
2. Common issues:
   - Missing `.env` file (GitHub doesn't have it)
   - Pod dependencies not installed
   - Xcode version incompatibility

3. **Solution for local testing:**
   ```bash
   # Test your iOS build locally if you have a Mac
   cd ios/SpeechMastery
   xcodebuild -version
   xcodebuild -scheme SpeechMastery -configuration Debug
   ```

### Database Issues

```bash
# If using Docker PostgreSQL
docker-compose logs postgres

# If using SQLite
rm test.db  # Delete and recreate
```

---

## Next Steps

### ✅ Immediate Goals
1. Run backend with: `uvicorn app.main:app --reload`
2. Access Swagger UI: `http://localhost:8000/docs`
3. Push to GitHub and watch iOS build in Actions

### 📱 Running the iOS App

You have two realistic paths:

**Path 1: Use GitHub Actions Build** (Recommended)
- Actions builds on macOS
- You get simulator build
- Can test in cloud or on Mac

**Path 2: Get Access to a Mac**
- Borrow a Mac temporarily
- Use cloud Mac services
- Download the build from GitHub Actions and run on simulator

### 🔄 Development Workflow

```bash
# 1. Make code changes in VSCode on Linux
# 2. Test backend locally
uvicorn app.main:app --reload

# 3. Commit and push
git push origin master

# 4. GitHub Actions automatically:
#    - Builds iOS app
#    - Tests backend
#    - Uploads artifacts

# 5. Check GitHub > Actions for results
```

---

## Useful Commands

### Backend Development
```bash
# Activate venv
source backend/venv/bin/activate

# Run with hot reload
uvicorn app.main:app --reload

# Run tests
pytest backend/

# Check code style
flake8 app/

# Database migrations (if using)
alembic upgrade head
alembic revision --autogenerate -m "description"
```

### Docker
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Rebuild images
docker-compose up -d --build
```

### Git & GitHub
```bash
# View workflows
git log --oneline

# Trigger build
git push origin master

# Check Actions online at:
# https://github.com/YOUR_USERNAME/speech_analyzer/actions
```

---

## Additional Resources

- **FastAPI Docs**: https://fastapi.tiangolo.com
- **Docker**: https://docs.docker.com
- **GitHub Actions**: https://docs.github.com/en/actions
- **Swift/iOS**: https://developer.apple.com/swift

---

**You're all set!** Questions? Check the GitHub Issues or project CLAUDE.md file.
