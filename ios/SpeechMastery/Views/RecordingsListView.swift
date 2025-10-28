//
//  RecordingsListView.swift
//  SpeechMastery
//
//  Library view displaying all recordings with filtering and sorting.
//  Implements MVVM pattern binding to RecordingsListViewModel.
//
//  Responsibilities:
//  - Display list of all recordings
//  - Support filtering (all, pending upload, analyzed)
//  - Support sorting (date, duration, score)
//  - Show recording details (duration, status, score)
//  - Navigate to analysis view
//  - Handle swipe-to-delete
//  - Show storage statistics
//
//  Integration Points:
//  - RecordingsListViewModel: Observes recordings array
//  - AnalysisResultView: Navigate to view analysis
//  - RecordingView: Navigate to record new
//
//  UI Components:
//  - Searchable list with recordings
//  - Filter chips (all, pending, analyzed)
//  - Sort menu
//  - Storage stats card
//  - Empty state view
//  - Pull-to-refresh
//
//  OPTIONAL FEATURE: Cloud Sync
//  - Sync status indicators
//  - Conflict resolution UI
//  - iCloud badge on synced items
//

import SwiftUI

/// Library view for all recordings
struct RecordingsListView: View {

    // MARK: - View Model

    /// Recordings list view model
    @StateObject private var viewModel = RecordingsListViewModel()

    // MARK: - State

    /// Search query text
    @State private var searchText = ""

    /// Whether to show filter menu
    @State private var showFilterMenu = false

