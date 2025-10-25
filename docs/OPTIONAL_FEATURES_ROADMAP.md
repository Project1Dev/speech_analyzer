# Optional Features Roadmap

This document outlines the implementation plan for premium features that will be added **after** the base prototype is complete.

## Implementation Status Legend
- 🔴 Not Started - Placeholder hooks exist in codebase
- 🟡 In Progress - Active development
- 🟢 Complete - Feature implemented and tested

---

## Priority 1: Core Premium Features

### 1. CEO Voice Synthesis 🔴

**Purpose**: Compare user's speech to leadership-style alternatives with reframing suggestions.

**Implementation Plan**:
1. Create database table for leadership speech templates
2. Implement text comparison service using difflib or semantic similarity
3. Build reframing algorithm to transform weak phrases
4. Add `/premium/ceo-voice/compare` endpoint
5. Create iOS `CEOVoiceSynthesisView.swift` with before/after comparison UI
6. Add side-by-side text display with highlighted changes

**File Hooks**:
- iOS: `ios/SpeechMastery/Views/Premium/CEOVoiceSynthesisView.swift`
- Backend: `backend/app/api/premium/ceo_voice.py`
- Service: `backend/app/services/ceo_synthesis_service.py` (TO CREATE)

**Data Requirements**:
```sql
CREATE TABLE leadership_templates (
    id UUID PRIMARY KEY,
    original_pattern TEXT,
    ceo_version TEXT,
    transformation_type VARCHAR(50),
    authority_boost DECIMAL(5,2)
);
```

**API Endpoint**:
```python
# POST /premium/ceo-voice/compare
{
  "recording_id": "uuid",
  "context": "business_presentation"
}

# Response:
{
  "comparisons": [
    {
      "original": "I think we should consider...",
      "ceo_version": "We're implementing...",
      "style_analysis": "Removes hedging, adds decisiveness",
      "authority_increase": 15.5
    }
  ]
}
```

**Estimated Effort**: 2-3 weeks

---

### 2. Live Guardian Mode 🔴

**Purpose**: Simplified post-conversation analysis with watch vibration alerts for filler word overuse.

**Implementation Plan**:
1. Add WatchConnectivity framework to iOS project
2. Create companion watchOS app target
3. Implement on-device filler word detection with basic keyword spotting
4. Add vibration alerts when threshold exceeded (e.g., 3 fillers in 30 seconds)
5. Create quick analysis endpoint for priority processing
6. Build 2-minute audio debrief generator
7. Implement AVSpeechSynthesizer for spoken summary

**File Hooks**:
- iOS: `ios/SpeechMastery/Views/Premium/LiveGuardianView.swift`
- iOS: `ios/SpeechMastery/Services/WatchConnectivityService.swift` (TO CREATE)
- watchOS: `ios/SpeechMasteryWatch/` (TO CREATE)
- Backend: `backend/app/api/premium/live_guardian.py`
- Service: `backend/app/services/live_analysis_service.py` (TO CREATE)

**WatchOS Integration**:
```swift
// Real-time filler detection
class LiveGuardianService: ObservableObject {
    @Published var fillerCount: Int = 0
    private var watchSession: WCSession?

    func detectFiller(_ text: String) {
        // Basic keyword matching
        if fillerWords.contains(text.lowercased()) {
            fillerCount += 1
            if fillerCount % 3 == 0 {
                triggerWatchVibration()
            }
        }
    }
}
```

**API Endpoints**:
```python
# POST /premium/live-guardian/start
# POST /premium/live-guardian/stop
# GET /premium/live-guardian/debrief/{session_id}
```

**Estimated Effort**: 4-5 weeks (includes watchOS development)

---

### 3. Simulation Arena 🔴

**Purpose**: Roleplay practice with predefined scenarios and difficulty scaling.

**Implementation Plan**:
1. Create `simulation_scenarios` database table
2. Build scenario management system with CRUD operations
3. Implement scenario script engine with variable difficulty
4. Create AI response generator (template-based for prototype)
5. Build iOS roleplay recording interface
6. Add performance scoring specific to scenario objectives
7. Create scenario browsing and selection UI

**File Hooks**:
- iOS: `ios/SpeechMastery/Views/Premium/SimulationArenaView.swift`
- Backend: `backend/app/api/premium/simulation.py`
- Service: `backend/app/services/simulation_service.py` (TO CREATE)
- Models: `backend/app/models/simulation_scenario.py` (TO CREATE)

**Scenario Structure**:
```json
{
  "id": "uuid",
  "title": "Difficult Client Negotiation",
  "description": "Handle objections from skeptical client",
  "difficulty": "hard",
  "script": [
    {
      "speaker": "client",
      "text": "Your price is too high.",
      "expected_response_type": "confident_rebuttal"
    }
  ],
  "success_criteria": {
    "min_authority_score": 75,
    "max_filler_count": 3,
    "required_persuasion_techniques": ["because_authority", "scarcity"]
  }
}
```

