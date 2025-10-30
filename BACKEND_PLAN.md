# Backend Implementation Plan

**Project**: Speech Mastery Backend API
**Goal**: Complete MVP - Record → Transcribe → Filler Detection → Display Pipeline
**Status**: Phase 1 (Foundation) - In Progress

---

## Current Status Summary

### ✅ Completed (Infrastructure)
- [x] FastAPI application setup with CORS
- [x] PostgreSQL database models (User, Recording, AnalysisResult)
- [x] Alembic migrations (initial schema)
- [x] Pydantic schemas for validation
- [x] Authentication system (single-user token)
- [x] File upload endpoint (`POST /analyze`)
- [x] Recording list endpoint (`GET /recordings`)
- [x] Recording deletion endpoint (`DELETE /recordings/{id}`)
- [x] Analysis retrieval endpoint (`GET /recordings/{id}/analysis`)
- [x] Health check endpoint (`GET /health`)
- [x] Database connection pooling
- [x] PowerDynamicsAnalyzer - Filler word detection (50% complete)
- [x] PowerDynamicsAnalyzer - Hedging phrase detection (50% complete)
- [x] MockTranscriptionService (working)

### 🔨 In Progress
- [ ] Local Whisper integration (P0 - Critical)
- [ ] PowerDynamicsAnalyzer completion (timestamps, tests)
- [ ] Logging infrastructure

### ⏳ Not Started (MVP)
- [ ] Unit tests for analyzers
- [ ] Error handling improvements
- [ ] LinguisticAuthorityAnalyzer (P2 - Post-MVP)
- [ ] VocalCommandAnalyzer (P2 - Post-MVP)
- [ ] PersuasionInfluenceAnalyzer (P2 - Post-MVP)

---

## Phase 1: Foundation - MVP Critical Path

**Goal**: Get one complete flow working: audio upload → Whisper transcription → filler detection → return results

**Estimated Time**: 8-12 hours
**Priority**: P0 (Critical for MVP)

---

### 1.1 Local Whisper Integration

**Priority**: P0 | **Complexity**: High | **Time**: 3-4 hours

#### Task 1.1.1: Research Whisper Options
- [ ] Research `faster-whisper` (Python, optimized for CPU/GPU)
- [ ] Research `whisper.cpp` (C++, lightweight, fast inference)
- [ ] Research `openai-whisper` (official but slower)
- [ ] Compare inference speed benchmarks for 1-5 min audio files
- [ ] Choose implementation based on speed and ease of integration
- [ ] **Decision**: Document choice in `backend/docs/WHISPER_SETUP.md`

**Success Criteria**: Written decision document with benchmark data

**Recommended**: `faster-whisper` - good Python integration, 4x faster than openai-whisper

---

#### Task 1.1.2: Install Whisper Dependencies
- [ ] Add `faster-whisper` to `backend/requirements.txt`
- [ ] Document CUDA/CPU requirements in README
- [ ] Update Dockerfile to include Whisper dependencies
- [ ] Test installation in virtual environment: `pip install faster-whisper`
- [ ] Verify model download works: `python -c "from faster_whisper import WhisperModel; WhisperModel('base')"`

**Success Criteria**: Can import and initialize Whisper model without errors

**Files Modified**: `backend/requirements.txt`, `backend/Dockerfile`

---

#### Task 1.1.3: Download Whisper Model
- [ ] Create model cache directory: `backend/models/`
- [ ] Download `base` model (~140MB) for development
- [ ] Test model inference with sample audio file
- [ ] Add `.gitignore` entry for `backend/models/`
- [ ] Document model size options (tiny/base/small/medium/large) in config

**Success Criteria**: Model downloaded and can transcribe a test file

**Command**:
```bash
cd backend
mkdir -p models
python -c "from faster_whisper import WhisperModel; model = WhisperModel('base', download_root='./models')"
```

---

#### Task 1.1.4: Implement WhisperTranscriptionService
- [ ] Open `backend/app/services/transcription_service.py`
- [ ] Locate `WhisperTranscriptionService` class (currently raises NotImplementedError)
- [ ] Implement `__init__()` to load Whisper model on startup
  - Load model from config (`base` model for dev, `small` for prod)
  - Store model as instance variable
  - Add error handling for model loading failures