    /// Whether to show sort menu
    @State private var showSortMenu = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    // TODO: Loading state
                    ProgressView("Loading recordings...")
                } else if viewModel.recordings.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Recordings list
                    recordingsList
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // TODO: Add filter button
                // TODO: Add sort button
                // TODO: Add sync button
            }
            .searchable(text: $searchText, prompt: "Search recordings")
            .onChange(of: searchText) { newValue in
                // TODO: Search recordings by query
                viewModel.searchRecordings(query: newValue)
            }
            .refreshable {
                // TODO: Pull-to-refresh
                await viewModel.refreshRecordings()
            }
            .alert("Delete Recording?", isPresented: $viewModel.showDeleteConfirmation) {
                // TODO: Delete confirmation buttons
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                Text("This recording will be permanently deleted.")
            }
            .sheet(isPresented: $showFilterMenu) {
                // TODO: Filter menu sheet
                filterMenuView
            }
            .sheet(isPresented: $showSortMenu) {
                // TODO: Sort menu sheet
                sortMenuView
            }
            .onAppear {
                // TODO: Load recordings on appear
                viewModel.loadRecordings()
            }
        }
    }

    // MARK: - Recordings List

    /// List of recordings
    private var recordingsList: some View {
        List {
            // Storage statistics section
            Section {
                storageStatsCard
            }

            // Filter chips
            Section {
                filterChips
            }

            // Recordings
            Section {
                ForEach(viewModel.recordings) { recording in
                    // TODO: Recording row with navigation
                    recordingRow(recording)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Delete button
                            Button(role: .destructive) {
                                viewModel.requestDelete(recording)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text("\(viewModel.recordings.count) recordings")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Recording Row

    /// Individual recording row
    /// - Parameter recording: Recording to display
    private func recordingRow(_ recording: Recording) -> some View {
        NavigationLink(destination: recordingDetailView(recording)) {
            HStack {
                // Icon with status
                VStack(spacing: 4) {
                    Image(systemName: recording.analyzed ? "checkmark.circle.fill" : "clock.fill")
                        .foregroundColor(recording.analyzed ? .green : .orange)
                        .font(.title2)

                    if !recording.uploaded {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    // Date
                    Text(recording.recordedAt, style: .date)
                        .font(.headline)

                    HStack(spacing: 12) {
                        // Duration
                        Label(recording.formattedDuration, systemImage: "clock")
                        // File size
                        Label(recording.formattedFileSize, systemImage: "doc")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Score (if analyzed)
                if recording.analyzed, let score = recording.analysisResult?.overallScore {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(score))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(score))

                        Text("Score")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if !recording.analyzed {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "arrow.right.circle")
                            .font(.title2)
                            .foregroundColor(.accentColor)

                        Text("Analyze")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Determine view to navigate to based on recording status
    @ViewBuilder
    private func recordingDetailView(_ recording: Recording) -> some View {
        if recording.analyzed, let analysis = recording.analysisResult {
            // Show analysis result
            AnalysisResultView(
                recording: recording,
                analysisResult: analysis
            )
        } else {
            // Show upload/analysis view
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        VStack(spacing: 8) {
                            Text("Ready to Analyze")
                                .font(.headline)

                            Text("This recording hasn't been analyzed yet. Tap the button below to upload and analyze.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()

                    Button(action: {
                        // TODO: Upload for analysis
                    }) {
                        HStack {
                            Image(systemName: "cloud.and.arrow.up")
                            Text("Upload for Analysis")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Recording")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Get score color
    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }

    // MARK: - Storage Stats Card

    /// Storage statistics card
    private var storageStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage")
                .font(.headline)

            HStack(spacing: 20) {
                // Total size
                VStack(alignment: .leading) {
                    Text(viewModel.totalStorageUsed)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Pending upload
                VStack(alignment: .leading) {
                    Text("\(viewModel.pendingUploadCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Analyzed
                VStack(alignment: .leading) {
                    Text("\(viewModel.analyzedCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Analyzed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Filter Chips

    /// Filter chips for quick filtering
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RecordingsListViewModel.FilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.filterType == filter,
                        action: {
                            viewModel.applyFilter(filter)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Filter Menu

    /// Filter menu sheet
    private var filterMenuView: some View {
        NavigationView {
            List {
                ForEach(RecordingsListViewModel.FilterType.allCases, id: \.self) { filter in
                    Button(action: {
                        viewModel.applyFilter(filter)
                        showFilterMenu = false
                    }) {
                        HStack {
                            Text(filter.rawValue)
                            Spacer()
                            if viewModel.filterType == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilterMenu = false
                    }
                }
            }
        }
    }

    // MARK: - Sort Menu

    /// Sort menu sheet
    private var sortMenuView: some View {
        NavigationView {
            List {
                ForEach(RecordingsListViewModel.SortOrder.allCases, id: \.self) { order in
                    Button(action: {
                        viewModel.applySortOrder(order)
                        showSortMenu = false
                    }) {
                        HStack {
                            Text(order.rawValue)
                            Spacer()
                            if viewModel.sortOrder == order {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showSortMenu = false
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    /// Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No Recordings Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Tap the Record tab to create your first recording")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Filter Chip Component

/// Filter chip button
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Preview

struct RecordingsListView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsListView()
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core UI implementation:
 1. Implement recording row layout with all metadata
 2. Add swipe-to-delete gesture
 3. Implement pull-to-refresh
 4. Add search functionality
 5. Style list and sections

 TODO: Filtering and sorting:
 1. Implement filter chips with selection state
 2. Create filter menu sheet
 3. Create sort menu sheet
 4. Persist filter/sort preferences
 5. Update list when filter/sort changes

 TODO: Navigation:
 1. Navigate to analysis view for analyzed recordings
 2. Navigate to upload view for unanalyzed recordings
 3. Handle back navigation properly
 4. Support deep linking to specific recording

 TODO: Storage statistics:
 1. Display storage stats card
 2. Update stats after deletions
 3. Show warnings for low storage
 4. Link to settings for cache management

 TODO: Empty state:
 1. Show meaningful empty state
 2. Provide call-to-action to record
 3. Handle filtered empty states differently
 4. Add illustration or animation

 TODO: Performance:
 1. Optimize for large lists (100+ recordings)
 2. Implement lazy loading if needed
 3. Cache row heights
 4. Profile with Instruments

 TODO: Accessibility:
 1. Add accessibility labels
 2. Support VoiceOver
 3. Test with Dynamic Type
 4. Add accessibility hints

 TODO: When implementing OPTIONAL FEATURE: Cloud Sync:
 1. Add sync status indicators to rows
 2. Show syncing progress bar
 3. Display iCloud badge on synced items
 4. Build conflict resolution UI
 5. Handle sync errors gracefully
 */
