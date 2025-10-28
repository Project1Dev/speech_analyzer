//
//  PrivacyManager.swift
//  SpeechMastery
//
//  Manages privacy-related functionality including microphone permissions,
//  recording indicators, and user consent tracking.
//
//  Responsibilities:
//  - Request and monitor microphone permissions
//  - Display visual recording indicators
//  - Track user consent for data processing
//  - Provide privacy status for UI
//  - Enforce privacy-first principles
//
//  Integration Points:
//  - AudioRecordingService: Checks permissions before recording
//  - RecordingView: Shows permission prompts and indicators
//  - SettingsView: Displays privacy controls
//  - APIService: Checks upload consent before sending data
//
//  Privacy Features:
//  - Microphone permission with clear purpose string
//  - Visual recording indicator (red dot)
//  - Manual review before upload (no auto-upload)
//  - 7-day auto-deletion policy
//  - No data collection without consent
//
//  OPTIONAL FEATURE: Privacy Dashboard
//  - Detailed privacy audit log
//  - Data export functionality (GDPR compliance)
//  - Granular permission controls
//

import Foundation
import AVFoundation
import Combine
import UIKit

/// Service for managing app privacy and permissions
class PrivacyManager: ObservableObject {

    // MARK: - Published Properties

    /// Current microphone permission status
    @Published var microphonePermission: PermissionStatus = .notDetermined

    /// Whether recording is currently active (for visual indicator)
    @Published var isRecordingActive: Bool = false

    /// Whether user has consented to data upload
    @Published var hasUploadConsent: Bool = true  // Default to true for prototype

    /// Whether user has seen privacy onboarding
    @Published var hasSeenPrivacyOnboarding: Bool = false

    // MARK: - Private Properties

    /// UserDefaults keys
    private let uploadConsentKey = "privacy_upload_consent"
    private let privacyOnboardingKey = "privacy_onboarding_seen"

    /// UserDefaults instance
    private let userDefaults: UserDefaults

    // MARK: - OPTIONAL FEATURE: Privacy Dashboard
    /// Audit log of privacy-related events
    // @Published var privacyAuditLog: [PrivacyEvent] = []
    // private let auditLogKey = "privacy_audit_log"

    // MARK: - Singleton

    /// Shared instance for global access
    static let shared = PrivacyManager()

    // MARK: - Initialization

    /// Initialize with custom UserDefaults (useful for testing)
    /// - Parameter userDefaults: UserDefaults instance to use
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load privacy preferences from UserDefaults
        loadPrivacyPreferences()