- [ ] Implement `transcribe(audio_file_path: str) -> str` method:
  - Load audio file with Whisper
  - Run inference: `segments, info = model.transcribe(audio_file_path)`
  - Combine segments into full transcript
  - Return transcript string
  - Add timeout handling (max 2 minutes)
  - Add error handling for corrupted audio files

**Success Criteria**: Method returns accurate transcript for sample audio

**Files Modified**: `backend/app/services/transcription_service.py`

**Code Structure**:
```python
class WhisperTranscriptionService(BaseTranscriptionService):
    def __init__(self, model_size: str = "base"):
        self.model = WhisperModel(model_size, device="cpu", compute_type="int8")

    def transcribe(self, audio_file_path: str) -> str:
        segments, info = self.model.transcribe(audio_file_path, beam_size=5)
        transcript = " ".join([segment.text for segment in segments])
        return transcript.strip()
```

---

#### Task 1.1.5: Update Service Factory
- [ ] Open `backend/app/services/transcription_service.py`
- [ ] Locate `get_transcription_service()` function
- [ ] Update the `whisper` case to instantiate `WhisperTranscriptionService`
- [ ] Add model size parameter from config
- [ ] Add error handling if Whisper import fails

**Success Criteria**: Factory returns working Whisper service when `TRANSCRIPTION_SERVICE=whisper`

**Files Modified**: `backend/app/services/transcription_service.py`

**Code**:
```python
def get_transcription_service(service_type: str = "mock") -> BaseTranscriptionService:
    if service_type == "whisper":
        return WhisperTranscriptionService(model_size=settings.WHISPER_MODEL_SIZE)
    elif service_type == "mock":
        return MockTranscriptionService()
    else:
        raise ValueError(f"Unknown transcription service: {service_type}")
```

---

#### Task 1.1.6: Add Whisper Configuration
- [ ] Open `backend/app/core/config.py`
- [ ] Add `WHISPER_MODEL_SIZE: str = "base"` to Settings class
- [ ] Add `WHISPER_DEVICE: str = "cpu"` (or "cuda" if GPU available)
- [ ] Add `WHISPER_COMPUTE_TYPE: str = "int8"` (performance optimization)
- [ ] Document config options in comments

**Success Criteria**: Config values accessible via `settings.WHISPER_MODEL_SIZE`

**Files Modified**: `backend/app/core/config.py`

---

#### Task 1.1.7: Test Whisper Integration
- [ ] Create test audio file: `backend/tests/fixtures/sample.m4a` (30 seconds, clear speech)
- [ ] Update `.env` to set `TRANSCRIPTION_SERVICE=whisper`
- [ ] Start backend: `docker-compose up backend`
- [ ] Upload test audio via `/analyze` endpoint
- [ ] Verify transcript in response
- [ ] Check for errors in logs
- [ ] Measure transcription time (should be < 10s for 30s audio)

**Success Criteria**: Real audio file transcribed accurately, response time acceptable

**Test Command**:
```bash
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
  -F "file=@tests/fixtures/sample.m4a"
```

---

### 1.2 PowerDynamicsAnalyzer Enhancement

**Priority**: P0 | **Complexity**: Medium | **Time**: 2-3 hours

#### Task 1.2.1: Review Current Implementation
- [ ] Open `backend/app/services/power_dynamics_analyzer.py`
- [ ] Review filler word detection logic (lines ~40-80)
- [ ] Review hedging phrase detection logic (lines ~80-120)
- [ ] Review scoring algorithm (lines ~120-160)
- [ ] Verify pattern lists are comprehensive
- [ ] Check for edge cases (empty transcript, very long transcript)

**Success Criteria**: Understand current code, note any bugs or improvements

**Files**: `backend/app/services/power_dynamics_analyzer.py`

---

#### Task 1.2.2: Fix Critical Moment Timestamps
- [ ] Locate critical moment creation code (currently hardcoded to `timestamp=0.0`)
- [ ] Find where filler words are detected (returns word + count, not positions)
- [ ] Modify detection to track word positions in transcript
- [ ] Calculate approximate timestamps: `(word_position / total_words) * duration`
- [ ] Update critical moment creation to use real timestamps
- [ ] Add `word_index` to critical moment context

