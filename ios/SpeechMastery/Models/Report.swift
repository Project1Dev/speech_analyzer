//
//  Report.swift
//  SpeechMastery
//
//  Daily aggregated report with pattern recognition and improvement suggestions.
//  Synthesizes insights from all recordings analyzed in a day.
//
//  Responsibilities:
//  - Store daily aggregate scores across all categories
//  - Identify top recurring patterns and weaknesses
//  - Provide critical moments from multiple recordings
//  - Track score changes over time
//  - Generate actionable improvement suggestions
//
//  Integration Points:
//  - APIService: Fetches from GET /reports/{date} endpoint
//  - DailyReportView: Displays report in UI
//  - ReportViewModel: Manages report state and loading
//  - Push notifications: Triggers daily report fetch
//
//  Report Generation:
//  - Server generates reports via daily cron job
//  - Aggregates all analyses from past 24 hours
//  - Calculates weighted scores and pattern frequencies
//  - Identifies improvement opportunities
//

import Foundation

/// Daily aggregated speech analysis report
struct Report: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for this report
    let id: UUID

    // MARK: - Date

    /// Date this report covers (YYYY-MM-DD)
    let reportDate: Date

    /// When this report was generated
    let generatedAt: Date

    // MARK: - Summary Metrics

    /// Number of recordings analyzed this day
    let recordingsAnalyzed: Int

    /// Total duration of all recordings (seconds)
    let totalDuration: Double

    // MARK: - Aggregated Scores (0-100 scale)

    /// Overall composite score for the day
    let overallScore: Double

    /// Power dynamics daily average
    let powerDynamicsScore: Double

    /// Linguistic authority daily average
    let linguisticAuthorityScore: Double

    /// Vocal command daily average
    let vocalCommandScore: Double

    /// Persuasion & influence daily average
    let persuasionInfluenceScore: Double

    // MARK: - Pattern Recognition

    /// Top recurring patterns detected across all recordings
    let topPatterns: [TopPattern]

    /// Critical moments from all recordings (sorted by severity)
    let criticalMoments: [CriticalMoment]

    /// Actionable improvement suggestions
    let improvementSuggestions: [String]

    // MARK: - Score Trends

    /// Change in overall score vs yesterday
    let scoreChange24h: Double?

    /// Change in overall score vs 7 days ago
    let scoreChange7d: Double?

    // MARK: - OPTIONAL FEATURE: Trend Visualization
    /// Historical score progression for charts
    // var trendData: TrendData?

    // MARK: - OPTIONAL FEATURE: Gamification
    /// XP earned this day
    // var xpEarned: Int?
    // var achievementsUnlocked: [String]?
    // var streakContinued: Bool?

    // MARK: - OPTIONAL FEATURE: Success Guarantee Tracking
    /// Progress towards 90-day goals
    // var programProgress: ProgramProgress?

    // MARK: - Initialization

    init(
        id: UUID,
        reportDate: Date,
        generatedAt: Date,
        recordingsAnalyzed: Int,
        totalDuration: Double,
        overallScore: Double,
        powerDynamicsScore: Double,
        linguisticAuthorityScore: Double,
        vocalCommandScore: Double,
        persuasionInfluenceScore: Double,
        topPatterns: [TopPattern],
        criticalMoments: [CriticalMoment],
        improvementSuggestions: [String],
        scoreChange24h: Double? = nil,
        scoreChange7d: Double? = nil
    ) {
        self.id = id
        self.reportDate = reportDate
        self.generatedAt = generatedAt
        self.recordingsAnalyzed = recordingsAnalyzed
        self.totalDuration = totalDuration
        self.overallScore = overallScore
        self.powerDynamicsScore = powerDynamicsScore
        self.linguisticAuthorityScore = linguisticAuthorityScore
        self.vocalCommandScore = vocalCommandScore
        self.persuasionInfluenceScore = persuasionInfluenceScore
        self.topPatterns = topPatterns
        self.criticalMoments = criticalMoments
        self.improvementSuggestions = improvementSuggestions
        self.scoreChange24h = scoreChange24h
        self.scoreChange7d = scoreChange7d
    }

    // MARK: - Helper Methods

    /// Get all scores for charting
    var allScores: [(category: String, score: Double)] {
        [
            ("Power Dynamics", powerDynamicsScore),
            ("Linguistic Authority", linguisticAuthorityScore),
            ("Vocal Command", vocalCommandScore),
            ("Persuasion & Influence", persuasionInfluenceScore)
        ]
    }

    /// Formatted report date (e.g., "Oct 23, 2025")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: reportDate)
    }

    /// Formatted total duration (e.g., "1h 24m")
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Check if this represents good progress (score > 75)
    var isGoodProgress: Bool {
        overallScore >= 75.0
    }

    /// Check if score improved vs yesterday
    var improvedSinceYesterday: Bool {
        guard let change = scoreChange24h else { return false }
        return change > 0
    }

    /// Check if score improved vs last week
    var improvedSinceLastWeek: Bool {
        guard let change = scoreChange7d else { return false }
        return change > 0
    }

    /// Get improvement emoji indicator
    var improvementIndicator: String {
        if let change = scoreChange24h {
            if change > 2.0 {
                return "📈"
            } else if change < -2.0 {
                return "📉"
            } else {
                return "➡️"
            }
        }
        return "—"
    }

    /// Get top 3 patterns only for summary view
    var topThreePatterns: [TopPattern] {
        Array(topPatterns.prefix(3))
    }

    /// Get highest priority improvement suggestion
    var prioritySuggestion: String? {
        improvementSuggestions.first
    }

    /// Get weakest category
    var weakestCategory: String {
        let scores = allScores
        let weakest = scores.min(by: { $0.score < $1.score })
        return weakest?.category ?? "Unknown"
    }

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case id
        case reportDate = "report_date"
        case generatedAt = "generated_at"
        case recordingsAnalyzed = "recordings_analyzed"
        case totalDuration = "total_duration"
        case overallScore = "overall_score"
        case powerDynamicsScore = "power_dynamics_score"
        case linguisticAuthorityScore = "linguistic_authority_score"
        case vocalCommandScore = "vocal_command_score"
        case persuasionInfluenceScore = "persuasion_influence_score"
        case topPatterns = "top_patterns"
        case criticalMoments = "critical_moments"
        case improvementSuggestions = "improvement_suggestions"
        case scoreChange24h = "score_change_24h"
        case scoreChange7d = "score_change_7d"

        // OPTIONAL FEATURE: Uncomment when implementing
        // case trendData = "trend_data"
        // case xpEarned = "xp_earned"
        // case achievementsUnlocked = "achievements_unlocked"
        // case streakContinued = "streak_continued"
        // case programProgress = "program_progress"
    }
}

