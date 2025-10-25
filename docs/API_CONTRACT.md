# API Contract Specification

## Base URL
- **Development**: `http://localhost:8000`
- **Production**: TBD

## Authentication
**Single-User Mode** (Prototype)
- All requests include header: `Authorization: Bearer <HARDCODED_TOKEN>`
- Token validation simplified for single-user testing

**OPTIONAL FEATURE: Multi-User Authentication**
<!-- When implementing full auth system:
- POST /auth/register - User registration
- POST /auth/login - Get JWT token
- POST /auth/refresh - Refresh token
- POST /auth/logout - Invalidate token
-->

## Core Endpoints (Base Prototype)

### 1. Analyze Recording

**POST /analyze**

Upload an audio recording for speech analysis.

**Request**:
```
Content-Type: multipart/form-data
Authorization: Bearer <token>

Body:
  audio_file: <binary audio file>
  recording_date: <ISO 8601 timestamp>
  duration: <float seconds>
  settings: <JSON object with audio quality settings>
```

**Response** (200 OK):
```json
{
  "recording_id": "uuid",
  "analysis_id": "uuid",
  "created_at": "2025-10-23T10:30:00Z",
  "scores": {
    "power_dynamics": 72.5,
    "linguistic_authority": 68.0,
    "vocal_command": 81.3,
    "persuasion_influence": 75.8,
    "overall": 74.4
  },
  "critical_moments": [
    {
      "timestamp": 12.5,
      "quote": "I think maybe we should consider...",
      "issue": "Hedging language detected",
      "category": "power_dynamics",
      "suggestion": "We should consider...",
      "severity": "medium"
    }
  ],
  "patterns": {
    "filler_words": {
      "count": 8,
      "words": {"um": 3, "like": 5},
      "per_minute": 2.4
    },
    "hedging": {
      "count": 4,
      "phrases": {"I think": 2, "maybe": 2}
    },
    "passive_voice_ratio": 0.15,
    "words_per_minute": 145.3,
    "average_sentence_length": 12.8
  },
  "transcript": "Full transcription text...",
  "duration": 200.5
}
```

**Error Responses**:
- 400 Bad Request: Invalid audio format or missing parameters
- 401 Unauthorized: Invalid or missing token
- 413 Payload Too Large: File exceeds size limit (default 50MB)
- 500 Internal Server Error: Analysis processing failed

---

### 2. Get Daily Report

**GET /reports/{date}**

Retrieve aggregated daily report for a specific date.

**Parameters**:
- `date`: ISO 8601 date string (e.g., "2025-10-23")

**Response** (200 OK):
```json
{
  "date": "2025-10-23",
  "report_id": "uuid",
  "recordings_analyzed": 5,
  "total_duration": 1247.5,
  "scores": {
    "power_dynamics": 74.2,
    "linguistic_authority": 70.5,
    "vocal_command": 79.8,
    "persuasion_influence": 76.3,
    "overall": 75.2
  },
  "top_patterns": [
    {
      "pattern_type": "filler_words",
      "category": "power_dynamics",
      "occurrences": 42,
      "impact_score": -5.5,
      "recommendation": "Practice pausing instead of using filler words"
    },
    {
      "pattern_type": "passive_voice",
      "category": "linguistic_authority",
      "occurrences": 18,
      "impact_score": -3.2,
      "recommendation": "Use active voice for stronger statements"
    }
  ],
  "critical_moments": [
    {
      "recording_id": "uuid",
      "timestamp": 45.2,
      "quote": "It was decided that we should...",
      "issue": "Passive voice removes agency",
      "suggestion": "We decided to...",
      "severity": "high"
    }
  ],
  "improvement_suggestions": [
    "Focus on eliminating 'um' and 'like' from your speech",
    "Reduce hedging phrases by 50% this week",
    "Practice speaking 10% slower for better clarity"
  ]
}
```

**OPTIONAL FEATURE: Trend Visualization Data**
<!-- When implementing historical trends:
Add "trends" field with time-series data:
  "trends": {
    "daily_scores": [
      {"date": "2025-10-17", "overall": 68.5},
      {"date": "2025-10-18", "overall": 71.2},
      ...
    ],
    "pattern_evolution": {...}
  }