**Success Criteria**: Critical moments show accurate timestamps (not all 0.0)

**Files Modified**: `backend/app/services/power_dynamics_analyzer.py`

**Current Issue**:
```python
# Current (wrong):
critical_moments.append({
    "timestamp": 0.0,  # TODO: actual timestamp
    "type": "filler_cluster",
    ...
})
```

**Fix**:
```python
# New (correct):
def _detect_filler_words_with_positions(transcript: str) -> List[Tuple[str, int, int]]:
    """Returns: (word, position, count)"""
    ...

critical_moments.append({
    "timestamp": (position / total_words) * duration,
    "word_index": position,
    ...
})
```

---

#### Task 1.2.3: Add Filler Word Position Tracking
- [ ] Create helper method `_find_word_positions(transcript: str, words: List[str]) -> Dict[str, List[int]]`
- [ ] Use regex or split to find each word's index in transcript
- [ ] Return dict mapping word → list of positions where it appears
- [ ] Handle case-insensitive matching
- [ ] Handle punctuation (e.g., "um," vs "um")

**Success Criteria**: Can locate exact positions of all filler words

**Files Modified**: `backend/app/services/power_dynamics_analyzer.py`

---

#### Task 1.2.4: Improve Scoring Algorithm Documentation
- [ ] Add docstring to `_calculate_score()` method
- [ ] Document penalty thresholds with comments
- [ ] Add examples of score calculations
- [ ] Document score range (0-100)
- [ ] Add inline comments explaining severity levels

**Success Criteria**: Code is self-documenting, easy to understand

**Files Modified**: `backend/app/services/power_dynamics_analyzer.py`

---

#### Task 1.2.5: Add Input Validation
- [ ] Add validation for empty transcript
- [ ] Add validation for negative duration
- [ ] Add validation for transcript length (warn if > 50,000 words)
- [ ] Return sensible defaults for edge cases
- [ ] Add logging for validation failures

**Success Criteria**: Analyzer doesn't crash on invalid inputs

**Files Modified**: `backend/app/services/power_dynamics_analyzer.py`

---

### 1.3 Structured Logging Infrastructure

**Priority**: P0 | **Complexity**: Low | **Time**: 1-2 hours

#### Task 1.3.1: Install Logging Library
- [ ] Add `loguru` to `backend/requirements.txt` (simple, powerful logging)
- [ ] Install: `pip install loguru`
- [ ] Test import: `from loguru import logger`

**Success Criteria**: Can import loguru

**Files Modified**: `backend/requirements.txt`

**Alternative**: Use Python's built-in `logging` with `structlog` for structured logs

---

#### Task 1.3.2: Configure Logger
- [ ] Create `backend/app/core/logging.py`
- [ ] Configure loguru with:
  - JSON output format
  - Log level from environment variable (`DEBUG` for dev, `INFO` for prod)
  - Log to stdout (Docker-friendly)
  - Optional: Log to file `logs/app.log` with rotation
- [ ] Add correlation ID for request tracing
- [ ] Add timestamp, level, message, context fields

**Success Criteria**: Logger configured and ready to use

**Files Created**: `backend/app/core/logging.py`

**Code Structure**:
```python
from loguru import logger
import sys

def setup_logging(level: str = "INFO"):
    logger.remove()  # Remove default handler
    logger.add(
        sys.stdout,
        format="{time} | {level} | {message} | {extra}",
        level=level,
        serialize=True  # JSON output
    )
```

---

#### Task 1.3.3: Add Logging to Transcription Service
- [ ] Import logger in `transcription_service.py`
- [ ] Log when transcription starts: `logger.info("Starting transcription", file=audio_file_path)`
- [ ] Log transcription duration: `logger.info("Transcription complete", duration_seconds=elapsed)`
- [ ] Log errors: `logger.error("Transcription failed", error=str(e))`
- [ ] Log model loading: `logger.info("Loading Whisper model", model_size=model_size)`

**Success Criteria**: Can track transcription in logs

**Files Modified**: `backend/app/services/transcription_service.py`

---