// MARK: - Nested Types

/// Top recurring pattern with recommendation
struct TopPattern: Identifiable, Codable, Hashable {
    var id: String { patternType }  // Use pattern type as ID

    let patternType: String  // e.g., "filler_words", "passive_voice"
    let category: String  // "power_dynamics", "linguistic_authority", etc.
    let occurrences: Int  // Total count across all recordings
    let impactScore: Double  // Negative impact on overall score
    let recommendation: String  // Actionable advice

    enum CodingKeys: String, CodingKey {
        case patternType = "pattern_type"
        case category
        case occurrences
        case impactScore = "impact_score"
        case recommendation
    }

    /// Human-readable pattern name
    var displayName: String {
        patternType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    /// Icon for pattern type
    var icon: String {
        switch patternType {
        case "filler_words": return "waveform.path.badge.minus"
        case "hedging": return "questionmark.circle"
        case "passive_voice": return "arrow.turn.up.left"
        case "pace_too_fast": return "hare"
        case "pace_too_slow": return "tortoise"
        default: return "exclamationmark.triangle"
        }
    }
}

// MARK: - OPTIONAL FEATURE: Trend Data Types

/*
/// Historical trend data for visualization
struct TrendData: Codable, Hashable {
    let dailyScores: [DailyScore]
    let patternEvolution: [String: [PatternDataPoint]]

    enum CodingKeys: String, CodingKey {
        case dailyScores = "daily_scores"
        case patternEvolution = "pattern_evolution"
    }
}

struct DailyScore: Codable, Hashable, Identifiable {
    var id: String { date }

    let date: String  // YYYY-MM-DD
    let overallScore: Double

    enum CodingKeys: String, CodingKey {
        case date
        case overallScore = "overall_score"
    }
}

struct PatternDataPoint: Codable, Hashable {
    let date: String
    let count: Int
}
*/

// MARK: - OPTIONAL FEATURE: Gamification Types

/*
/// Achievement unlocked during this day
struct Achievement: Codable, Hashable {
    let name: String
    let description: String
    let icon: String
    let xpValue: Int

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case icon
        case xpValue = "xp_value"
    }
}
*/

// MARK: - OPTIONAL FEATURE: Success Guarantee Types

/*
/// 90-day program progress tracking
struct ProgramProgress: Codable, Hashable {
    let dayNumber: Int  // 1-90
    let milestonesMet: [String]
    let onTrackForGuarantee: Bool
    let nextMilestone: String?

    enum CodingKeys: String, CodingKey {
        case dayNumber = "day_number"
        case milestonesMet = "milestones_met"
        case onTrackForGuarantee = "on_track_for_guarantee"
        case nextMilestone = "next_milestone"
    }
}
*/

// MARK: - Sample Data for Previews

extension Report {
    static var sample: Report {
        Report(
            id: UUID(),
            reportDate: Date(),
            generatedAt: Date(),
            recordingsAnalyzed: 5,
            totalDuration: 1247.5,
            overallScore: 75.2,
            powerDynamicsScore: 74.2,
            linguisticAuthorityScore: 70.5,
            vocalCommandScore: 79.8,
            persuasionInfluenceScore: 76.3,
            topPatterns: [
                .sampleFillerWords,
                .samplePassiveVoice,
                .sampleHedging
            ],
            criticalMoments: [
                .sample,
                .sampleHighSeverity
            ],
            improvementSuggestions: [
                "Focus on eliminating 'um' and 'like' from your speech",
                "Reduce hedging phrases by 50% this week",
                "Practice speaking 10% slower for better clarity"
            ],
            scoreChange24h: 3.5,
            scoreChange7d: 8.2
        )
    }
}

extension TopPattern {
    static var sampleFillerWords: TopPattern {
        TopPattern(
            patternType: "filler_words",
            category: "power_dynamics",
            occurrences: 42,
            impactScore: -5.5,
            recommendation: "Practice pausing instead of using filler words"
        )
    }

