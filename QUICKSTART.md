# 🚀 Quick Start - Speech Mastery

## **TL;DR - Get Running in 5 Minutes**

### Linux - Run Backend Immediately

```bash
# 1. One-time setup (2 minutes)
bash quick-start.sh

# 2. Start backend (in separate terminal)
bash run-backend.sh

# 3. Open in browser
# http://localhost:8000/docs
```

**That's it!** You now have a full API with Swagger documentation.

---

## What You'll See

### API Documentation (Interactive!)
```
http://localhost:8000/docs
```

Shows all available endpoints with:
- ✅ Try-it-out button for each endpoint
- ✅ Request/response examples
- ✅ Authentication header setup
- ✅ Full API specification

### Alternative API Docs
```
http://localhost:8000/redoc
```

---

## Testing the Setup

```bash
# Verify everything is configured
bash test-setup.sh

# Shows:
# ✅ Python version check
# ✅ Backend files found
# ✅ iOS files found
# ✅ GitHub Actions workflows
# ✅ Docker configuration
```

---

## For iOS Development (Build in Cloud)

### Step 1: Push to GitHub
```bash
git add .
git commit -m "My changes"
git push origin master
```

### Step 2: Watch Build
- Go to: `https://github.com/YOUR_USERNAME/speech_analyzer`
- Click: **Actions** tab
- Watch: iOS build run on macOS automatically
- Download: Build artifacts when complete

**No Mac needed!** The build happens in the cloud.

---

## Project Structure

```
speech_analyzer/
├── backend/              ← Run on Linux ✅
│   ├── app/
│   │   ├── main.py      ← FastAPI entry point
│   │   ├── services/    ← Analysis engines
│   │   ├── models/      ← Database
│   │   └── schemas/     ← Request/response
│   ├── requirements.txt
│   ├── .env            ← Config file
│   └── venv/           ← Python environment
│
├── ios/                 ← Build with GitHub Actions ☁️
│   └── SpeechMastery/
│       ├── Views/       ← RecordingView, etc.
│       ├── ViewModels/  ← MVVM models
│       ├── Services/    ← API client
│       └── Models/      ← Data structures
│
├── quick-start.sh       ← Run this first!
├── run-backend.sh       ← Run backend
├── test-setup.sh        ← Test setup
└── SETUP.md            ← Full guide
```

---

## Common Tasks

### Start Backend
```bash
bash run-backend.sh
```
Starts at: `http://localhost:8000`

### Stop Backend
Press `Ctrl+C` in terminal

### View API Documentation
```
http://localhost:8000/docs
```

### Test an API Endpoint
```bash
# From any terminal
curl -X GET http://localhost:8000/health \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345"
```

### Build iOS App
1. Commit code: `git push origin master`
2. Go to GitHub Actions
3. Watch build complete in 5-10 minutes
4. Download artifacts

### Run with Docker (Optional)
```bash
# Start all services (backend + database + redis)
docker-compose up -d

# Stop everything
docker-compose down

# View logs
docker-compose logs -f backend
```

---

## Troubleshooting

### Backend won't start
```bash
# Check what's running on port 8000
lsof -i :8000

# If something is there, kill it
kill -9 <PID>

# Then try again
bash run-backend.sh
```

### Python not found
```bash
# You need Python 3.9+
python3 --version

# If you have it, use:
python3 -m pip install -r backend/requirements.txt
```

### Can't connect to localhost:8000
```bash
# Make sure backend is actually running
ps aux | grep uvicorn

# Check firewall (rarely an issue locally)
# Or try: http://127.0.0.1:8000/docs
```

### GitHub Actions build failing
1. Check the workflow logs in: `GitHub > Actions > [workflow] > Build step`
2. Common issues:
   - Missing files
   - Xcode version incompatibility
   - Pod installation failed

---

## Architecture Overview

### Backend (Python/FastAPI)
- **Input**: Audio files + metadata from iOS app
- **Processing**: 4 speech analyzers (Power Dynamics, Linguistic Authority, Vocal Command, Persuasion)
- **Output**: JSON with scores, patterns, critical moments
- **Storage**: SQLite (local) or PostgreSQL (production)

### iOS App (SwiftUI)
- **Recording**: Captures audio using AVFoundation
- **Display**: Shows real-time waveform + duration
- **Analysis**: Sends to backend for processing
- **Results**: Beautiful visualizations of scores + patterns

### GitHub Actions (Automation)
- **Builds**: iOS app on macOS automatically
- **Tests**: Backend on Linux
- **Artifacts**: Available for download

---

## What's Implemented ✅

| Component | Status | Details |
|-----------|--------|---------|
| Backend API | ✅ | FastAPI with 4 analyzers |
| Recording View | ✅ | Full recording controls |
| Analysis View | ✅ | Score cards + patterns |
| Library View | ✅ | List, filter, sort |
| Settings View | ✅ | Audio quality, privacy |
| Daily Reports | ✅ | Aggregated daily stats |
| GitHub Actions | ✅ | Auto-build iOS + test backend |
| Docker | ✅ | Full stack in containers |

---

## Next Steps

1. **Run setup**: `bash quick-start.sh`
2. **Start backend**: `bash run-backend.sh`
3. **Open API docs**: `http://localhost:8000/docs`
4. **Explore endpoints**: Try the "Try it out" button
5. **Build iOS**: `git push origin master` → GitHub Actions

---

## Need Help?

- **Setup issues**: See `SETUP.md` for detailed guide
- **Architecture**: See `CLAUDE.md` for design decisions
- **API endpoints**: See `http://localhost:8000/docs` (interactive)
- **Code questions**: Check file headers in VSCode

---

## Quick Command Reference

```bash
# Setup (one time)
bash quick-start.sh

# Run backend
bash run-backend.sh

# Test everything
bash test-setup.sh

# Git workflow
git add .
git commit -m "message"
git push origin master

# Docker (optional)
docker-compose up -d      # Start
docker-compose down       # Stop
docker-compose logs -f    # View logs
```

---

**You're ready to go! 🎉**

Start with: `bash quick-start.sh`
