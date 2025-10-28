# 🎉 Speech Mastery - START HERE

## ⚡ Get Running in 3 Commands

```bash
# 1. Setup (2 minutes)
bash quick-start.sh

# 2. Start backend (in new terminal)
bash run-backend.sh

# 3. Test it works (in another terminal)
bash test-api.sh
```

Then open in browser: **http://localhost:8000/docs**

---

## 📚 Documentation Guide

### 🚀 **For Quick Start** → Read: `QUICKSTART.md`
- Get running in 5 minutes
- Basic commands
- Troubleshooting
- **Read this first if you're in a hurry**

### 🔧 **For Complete Setup** → Read: `SETUP.md`
- Detailed step-by-step instructions
- Both direct Python and Docker options
- Full troubleshooting
- Project structure explanation
- **Read this for comprehensive understanding**

### 🏗️ **For Architecture** → Read: `WORKFLOW.md`
- ASCII architecture diagrams
- User journey visualization
- Backend pipeline explanation
- Data models
- API endpoint reference
- **Read this to understand how it all fits together**

### ⚙️ **For GitHub Actions** → Read: `GITHUB_ACTIONS_SETUP.md`
- Workflow configuration details
- How to monitor builds
- How to download artifacts
- Manual trigger instructions
- **Read this to understand cloud builds**

### 📖 **For Project Details** → Read: `CLAUDE.md`
- Design decisions and architecture
- Development commands
- Database schema
- Optional features roadmap
- **Read this to understand the design philosophy**

---

## 🎯 What's Ready to Use

### ✅ Backend (Python/FastAPI)
- **Status**: Fully implemented
- **Run**: `bash run-backend.sh`
- **URL**: http://localhost:8000
- **Docs**: http://localhost:8000/docs
- **Features**:
  - 4 speech analyzers (Power Dynamics, Linguistic Authority, Vocal Command, Persuasion)
  - FastAPI with auto-documentation
  - Request/response validation
  - Mock authentication

### ✅ iOS App (SwiftUI)
- **Status**: Code complete (ready to build)
- **Build**: GitHub Actions (automatic)
- **Views**: 5 complete views
  - RecordingView (record speeches)
  - AnalysisResultView (show scores)
  - RecordingsListView (list all)
  - DailyReportView (daily stats)
  - SettingsView (preferences)
- **ViewModels**: Full MVVM implementation
- **Services**: API client, storage, privacy

### ✅ GitHub Actions (CI/CD)
- **Status**: Fully configured
- **iOS Build**: Automatic on push
- **Backend Tests**: Automatic on push
- **Artifacts**: Downloadable after build

### ✅ Documentation
- **Status**: Comprehensive
- **Files**: 5 detailed guides + this file
- **Coverage**: Setup, architecture, workflows, API reference

---

## 📋 Script Reference

### Essential Scripts

| Script | Purpose | Command |
|--------|---------|---------|
| `quick-start.sh` | One-time setup | `bash quick-start.sh` |
| `run-backend.sh` | Start backend | `bash run-backend.sh` |
| `test-setup.sh` | Verify setup | `bash test-setup.sh` |
| `test-api.sh` | Test API | `bash test-api.sh` |

### Where to Use

```bash
# On your Linux machine:
cd /path/to/speech_analyzer

# First time only:
bash quick-start.sh

# Every day you want to develop:
bash run-backend.sh              # Terminal 1
bash test-api.sh                 # Terminal 2
```

---

## 🔄 Development Workflow

### 1. **Setup** (Once)
```bash
bash quick-start.sh
```
Creates virtual environment and installs dependencies.

### 2. **Start Backend** (Daily)
```bash
bash run-backend.sh
```
Starts FastAPI server on `localhost:8000`

### 3. **Test Locally** (As you code)
```bash
bash test-api.sh
```
Verifies backend is working and lists all endpoints.

### 4. **Make Changes** (In VSCode)
- Edit Python files in `backend/app/`
- Edit Swift files in `ios/SpeechMastery/`
- Backend auto-reloads (hot reload enabled)

### 5. **Test Changes** (Before pushing)
```bash
# Backend tests
pytest backend/

# Code style check
flake8 backend/app/
```

### 6. **Push to GitHub** (Share your changes)
```bash
git add .
git commit -m "Description of changes"
git push origin master
```
This automatically triggers:
- iOS build on macOS
- Backend tests on Linux

### 7. **Monitor GitHub Actions**
- Go to: `https://github.com/YOUR_USERNAME/speech_analyzer/actions`
- Watch workflows run
- Download artifacts when complete

---

## 🌐 URLs & Access Points

### Local Development (After running `bash run-backend.sh`)
```
API Service:        http://localhost:8000
Swagger UI:         http://localhost:8000/docs
ReDoc Alternative:  http://localhost:8000/redoc
OpenAPI JSON:       http://localhost:8000/openapi.json
Health Check:       http://localhost:8000/health
```

