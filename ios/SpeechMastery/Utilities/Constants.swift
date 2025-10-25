//
//  Constants.swift
//  SpeechMastery
//
//  App-wide constants and configuration values.
//
//  Responsibilities:
//  - Define API endpoints
//  - Define app-wide constants
//  - Configure feature flags
//  - Store magic numbers and limits
//

import Foundation

/// App-wide constants
enum Constants {
    // MARK: - API Configuration
    enum API {
        static let baseURL = "http://localhost:8000"
        static let authToken = "dev-prototype-token-12345"
        static let timeout: TimeInterval = 30.0
    }

    // MARK: - Recording Limits
    enum Recording {
        static let maxDurationSeconds: Double = 600.0  // 10 minutes
        static let minDurationSeconds: Double = 5.0    // 5 seconds
    }

    // MARK: - Storage
    enum Storage {
        static let retentionDays = 7
        static let maxCacheSizeBytes: Int64 = 100 * 1024 * 1024  // 100MB
    }

    // MARK: - OPTIONAL FEATURE FLAGS
    // Uncomment to enable optional features
    // static let enableCEOVoice = false
    // static let enableLiveGuardian = false
    // static let enableSimulation = false
    // static let enableGamification = false
}