-->

---

### 3. List Recordings

**GET /recordings**

Get list of all recordings for the user.

**Query Parameters**:
- `limit`: Number of results (default: 50, max: 100)
- `offset`: Pagination offset (default: 0)
- `start_date`: Filter by start date (ISO 8601)
- `end_date`: Filter by end date (ISO 8601)

**Response** (200 OK):
```json
{
  "total": 127,
  "limit": 50,
  "offset": 0,
  "recordings": [
    {
      "id": "uuid",
      "created_at": "2025-10-23T10:30:00Z",
      "duration": 200.5,
      "file_size": 2048000,
      "analyzed": true,
      "analysis_id": "uuid",
      "overall_score": 74.4
    }
  ]
}
```

---

### 4. Delete Recording

**DELETE /recordings/{recording_id}**

Delete a specific recording and its analysis results.

**Response** (204 No Content)

**Error Responses**:
- 404 Not Found: Recording does not exist
- 403 Forbidden: Recording belongs to another user (multi-user mode only)

---

## OPTIONAL FEATURE ENDPOINTS

### Premium: CEO Voice Synthesis

**POST /premium/ceo-voice/compare**

Compare user's speech to leadership-style alternatives.

<!-- TODO: Implement when CEO Voice Synthesis feature is enabled
Request:
{
  "recording_id": "uuid",
  "context": "business_presentation" | "negotiation" | "general"
}

Response:
{
  "comparisons": [
    {
      "original": "I think we should consider this approach",
      "ceo_version": "We're implementing this approach",
      "style_analysis": "More decisive, removes hedging",
      "authority_increase": 15.5
    }
  ]
}
-->

---

### Premium: Live Guardian Mode

**POST /premium/live-guardian/start**

Start a live monitoring session (simplified post-conversation analysis).

<!-- TODO: Implement when Live Guardian Mode is enabled
Real-time endpoints for:
- Session management
- Quick analysis results
- Watch connectivity integration
-->

---

### Premium: Simulation Arena

**GET /premium/simulation/scenarios**

Get available roleplay scenarios.

**POST /premium/simulation/analyze**

Analyze performance in simulation.

<!-- TODO: Implement when Simulation Arena is enabled
Scenarios include:
- Difficult conversation handling
- Negotiation simulation
- Presentation practice
- Interview preparation
-->

---

### Premium: Gamification

**GET /premium/gamification/stats**

Get user XP, streaks, and achievements.

**GET /premium/gamification/leaderboard**

Get anonymous leaderboard rankings.

<!-- TODO: Implement when Gamification System is enabled
Includes:
- XP calculation based on improvement
- Daily/weekly streaks
- Achievement unlocks
- Anonymous competitive rankings
-->

---

## Data Models

### AudioSettings
```json
{
  "sample_rate": 16000,
  "bit_rate": 128000,
  "format": "m4a",
  "channels": 1
}
```

### ScoreBreakdown
```json
{
  "score": 74.5,
  "components": {
    "filler_score": 70.0,
    "hedging_score": 75.0,
    "clarity_score": 78.5
  },
  "percentile": 65
}
```

## Error Response Format

All errors follow this structure:
```json
{
  "error": {
    "code": "INVALID_AUDIO_FORMAT",
    "message": "Unsupported audio format. Please upload M4A, MP3, or WAV.",
    "details": {
      "received_format": "ogg",
      "supported_formats": ["m4a", "mp3", "wav"]
    }
  }
}
```

## Rate Limiting

**Base Prototype**: No rate limiting
**OPTIONAL FEATURE**: Implement rate limiting for production
<!-- TODO: Add when scaling to production
- 100 requests per hour for analysis
- 1000 requests per hour for reads
- Rate limit headers: X-RateLimit-Limit, X-RateLimit-Remaining
-->

## Versioning

**Current Version**: v1
**Base Path**: `/v1/` (currently default)
**OPTIONAL FEATURE**: Version management for breaking changes