### GitHub
```
Repository:         https://github.com/YOUR_USERNAME/speech_analyzer
Actions:            https://github.com/YOUR_USERNAME/speech_analyzer/actions
Workflows:          .github/workflows/ (in your repo)
```

### IDE
```
VSCode:             Edit code on Linux
GitHub Desktop:     Manage git
Browser DevTools:   Debug API
```

---

## 🎓 Understanding the Project

### Three Layers

```
┌─────────────────────────────────────────┐
│  iOS App (SwiftUI)                      │
│  • RecordingView: Record audio          │
│  • AnalysisView: Show results           │
│  • LibraryView: List recordings         │
│  • SettingsView: Configure app          │
├─────────────────────────────────────────┤
│  Backend API (FastAPI)                  │
│  • Transcribe audio (Whisper)           │
│  • Analyze speech (4 analyzers)         │
│  • Store results (SQLite/PostgreSQL)    │
│  • Return JSON with scores              │
├─────────────────────────────────────────┤
│  Infrastructure (GitHub Actions)        │
│  • Build iOS app on macOS               │
│  • Test backend on Linux                │
│  • Run on your code changes             │
└─────────────────────────────────────────┘
```

### Data Flow

```
User records speech (iOS)
        ↓
Sends audio to backend (http://localhost:8000)
        ↓
Backend processes in parallel:
  • Transcription
  • Power Dynamics Analysis
  • Linguistic Authority Analysis
  • Vocal Command Analysis
  • Persuasion & Influence Analysis
        ↓
Returns JSON with scores & patterns
        ↓
iOS displays beautiful results
```

---

## 🚀 The Fast Way (Impatient? Start Here)

```bash
# 1. Get running (5 min)
bash quick-start.sh
bash run-backend.sh

# 2. See it working (1 min)
bash test-api.sh

# 3. Open in browser (immediately)
# Go to: http://localhost:8000/docs

# 4. Push to GitHub (whenever ready)
git push origin master

# 5. Watch build (5 min)
# Go to: GitHub.com > Actions tab
```

---

## 🛠️ When Things Go Wrong

### "Backend won't start"
```bash
bash test-setup.sh        # Check what's wrong
python3 --version         # Need 3.9+
lsof -i :8000            # Port in use?
kill -9 <PID>            # Kill process
```

### "Can't connect to localhost:8000"
```bash
# Make sure backend is running
ps aux | grep uvicorn

# Restart it
bash run-backend.sh
```

### "Test setup fails"
```bash
# Re-run setup
bash quick-start.sh

# Check Python
python3 --version        # Need 3.9+

# Read detailed guide
cat SETUP.md
```

### "GitHub Actions build fails"
1. Go to: `GitHub.com > Actions > [workflow]`
2. Click on the failed step
3. Read the error message
4. Fix in your code locally
5. Push again

---

## 📞 Quick Reference Card

```bash
# ONE-TIME SETUP
bash quick-start.sh

# DAILY DEVELOPMENT
bash run-backend.sh                    # Terminal 1
bash test-api.sh                       # Terminal 2

# TESTING
bash test-setup.sh
pytest backend/
flake8 backend/app/

# GIT WORKFLOW
git add .
git commit -m "What I changed"
git push origin master

# TROUBLESHOOTING
python3 --version                      # Check Python
lsof -i :8000                         # Check port
ps aux | grep uvicorn                 # Check backend
```

---

## 📊 Status Summary

| Component | Status | Location |
|-----------|--------|----------|
| **Backend API** | ✅ Ready | `backend/app/main.py` |
| **iOS App** | ✅ Code complete | `ios/SpeechMastery/` |
| **Documentation** | ✅ Comprehensive | `*.md` files |
| **GitHub Actions** | ✅ Configured | `.github/workflows/` |
| **Setup Scripts** | ✅ Ready | `quick-start.sh`, `run-backend.sh` |
| **Docker** | ✅ Ready | `docker-compose.yml` |

---

## 🎯 Next Step

**Right now**:
```bash
bash quick-start.sh
```

Then read: `QUICKSTART.md`

That's it! You're on your way. 🚀

---

## 📖 Full Documentation Index

1. **START_HERE.md** ← You are here
2. **QUICKSTART.md** - Get running fast
3. **SETUP.md** - Detailed setup guide
4. **WORKFLOW.md** - Architecture & diagrams
5. **GITHUB_ACTIONS_SETUP.md** - CI/CD details
6. **CLAUDE.md** - Project design & philosophy

---

**Questions? Start with QUICKSTART.md or SETUP.md.**

**Ready? Type: `bash quick-start.sh`**