#### Task 1.3.4: Add Logging to Analyzers
- [ ] Import logger in `power_dynamics_analyzer.py`
- [ ] Log analysis start/complete with duration
- [ ] Log filler word counts: `logger.debug("Filler words detected", count=total_fillers)`
- [ ] Log score: `logger.info("Power dynamics score", score=result['score'])`
- [ ] Log critical moments count

**Success Criteria**: Analyzer execution visible in logs

**Files Modified**: `backend/app/services/power_dynamics_analyzer.py`

---

#### Task 1.3.5: Add Logging to API Routes
- [ ] Import logger in `routes.py`
- [ ] Log incoming requests: `logger.info("Upload request", file_size=file.size)`
- [ ] Log request completion: `logger.info("Analysis complete", recording_id=recording.id)`
- [ ] Log errors with context: `logger.error("Upload failed", error=str(e), user_id=user.id)`
- [ ] Add request correlation ID middleware

**Success Criteria**: All API requests logged with timing

**Files Modified**: `backend/app/api/routes.py`

---

### 1.4 End-to-End Verification

**Priority**: P0 | **Complexity**: Low | **Time**: 1 hour

#### Task 1.4.1: Test Complete Flow
- [ ] Restart Docker services: `docker-compose down && docker-compose up -d`
- [ ] Upload test audio file
- [ ] Verify transcript in database
- [ ] Verify filler words detected correctly
- [ ] Verify timestamps are accurate (not 0.0)
- [ ] Verify scores calculated correctly
- [ ] Check logs for any errors

**Success Criteria**: Complete flow works without errors

**Test Script**:
```bash
# Upload audio
response=$(curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
  -F "file=@tests/fixtures/sample.m4a")

# Extract recording ID
recording_id=$(echo $response | jq -r '.recording_id')

# Fetch analysis
curl http://localhost:8000/api/v1/recordings/$recording_id/analysis \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345"
```

---

#### Task 1.4.2: Verify Database Storage
- [ ] Connect to PostgreSQL: `docker exec -it speech_mastery_postgres psql -U speech_mastery`
- [ ] Query recordings: `SELECT id, file_path, duration FROM recordings;`
- [ ] Query analysis: `SELECT recording_id, overall_score, patterns FROM analysis_results;`
- [ ] Verify patterns JSON contains filler word details
- [ ] Verify critical_moments JSON contains timestamp data

**Success Criteria**: Data correctly stored in database

---

#### Task 1.4.3: Performance Benchmarking
- [ ] Measure total time: upload → transcription → analysis → response
- [ ] Measure transcription time separately
- [ ] Measure analyzer time separately
- [ ] Document baseline performance in `docs/PERFORMANCE.md`
- [ ] Target: < 30 seconds for 1 minute audio (with base model)

**Success Criteria**: Performance metrics documented

**Expected Times**:
- File upload: < 1s
- Transcription (Whisper base): 5-10s per minute of audio
- Analysis: < 1s
- Database write: < 0.5s

---

## Phase 2: Quality & Reliability

**Goal**: Add tests, error handling, and robustness
**Estimated Time**: 4-6 hours
**Priority**: P1 (Important for stability)

---

### 2.1 Unit Tests for PowerDynamicsAnalyzer

**Priority**: P1 | **Complexity**: Medium | **Time**: 2-3 hours

#### Task 2.1.1: Set Up Test Infrastructure
- [ ] Create `backend/tests/test_services/` directory
- [ ] Create `backend/tests/test_services/__init__.py`
- [ ] Create `backend/tests/test_services/test_power_dynamics_analyzer.py`
- [ ] Add pytest fixtures for sample transcripts
- [ ] Add pytest fixtures for expected results

**Success Criteria**: Test file structure ready

**Files Created**: `backend/tests/test_services/test_power_dynamics_analyzer.py`

---

#### Task 2.1.2: Test Filler Word Detection
- [ ] Write test: `test_filler_word_detection_basic()`
  - Input: "Um, I think, uh, this is good"
  - Expected: Detects "um" (1), "uh" (1)
- [ ] Write test: `test_filler_word_detection_case_insensitive()`
  - Input: "UM um Um"
  - Expected: Detects 3 instances
