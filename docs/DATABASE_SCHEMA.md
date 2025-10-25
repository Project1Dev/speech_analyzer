# Database Schema

## Technology Stack
- **Database**: PostgreSQL 15+
- **ORM**: SQLAlchemy 2.0+
- **Migrations**: Alembic

## Schema Overview

```
users (single-user for prototype)
  ↓
recordings ←→ analysis_results
  ↓
reports
```

---

## Tables

### users

Stores user account information (simplified for single-user prototype).

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,

    -- OPTIONAL FEATURE: Premium subscription tracking
    -- premium_tier VARCHAR(50),  -- 'free', 'premium', 'pro'
    -- premium_expires_at TIMESTAMP WITH TIME ZONE,

    -- OPTIONAL FEATURE: Gamification
    -- total_xp INTEGER DEFAULT 0,
    -- current_streak INTEGER DEFAULT 0,
    -- longest_streak INTEGER DEFAULT 0,
    -- last_activity_date DATE,

    -- OPTIONAL FEATURE: Success Guarantee System
    -- program_start_date DATE,
    -- program_status VARCHAR(50),  -- 'enrolled', 'completed', 'refunded'

    CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
```

**Note**: For single-user prototype, seed with one default user.

---

### recordings

Stores metadata about audio recordings.

```sql
CREATE TABLE recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Recording metadata
    file_path VARCHAR(512) NOT NULL,
    file_size BIGINT NOT NULL,  -- bytes
    duration DECIMAL(10, 2) NOT NULL,  -- seconds

    -- Audio settings
    sample_rate INTEGER NOT NULL,  -- Hz (e.g., 16000)
    bit_rate INTEGER NOT NULL,     -- bps (e.g., 128000)
    format VARCHAR(10) NOT NULL,   -- 'm4a', 'mp3', 'wav'
    channels INTEGER DEFAULT 1,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Analysis status
    analyzed BOOLEAN DEFAULT FALSE,
    analysis_started_at TIMESTAMP WITH TIME ZONE,
    analysis_completed_at TIMESTAMP WITH TIME ZONE,

    -- Privacy & retention
    auto_delete_at TIMESTAMP WITH TIME ZONE NOT NULL,  -- 7 days from recorded_at
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT recordings_duration_positive CHECK (duration > 0),
    CONSTRAINT recordings_file_size_positive CHECK (file_size > 0)
);

