//
//  AnalysisResult.swift
//  SpeechMastery
//
//  Comprehensive speech analysis result returned from backend.
//  Contains scores, patterns, critical moments, and transcript.
//
//  Responsibilities:
//  - Store all analysis data (4 core analyzers + overall score)
//  - Provide structured access to critical moments and patterns
//  - Support JSON decoding from backend API
//  - Calculate derived metrics and insights
//
//  Integration Points:
//  - APIService: Decodes from POST /analyze response
//  - AnalysisResultView: Displays scores and moments in UI
//  - ReportGenerator: Aggregates for daily reports
//  - Recording model: Links to parent recording
//
//  Data Structure:
//  - Scores: 0-100 scale for each category
//  - Patterns: Detailed metrics (filler counts, WPM, etc.)
//  - Critical Moments: Timestamped issues with suggestions
//  - Transcript: Full text with optional timestamps
//

import Foundation

/// Complete speech analysis result for a recording
struct AnalysisResult: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for this analysis
    let id: UUID

    /// Reference to the recording that was analyzed
    let recordingID: UUID

    // MARK: - Timestamps

    /// When the analysis was created
    let createdAt: Date

    // MARK: - Scores (0-100 scale)

    /// Overall composite score across all categories
    let overallScore: Double

    /// Power dynamics score (filler words, hedging, upspeak)
    let powerDynamicsScore: Double

    /// Linguistic authority score (active voice, word economy, precision)
    let linguisticAuthorityScore: Double

    /// Vocal command score (pace, rhythm, pauses)
    let vocalCommandScore: Double

    /// Persuasion & influence score (coherence, persuasion techniques)
    let persuasionInfluenceScore: Double

    // MARK: - Transcription

    /// Full transcript of the recording
    let transcript: String

    /// Word count in transcript
    let wordCount: Int

    // MARK: - Pattern Details

    /// Detailed pattern breakdown (nested structure)
    let patterns: PatternDetails

    /// Array of critical moments with timestamps
    let criticalMoments: [CriticalMoment]

    /// Duration of analyzed recording (seconds)
    let duration: Double

    // MARK: - OPTIONAL FEATURE: CEO Voice Synthesis
    /// Comparisons to leadership-style alternatives
    // var ceoComparisons: [CEOComparison]?

    // MARK: - OPTIONAL FEATURE: Simulation Arena
    /// Simulation-specific scoring
    // var simulationPerformance: SimulationPerformance?

    // MARK: - OPTIONAL FEATURE: Conversational Chess
    /// Multi-speaker conversation analysis
    // var conversationAnalysis: ConversationAnalysis?

    // MARK: - OPTIONAL FEATURE: Voice Command Training
    /// Drill-specific metrics
    // var trainingMetrics: TrainingMetrics?

    // MARK: - Initialization

    init(
        id: UUID,
        recordingID: UUID,
        createdAt: Date,
        overallScore: Double,
        powerDynamicsScore: Double,
        linguisticAuthorityScore: Double,
        vocalCommandScore: Double,
        persuasionInfluenceScore: Double,
        transcript: String,
        wordCount: Int,
        patterns: PatternDetails,
        criticalMoments: [CriticalMoment],
        duration: Double
    ) {
        self.id = id
        self.recordingID = recordingID
        self.createdAt = createdAt
        self.overallScore = overallScore
        self.powerDynamicsScore = powerDynamicsScore
        self.linguisticAuthorityScore = linguisticAuthorityScore
        self.vocalCommandScore = vocalCommandScore
        self.persuasionInfluenceScore = persuasionInfluenceScore
        self.transcript = transcript
        self.wordCount = wordCount
        self.patterns = patterns
        self.criticalMoments = criticalMoments
        self.duration = duration
    }

    // MARK: - Helper Methods

    /// Get all scores as an array for charting
    var allScores: [(category: String, score: Double)] {
        [
            ("Power Dynamics", powerDynamicsScore),
            ("Linguistic Authority", linguisticAuthorityScore),
            ("Vocal Command", vocalCommandScore),
            ("Persuasion & Influence", persuasionInfluenceScore)
        ]
    }

    /// Get score color based on value (red < 60, yellow 60-80, green > 80)
    func scoreColor(for score: Double) -> String {
        if score >= 80 {
            return "green"
        } else if score >= 60 {
            return "yellow"
        } else {
            return "red"
        }
    }

    /// Count critical moments by severity
    var criticalMomentsBySeverity: [String: Int] {
        Dictionary(grouping: criticalMoments, by: { $0.severity })
            .mapValues { $0.count }
    }

    /// Get high-severity moments only
    var highSeverityMoments: [CriticalMoment] {
        criticalMoments.filter { $0.severity == "high" }
    }

    /// Check if analysis shows good performance (overall > 75)
    var isGoodPerformance: Bool {
        overallScore >= 75.0
    }

    /// Get weakest category
    var weakestCategory: String {
        let scores = allScores
        let weakest = scores.min(by: { $0.score < $1.score })
        return weakest?.category ?? "Unknown"
    }

    /// Get strongest category
    var strongestCategory: String {
        let scores = allScores
        let strongest = scores.max(by: { $0.score < $1.score })
        return strongest?.category ?? "Unknown"
    }

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case id
        case recordingID = "recording_id"
        case createdAt = "created_at"
        case overallScore = "overall_score"
        case powerDynamicsScore = "power_dynamics_score"
        case linguisticAuthorityScore = "linguistic_authority_score"
        case vocalCommandScore = "vocal_command_score"
        case persuasionInfluenceScore = "persuasion_influence_score"
        case transcript
        case wordCount = "word_count"
        case patterns
        case criticalMoments = "critical_moments"
        case duration

        // OPTIONAL FEATURE: Uncomment when implementing
        // case ceoComparisons = "ceo_comparisons"
        // case simulationPerformance = "simulation_performance"
        // case conversationAnalysis = "conversation_analysis"
        // case trainingMetrics = "training_metrics"
    }
}

