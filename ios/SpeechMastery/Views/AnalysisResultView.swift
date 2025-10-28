//
//  AnalysisResultView.swift
//  SpeechMastery
//
//  Analysis results display screen.
//  Shows scores, patterns, critical moments, and transcript.
//
//  Responsibilities:
//  - Display overall score and category breakdown
//  - Show critical moments timeline
//  - Display pattern analysis
//  - Show full transcript with highlighting
//  - Navigate through critical moments
//
//  Integration Points:
//  - AnalysisViewModel: Observes analysis result
//  - RecordingsListView: Navigate from library
//  - RecordingView: Navigate after recording
//
//  UI Components:
//  - Score cards with color coding
//  - Critical moments list
//  - Pattern breakdown cards
//  - Transcript viewer
//  - Navigation controls
//
//  OPTIONAL FEATURE: CEO Voice Synthesis
//  - Side-by-side comparison view
//  - Authority score improvements
//  - Text difference highlighting
//

import SwiftUI

/// Analysis results display view
struct AnalysisResultView: View {
    // MARK: - Parameters

    /// The recording being analyzed (may navigate directly with analysis result)
    let recording: Recording?

    /// Analysis result to display (optional for cases where we load it)
    var analysisResult: AnalysisResult?

    // MARK: - State

    @StateObject private var viewModel = AnalysisViewModel()
    @State private var selectedMomentIndex = 0
    @State private var showDetailedTranscript = false
    @State private var showCriticalMomentsOnly = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if let analysis = analysisResult {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Overall Score Card
                            overallScoreCard(analysis)

                            // Score Breakdown
                            scoreCardsSection(analysis)

                            // Critical Moments
                            if !analysis.criticalMoments.isEmpty {
                                criticalMomentsSection(analysis)
                            }

                            // Pattern Breakdown
                            patternDetailsSection(analysis)

                            // Transcript
                            transcriptSection(analysis)

                            Spacer(minLength: 24)
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        ProgressView("Loading analysis...")
                    }
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            // Load analysis if provided recording but no analysis
            if let recording = recording, analysisResult == nil {
                // In a real scenario, we would load from API
                // await viewModel.loadAnalysis(analysisID: recording.analysisID ?? UUID())
            }
        }
    }

    // MARK: - Overall Score Card

    private func overallScoreCard(_ analysis: AnalysisResult) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Overall Score")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("\(Int(analysis.overallScore))")
                    .font(.system(size: 72, weight: .bold, design: .default))
                    .foregroundColor(scoreColor(analysis.overallScore))

                Text(scoreDescription(analysis.overallScore))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Score range indicator
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            Double(i * 20) < analysis.overallScore
                            ? scoreColor(analysis.overallScore)
                            : Color.gray.opacity(0.3)
                        )
                        .frame(height: 6)
                }
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Score Cards Section

    private func scoreCardsSection(_ analysis: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)

            VStack(spacing: 12) {
                scoreCard(category: "Power Dynamics", score: analysis.powerDynamicsScore)
                scoreCard(category: "Linguistic Authority", score: analysis.linguisticAuthorityScore)
                scoreCard(category: "Vocal Command", score: analysis.vocalCommandScore)
                scoreCard(category: "Persuasion & Influence", score: analysis.persuasionInfluenceScore)
            }
        }
    }

    private func scoreCard(category: String, score: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(score))")
                    .font(.headline)
                    .foregroundColor(scoreColor(score))
            }

            // Score bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor(score))
                        .frame(width: geometry.size.width * CGFloat(score / 100.0))
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    // MARK: - Critical Moments Section

    private func criticalMomentsSection(_ analysis: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Critical Moments")
                    .font(.headline)

                Spacer()

                Toggle("High Only", isOn: $showCriticalMomentsOnly)
                    .font(.caption)
            }

            let moments = showCriticalMomentsOnly ? analysis.highSeverityMoments : analysis.criticalMoments

            if moments.isEmpty {
                Text("No critical moments detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: moment.severityIcon)
                                    .font(.body)
                                    .foregroundColor(severityColor(moment.severity))
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(moment.issue)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Spacer()

                                        Text(moment.formattedTimestamp)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Original:")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)

                                        Text("\"\(moment.quote)\"")
                                            .font(.caption)
                                            .italic()
                                            .foregroundColor(.primary)

                                        Text("Better:")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)

                                        Text("\"\(moment.suggestion)\"")
                                            .font(.caption)
                                            .italic()
                                            .foregroundColor(.accentColor)
                                    }
                                }

                                Spacer()
                            }

                            if index < moments.count - 1 {
                                Divider()
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(12)
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Pattern Details Section

    private func patternDetailsSection(_ analysis: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speech Patterns")
                .font(.headline)

            VStack(spacing: 12) {
                // Filler Words
                patternCard(
                    title: "Filler Words",
                    count: analysis.patterns.fillerWords.count,
                    detail: String(format: "%.1f per minute", analysis.patterns.fillerWords.perMinute),
                    breakdown: analysis.patterns.fillerWords.words
                )

                // Hedging Phrases
                patternCard(
                    title: "Hedging Phrases",
                    count: analysis.patterns.hedging.count,
                    detail: "Uncertainty indicators",
                    breakdown: analysis.patterns.hedging.phrases
                )

                // Vocal Patterns
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vocal Patterns")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 16) {
                        metricPill(
                            label: "Words/Min",
                            value: String(format: "%.0f", analysis.patterns.wordsPerMinute)
                        )

                        metricPill(
                            label: "Avg Pause",
                            value: String(format: "%.1fs", analysis.patterns.averagePauseDuration ?? 0)
                        )

                        metricPill(
                            label: "Upspeak",
                            value: "\(analysis.patterns.upspeakIndicators)"
                        )
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
    }

    private func patternCard(
        title: String,
        count: Int,
        detail: String,
        breakdown: [String: Int]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }

            // Top 3 items
            if !breakdown.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(
                        breakdown.sorted { $0.value > $1.value }.prefix(3),
                        id: \.key
                    ) { item, count in
                        HStack {
                            Text(item)
                                .font(.caption)

                            Spacer()

                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private func metricPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(.accentColor)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }

    // MARK: - Transcript Section

    private func transcriptSection(_ analysis: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcript")
                    .font(.headline)

                Spacer()

                Text("\(analysis.wordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(analysis.transcript)
                    .font(.body)
                    .lineSpacing(4)

                if analysis.transcript.count > 200 {
                    Button(action: { showDetailedTranscript = true }) {
                        HStack {
                            Text("View Full Transcript")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
    }

    // MARK: - Helper Functions

    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }

    private func scoreDescription(_ score: Double) -> String {
        if score >= 85 {
            return "Excellent"
        } else if score >= 75 {
            return "Good"
        } else if score >= 60 {
            return "Fair"
        } else {
            return "Needs Improvement"
        }
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "high": return .red
        case "medium": return .orange
        case "low": return .yellow
        default: return .gray
        }
    }
}

struct AnalysisResultView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisResultView(
            recording: Recording.sample,
            analysisResult: AnalysisResult.sample
        )
    }
}

// MARK: - COMPLETED Implementation
/*
 ✅ COMPLETED Core UI implementation:
 ✅ Display overall score card with visual progress
 ✅ Show category scores with color coding
 ✅ Display critical moments with severity indicators
 ✅ Show pattern breakdown with top items
 ✅ Display transcript excerpt with word count
 ✅ Show vocal patterns metrics
 ✅ Add navigation and expandable sections

 ✅ COMPLETED Visualizations:
 ✅ Score progress bar for overall score
 ✅ Category score bars with color coding
 ✅ Pattern breakdown cards
 ✅ Severity icons for critical moments

 TODO: Enhancements:
 1. Add full transcript view modal
 2. Implement waveform visualization with critical moment markers
 3. Add charts for score comparison
 4. Highlight critical moments in transcript
 5. Add share/export functionality
 6. Add playback with moment navigation

 TODO: When implementing OPTIONAL FEATURE: CEO Voice Synthesis:
 1. Add side-by-side comparison toggle
 2. Show authority score improvements
 3. Highlight text differences
 4. Play audio comparisons
 */