        // Check initial microphone permission status
        _ = checkMicrophonePermission()
    }

    // MARK: - Microphone Permissions

    /// Check current microphone permission status
    /// - Returns: Current PermissionStatus
    func checkMicrophonePermission() -> PermissionStatus {
        let recordPermission = AVAudioSession.sharedInstance().recordPermission

        let status: PermissionStatus
        switch recordPermission {
        case .granted:
            status = .granted
        case .denied:
            status = .denied
        case .undetermined:
            status = .notDetermined
        @unknown default:
            status = .notDetermined
        }

        // Update published property on main thread
        DispatchQueue.main.async {
            self.microphonePermission = status
        }

        return status
    }

    /// Quick check if microphone permission is granted (for guards)
    /// - Returns: True if permission granted
    func hasMicrophonePermission() -> Bool {
        return checkMicrophonePermission() == .granted
    }

    /// Request microphone permission from user
    /// - Returns: True if granted, false if denied
    func requestMicrophonePermission() async -> Bool {
        // Check if already granted
        if hasMicrophonePermission() {
            return true
        }

        // Request permission using continuation
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                // Update status
                DispatchQueue.main.async {
                    _ = self.checkMicrophonePermission()
                }

                print(granted ? "✅ Microphone permission granted" : "❌ Microphone permission denied")

                continuation.resume(returning: granted)
            }
        }
    }

    /// Open Settings app to privacy page (if permission denied)
    func openPrivacySettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            print("📱 Opening app settings")
        }
    }

    // MARK: - Recording Indicators

    /// Show recording indicator (called when recording starts)
    func showRecordingIndicator() {
        DispatchQueue.main.async {
            self.isRecordingActive = true
        }
        print("🔴 Recording indicator shown")
    }

    /// Hide recording indicator (called when recording stops)
    func hideRecordingIndicator() {
        DispatchQueue.main.async {
            self.isRecordingActive = false
        }
        print("⚫ Recording indicator hidden")
    }

    // MARK: - Upload Consent

    /// Get upload consent status
    /// - Returns: True if user has consented to uploads
    func getUploadConsent() -> Bool {
        return hasUploadConsent
    }

    /// Set upload consent preference
    /// - Parameter consent: User's consent choice
    func setUploadConsent(_ consent: Bool) {
        hasUploadConsent = consent
        userDefaults.set(consent, forKey: uploadConsentKey)
        print("📝 Upload consent set to: \(consent)")
    }

    /// Show upload consent dialog before first upload
    /// - Returns: User's consent decision
    func requestUploadConsent() async -> Bool {
        // For prototype: Default to true
        // In production: Show actual consent dialog
        setUploadConsent(true)
        return true
    }

    // MARK: - Privacy Onboarding

    /// Check if user has seen privacy onboarding
    /// - Returns: True if onboarding completed
    func hasCompletedPrivacyOnboarding() -> Bool {
        return hasSeenPrivacyOnboarding
    }

    /// Mark privacy onboarding as completed
    func completePrivacyOnboarding() {
        hasSeenPrivacyOnboarding = true
        userDefaults.set(true, forKey: privacyOnboardingKey)
        print("✅ Privacy onboarding completed")
    }

    /// Show privacy onboarding flow
    func showPrivacyOnboarding() {
        // For prototype: Just mark as completed
        // In production: Show actual onboarding screens
        completePrivacyOnboarding()
    }

    // MARK: - Data Deletion

    /// Check if auto-deletion is enabled (always true for this app)
    /// - Returns: True (7-day deletion is mandatory)
    func isAutoDeletionEnabled() -> Bool {
        return true  // Always enabled, 7-day retention policy
    }

    /// Get auto-deletion period in days
    /// - Returns: 7 (fixed retention period)
    func getAutoDeletionPeriod() -> Int {
        return 7  // Fixed 7-day retention
    }

    // MARK: - Privacy Status

    /// Get comprehensive privacy status for UI display
    /// - Returns: PrivacyStatus with all privacy-related flags
    func getPrivacyStatus() -> PrivacyStatus {
        // TODO: Gather all privacy flags
        // TODO: Return PrivacyStatus struct
        return PrivacyStatus(
            microphoneGranted: microphonePermission == .granted,
            uploadConsentGranted: hasUploadConsent,
            onboardingCompleted: hasSeenPrivacyOnboarding,
            autoDeletionEnabled: true,
            autoDeletionDays: 7
        )
    }

    // MARK: - OPTIONAL FEATURE: Privacy Dashboard

    /// Log a privacy-related event to audit log
    // func logPrivacyEvent(type: PrivacyEventType, description: String) {
    //     TODO: Create PrivacyEvent with timestamp
    //     TODO: Append to privacyAuditLog
    //     TODO: Persist to UserDefaults
    //     TODO: Trim old events (keep last 100)
    // }

    /// Get all privacy audit events
    // func getAuditLog() -> [PrivacyEvent] {
    //     TODO: Return privacyAuditLog sorted by date
    // }

    /// Export user data for GDPR compliance
    // func exportUserData() async -> URL {
    //     TODO: Gather all user data (recordings, settings, preferences)
    //     TODO: Create JSON export file
    //     TODO: Return temporary file URL for sharing
    // }

    /// Delete all user data (GDPR right to deletion)
    // func deleteAllUserData() async throws {
    //     TODO: Delete all recordings and files
    //     TODO: Clear all UserDefaults
    //     TODO: Clear cache
    //     TODO: Log deletion event
    //     TODO: Reset app state
    // }

    // MARK: - Private Helper Methods

    /// Load privacy preferences from UserDefaults
    private func loadPrivacyPreferences() {
        hasUploadConsent = userDefaults.bool(forKey: uploadConsentKey)
        hasSeenPrivacyOnboarding = userDefaults.bool(forKey: privacyOnboardingKey)

        // If no value set, default to true for prototype
        if !userDefaults.objectIsForced(forKey: uploadConsentKey) {
            hasUploadConsent = true
        }

        print("📖 Privacy preferences loaded")
    }

    /// Persist privacy preferences to UserDefaults
    private func persistPrivacyPreferences() {
        userDefaults.set(hasUploadConsent, forKey: uploadConsentKey)
        userDefaults.set(hasSeenPrivacyOnboarding, forKey: privacyOnboardingKey)
        print("💾 Privacy preferences saved")
    }

    // MARK: - Supporting Types

    /// Microphone permission status
    enum PermissionStatus {
        case granted
        case denied
        case notDetermined
        case restricted  // Parental controls or MDM

        /// User-facing description
        var description: String {
            switch self {
            case .granted:
                return "Microphone access granted"
            case .denied:
                return "Microphone access denied"
            case .notDetermined:
                return "Microphone permission not requested"
            case .restricted:
                return "Microphone access restricted"
            }
        }

        /// Whether recording is allowed
        var canRecord: Bool {
            return self == .granted
        }
    }
}