// MARK: - Nested Types

/// Detailed pattern breakdown from analysis
struct PatternDetails: Codable, Hashable {
    // Power Dynamics patterns
    let fillerWords: FillerWordsPattern
    let hedging: HedgingPattern
    let upspeakIndicators: Int

    // Linguistic Authority patterns
    let passiveVoiceRatio: Double
    let averageSentenceLength: Double
    let wordDiversityScore: Double
    let jargonOveruseScore: Double?

    // Vocal Command patterns
    let wordsPerMinute: Double
    let averagePauseDuration: Double?
    let paceVariance: Double?

    // Persuasion patterns
    let storyCoherenceScore: Double?
    let persuasionKeywords: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case fillerWords = "filler_words"
        case hedging
        case upspeakIndicators = "upspeak_indicators"
        case passiveVoiceRatio = "passive_voice_ratio"
        case averageSentenceLength = "average_sentence_length"
        case wordDiversityScore = "word_diversity_score"
        case jargonOveruseScore = "jargon_overuse_score"
        case wordsPerMinute = "words_per_minute"
        case averagePauseDuration = "average_pause_duration"
        case paceVariance = "pace_variance"
        case storyCoherenceScore = "story_coherence_score"
        case persuasionKeywords = "persuasion_keywords"
    }
}

/// Filler words pattern analysis
struct FillerWordsPattern: Codable, Hashable {
    let count: Int
    let words: [String: Int]  // e.g., {"um": 3, "like": 5}
    let perMinute: Double

    enum CodingKeys: String, CodingKey {
        case count
        case words
        case perMinute = "per_minute"
    }
}

/// Hedging language pattern analysis
struct HedgingPattern: Codable, Hashable {
    let count: Int
    let phrases: [String: Int]  // e.g., {"I think": 2, "maybe": 3}

    enum CodingKeys: String, CodingKey {
        case count
        case phrases
    }
}

/// Critical moment with timestamp and suggestion
struct CriticalMoment: Identifiable, Codable, Hashable {
    var id: String {
        "\(recordingID)-\(timestamp)"  // Composite ID
    }

    let recordingID: UUID?  // Optional for backwards compatibility
    let timestamp: Double  // Seconds from start
    let quote: String  // Original problematic text
    let issue: String  // Description of the issue
    let category: String  // "power_dynamics", "linguistic_authority", etc.
    let suggestion: String  // Recommended alternative
    let severity: String  // "low", "medium", "high"

    enum CodingKeys: String, CodingKey {
        case recordingID = "recording_id"
        case timestamp
        case quote
        case issue
        case category
        case suggestion
        case severity
    }

