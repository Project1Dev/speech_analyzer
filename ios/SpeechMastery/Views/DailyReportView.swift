//
//  DailyReportView.swift
//  SpeechMastery
//
//  Daily report display screen.
//  Shows aggregated scores, patterns, and improvements for a specific date.
//
//  Responsibilities:
//  - Display daily aggregate scores
//  - Show top recurring patterns
//  - Display critical moments from all recordings
//  - Provide improvement suggestions
//  - Navigate between dates
//
//  Integration Points:
//  - ReportViewModel: Observes current report
//  - Date picker for navigation
//
//  UI Components:
//  - Date selector with prev/next
//  - Overall score card
//  - Category scores breakdown
//  - Top patterns list
//  - Improvement suggestions
//  - Critical moments timeline
//
//  OPTIONAL FEATURE: Trend Visualization
//  - 7-day and 30-day trend charts
//  - Pattern evolution graphs
//  - Score progression visualization
//

import SwiftUI

/// Daily report display view
struct DailyReportView: View {
    // MARK: - State

    @State private var selectedDate = Date()
    @StateObject private var viewModel = ReportViewModel()

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Date Navigation
                        dateNavigationSection

                        // No data state
                        if !viewModel.hasDataForDate(selectedDate) {
                            emptyStateView
                        } else {
                            // Overall Score
                            overallScoreCard

                            // Category Breakdown
                            categoryBreakdown

                            // Top Patterns
                            topPatternsSection

                            // Improvement Suggestions
                            suggestionsSection

                            Spacer(minLength: 24)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Daily Report")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadReportForDate(selectedDate)
            }
            .onChange(of: selectedDate) { newDate in
                Task {
                    await viewModel.loadReportForDate(newDate)
                }
            }
        }
    }

    // MARK: - Date Navigation

    private var dateNavigationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)! }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(selectedDate, style: .date)
                        .font(.headline)
                        .fontWeight(.bold)

                    if Calendar.current.isDateInToday(selectedDate) {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)! }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
                .disabled(Calendar.current.isDateInToday(Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!))
            }

            // Quick date buttons
            HStack(spacing: 8) {
                QuickDateButton(label: "Today", action: { selectedDate = Date() })
                QuickDateButton(label: "Yesterday", action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())! })
                QuickDateButton(label: "Last 7 Days", action: { selectedDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())! })
            }
        }
    }

    // MARK: - Overall Score Card

    private var overallScoreCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Daily Average")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("\(Int(viewModel.dailyAverageScore))")
                    .font(.system(size: 60, weight: .bold, design: .default))
                    .foregroundColor(scoreColor(viewModel.dailyAverageScore))

                Text("\(viewModel.recordingsCount) recordings analyzed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Scores")
                .font(.headline)

            VStack(spacing: 12) {
                scoreBar(category: "Power Dynamics", score: viewModel.categoryAverages["power_dynamics"] ?? 0)
                scoreBar(category: "Linguistic Authority", score: viewModel.categoryAverages["linguistic_authority"] ?? 0)
                scoreBar(category: "Vocal Command", score: viewModel.categoryAverages["vocal_command"] ?? 0)
                scoreBar(category: "Persuasion & Influence", score: viewModel.categoryAverages["persuasion"] ?? 0)
            }
        }
    }

    private func scoreBar(category: String, score: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(score))")
                    .font(.subheadline)
                    .foregroundColor(scoreColor(score))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor(score))
                        .frame(width: geometry.size.width * CGFloat(score / 100.0))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Top Patterns

    private var topPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Patterns")
                .font(.headline)

            if viewModel.topPatterns.isEmpty {
                Text("No pattern data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.topPatterns.prefix(5)), id: \.key) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.key)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("Detected \(item.value) times")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("\(item.value)")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Improvement Focus")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(viewModel.suggestions.prefix(3), id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Data Available")
                .font(.headline)

            Text("Record and analyze speeches on this date to see your report")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Quick Date Button

struct QuickDateButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
        }
    }
}

// MARK: - Preview

struct DailyReportView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReportView()
    }
}

// MARK: - COMPLETED Implementation
/*
 ✅ COMPLETED Core UI:
 ✅ Date navigation with prev/next buttons
 ✅ Quick date selection buttons (Today, Yesterday, etc.)
 ✅ Overall daily average score display
 ✅ Category breakdown with score bars
 ✅ Top patterns list
 ✅ Improvement suggestions
 ✅ Empty state handling

 TODO: Enhancements:
 1. Add date range selection (week/month views)
 2. Implement trend charts
 3. Add historical comparison
 4. Export daily report as PDF
 5. Share report functionality
 6. Performance optimization for large datasets
 */