- [ ] Write test: `test_filler_word_detection_with_punctuation()`
  - Input: "Um, uh. Like, you know?"
  - Expected: Handles punctuation correctly
- [ ] Write test: `test_filler_word_detection_none_present()`
  - Input: "This is a clean professional sentence."
  - Expected: 0 fillers detected

**Success Criteria**: All tests pass

**Example Test**:
```python
def test_filler_word_detection_basic():
    analyzer = PowerDynamicsAnalyzer()
    transcript = "Um, I think this is, uh, a good idea."
    duration = 5.0

    result = analyzer.analyze(transcript, duration)

    assert result['filler_words_per_minute'] > 0
    assert 'um' in result['patterns']['filler_words']
    assert 'uh' in result['patterns']['filler_words']
```

---

#### Task 2.1.3: Test Hedging Phrase Detection
- [ ] Write test: `test_hedging_detection_basic()`
- [ ] Write test: `test_hedging_detection_multiple_phrases()`
- [ ] Write test: `test_hedging_detection_none_present()`
- [ ] Write test: `test_hedging_per_minute_calculation()`

**Success Criteria**: All tests pass

---

#### Task 2.1.4: Test Scoring Algorithm
- [ ] Write test: `test_score_with_no_fillers()` → expect high score (~95-100)
- [ ] Write test: `test_score_with_many_fillers()` → expect low score (< 50)
- [ ] Write test: `test_score_boundaries()` → test edge cases (0 duration, empty transcript)
- [ ] Write test: `test_score_calculation_formula()`

**Success Criteria**: All tests pass, scoring logic verified

---

#### Task 2.1.5: Test Critical Moments
- [ ] Write test: `test_critical_moments_timestamps_not_zero()`
- [ ] Write test: `test_critical_moments_severity_ordering()`
- [ ] Write test: `test_critical_moments_suggestions_present()`
- [ ] Verify timestamps are within audio duration

**Success Criteria**: All tests pass

---

#### Task 2.1.6: Run Tests and Check Coverage
- [ ] Run: `pytest backend/tests/test_services/test_power_dynamics_analyzer.py -v`
- [ ] Run with coverage: `pytest --cov=app.services.power_dynamics_analyzer --cov-report=html`
- [ ] Check coverage report in `htmlcov/index.html`
- [ ] Target: > 80% coverage for PowerDynamicsAnalyzer

**Success Criteria**: All tests pass, coverage > 80%

---

### 2.2 Error Handling Improvements

**Priority**: P1 | **Complexity**: Medium | **Time**: 2-3 hours

#### Task 2.2.1: Handle File Upload Errors
- [ ] Open `backend/app/api/routes.py`
- [ ] Add try-except around file save operations
- [ ] Handle disk full errors
- [ ] Handle permission errors
- [ ] Handle invalid file format errors
- [ ] Return proper HTTP status codes (413 for too large, 415 for wrong type)
- [ ] Clean up partial files on error

**Success Criteria**: Upload errors handled gracefully

**Files Modified**: `backend/app/api/routes.py`

---

#### Task 2.2.2: Handle Transcription Errors
- [ ] Wrap transcription service call in try-except
- [ ] Handle timeout errors (if Whisper takes too long)
- [ ] Handle corrupted audio file errors
- [ ] Handle model loading errors
- [ ] Return partial results if transcription fails but analysis can run
- [ ] Log transcription errors with context

**Success Criteria**: Transcription failures don't crash API

**Files Modified**: `backend/app/api/routes.py`, `backend/app/services/transcription_service.py`

---

#### Task 2.2.3: Handle Analyzer Errors
- [ ] Wrap each analyzer call in try-except
- [ ] If one analyzer fails, continue with others
- [ ] Return partial results with note about failed analyzers
- [ ] Log analyzer errors with stack trace
- [ ] Add `"status": "partial"` field to response if any analyzer failed

**Success Criteria**: One analyzer failure doesn't fail entire pipeline

**Files Modified**: `backend/app/services/analysis_engine.py`

---

#### Task 2.2.4: Handle Database Errors
- [ ] Wrap database operations in try-except
- [ ] Handle unique constraint violations
- [ ] Handle connection timeouts
- [ ] Retry failed database writes (max 3 attempts)
- [ ] Return proper HTTP 500 errors with error ID for debugging