// MARK: - Supporting Types

/// Comprehensive privacy status for UI display
struct PrivacyStatus {
    let microphoneGranted: Bool
    let uploadConsentGranted: Bool
    let onboardingCompleted: Bool
    let autoDeletionEnabled: Bool
    let autoDeletionDays: Int

    /// Whether all privacy requirements are met
    var isFullyConfigured: Bool {
        return microphoneGranted && onboardingCompleted
    }

    /// Privacy compliance percentage (0-100)
    var compliancePercentage: Int {
        var score = 0
        if microphoneGranted { score += 40 }
        if uploadConsentGranted { score += 20 }
        if onboardingCompleted { score += 20 }
        if autoDeletionEnabled { score += 20 }
        return score
    }
}

// MARK: - OPTIONAL FEATURE: Privacy Dashboard Types

/*
/// Privacy audit event types
enum PrivacyEventType: String, Codable {
    case permissionRequested = "permission_requested"
    case permissionGranted = "permission_granted"
    case permissionDenied = "permission_denied"
    case recordingStarted = "recording_started"
    case recordingStopped = "recording_stopped"
    case uploadConsentGranted = "upload_consent_granted"
    case uploadConsentRevoked = "upload_consent_revoked"
    case dataUploaded = "data_uploaded"
    case dataDeleted = "data_deleted"
    case dataExported = "data_exported"
}

/// Privacy audit event
struct PrivacyEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: PrivacyEventType
    let description: String

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case type
        case description
    }
}
*/

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core privacy implementation:
 1. Implement checkMicrophonePermission() with AVAudioSession
 2. Implement requestMicrophonePermission() with async/await
 3. Add recording indicator state management
 4. Implement upload consent dialog
 5. Test permission flows on device (not simulator)

 TODO: Privacy onboarding:
 1. Design onboarding screens explaining privacy practices
 2. Show examples of data usage and deletion
 3. Request permissions in context
 4. Implement skip option with limitations

 TODO: Settings integration:
 1. Add privacy section to SettingsView
 2. Show current permission status
 3. Provide link to system Settings
 4. Display auto-deletion status

 TODO: Info.plist configuration:
 1. Add NSMicrophoneUsageDescription key
 2. Write clear, user-friendly purpose string
 3. Explain why microphone access is needed

 TODO: Testing:
 1. Test permission request flow
 2. Test permission denial handling
 3. Test Settings deep-link
 4. Verify recording indicator appears/disappears
 5. Test consent persistence

 TODO: When implementing OPTIONAL FEATURE: Privacy Dashboard:
 1. Uncomment privacy audit types and methods
 2. Create audit log view in SettingsView
 3. Implement data export to JSON
 4. Add "Delete All Data" button with confirmation
 5. Test GDPR compliance (data export, deletion)

 TODO: Compliance and legal:
 1. Review privacy policy requirements
 2. Add privacy policy link in onboarding
 3. Consider GDPR, CCPA requirements
 4. Add data retention notice in UI
 */