CREATE INDEX idx_recordings_user_id ON recordings(user_id);
CREATE INDEX idx_recordings_recorded_at ON recordings(recorded_at DESC);
CREATE INDEX idx_recordings_auto_delete_at ON recordings(auto_delete_at);
CREATE INDEX idx_recordings_analyzed ON recordings(analyzed);
```

---

### analysis_results

Stores comprehensive speech analysis results for each recording.

```sql
CREATE TABLE analysis_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID UNIQUE NOT NULL REFERENCES recordings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Overall scores (0-100 scale)
    overall_score DECIMAL(5, 2) NOT NULL,
    power_dynamics_score DECIMAL(5, 2) NOT NULL,
    linguistic_authority_score DECIMAL(5, 2) NOT NULL,
    vocal_command_score DECIMAL(5, 2) NOT NULL,
    persuasion_influence_score DECIMAL(5, 2) NOT NULL,

    -- Transcription
    transcript TEXT NOT NULL,
    word_count INTEGER NOT NULL,

    -- Power Dynamics Analysis
    filler_words JSONB NOT NULL,  -- {"um": 3, "like": 5, ...}
    filler_words_total INTEGER DEFAULT 0,
    filler_words_per_minute DECIMAL(5, 2) DEFAULT 0,

    hedging_phrases JSONB NOT NULL,  -- {"I think": 2, "maybe": 3, ...}
    hedging_total INTEGER DEFAULT 0,

    upspeak_indicators INTEGER DEFAULT 0,  -- question marks as proxy

    -- Linguistic Authority Analysis
    passive_voice_count INTEGER DEFAULT 0,
    active_voice_count INTEGER DEFAULT 0,
    passive_voice_ratio DECIMAL(4, 3) DEFAULT 0,  -- 0.000 to 1.000

    average_sentence_length DECIMAL(5, 2) DEFAULT 0,
    word_diversity_score DECIMAL(5, 2) DEFAULT 0,  -- entropy measure

    jargon_overuse_score DECIMAL(5, 2) DEFAULT 0,
    jargon_terms JSONB,  -- ["synergy", "paradigm", ...]

    -- Vocal Command Analysis
    words_per_minute DECIMAL(6, 2) NOT NULL,
    average_pause_duration DECIMAL(5, 2) DEFAULT 0,  -- seconds
    pace_variance DECIMAL(5, 2) DEFAULT 0,

    -- Persuasion & Influence Analysis
    story_coherence_score DECIMAL(5, 2) DEFAULT 0,
    persuasion_keywords JSONB,  -- ["because": 3, "limited": 1, ...]

    -- Critical moments (issues detected)
    critical_moments JSONB NOT NULL,  -- Array of moment objects
    critical_moments_count INTEGER DEFAULT 0,

    -- Pattern summary
    patterns_detected JSONB NOT NULL,  -- Summary of all patterns

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- OPTIONAL FEATURE: CEO Voice Synthesis comparisons
    -- ceo_comparisons JSONB,

    -- OPTIONAL FEATURE: Simulation Arena scoring
    -- simulation_scenario_id UUID,
    -- simulation_performance_score DECIMAL(5, 2),

    CONSTRAINT analysis_overall_score_range CHECK (overall_score >= 0 AND overall_score <= 100),
    CONSTRAINT analysis_scores_range CHECK (
        power_dynamics_score >= 0 AND power_dynamics_score <= 100 AND
        linguistic_authority_score >= 0 AND linguistic_authority_score <= 100 AND
        vocal_command_score >= 0 AND vocal_command_score <= 100 AND
        persuasion_influence_score >= 0 AND persuasion_influence_score <= 100
    )
);

CREATE INDEX idx_analysis_results_recording_id ON analysis_results(recording_id);
CREATE INDEX idx_analysis_results_user_id ON analysis_results(user_id);
CREATE INDEX idx_analysis_results_created_at ON analysis_results(created_at DESC);
CREATE INDEX idx_analysis_results_overall_score ON analysis_results(overall_score);
```

**JSONB Structure Examples**:

```json
// critical_moments
[
  {
    "timestamp": 12.5,
    "quote": "I think maybe we should...",
    "issue": "Hedging language detected",
    "category": "power_dynamics",
    "suggestion": "We should...",
    "severity": "medium"
  }
]

// patterns_detected
{
  "filler_words": {"count": 8, "per_minute": 2.4},
  "hedging": {"count": 4, "impact": "medium"},
  "passive_voice": {"ratio": 0.15, "impact": "low"}
}
```

---

### reports

Stores aggregated daily reports with pattern recognition.

```sql
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Report metadata
    report_date DATE NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Summary metrics
    recordings_analyzed INTEGER NOT NULL,
    total_duration DECIMAL(10, 2) NOT NULL,  -- seconds

    -- Aggregated scores
    overall_score DECIMAL(5, 2) NOT NULL,
    power_dynamics_score DECIMAL(5, 2) NOT NULL,
    linguistic_authority_score DECIMAL(5, 2) NOT NULL,
    vocal_command_score DECIMAL(5, 2) NOT NULL,
    persuasion_influence_score DECIMAL(5, 2) NOT NULL,

    -- Top patterns detected
    top_patterns JSONB NOT NULL,  -- Array of pattern objects with recommendations

    -- Critical moments across all recordings
    critical_moments JSONB NOT NULL,

    -- Improvement suggestions
    improvement_suggestions JSONB NOT NULL,  -- Array of actionable recommendations

    -- Comparison to previous periods
    score_change_24h DECIMAL(5, 2),  -- Change vs yesterday
    score_change_7d DECIMAL(5, 2),   -- Change vs 7 days ago

    -- OPTIONAL FEATURE: Trend data for visualization
    -- trend_data JSONB,  -- Historical score progression

    CONSTRAINT reports_user_date_unique UNIQUE(user_id, report_date),
    CONSTRAINT reports_scores_range CHECK (
        overall_score >= 0 AND overall_score <= 100 AND
        power_dynamics_score >= 0 AND power_dynamics_score <= 100 AND
        linguistic_authority_score >= 0 AND linguistic_authority_score <= 100 AND
        vocal_command_score >= 0 AND vocal_command_score <= 100 AND
        persuasion_influence_score >= 0 AND persuasion_influence_score <= 100
    )
);