**Success Criteria**: Database errors handled gracefully

**Files Modified**: `backend/app/api/routes.py`

---

#### Task 2.2.5: Add Request Timeout
- [ ] Configure FastAPI request timeout (max 2 minutes)
- [ ] Add timeout to transcription service (max 90 seconds)
- [ ] Add timeout to file upload (max 30 seconds)
- [ ] Return 504 Gateway Timeout on timeout
- [ ] Clean up resources on timeout

**Success Criteria**: Long-running requests timeout gracefully

**Files Modified**: `backend/app/main.py`, `backend/app/api/routes.py`

---

### 2.3 Performance Monitoring

**Priority**: P1 | **Complexity**: Low | **Time**: 1 hour

#### Task 2.3.1: Add Timing Middleware
- [ ] Create `backend/app/middleware/timing.py`
- [ ] Add FastAPI middleware to log request duration
- [ ] Log slow requests (> 5 seconds) at WARNING level
- [ ] Add timing to response headers: `X-Response-Time`

**Success Criteria**: Can see request timing in logs and headers

**Files Created**: `backend/app/middleware/timing.py`

---

#### Task 2.3.2: Add Service-Level Metrics
- [ ] Add timer decorator for analyzer methods
- [ ] Log analyzer execution time
- [ ] Log transcription service execution time
- [ ] Track average times over 100 requests
- [ ] Add `/metrics` endpoint for basic stats (requests, avg time, errors)

**Success Criteria**: Can monitor performance per service

**Files Modified**: Various service files

---

## Phase 3: Complete Analyzer Suite (Post-MVP)

**Goal**: Implement remaining 3 analyzers
**Estimated Time**: 12-16 hours
**Priority**: P2 (Post-MVP, medium priority)

---

### 3.1 LinguisticAuthorityAnalyzer

**Priority**: P2 | **Complexity**: High | **Time**: 4-5 hours

#### Task 3.1.1: Set Up spaCy
- [ ] Add `spacy` to requirements.txt
- [ ] Download English model: `python -m spacy download en_core_web_sm`
- [ ] Test spaCy import and loading
- [ ] Add model to Docker image

**Success Criteria**: spaCy working

---

#### Task 3.1.2: Implement Passive Voice Detection
- [ ] Research passive voice patterns in English
- [ ] Use spaCy dependency parsing to detect passive constructions
- [ ] Count passive vs active sentences
- [ ] Calculate passive voice ratio
- [ ] Add unit tests

**Success Criteria**: Can accurately detect passive voice

---

#### Task 3.1.3: Implement Sentence Metrics
- [ ] Split transcript into sentences using spaCy
- [ ] Calculate average sentence length
- [ ] Calculate sentence length variance
- [ ] Identify overly long sentences (> 30 words)
- [ ] Identify overly short sentences (< 5 words)

**Success Criteria**: Sentence metrics calculated correctly

---

#### Task 3.1.4: Implement Vocabulary Analysis
- [ ] Calculate unique word count
- [ ] Calculate type-token ratio (unique / total)
- [ ] Identify repeated words (beyond common words)
- [ ] Calculate vocabulary diversity score

**Success Criteria**: Vocabulary metrics accurate

---

#### Task 3.1.5: Implement Jargon Detection
- [ ] Define jargon word lists (industry terms, acronyms)
- [ ] Count jargon usage
- [ ] Calculate jargon overuse score
- [ ] Identify sentences with too much jargon

**Success Criteria**: Jargon detection working

---

#### Task 3.1.6: Implement Scoring Algorithm
- [ ] Combine all metrics into single score
- [ ] Weight: passive voice (30%), sentence quality (30%), vocabulary (20%), jargon (20%)
- [ ] Return score 0-100
- [ ] Add critical moments for issues

**Success Criteria**: Score calculated correctly

---

#### Task 3.1.7: Add Unit Tests
- [ ] Test passive voice detection
- [ ] Test sentence metrics
- [ ] Test vocabulary analysis
- [ ] Test jargon detection
- [ ] Test scoring algorithm
- [ ] Target: > 80% coverage

**Success Criteria**: All tests pass

---

### 3.2 VocalCommandAnalyzer

