//
//  ContentView.swift
//  SpeechMastery
//
//  Main app container with tab-based navigation.
//  Root view of the app containing all main screens.
//
//  Responsibilities:
//  - Provide tab bar navigation
//  - Manage global app state
//  - Handle deep linking
//  - Show onboarding on first launch
//
//  Integration Points:
//  - RecordingView: Main recording tab
//  - RecordingsListView: Library tab
//  - DailyReportView: Reports tab
//  - SettingsView: Settings tab
//
//  Navigation Structure:
//  - Tab 1: Record (RecordingView)
//  - Tab 2: Library (RecordingsListView)
//  - Tab 3: Reports (DailyReportView)
//  - Tab 4: Settings (SettingsView)
//
//  OPTIONAL FEATURE: Premium Tabs
//  - Simulation Arena tab
//  - Training tab
//  - Arsenal tab
//

import SwiftUI

/// Main app container with tab navigation
struct ContentView: View {

    // MARK: - State

    /// Selected tab index
    @State private var selectedTab = 0

    /// Whether to show onboarding
    @State private var showOnboarding = false

    /// Privacy manager for onboarding check
    @StateObject private var privacyManager = PrivacyManager.shared

    // MARK: - OPTIONAL FEATURE: Premium Tabs
    /// Whether to show premium tabs
    // @AppStorage("show_premium_tabs") private var showPremiumTabs = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Record Tab
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
                .tag(0)

            // Library Tab
            RecordingsListView()
                .tabItem {
                    Label("Library", systemImage: "folder.fill")
                }
                .tag(1)

            // Reports Tab
            DailyReportView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(2)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)

            // OPTIONAL FEATURE: Premium tabs (commented out)
            // SimulationArenaView()
            //     .tabItem {
            //         Label("Arena", systemImage: "person.2.fill")
            //     }
            //     .tag(4)

            // TrainingView()
            //     .tabItem {
            //         Label("Training", systemImage: "figure.walk")
            //     }
            //     .tag(5)
        }
        .accentColor(.red)  // Tab bar tint color
        .sheet(isPresented: $showOnboarding) {
            // TODO: Onboarding flow
            privacyOnboardingView
        }
        .onAppear {
            // TODO: Check if should show onboarding
            checkOnboarding()
        }
    }

    // MARK: - Privacy Onboarding

    /// Privacy onboarding view
    private var privacyOnboardingView: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // App icon/logo
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.red)

                Text("Welcome to Speech Mastery")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Your privacy-first speech coaching app")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    // Privacy points
                    privacyPoint(icon: "lock.fill", text: "All recordings stored locally")
                    privacyPoint(icon: "trash.fill", text: "Auto-delete after 7 days")
                    privacyPoint(icon: "hand.raised.fill", text: "No upload without your consent")
                }
                .padding(.horizontal, 40)

                Spacer()

                Button(action: {
                    // TODO: Complete onboarding
                    privacyManager.completePrivacyOnboarding()
                    showOnboarding = false
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    /// Privacy point row
    /// - Parameters:
    ///   - icon: SF Symbol name
    ///   - text: Description text
    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 30)

            Text(text)
                .font(.body)

            Spacer()
        }
    }

    // MARK: - Onboarding Check

    /// Check if should show onboarding
    private func checkOnboarding() {
        // TODO: Check if user has completed onboarding
        // TODO: Show onboarding if not completed
        if !privacyManager.hasCompletedPrivacyOnboarding() {
            showOnboarding = true
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core navigation:
 1. Implement tab bar with all screens
 2. Handle tab selection state
 3. Preserve navigation state per tab
 4. Support deep linking to tabs

 TODO: Onboarding:
 1. Design onboarding flow (2-3 screens)
 2. Explain app features and privacy
 3. Request microphone permission
 4. Request upload consent
 5. Mark onboarding as completed

 TODO: Deep linking:
 1. Support URL schemes
 2. Handle notifications tapping
 3. Navigate to specific screens from links
 4. Handle universal links

 TODO: Global state:
 1. Manage app-level state
 2. Handle app lifecycle events
 3. Support background modes
 4. Handle interruptions

 TODO: When implementing OPTIONAL FEATURE: Premium Tabs:
 1. Uncomment premium tab views
 2. Check premium tier before showing
 3. Show upgrade prompt for locked tabs
 4. Persist tab visibility preference
 5. Dynamically add/remove tabs based on subscription
 */