**API Endpoints**:
```python
# GET /premium/simulation/scenarios
# POST /premium/simulation/analyze
# GET /premium/simulation/results/{session_id}
```

**Estimated Effort**: 3-4 weeks

---

### 4. Gamification System 🔴

**Purpose**: XP, streaks, achievements, and leaderboards to drive engagement.

**Implementation Plan**:
1. Add gamification columns to `users` table (XP, streaks, level)
2. Create `achievements` table with unlockable badges
3. Implement XP calculation algorithm based on:
   - Recording frequency
   - Score improvements
   - Streak maintenance
   - Milestone achievements
4. Build leaderboard service with anonymous rankings
5. Create iOS `GamificationView.swift` with progress visualization
6. Add push notifications for streak reminders and achievement unlocks

**File Hooks**:
- iOS: `ios/SpeechMastery/Views/Premium/GamificationView.swift`
- Backend: `backend/app/api/premium/gamification.py`
- Service: `backend/app/services/gamification_service.py` (TO CREATE)

**XP Calculation Formula**:
```python
def calculate_xp(analysis_result, previous_score, streak_days):
    base_xp = 10  # Per recording
    improvement_bonus = max(0, (analysis_result.overall_score - previous_score) * 5)
    streak_multiplier = 1 + (min(streak_days, 30) * 0.05)  # Up to 2.5x at 30-day streak
    return int((base_xp + improvement_bonus) * streak_multiplier)
```

**Achievement Examples**:
- "First Steps" - Complete first recording (10 XP)
- "Week Warrior" - 7-day streak (100 XP)
- "Filler Fighter" - Reduce filler words by 50% (50 XP)
- "Authority Master" - Score 90+ on Linguistic Authority (200 XP)

**API Endpoints**:
```python
# GET /premium/gamification/stats
# GET /premium/gamification/achievements
# GET /premium/gamification/leaderboard
```

**Estimated Effort**: 2-3 weeks

---

## Priority 2: Advanced Features

### 5. Pre-Game Prep Mode 🔴

**Purpose**: Generate talking points and warm-up exercises before important conversations.

**Implementation Plan**:
1. Analyze recent weak patterns for user
2. Create agenda input form in iOS
3. Generate talking points from template system
4. Build warm-up exercise library (vocal, pacing, articulation)
5. Add audio playback for practice prompts
6. Track prep session completion and impact on performance

**File Hooks**:
- iOS: `ios/SpeechMastery/Views/Premium/PreGamePrepView.swift` (TO CREATE)
- Backend: `backend/app/api/premium/prep_mode.py` (TO CREATE)

**Estimated Effort**: 2 weeks

---

### 6. Power Language Arsenal 🔴

**Purpose**: Personalized phrase database for replacing weak language with strong alternatives.

**Implementation Plan**:
1. Create `phrase_arsenal` table with weak→strong mappings
2. Build categorization system (hedging, passive, filler, etc.)
3. Generate personalized suggestions based on user's patterns
4. Create searchable iOS interface for browsing phrases
5. Add practice mode with audio recording
6. Track phrase usage and improvement

**File Hooks**:
- iOS: `ios/SpeechMastery/Views/Premium/PowerLanguageArsenalView.swift` (TO CREATE)
- Backend: `backend/app/api/premium/arsenal.py` (TO CREATE)

**Example Mappings**:
```json
[
  {
    "weak": "I think we should...",
    "strong": "We should...",
    "category": "hedging"
  },
  {
    "weak": "It was decided that...",
    "strong": "We decided to...",
    "category": "passive_voice"
  }
]
```

**Estimated Effort**: 2 weeks

---

### 7. Conversational Chess 🔴

**Purpose**: Multi-speaker analysis for airtime ratios and tactical insights.

**Implementation Plan**:
1. Implement basic speaker diarization (or use external service)
2. Calculate airtime ratios and interruption counts
3. Detect conversational tactics (questioning, asserting, etc.)
4. Create visualization of conversation flow
5. Build iOS tactical analysis view with charts

**File Hooks**:
- Backend: `backend/app/services/conversation_analyzer.py` (TO CREATE)
- Models: `backend/app/models/conversation_analysis.py` (TO CREATE)

**Technical Challenge**: Speaker diarization is complex. Consider using:
- External API (AssemblyAI, AWS Transcribe)
- Pyannote.audio library
- Simplified approach: User manually marks their segments

**Estimated Effort**: 3-4 weeks

---

### 8. Voice Command Training 🔴

**Purpose**: Daily drills with exercises for pace, articulation, and tonality.

**Implementation Plan**:
1. Create exercise library (tongue twisters, pace control, breathing)
2. Build iOS drill interface with timers
3. Add on-device pace calculation during drills
4. Upload drill recordings for server scoring
5. Track progress over time with visualization
6. Generate adaptive workout plans

