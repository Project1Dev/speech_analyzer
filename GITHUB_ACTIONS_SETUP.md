# GitHub Actions Setup - Complete Guide

## ✅ What Was Created

I've set up **complete automation** for your project using GitHub Actions. Here's everything:

### 1️⃣ GitHub Workflow Files

**Location**: `.github/workflows/`

#### A. `build-ios.yml` (iOS Build Workflow)
- **Triggers**: On push to master/main, pull requests, or manual trigger
- **Runs on**: macOS (GitHub's cloud Mac)
- **Does**:
  - ✅ Builds iOS app for simulator
  - ✅ Builds iOS app for physical device (if certs available)
  - ✅ Runs unit tests
  - ✅ Uploads build artifacts (IPA files, logs)
  - ✅ Auto-trigger: 5-10 minutes after code push

#### B. `test-backend.yml` (Backend Test Workflow)
- **Triggers**: On push to master/main, pull requests, or manual trigger
- **Runs on**: Linux (Ubuntu) with multiple Python versions (3.9, 3.10, 3.11)
- **Does**:
  - ✅ Sets up PostgreSQL database
  - ✅ Sets up Redis cache
  - ✅ Installs dependencies
  - ✅ Runs pytest tests
  - ✅ Checks code style (flake8)
  - ✅ Verifies imports
  - ✅ Generates coverage reports
  - ✅ Tests on 3 Python versions

### 2️⃣ Bash Scripts for Local Development

**Location**: Project root

#### A. `quick-start.sh` (One-time Setup)
```bash
bash quick-start.sh
```
- Creates Python virtual environment
- Installs all dependencies
- Creates `.env` configuration
- Tests imports
- Takes ~2 minutes

#### B. `run-backend.sh` (Start Backend)
```bash
bash run-backend.sh
```
- Activates virtual environment
- Starts FastAPI server
- Available at: http://localhost:8000
- Hot-reload enabled (auto-restart on code changes)
- Runs forever until you press Ctrl+C

#### C. `test-setup.sh` (Verify Setup)
```bash
bash test-setup.sh
```
- Checks Python version
- Verifies all files exist
- Tests virtual environment
- Checks Docker (optional)
- Takes ~30 seconds

#### D. `test-api.sh` (Test API Endpoints)
```bash
bash test-api.sh
```
- Checks if backend is running
- Tests authentication
- Lists all API endpoints
- Shows example curl commands
- Requires backend to be running first

### 3️⃣ Documentation Files

#### A. `QUICKSTART.md` (⭐ Start here!)
- TL;DR version
- 5-minute quick start
- Key commands only
- Link to full docs

#### B. `SETUP.md` (Complete Setup Guide)
- Detailed step-by-step instructions
- Option A: Direct Python installation
- Option B: Docker setup
- Troubleshooting section
- Project structure reference
- 3000+ lines of comprehensive documentation

#### C. `WORKFLOW.md` (Architecture Diagrams)
- Complete ASCII diagrams
- User journey visualization
- Backend processing pipeline
- Data models
- API endpoints reference
- Deployment path

#### D. `GITHUB_ACTIONS_SETUP.md` (This file!)
- Explains GitHub Actions setup
- How to use workflows
- How to monitor builds
- How to download artifacts

---

## 🚀 Getting Started (Steps)

### Step 1: One-Time Setup (2 minutes)
```bash
cd /path/to/speech_analyzer

# Setup backend
bash quick-start.sh
```

**What happens**:
- Creates `backend/venv/` directory
- Installs Python dependencies
- Creates `backend/.env` config
- Tests that everything imports correctly

### Step 2: Start Backend (On Your Linux Machine)
```bash
# In a new terminal
bash run-backend.sh
```

**Output**:
```
═══════════════════════════════════════
  Speech Mastery Backend - Starting
═══════════════════════════════════════

Environment:
  Python: Python 3.11.x
  Location: /path/to/backend

Service will be available at:
  http://localhost:8000
  http://localhost:8000/docs (Interactive API)
  http://localhost:8000/redoc (Alternative API docs)

═══════════════════════════════════════
```

### Step 3: Test Backend is Running
```bash
# In another terminal
bash test-api.sh
```

**Output**:
```
════════════════════════════════════════
  Speech Mastery - API Test Script
════════════════════════════════════════

✅ Backend is running!

═══════════════════════════════════════
Test 1: Health Check
═══════════════════════════════════════
GET /health

Response:
{"status": "ok"}
```

### Step 4: Access Interactive API Docs
Open in browser:
```
http://localhost:8000/docs
```

You'll see:
- All available endpoints
- Request/response examples
- "Try it out" button for each endpoint
- Authentication setup
- Live API testing

### Step 5: Build iOS in Cloud
Push your code to GitHub:
```bash
git add .
git commit -m "Complete implementation"
git push origin master
```

### Step 6: Monitor Build on GitHub
1. Go to: `https://github.com/YOUR_USERNAME/speech_analyzer`
2. Click: **Actions** tab
3. You'll see:
   - ✅ "Build iOS App" workflow running
   - ✅ "Test Backend" workflow running

Wait 5-10 minutes for builds to complete.

### Step 7: Download Build Artifacts
When workflow completes:
1. Click on the workflow run
2. Scroll to: **Artifacts** section
3. Download:
   - `ios-build-artifacts` (iOS build)
   - `coverage-report-python-X.Y` (Test results)

---

## 📊 Workflow Details

### Build iOS App Workflow

**Runs on**: `macos-latest` (GitHub's latest macOS)

**Steps**:
```
1. Checkout code from GitHub
2. Select Xcode version
3. Install dependencies (CocoaPods if needed)
4. Build for Simulator
   └─ Generates .app file
5. Build for Device (if certificates available)
   └─ Generates .ipa file
6. Run unit tests
   └─ Tests on iOS Simulator
7. Upload artifacts
   └─ Available for download
```

**Duration**: 5-10 minutes

**Triggers**:
- Push to `master` or `main` branch
- Create a pull request
- Manual trigger via "Run workflow" button

### Test Backend Workflow

**Runs on**: `ubuntu-latest` with services:
- PostgreSQL 15
- Redis 7

**Steps**:
```
1. Checkout code
2. Setup Python (3.9, 3.10, 3.11)
3. Install dependencies from requirements.txt
4. Create .env file
5. Run database migrations
6. Run flake8 linter (optional)
7. Run pytest tests
8. Upload coverage reports
```

**Duration**: 3-5 minutes per Python version

**Triggers**:
- Push to `master` or `main` branch
- Create a pull request
- Manual trigger via "Run workflow" button

---

## 🎮 Manual Workflow Triggers

You can trigger workflows without pushing code:

### Via GitHub Web UI

1. Go to repository
2. Click **Actions** tab
3. Select workflow (e.g., "Build iOS App")
4. Click **Run workflow**
5. Select branch (master)
6. Click green **Run workflow** button
7. Workflow starts immediately

### Via GitHub CLI (Advanced)

```bash
# Trigger iOS build
gh workflow run build-ios.yml -r master

# Trigger backend tests
gh workflow run test-backend.yml -r master

# List workflow runs
gh run list
```

---

## 📈 Monitoring Builds

### Check Build Status

**On GitHub**:
1. Repository > Actions tab
2. See all workflow runs
3. Green checkmark = Success
4. Red X = Failed
5. Yellow dot = Running

**Build Duration**:
- iOS build: 5-10 minutes
- Backend tests: 3-5 minutes per Python version
- Total: ~20 minutes for both

### View Build Logs

1. Click on workflow run
2. Click on job (e.g., "Build iOS App")
3. Click on step to expand logs
4. See detailed output

### Download Artifacts

1. Workflow completes
2. Click on workflow run
3. Scroll to "Artifacts"
4. Download ZIP files
5. Use for testing/deployment

---

## 🔍 What Gets Built

### iOS Build Artifacts

```
ios-build-artifacts/
├── build/
│   ├── Debug-iphonesimulator/
│   │   └── SpeechMastery.app/      ← Simulator app
│   ├── Debug-iphoneos/
│   │   └── SpeechMastery.ipa/      ← Device app (if built)
│   ├── logs/
│   │   └── build.log              ← Build output
│   └── test-results/
│       └── test-results.xcresult/ ← Test results
```

### Backend Test Artifacts

```
coverage-report-python-3.9/
├── index.html                      ← Open in browser
├── status.json
└── [source files with coverage]
```

---

## 🛠️ Customizing Workflows

### To Trigger Only on Certain Branches

Edit `.github/workflows/build-ios.yml`:
```yaml
on:
  push:
    branches: [ master, develop ]  # Only these branches
```

### To Trigger on Pull Requests

Already configured! When you create a PR:
- iOS build runs automatically
- Backend tests run automatically
- PR shows results with checkmarks/X

### To Add More Python Versions

Edit `.github/workflows/test-backend.yml`:
```yaml
strategy:
  matrix:
    python-version: ['3.9', '3.10', '3.11', '3.12']  # Add 3.12
```

### To Add More Steps

Example: Add code coverage upload
```yaml
- name: Upload to Codecov
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage.xml
```

---

## ⚠️ Common Issues & Fixes

### Build Fails: "Pod install failed"

**Cause**: CocoaPods not installed on GitHub's Mac

**Fix**: Remove pod dependency or pre-install:
```yaml
- name: Install CocoaPods
  run: sudo gem install cocoapods
```

### Build Fails: "xcodebuild not found"

**Cause**: Wrong macOS version

**Fix**: Use `macos-latest`:
```yaml
runs-on: macos-latest  # Not macos-12 or macos-11
```

### Backend Tests Fail: Database error

**Cause**: PostgreSQL not started

**Fix**: Already handled in workflow! Services auto-start.

### No Artifacts Uploaded

**Cause**: Build failed before artifact step

**Fix**: Check build logs for errors.

---

## 💡 Pro Tips

### Run Tests Locally Before Pushing

```bash
# Test backend locally
cd backend
pytest

# Check linting
flake8 app/
```

### View Workflow Status Badge

Add to README.md:
```markdown
[![Build iOS](https://github.com/YOUR_USERNAME/speech_analyzer/actions/workflows/build-ios.yml/badge.svg)](https://github.com/YOUR_USERNAME/speech_analyzer/actions)

[![Test Backend](https://github.com/YOUR_USERNAME/speech_analyzer/actions/workflows/test-backend.yml/badge.svg)](https://github.com/YOUR_USERNAME/speech_analyzer/actions)
```

### Schedule Nightly Builds

Edit workflow, add schedule:
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
```

### Notify on Failure

Add step in workflow:
```yaml
- name: Notify Slack
  if: failure()
  run: |
    # Send notification to Slack webhook
```

---

## 🎯 Recommended Workflow

1. **Write code locally in VSCode**
2. **Test locally**:
   ```bash
   bash run-backend.sh      # Terminal 1
   bash test-api.sh         # Terminal 2
   ```
3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add feature"
   git push origin master
   ```
4. **Monitor on GitHub Actions**
   - Go to Actions tab
   - Watch workflows run
   - Check for green checkmarks
5. **If all pass**: Code is ready to deploy
6. **If any fail**: Check logs, fix locally, push again

---

## 🚀 Next Steps

1. **Complete Setup**: `bash quick-start.sh`
2. **Start Backend**: `bash run-backend.sh`
3. **Test API**: `bash test-api.sh`
4. **Push Code**: `git push origin master`
5. **Watch Builds**: Go to GitHub Actions
6. **Download Artifacts**: Get iOS build
7. **Deploy**: Use the built artifacts

---

## 📞 Quick Reference

```bash
# Setup (one time)
bash quick-start.sh

# Daily development
bash run-backend.sh                # Terminal 1
bash test-api.sh                  # Terminal 2 (after backend starts)

# Testing
bash test-setup.sh                # Verify installation
pytest backend/                   # Run backend tests locally

# Git workflow
git add .
git commit -m "message"
git push origin master            # Triggers GitHub Actions

# View workflows
# Go to: https://github.com/YOUR_USERNAME/speech_analyzer/actions
```

---

**You're all set! The entire CI/CD pipeline is ready. Start building! 🚀**