CREATE INDEX idx_reports_user_id ON reports(user_id);
CREATE INDEX idx_reports_date ON reports(report_date DESC);
CREATE INDEX idx_reports_generated_at ON reports(generated_at DESC);
```

---

## OPTIONAL FEATURE: Premium Feature Tables

These tables support premium features and should be created when those features are implemented.

### simulation_scenarios

```sql
-- OPTIONAL FEATURE: Simulation Arena
-- Stores predefined roleplay scenarios for practice

CREATE TABLE simulation_scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    difficulty_level VARCHAR(20) NOT NULL,  -- 'easy', 'medium', 'hard', 'expert'
    scenario_type VARCHAR(50) NOT NULL,     -- 'negotiation', 'presentation', 'interview', etc.
    script TEXT NOT NULL,
    expected_responses JSONB,
    success_criteria JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### achievements

```sql
-- OPTIONAL FEATURE: Gamification System
-- Tracks unlockable achievements and badges

CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(100) NOT NULL,
    achievement_name VARCHAR(255) NOT NULL,
    description TEXT,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    xp_awarded INTEGER DEFAULT 0
);
```

### phrase_arsenal

```sql
-- OPTIONAL FEATURE: Power Language Arsenal
-- Stores personalized phrase mappings for the user

CREATE TABLE phrase_arsenal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    weak_phrase TEXT NOT NULL,
    strong_alternative TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,  -- 'hedging', 'passive', 'filler', etc.
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### conversation_analyses

```sql
-- OPTIONAL FEATURE: Conversational Chess
-- Detailed multi-speaker conversation analysis

CREATE TABLE conversation_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID NOT NULL REFERENCES recordings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Speaker diarization results
    speakers JSONB NOT NULL,  -- Array of speaker segments

    -- Conversational metrics
    user_airtime_ratio DECIMAL(4, 3),  -- 0.000 to 1.000
    interruption_count INTEGER DEFAULT 0,
    question_to_statement_ratio DECIMAL(5, 2),

    -- Tactical analysis
    tactics_detected JSONB,  -- Persuasion tactics used

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Indexes for Performance

```sql
-- Composite indexes for common queries
CREATE INDEX idx_recordings_user_analyzed ON recordings(user_id, analyzed, recorded_at DESC);
CREATE INDEX idx_analysis_user_score ON analysis_results(user_id, overall_score DESC);
CREATE INDEX idx_reports_user_date ON reports(user_id, report_date DESC);
```

---

## Migration Strategy

1. **Initial Schema**: Create users, recordings, analysis_results, reports tables
2. **Phase 1**: Add indexes for query optimization
3. **Phase 2**: Add JSONB GIN indexes if pattern queries are slow
4. **Future**: Add premium feature tables as features are implemented

```sql
-- JSONB indexing for fast pattern queries (if needed)
CREATE INDEX idx_analysis_filler_words ON analysis_results USING GIN (filler_words);
CREATE INDEX idx_analysis_critical_moments ON analysis_results USING GIN (critical_moments);
```

---

## Data Retention Policy

- **Recordings**: Auto-deleted after 7 days (auto_delete_at field)
- **Analysis Results**: Retained indefinitely for trend analysis
- **Reports**: Retained indefinitely
- **Soft Deletes**: Use deleted_at timestamps where applicable

**TODO**: Implement automated cleanup job for expired recordings

---

## Backup & Recovery

**Base Prototype**: Manual PostgreSQL dumps
**OPTIONAL FEATURE**: Automated daily backups to S3/GCS with point-in-time recovery
