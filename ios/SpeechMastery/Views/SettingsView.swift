//
//  SettingsView.swift
//  SpeechMastery
//
//  App settings and preferences screen.
//  Displays configuration options, privacy controls, and app information.
//
//  Responsibilities:
//  - Manage audio quality settings
//  - Control privacy preferences
//  - Display storage statistics
//  - Manage cache and cleanup
//  - Show app information
//  - Provide data management options
//
//  Integration Points:
//  - SettingsViewModel: Observes all settings
//  - PrivacyManager: Privacy controls
//  - CacheService: Cache management
//  - AutoDeletionService: Cleanup stats
//
//  UI Components:
//  - Audio quality picker
//  - Privacy toggles
//  - Storage stats cards
//  - Cache management buttons
//  - App info section
//  - Clear data confirmation
//
//  OPTIONAL FEATURE: Premium Settings
//  - Premium tier display
//  - Feature toggles
//  - Subscription management
//

import SwiftUI

/// Settings and preferences view
struct SettingsView: View {
    // MARK: - State

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            List {
                // Audio Quality Section
                Section("Audio Quality") {
                    Picker("Quality", selection: $viewModel.audioQuality) {
                        Text("Compressed (64 kbps)").tag(AudioSettings.compressed)
                        Text("Standard (128 kbps)").tag(AudioSettings.standard)
                        Text("High (256 kbps)").tag(AudioSettings.high)
                        Text("Lossless WAV").tag(AudioSettings.wav)
                    }
                }

                // Privacy Section
                Section("Privacy & Safety") {
                    Toggle("Upload to Server", isOn: $viewModel.uploadConsentGranted)

                    Toggle("Wi-Fi Only Uploads", isOn: $viewModel.wiFiOnlyUploads)

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "lock.doc")
                            Text("View Privacy Policy")
                        }
                        .foregroundColor(.accentColor)
                    }
                }

                // Storage Section
                Section("Storage") {
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(viewModel.totalStorageUsed)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Recordings")
                        Spacer()
                        Text("\(viewModel.recordingsCount)")
                            .foregroundColor(.secondary)
                    }

                    Button(action: { viewModel.requestClearCache() }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Cache")
                        }
                        .foregroundColor(.orange)
                    }
                }

                // Auto-Delete Section
                Section("Auto-Delete") {
                    HStack {
                        Text("Recordings auto-delete after")
                        Spacer()
                        Text("7 days")
                            .foregroundColor(.secondary)
                    }

                    Text("All recordings are automatically deleted 7 days after creation for your privacy.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("Prototype")
                            .foregroundColor(.secondary)
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Visit Website")
                        }
                        .foregroundColor(.accentColor)
                    }
                }

                // Dangerous Zone
                Section("Data Management") {
                    Button(action: { viewModel.requestClearAllData() }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Clear All Data")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data?", isPresented: $viewModel.showClearDataConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelClearAllData()
                }
                Button("Clear", role: .destructive) {
                    viewModel.confirmClearAllData()
                }
            } message: {
                Text("This will permanently delete all recordings and data. This action cannot be undone.")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

// MARK: - COMPLETED Implementation
/*
 ✅ COMPLETED Core UI:
 ✅ Audio quality picker with options
 ✅ Privacy & safety controls
 ✅ Storage statistics display
 ✅ Auto-delete information
 ✅ About section with version info
 ✅ Cache management
 ✅ Clear all data with confirmation

 TODO: Enhancements:
 1. Add notification preferences
 2. Implement theme settings
 3. Add gesture customization
 4. Add language settings
 5. Implement app shortcuts
 */