    static var samplePassiveVoice: TopPattern {
        TopPattern(
            patternType: "passive_voice",
            category: "linguistic_authority",
            occurrences: 18,
            impactScore: -3.2,
            recommendation: "Use active voice for stronger statements"
        )
    }

    static var sampleHedging: TopPattern {
        TopPattern(
            patternType: "hedging",
            category: "power_dynamics",
            occurrences: 15,
            impactScore: -4.0,
            recommendation: "Replace 'I think' and 'maybe' with definitive statements"
        )
    }
}

// MARK: - Local Caching

extension Report {
    /// Key for caching reports in UserDefaults
    private static func cacheKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "cached_report_\(formatter.string(from: date))"
    }

    /// Save this report to local cache
    func cache() {
        if let encoded = try? JSONEncoder().encode(self) {
            let key = Self.cacheKey(for: reportDate)
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    /// Load cached report for date
    static func loadCached(for date: Date) -> Report? {
        let key = cacheKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: key),
              let report = try? JSONDecoder().decode(Report.self, from: data) else {
            return nil
        }
        return report
    }

    /// Clear cached report for date
    static func clearCache(for date: Date) {
        let key = cacheKey(for: date)
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Clear all cached reports
    static func clearAllCaches() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        keys.filter { $0.hasPrefix("cached_report_") }.forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: When implementing daily reports view:
 1. Create score breakdown cards with trend indicators
 2. Build top patterns list with recommendations
 3. Display critical moments timeline
 4. Add improvement suggestions section
 5. Show historical comparison (24h, 7d)

 TODO: When implementing OPTIONAL FEATURE: Trend Visualization:
 1. Uncomment TrendData types
 2. Create line charts with Swift Charts
 3. Show 7-day and 30-day trend views
 4. Add pattern evolution over time graphs

 TODO: When implementing OPTIONAL FEATURE: Gamification:
 1. Uncomment gamification properties
 2. Display XP earned with animations
 3. Show achievement unlock celebrations
 4. Add streak indicator in report header

 TODO: When implementing OPTIONAL FEATURE: Success Guarantee:
 1. Uncomment ProgramProgress types
 2. Create milestone tracking view
 3. Show progress bar for 90-day program
 4. Display on-track status prominently

 TODO: Push notifications:
 1. Schedule daily notification for report availability
 2. Send reminder if no recordings today
 3. Celebrate improvements with push alerts
 4. Notify when new achievement unlocked

 TODO: Performance optimizations:
 1. Implement report caching strategy
 2. Prefetch next/previous day reports
 3. Lazy load critical moments and patterns
 4. Add background refresh for latest reports
 */
