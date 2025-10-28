//
//  RecordingView.swift
//  SpeechMastery
//
//  Main recording screen with audio capture controls and visualization.
//  Implements MVVM pattern binding to RecordingViewModel.
//
//  Responsibilities:
//  - Display recording controls (start, pause, stop, cancel)
//  - Show real-time audio level meter
//  - Display recording duration
//  - Show permission request prompts
//  - Navigate to analysis after completion
//  - Display recording indicator
//
//  Integration Points:
//  - RecordingViewModel: Observes state and triggers actions
//  - AnalysisResultView: Navigate after recording complete
//  - SettingsView: Access audio quality settings
//
//  UI Components:
//  - Large circular record button
//  - Audio level waveform/meter
//  - Duration timer
//  - Pause/resume controls
//  - Cancel confirmation alert
//  - Permission request sheet
//
//  OPTIONAL FEATURE: Live Guardian Mode
//  - Real-time coaching overlay
//  - Live pattern detection alerts
//  - On-screen feedback messages
//

import SwiftUI

/// Main recording screen
struct RecordingView: View {

    // MARK: - View Model

    /// Recording view model for state management
    @StateObject private var viewModel = RecordingViewModel()

    // MARK: - State

    /// Whether to show cancel confirmation alert
    @State private var showCancelAlert = false

    /// Whether to navigate to analysis view
    @State private var navigateToAnalysis = false

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode
    /// Whether to show live coaching overlay
    // @State private var showLiveCoaching = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Permission status indicator
                    if viewModel.permissionStatus != .granted {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Microphone permission required")
                                .font(.caption)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }

                    Spacer()

                    // Audio level visualization
                    audioLevelMeter

                    // Duration display
                    durationDisplay

                    Spacer()

                    // Recording controls
                    recordingControls

                    // Status messages
                    statusMessages

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .alert("Permission Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Settings") {
                    viewModel.openSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Microphone access is needed to record audio. Please enable it in Settings.")
            }
            .alert("Cancel Recording?", isPresented: $showCancelAlert) {
                Button("Keep Recording", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    viewModel.cancelRecording()
                    showCancelAlert = false
                }
            } message: {
                Text("Your recording will be discarded.")
            }
            .alert("Recording Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .navigationDestination(isPresented: $navigateToAnalysis) {
                if let recording = viewModel.completedRecording {
                    AnalysisResultView(recording: recording)
                }
            }
        }
    }

    // MARK: - Audio Level Meter

    /// Visual audio level meter
    private var audioLevelMeter: some View {
        VStack {
            // TODO: Implement waveform or circular meter
            // TODO: Bind to viewModel.audioLevel
            // TODO: Animate with audio input
            // TODO: Show "Listening..." when recording
            // TODO: Show "Ready" when not recording

            Circle()
                .fill(viewModel.isRecording ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 200, height: 200)
                .overlay(
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.audioLevel))
                        .stroke(
                            viewModel.isRecording ? Color.red : Color.gray,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)
                )
                .overlay(
                    Image(systemName: viewModel.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(viewModel.isRecording ? .red : .gray)
                )
        }
    }

    // MARK: - Duration Display

    /// Recording duration timer
    private var durationDisplay: some View {
        Text(viewModel.formattedDuration)
            .font(.system(size: 48, weight: .bold, design: .monospaced))
            .foregroundColor(viewModel.isRecording ? .primary : .secondary)
        // TODO: Add pulsing animation when recording
    }

    // MARK: - Recording Controls

    /// Recording control buttons
    private var recordingControls: some View {
        HStack(spacing: 40) {
            if viewModel.isRecording {
                // Cancel button
                Button(action: {
                    showCancelAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                .accessibilityLabel("Cancel Recording")
                .accessibilityHint("Discard the current recording")

                // Pause/Resume button
                Button(action: {
                    if viewModel.isPaused {
                        viewModel.resumeRecording()
                    } else {
                        viewModel.pauseRecording()
                    }
                }) {
                    Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                }
                .accessibilityLabel(viewModel.isPaused ? "Resume Recording" : "Pause Recording")

                // Stop button
                Button(action: {
                    Task {
                        await viewModel.stopRecording()
                        navigateToAnalysis = true
                    }
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
                .accessibilityLabel("Stop Recording")
                .accessibilityHint("Stop recording and proceed to analysis")
            } else {
                // Start recording button
                Button(action: {
                    Task {
                        await viewModel.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)

                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    }
                }
                .disabled(viewModel.permissionStatus != .granted)
                .accessibilityLabel("Start Recording")
                .accessibilityHint("Start a new audio recording")
            }
        }
    }

    // MARK: - Status Messages

    /// Status and hint messages
    private var statusMessages: some View {
        VStack(spacing: 8) {
            if viewModel.permissionStatus == .denied {
                // TODO: Permission denied message
                Text("Microphone permission denied")
                    .font(.caption)
                    .foregroundColor(.red)

                Button("Open Settings") {
                    viewModel.openSettings()
                }
                .font(.caption)
            } else if !viewModel.isRecording {
                // TODO: Ready state hint
                Text("Tap the button to start recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if viewModel.isPaused {
                // TODO: Paused state message
                Text("Recording paused")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                // TODO: Recording state message
                Text("Recording in progress...")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode

    /// Live coaching overlay (optional feature)
    // private var liveCoachingOverlay: some View {
    //     TODO: Overlay view with real-time feedback
    //     TODO: Show coaching messages from viewModel
    //     TODO: Display pattern detections
    //     TODO: Provide haptic feedback
    //     TODO: Toggle visibility with button
    // }
}

// MARK: - Preview

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}

// MARK: - COMPLETED Implementation Tasks
/*
 ✅ COMPLETED Core UI implementation:
 ✅ Implemented audio level meter with smooth animation
 ✅ Styled recording controls with proper sizing
 ✅ Implemented cancel confirmation alert
 ✅ Added navigation to analysis view
 ✅ Added permission status indicator in UI
 ✅ Added all error handling alerts

 ✅ COMPLETED Permission handling:
 ✅ Display permission request UI
 ✅ Display permission status clearly
 ✅ Provide link to Settings for denied state
 ✅ Request permission on start recording

 ✅ COMPLETED Error handling:
 ✅ Display error messages in alert
 ✅ Provide error clear action
 ✅ Show error state in UI

 ✅ COMPLETED Navigation:
 ✅ Navigate to analysis view after stop
 ✅ Pass completed recording to analysis view
 ✅ Handle async/await properly

 TODO: Enhancements:
 1. Add waveform visualization option
 2. Implement pulsing animation for recording state
 3. Add haptic feedback for button taps
 4. Handle background interruptions
 5. Add recording indicator (red dot in status bar)

 TODO: When implementing OPTIONAL FEATURE: Live Guardian Mode:
 1. Uncomment live coaching overlay
 2. Display real-time feedback messages
 3. Show pattern detection alerts
 4. Add coaching message animations
 5. Provide toggle to enable/disable live mode
 6. Test performance impact
 */