    /// Human-readable timestamp (MM:SS)
    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Severity icon
    var severityIcon: String {
        switch severity {
        case "high": return "exclamationmark.triangle.fill"
        case "medium": return "exclamationmark.circle.fill"
        case "low": return "info.circle.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - OPTIONAL FEATURE: CEO Voice Synthesis Types

/*
/// Comparison to CEO-style alternative
struct CEOComparison: Codable, Hashable {
    let original: String
    let ceoVersion: String
    let styleAnalysis: String
    let authorityIncrease: Double

    enum CodingKeys: String, CodingKey {
        case original
        case ceoVersion = "ceo_version"
        case styleAnalysis = "style_analysis"
        case authorityIncrease = "authority_increase"
    }
}
*/

// MARK: - OPTIONAL FEATURE: Simulation Arena Types

/*
/// Simulation performance metrics
struct SimulationPerformance: Codable, Hashable {
    let scenarioID: UUID
    let difficulty: String
    let performanceScore: Double
    let objectivesMet: [String]
    let objectivesMissed: [String]

    enum CodingKeys: String, CodingKey {
        case scenarioID = "scenario_id"
        case difficulty
        case performanceScore = "performance_score"
        case objectivesMet = "objectives_met"
        case objectivesMissed = "objectives_missed"
    }
}
*/

// MARK: - OPTIONAL FEATURE: Conversational Chess Types

/*
/// Multi-speaker conversation analysis
struct ConversationAnalysis: Codable, Hashable {
    let speakerCount: Int
    let userAirtimeRatio: Double
    let interruptionCount: Int
    let tacticsDetected: [String]

    enum CodingKeys: String, CodingKey {
        case speakerCount = "speaker_count"
        case userAirtimeRatio = "user_airtime_ratio"
        case interruptionCount = "interruption_count"
        case tacticsDetected = "tactics_detected"
    }
}
*/

// MARK: - OPTIONAL FEATURE: Voice Command Training Types

/*
/// Training drill metrics
struct TrainingMetrics: Codable, Hashable {
    let exerciseID: UUID
    let exerciseType: String
    let targetMetric: Double
    let actualMetric: Double
    let accuracy: Double  // Percentage

    enum CodingKeys: String, CodingKey {
        case exerciseID = "exercise_id"
        case exerciseType = "exercise_type"
        case targetMetric = "target_metric"
        case actualMetric = "actual_metric"
        case accuracy
    }
}
*/

// MARK: - Sample Data for Previews

extension AnalysisResult {
    static var sample: AnalysisResult {
        AnalysisResult(
            id: UUID(),
            recordingID: UUID(),
            createdAt: Date(),
            overallScore: 74.5,
            powerDynamicsScore: 72.0,
            linguisticAuthorityScore: 68.5,
            vocalCommandScore: 81.0,
            persuasionInfluenceScore: 76.5,
            transcript: "I think maybe we should consider this approach because it offers significant benefits...",
            wordCount: 245,
            patterns: .sample,
            criticalMoments: [.sample, .sampleHighSeverity],
            duration: 125.5
        )
    }
}

extension PatternDetails {
    static var sample: PatternDetails {
        PatternDetails(
            fillerWords: FillerWordsPattern(count: 8, words: ["um": 3, "like": 5], perMinute: 3.8),
            hedging: HedgingPattern(count: 4, phrases: ["I think": 2, "maybe": 2]),
            upspeakIndicators: 6,
            passiveVoiceRatio: 0.15,
            averageSentenceLength: 12.5,
            wordDiversityScore: 68.0,
            jargonOveruseScore: 15.0,
            wordsPerMinute: 145.0,
            averagePauseDuration: 0.8,
            paceVariance: 12.5,
            storyCoherenceScore: 75.0,
            persuasionKeywords: ["because": 3, "limited": 1]
        )
    }
}

extension CriticalMoment {
    static var sample: CriticalMoment {
        CriticalMoment(
            recordingID: UUID(),
            timestamp: 45.2,
            quote: "I think maybe we should consider...",
            issue: "Hedging language detected",
            category: "power_dynamics",
            suggestion: "We should consider...",
            severity: "medium"
        )
    }

    static var sampleHighSeverity: CriticalMoment {
        CriticalMoment(
            recordingID: UUID(),
            timestamp: 78.5,
            quote: "It was decided that the approach would be...",
            issue: "Passive voice removes agency",
            category: "linguistic_authority",
            suggestion: "We decided to take this approach...",
            severity: "high"
        )
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: When implementing analysis result display:
 1. Create score card views with color coding
 2. Build timeline view for critical moments
 3. Add pattern breakdown visualization
 4. Implement transcript view with highlighting

 TODO: When implementing OPTIONAL FEATURE: CEO Voice Synthesis:
 1. Uncomment CEOComparison types
 2. Add side-by-side comparison view
 3. Highlight differences in text
 4. Show authority score improvements

 TODO: When implementing OPTIONAL FEATURE: Simulation Arena:
 1. Uncomment SimulationPerformance types
 2. Create objectives checklist view
 3. Show scenario-specific feedback
 4. Track progress across difficulty levels

 TODO: When implementing OPTIONAL FEATURE: Conversational Chess:
 1. Uncomment ConversationAnalysis types
 2. Build speaker diarization visualization
 3. Create airtime ratio charts
 4. Display tactical analysis insights

 TODO: When implementing OPTIONAL FEATURE: Voice Command Training:
 1. Uncomment TrainingMetrics types
 2. Show target vs actual metrics
 3. Create accuracy progress charts
 4. Track improvement over drill sessions

 TODO: Performance optimizations:
 1. Add lazy loading for long transcripts
 2. Cache processed pattern data
 3. Optimize critical moment sorting/filtering
 4. Consider pagination for large result sets
 */
