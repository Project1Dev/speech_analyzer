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
        /// Backend API base URL
        ///
        /// **Dual-VM Development Setup:**
        /// This app is developed using a dual-VM workflow:
        /// - Linux VM: Backend (FastAPI, PostgreSQL, Docker)
        /// - macOS VM: iOS app (Xcode, Simulator)
        ///
        /// **Configuration Options:**
        ///
        /// 1. **Simulator on same machine as backend**:
        ///    ```swift
        ///    static let baseURL = "http://localhost:8000"
        ///    ```
        ///
        /// 2. **Simulator connecting to Linux VM backend** (RECOMMENDED for dual-VM setup):
        ///    ```swift
        ///    static let baseURL = "http://192.168.1.150:8000"  // Replace with Linux VM IP
        ///    ```
        ///    To find Linux VM IP, run on Linux VM:
        ///    ```bash
        ///    hostname -I
        ///    # or
        ///    ip addr show | grep "inet " | grep -v 127.0.0.1
        ///    # or use helper script
        ///    cd backend && ./show_api_url.sh
        ///    ```
        ///
        /// 3. **Physical iOS device**:
        ///    Same as option 2 - use Mac's or Linux VM's IP address
        ///
        /// **Troubleshooting:**
        /// - Ensure backend is running: `docker-compose ps` on Linux VM
        /// - Test connectivity: `curl http://<linux-vm-ip>:8000/health` from macOS VM
        /// - Check firewall: `sudo ufw allow 8000` on Linux VM
        /// - Verify both VMs are on same network (bridged mode)
        ///
        /// **Current Configuration:**
        static let baseURL = "http://localhost:8000"  // ← CHANGE THIS for dual-VM setup!

        /// Authentication token for single-user prototype mode
        static let authToken = "SINGLE_USER_DEV_TOKEN_12345"

        /// Request timeout in seconds
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
