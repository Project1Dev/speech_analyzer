# Speech Mastery - Complete Workflow

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  YOUR LINUX COMPUTER (Development Environment)                  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  VSCode/Terminal                                         │  │
│  │  ├─ Edit Python backend code                            │  │
│  │  ├─ Edit Swift iOS code                                │  │
│  │  └─ Run: bash run-backend.sh                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                      │
│                           ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Backend Service (Python/FastAPI) - localhost:8000       │  │
│  │  ├─ 🎯 API Documentation: http://localhost:8000/docs    │  │
│  │  ├─ 📊 Analysis Engine (4 analyzers)                    │  │
│  │  ├─ 🗄️  Database (SQLite local or PostgreSQL)          │  │
│  │  ├─ 🔐 Authentication (Bearer token)                   │  │
│  │  └─ ✅ Health Check: GET /health                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Optional: Docker Services                              │  │
│  │  ├─ PostgreSQL (postgres:5432)                          │  │
│  │  ├─ Redis (redis:6379)                                 │  │
│  │  └─ pgAdmin (http://localhost:5050)                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ Git Push
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub Repository                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  GitHub Actions (Automated CI/CD)                        │  │
│  │                                                          │  │
│  │  ┌──────────────────┐         ┌──────────────────┐     │  │
│  │  │  Workflow 1      │         │  Workflow 2      │     │  │
│  │  │  Build iOS       │         │  Test Backend    │     │  │
│  │  ├──────────────────┤         ├──────────────────┤     │  │
│  │  │ Runs on: macOS   │         │ Runs on: Linux   │     │  │
│  │  │ ✅ Builds app    │         │ ✅ Pytest        │     │  │
│  │  │ ✅ Runs tests    │         │ ✅ Python 3.9+   │     │  │
│  │  │ ✅ Uploads build │         │ ✅ Linting       │     │  │
│  │  └──────────────────┘         └──────────────────┘     │  │
│  │         │                                    │          │  │
│  │         └────────────────┬───────────────────┘          │  │
│  │                          │                              │  │
│  │              ▼ Both pass? ▼                             │  │
│  │        ✅ Build succeeds                               │  │
│  │        📦 Artifacts uploaded                            │  │
│  │        🔔 Notifications sent                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 User Journey (Complete Flow)

```
START
  │
  ├─ 1️⃣ User opens app (iOS)
  │     │
  │     ├─ Sees onboarding (privacy info)
  │     ├─ Grants microphone permission
  │     └─ Grants upload consent
  │
  ├─ 2️⃣ Navigate to Record tab
  │     │
  │     ├─ Taps record button 🔴
  │     ├─ Speaks naturally
  │     ├─ App shows real-time audio meter 📊
  │     └─ Taps stop ⏹️
  │
  ├─ 3️⃣ Recording saved locally
  │     │
  │     ├─ Appears in Library 📚
  │     ├─ Shows duration & file size
  │     └─ Status: "Pending Upload" ⏱️
  │
  ├─ 4️⃣ Upload for Analysis
  │     │
  │     ├─ Sends to Backend (localhost:8000)
  │     │     │
  │     │     ├─ Receives audio file
  │     │     ├─ Transcribes audio 🎙️
  │     │     ├─ Runs 4 analyzers in parallel
  │     │     │   ├─ Power Dynamics
  │     │     │   ├─ Linguistic Authority
  │     │     │   ├─ Vocal Command
  │     │     │   └─ Persuasion & Influence
  │     │     │
  │     │     └─ Returns scores + patterns 📈
  │     │
  │     └─ Status: "Analyzed" ✅
  │
  ├─ 5️⃣ View Analysis Results
  │     │
  │     ├─ Overall Score: 74/100 🟡
  │     ├─ Category Breakdown:
  │     │   ├─ Power Dynamics: 72
  │     │   ├─ Linguistic Authority: 68
  │     │   ├─ Vocal Command: 81
  │     │   └─ Persuasion: 77
  │     │
  │     ├─ Critical Moments: 5
  │     │   ├─ "Filler words detected at 0:45"
  │     │   ├─ "Hedging language at 2:30"
  │     │   └─ [Suggestions shown]
  │     │
  │     └─ Speech Patterns:
  │         ├─ Filler Words: 8 (3.8/min)
  │         ├─ Hedging Phrases: 4
  │         └─ Words/min: 145
  │
  ├─ 6️⃣ View Library (All Recordings)
  │     │
  │     ├─ Filter by:
  │     │   ├─ All recordings
  │     │   ├─ Pending upload
  │     │   ├─ Analyzed
  │     │   └─ Unanalyzed
  │     │
  │     ├─ Sort by:
  │     │   ├─ Date (newest first)
  │     │   ├─ Duration
  │     │   └─ Score
  │     │
  │     └─ Swipe to delete
  │
  ├─ 7️⃣ Daily Reports
  │     │
  │     ├─ Navigate dates (previous/next/today)
  │     ├─ See daily average score
  │     ├─ View pattern trends
  │     └─ Get improvement suggestions
  │
  ├─ 8️⃣ Settings
  │     │
  │     ├─ Audio Quality: Standard/High/Very High
  │     ├─ Privacy Controls: Upload consent
  │     ├─ Storage Stats: Used/Available
  │     └─ Data Management: Clear cache
  │
  └─ END (Repeat daily for coaching!)

```

---

## 🖥️ Backend Processing Pipeline

```
┌─────────────────────────────────────────────────────┐
│  Audio File Arrives                                 │
│  (POST /analyze)                                    │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  ① Transcription                                    │
│  Input: Audio bytes                                 │
│  Service: TranscriptionService (Whisper/Mock)      │
│  Output: Text transcript                           │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  ② Parallel Analysis (4 concurrent)                │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ Power Dynamics Analyzer                      │  │
│  │ • Detect filler words (um, like, uh)        │  │
│  │ • Identify hedging language                 │  │
│  │ • Check for upspeak (rising intonation)     │  │
│  │ • Calculate power score (0-100)             │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ Linguistic Authority Analyzer                │  │
│  │ • Analyze passive vs active voice           │  │
│  │ • Calculate word economy (conciseness)      │  │
│  │ • Check precision of language               │  │
│  │ • Calculate authority score (0-100)         │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ Vocal Command Analyzer                       │  │
│  │ • Measure words per minute (WPM)            │  │
│  │ • Analyze pause patterns                    │  │
│  │ • Check pace consistency                    │  │
│  │ • Calculate vocal command score (0-100)     │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ Persuasion & Influence Analyzer              │  │
│  │ • Analyze narrative coherence               │  │
│  │ • Identify persuasion techniques            │  │
│  │ • Check rhetorical devices                  │  │
│  │ • Calculate persuasion score (0-100)        │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  ③ Aggregation                                      │
│  • Calculate overall score (average of 4)          │
│  • Identify critical moments (severity-sorted)     │
│  • Sort top patterns by frequency                  │
│  • Generate improvement suggestions                │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  ④ Storage                                          │
│  • Save to database (SQLite/PostgreSQL)            │
│  • Linked to user's recording                      │
│  • Indexed for fast retrieval                      │
│  • Cached for offline access                       │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  Response (JSON)                                    │
│  {                                                  │
│    "overall_score": 74.5,                          │
│    "scores": {                                      │
│      "power_dynamics": 72.0,                       │
│      "linguistic_authority": 68.5,                │
│      "vocal_command": 81.0,                       │
│      "persuasion_influence": 76.5                 │
│    },                                              │
│    "critical_moments": [...],                     │
│    "patterns": {...},                             │
│    "transcript": "Hello, I think..."              │
│  }                                                  │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Data Models

### Recording Model
```
Recording
├─ id: UUID
├─ file_path: string
├─ file_size: bytes
├─ duration: seconds
├─ recorded_at: timestamp
├─ audio_settings: {sample_rate, bit_rate, channels}
├─ analyzed: boolean
├─ analysis_id: UUID (foreign key)
└─ uploaded: boolean
```

### AnalysisResult Model
```
AnalysisResult
├─ id: UUID
├─ recording_id: UUID (foreign key)
├─ overall_score: 0-100
├─ power_dynamics_score: 0-100
├─ linguistic_authority_score: 0-100
├─ vocal_command_score: 0-100
├─ persuasion_influence_score: 0-100
├─ transcript: string
├─ critical_moments: [
│  ├─ timestamp: seconds
│  ├─ issue: string
│  ├─ suggestion: string
│  └─ severity: high|medium|low
│  ]
├─ patterns: {
│  ├─ filler_words: {count, words_breakdown, per_minute}
│  ├─ hedging: {count, phrases_breakdown}
│  ├─ passive_voice_ratio: percentage
│  └─ words_per_minute: number
│  }
└─ created_at: timestamp
```

### Report Model
```
Report
├─ date: YYYY-MM-DD
├─ overall_score: 0-100 (daily average)
├─ recordings_analyzed: count
├─ category_scores: {pd, la, vc, pi averages}
├─ top_patterns: [pattern_name, frequency]
├─ critical_moments: [all for the day]
├─ improvement_suggestions: [strings]
└─ score_trends: {change_24h, change_7d}
```

---

## 🔌 API Endpoints (at http://localhost:8000/docs)

### Authentication
```
All requests need header:
Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345
```

### Core Endpoints
```
POST /analyze
├─ Upload audio file
├─ Returns: AnalysisResult with scores
└─ Takes: 2-10 seconds depending on file size

GET /recordings
├─ List all user's recordings
└─ Returns: [Recording]

GET /recordings/{id}
├─ Get specific recording details
└─ Returns: Recording

DELETE /recordings/{id}
├─ Delete a recording
└─ Returns: Success message

GET /reports/{date}
├─ Get daily report for a date
├─ Example: /reports/2025-10-27
└─ Returns: Report with aggregated stats

GET /health
├─ Check if backend is alive
└─ Returns: {"status": "ok"}
```

---

## 🚀 Deployment Path

### Development (Today)
```
Linux (Your Computer)
    ↓
    Backend: localhost:8000
    iOS: Simulated in GitHub Actions
```

### Testing (Next)
```
GitHub Actions (Cloud)
    ↓
    Builds iOS automatically
    Tests Backend on Linux
    Uploads artifacts
```

### Production (Later)
```
Azure/AWS/Heroku
    ├─ Backend: Deployed API
    └─ iOS: App Store / TestFlight
```

---

## 🎯 Current Status

| Component | Status | Location |
|-----------|--------|----------|
| Backend API | ✅ Ready | `localhost:8000` |
| iOS App | ✅ Code complete | `ios/SpeechMastery/` |
| GitHub Actions | ✅ Configured | `.github/workflows/` |
| Docker | ✅ Ready | `docker-compose.yml` |
| Documentation | ✅ Complete | `SETUP.md`, `QUICKSTART.md` |

---

## 🎓 Learning Path

1. **Understand Backend** (30 min)
   - Read: `CLAUDE.md` (Architecture section)
   - Run: `bash run-backend.sh`
   - Visit: `http://localhost:8000/docs`

2. **Understand iOS Code** (1 hour)
   - Read: iOS view files in VSCode
   - Understand: MVVM pattern
   - Study: ViewModels (state management)

3. **See It Build** (5 minutes)
   - Push to GitHub: `git push`
   - Watch: GitHub Actions run
   - Download: Build artifacts

4. **Extend It** (Start hacking!)
   - Add new analyzer
   - Create new API endpoint
   - Enhance iOS UI

---

## 📚 File Reference

```
Key files for understanding:

Backend:
- backend/app/main.py           # FastAPI entry point
- backend/app/services/         # Analyzer implementations
- backend/requirements.txt       # Dependencies

iOS:
- ios/.../Views/RecordingView.swift       # Recording UI
- ios/.../Views/AnalysisResultView.swift  # Results UI
- ios/.../ViewModels/AnalysisViewModel.swift

CI/CD:
- .github/workflows/build-ios.yml    # iOS build automation
- .github/workflows/test-backend.yml # Backend testing

Documentation:
- QUICKSTART.md   # This file! Start here
- SETUP.md       # Detailed setup guide
- CLAUDE.md      # Architecture & decisions
- WORKFLOW.md    # This file (workflows)
```

---

**Next: Run `bash quick-start.sh` to begin!**