**File Hooks**:
- iOS: `ios/SpeechMastery/Views/Premium/VoiceTrainingView.swift` (TO CREATE)
- Backend: `backend/app/services/training_service.py` (TO CREATE)

**Exercise Examples**:
- Pace Control: "Read this passage at exactly 120 WPM"
- Articulation: "Red leather, yellow leather" (repeat 10x clearly)
- Power Pauses: "Practice strategic pausing after key statements"

**Estimated Effort**: 2-3 weeks

---

### 9. Success Guarantee System 🔴

**Purpose**: 90-day protocol with before/after tracking and refund eligibility.

**Implementation Plan**:
1. Add program enrollment system to user model
2. Track baseline metrics from first 3 recordings
3. Generate milestone checkpoints (30, 60, 90 days)
4. Create before/after comparison reports
5. Implement progress tracking dashboard
6. Add refund eligibility checker (manual review for prototype)

**File Hooks**:
- Backend: `backend/app/services/success_guarantee_service.py` (TO CREATE)
- Database: Add columns to `users` table for program tracking

**Success Metrics**:
- Filler word reduction: 70%+
- Hedging reduction: 60%+
- Overall score improvement: 20+ points
- Consistency: 80% of recordings meet targets

**Estimated Effort**: 2 weeks

---

## Implementation Dependencies

```
Base Prototype (COMPLETE)
       ↓
┌──────┴──────┬──────────┬────────────┐
│             │          │            │
CEO Voice   Gamif.   Sim Arena   Live Guardian
  (2-3w)     (2-3w)   (3-4w)        (4-5w)
                                      ↓
                              Requires watchOS
       ↓
   Pre-Game    Arsenal    Conv Chess    Training
    (2w)        (2w)        (3-4w)       (2-3w)
       ↓
   Success Guarantee (2w)
```

**Recommended Order**:
1. **Gamification** - Drives engagement, no complex dependencies
2. **CEO Voice Synthesis** - High value, moderate complexity
3. **Simulation Arena** - Builds on analysis engine
4. **Pre-Game Prep** - Leverages existing pattern analysis
5. **Power Language Arsenal** - Natural extension of patterns
6. **Voice Command Training** - Independent feature
7. **Live Guardian Mode** - Requires watchOS expertise
8. **Conversational Chess** - Complex speaker diarization
9. **Success Guarantee** - Capstone feature requiring historical data

---

## Feature Flags

All optional features should use feature flags for controlled rollout:

```python
# backend/app/config.py
class Settings:
    # Feature flags (environment variables)
    ENABLE_CEO_VOICE: bool = False
    ENABLE_LIVE_GUARDIAN: bool = False
    ENABLE_SIMULATION_ARENA: bool = False
    ENABLE_GAMIFICATION: bool = False
    # ... etc
```

```swift
// ios/SpeechMastery/Utilities/FeatureFlags.swift
enum FeatureFlag {
    static let ceoVoice = false
    static let liveGuardian = false
    static let simulationArena = false
    static let gamification = false
}
```

---

## Testing Requirements for Optional Features

Each optional feature must include:
1. **Unit Tests**: Core logic functions
2. **Integration Tests**: API endpoint flows
3. **UI Tests**: Critical user journeys (iOS)
4. **Performance Tests**: Impact on analysis speed
5. **Privacy Review**: Data handling compliance
6. **Documentation**: User-facing guides

---

## Premium Tier Strategy

**Prototype**: All features behind single "Premium" tier

**Future**: Tiered pricing
- **Free**: Base analysis only
- **Premium** ($9.99/mo): CEO Voice, Gamification, Arsenal
- **Pro** ($19.99/mo): All features including Live Guardian, Simulation Arena
- **Enterprise** (Custom): Team dashboards, admin controls

---

## Migration Path

When implementing each optional feature:

1. **Uncomment placeholder files** already in skeleton
2. **Implement service layer** with abstract interfaces
3. **Add database migrations** for new tables
4. **Create API endpoints** following existing patterns
5. **Build iOS views** matching app's design system
6. **Write comprehensive tests**
7. **Update documentation**
8. **Enable feature flag** for testing
9. **Beta test** with small user group
10. **Full rollout** with monitoring

---

## Notes for Implementer

- **All commented code sections** marked with `OPTIONAL FEATURE: [Name]` indicate where premium features integrate
- **Follow existing patterns** - maintain consistency with base prototype architecture
- **Abstract interfaces first** - design generic APIs before concrete implementations
- **Test thoroughly** - optional features should never break core functionality
- **Document extensively** - these features are complex and will need maintenance

---

## Questions to Address During Implementation

For each feature, consider:
- [ ] How does this integrate with existing analysis pipeline?
- [ ] What new database tables/columns are needed?
- [ ] What's the performance impact on base features?
- [ ] How does this work in offline mode (iOS)?
- [ ] What privacy concerns does this introduce?
- [ ] How is this feature tested and monitored?
- [ ] What's the user onboarding flow?
- [ ] How do we measure feature success/usage?