**Priority**: P2 | **Complexity**: High | **Time**: 4-5 hours

#### Task 3.2.1: Implement WPM Calculation
- [ ] Count words in transcript
- [ ] Divide by duration (in minutes)
- [ ] Return words per minute
- [ ] Add validation for edge cases

**Success Criteria**: WPM calculated accurately

---

#### Task 3.2.2: Implement Pause Detection
- [ ] Research audio silence detection libraries (librosa, pydub)
- [ ] Load audio file
- [ ] Detect silent segments (< -40 dB)
- [ ] Calculate pause statistics (average, min, max, count)
- [ ] Identify awkward long pauses (> 3 seconds)

**Success Criteria**: Pauses detected from audio

**Libraries**: `librosa` for audio analysis

---

#### Task 3.2.3: Implement Pace Variance
- [ ] Split transcript into 10-second chunks
- [ ] Calculate WPM for each chunk
- [ ] Calculate variance across chunks
- [ ] Identify rushed sections (> 180 WPM)
- [ ] Identify slow sections (< 100 WPM)

**Success Criteria**: Pace variance calculated

---

#### Task 3.2.4: Implement Scoring Algorithm
- [ ] Optimal range: 120-150 WPM
- [ ] Penalty for too slow (< 100) or too fast (> 180)
- [ ] Penalty for high variance (monotone or erratic)
- [ ] Penalty for excessive pauses (> 2s average)
- [ ] Return score 0-100

**Success Criteria**: Score calculated correctly

---

#### Task 3.2.5: Add Critical Moments
- [ ] Flag rushed sections
- [ ] Flag slow sections
- [ ] Flag long awkward pauses
- [ ] Add timestamps and suggestions

**Success Criteria**: Critical moments identified

---

#### Task 3.2.6: Add Unit Tests
- [ ] Test WPM calculation
- [ ] Test pause detection
- [ ] Test pace variance
- [ ] Test scoring algorithm
- [ ] Target: > 80% coverage

**Success Criteria**: All tests pass

---

### 3.3 PersuasionInfluenceAnalyzer

**Priority**: P2 | **Complexity**: Medium | **Time**: 3-4 hours

#### Task 3.3.1: Implement Keyword Detection
- [ ] Use existing keyword lists (CALL_TO_ACTION_WORDS, POWER_WORDS, EVIDENCE_INDICATORS)
- [ ] Count occurrences of each keyword category
- [ ] Return counts in result

**Success Criteria**: Keywords detected and counted

---

#### Task 3.3.2: Implement Story Structure Analysis
- [ ] Detect story markers (narrative arc)
- [ ] Look for: opening, conflict, resolution, closing
- [ ] Calculate story coherence score
- [ ] Identify missing story elements

**Success Criteria**: Story structure analyzed

---

#### Task 3.3.3: Implement Evidence Usage Analysis
- [ ] Count evidence indicators
- [ ] Detect statistics, data, quotes
- [ ] Calculate evidence usage ratio
- [ ] Flag unsupported claims

**Success Criteria**: Evidence usage scored

---

#### Task 3.3.4: Implement Logical Fallacy Detection
- [ ] Define fallacy patterns (ad hominem, straw man, false dichotomy, etc.)
- [ ] Use pattern matching and NLP
- [ ] Flag potential fallacies
- [ ] Add to critical moments

**Success Criteria**: Fallacies detected (basic patterns)

---

#### Task 3.3.5: Implement Scoring Algorithm
- [ ] Weight: keywords (25%), story structure (30%), evidence (30%), fallacies (15%)
- [ ] Return score 0-100
- [ ] Add critical moments for weak persuasion

**Success Criteria**: Score calculated correctly

---

#### Task 3.3.6: Add Unit Tests
- [ ] Test keyword detection
- [ ] Test story structure analysis
- [ ] Test evidence detection
- [ ] Test scoring algorithm
- [ ] Target: > 80% coverage

**Success Criteria**: All tests pass

---

## Phase 4: Advanced Features (Future)

**Goal**: Production-ready features
**Estimated Time**: 10+ hours
**Priority**: P3 (Future work)

---

### 4.1 Daily Reports Aggregation

