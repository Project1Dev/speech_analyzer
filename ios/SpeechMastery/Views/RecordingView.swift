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
                    // TODO: Add navigation title
                    // TODO: Add permission status indicator

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
                // TODO: Add settings button
                // TODO: Add audio quality indicator
            }
            .alert("Permission Required", isPresented: $viewModel.showPermissionAlert) {
                // TODO: Permission request alert buttons
            } message: {
                // TODO: Permission explanation message
            }
            .alert("Cancel Recording?", isPresented: $showCancelAlert) {
                // TODO: Cancel confirmation buttons
            } message: {
                // TODO: Cancel warning message
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                // TODO: Error alert buttons
            } message: {
                // TODO: Error message display
            }
            .sheet(isPresented: $navigateToAnalysis) {
                // TODO: Navigate to AnalysisResultView with completed recording
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
                    // TODO: Show cancel confirmation
                    showCancelAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }

                // Pause/Resume button
                Button(action: {
                    // TODO: Toggle pause/resume
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

                // Stop button
                Button(action: {
                    // TODO: Stop recording
                    viewModel.stopRecording()
                    navigateToAnalysis = true
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
            } else {
                // Start recording button
                Button(action: {
                    // TODO: Start recording
                    Task {
                        await viewModel.requestPermission()
                        viewModel.startRecording()
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

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core UI implementation:
 1. Implement audio level meter with smooth animation
 2. Add recording indicator (red dot + pulsing)
 3. Style recording controls with proper sizing
 4. Implement cancel confirmation alert
 5. Add navigation to analysis view

 TODO: Permission handling:
 1. Show permission request UI on first launch
 2. Display permission status clearly
 3. Provide link to Settings for denied state
 4. Test on physical device

 TODO: Visual polish:
 1. Add waveform visualization option
 2. Implement pulsing animation for recording state
 3. Add smooth transitions between states
 4. Use haptic feedback for button taps
 5. Add accessibility labels

 TODO: Error handling:
 1. Display error messages in alert
 2. Provide recovery actions
 3. Show retry option for failed recordings
 4. Handle background interruptions

 TODO: Navigation:
 1. Navigate to analysis view after stop
 2. Pass completed recording to analysis view
 3. Handle back navigation properly
 4. Clear completed recording on dismiss

 TODO: When implementing OPTIONAL FEATURE: Live Guardian Mode:
 1. Uncomment live coaching overlay
 2. Display real-time feedback messages
 3. Show pattern detection alerts
 4. Add coaching message animations
 5. Provide toggle to enable/disable live mode
 6. Test performance impact
 */