#### Task 4.1.1: Implement Daily Report Generation
- [ ] Create aggregation service
- [ ] Query all recordings for a specific date
- [ ] Calculate average scores
- [ ] Identify top patterns
- [ ] Store in database
- [ ] Add API endpoint `GET /reports/{date}`

**Time**: 2-3 hours

---

### 4.2 Integration Tests

#### Task 4.2.1: Write API Integration Tests
- [ ] Test complete upload → analyze → retrieve flow
- [ ] Test error scenarios (invalid file, missing auth, etc.)
- [ ] Test concurrent uploads
- [ ] Use pytest fixtures for test data

**Time**: 3-4 hours

---

### 4.3 Performance Optimization

#### Task 4.3.1: Optimize Database Queries
- [ ] Add indexes for common queries
- [ ] Optimize ORM queries (reduce N+1)
- [ ] Add query caching for reports

**Time**: 2 hours

---

#### Task 4.3.2: Parallel Analyzer Execution
- [ ] Use `asyncio` to run analyzers in parallel
- [ ] Reduce total analysis time by 3-4x
- [ ] Handle errors in parallel execution

**Time**: 2-3 hours

---

### 4.4 Production Deployment

#### Task 4.4.1: Production Configuration
- [ ] Create `docker-compose.prod.yml`
- [ ] Configure environment variables securely
- [ ] Set up SSL/TLS
- [ ] Configure reverse proxy (nginx)
- [ ] Set up log aggregation

**Time**: 4-5 hours

---

## Testing Checklist

After completing each phase, verify:

### Phase 1 Checklist
- [ ] Audio file uploads successfully
- [ ] Whisper transcription returns accurate text
- [ ] PowerDynamicsAnalyzer detects filler words
- [ ] Critical moments have real timestamps (not 0.0)
- [ ] Analysis results stored in database
- [ ] API returns complete response
- [ ] Logs show execution flow
- [ ] No errors in Docker logs

### Phase 2 Checklist
- [ ] All unit tests pass
- [ ] Test coverage > 80% for PowerDynamicsAnalyzer
- [ ] Error scenarios handled gracefully
- [ ] Performance metrics visible
- [ ] Slow requests logged

### Phase 3 Checklist
- [ ] All 4 analyzers return non-stub results
- [ ] LinguisticAuthorityAnalyzer working
- [ ] VocalCommandAnalyzer working
- [ ] PersuasionInfluenceAnalyzer working
- [ ] All analyzers have unit tests

---

## Dependencies & Prerequisites

### Required Software
- Python 3.10+
- PostgreSQL 15
- Docker & Docker Compose
- FFmpeg (for audio processing)

### Python Packages
```
fastapi
uvicorn
sqlalchemy
alembic
psycopg2-binary
pydantic
python-multipart
librosa
faster-whisper  # or openai-whisper
spacy
loguru
pytest
pytest-cov
```

### System Requirements
- RAM: 4GB minimum (8GB recommended for Whisper)
- Storage: 10GB for models and data
- CPU: Multi-core recommended for faster transcription

---

## Success Metrics

### MVP Success (Phase 1)
- ✅ Can upload audio file via API
- ✅ Transcription completes in < 30s per minute of audio
- ✅ Filler words detected with > 90% accuracy
- ✅ Timestamps accurate within ±2 seconds
- ✅ End-to-end latency < 60s for 2-minute audio

### Quality Success (Phase 2)
- ✅ Unit test coverage > 80%
- ✅ No unhandled exceptions in logs
- ✅ Error rate < 1% for valid requests
- ✅ Performance metrics tracked

### Complete Success (Phase 3)
- ✅ All 4 analyzers working
- ✅ Overall score combines all categories
- ✅ Critical moments from all analyzers
- ✅ Test coverage > 80% for all analyzers

---

## Notes

- **Whisper Model**: Start with `base` model for speed, upgrade to `small` or `medium` if accuracy needed
- **Async**: Consider making analyzer execution async in Phase 3 for better performance
- **Caching**: Add Redis caching for repeated analysis of same audio (future optimization)
- **Scalability**: For production, consider task queue (Celery) for background processing

---

**Last Updated**: 2025-10-29
**Current Phase**: Phase 1 - Foundation (In Progress)
