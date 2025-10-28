//
//  APIService.swift
//  SpeechMastery
//
//  Centralized HTTP client for all backend API communication.
//  Handles authentication, multipart uploads, JSON encoding/decoding, and error handling.
//
//  Responsibilities:
//  - Manage base URL configuration
//  - Handle authentication headers (hardcoded token for prototype)
//  - Upload audio files with multipart/form-data
//  - Fetch analysis results and reports
//  - Parse JSON responses into Swift models
//  - Provide typed error handling
//
//  Integration Points:
//  - AnalysisViewModel: Uploads recordings and fetches results
//  - ReportViewModel: Fetches daily reports
//  - RecordingsListViewModel: Syncs recording metadata
//  - NetworkMonitor: Checks connectivity before requests
//
//  API Endpoints (see docs/API_CONTRACT.md):
//  - POST /analyze - Upload audio for analysis
//  - GET /analysis/{id} - Fetch analysis result
//  - GET /reports/{date} - Fetch daily report
//  - GET /recordings - List all recordings
//  - DELETE /recordings/{id} - Delete recording
//
//  OPTIONAL FEATURE: Premium Endpoints
//  - POST /premium/ceo-voice/compare - CEO Voice Synthesis
//  - POST /premium/live-guardian/stream - Live Guardian Mode
//  - POST /premium/simulation/start - Simulation Arena
//  - GET /premium/gamification/progress - Gamification stats
//

import Foundation
import Combine

/// HTTP client for backend API communication
class APIService: ObservableObject {

    // MARK: - Configuration

    /// Base URL for API endpoints
    private let baseURL: URL

    /// Authentication token (hardcoded for single-user prototype)
    private let authToken: String = "SINGLE_USER_DEV_TOKEN_12345"

    /// URLSession for network requests
    private let session: URLSession

    /// JSON decoder configured for snake_case keys
    private let jsonDecoder: JSONDecoder

    /// JSON encoder configured for snake_case keys
    private let jsonEncoder: JSONEncoder

    /// Network monitor for connectivity checks
    private let networkMonitor: NetworkMonitor

    // MARK: - Singleton

    /// Shared instance for global access
    static let shared = APIService()

    // MARK: - Initialization

    /// Initialize with custom configuration (useful for testing)
    /// - Parameters:
    ///   - baseURL: Base API URL (defaults to localhost:8000)
    ///   - session: URLSession instance
    ///   - networkMonitor: Network connectivity monitor
    init(
        baseURL: URL? = nil,
        session: URLSession = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        // Default to localhost for development
        self.baseURL = baseURL ?? URL(string: "http://localhost:8000")!
        self.session = session
        self.networkMonitor = networkMonitor

        // Configure JSON decoder for snake_case
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        jsonDecoder.dateDecodingStrategy = .iso8601

        // Configure JSON encoder for snake_case
        self.jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        jsonEncoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Analysis Endpoints

    /// Upload audio file for analysis
    /// - Parameters:
    ///   - recording: Recording to upload
    ///   - progressHandler: Optional callback for upload progress (0.0 to 1.0)
    /// - Returns: AnalysisResult from backend
    /// - Throws: APIError if upload or analysis fails
    func uploadForAnalysis(
        recording: Recording,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> AnalysisResult {
        // Check network connectivity
        guard networkMonitor.isConnected else {
            throw APIError.networkUnavailable
        }

        // Get file URL for recording
        let storageService = AudioStorageService.shared
        let fileURL = storageService.getFileURL(for: recording)

        // Verify file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw APIError.fileNotFound
        }

        // Determine MIME type from file extension
        let mimeType: String
        if fileURL.pathExtension.lowercased() == "m4a" {
            mimeType = "audio/m4a"
        } else if fileURL.pathExtension.lowercased() == "wav" {
            mimeType = "audio/wav"
        } else {
            mimeType = "audio/mpeg"
        }

        // Build additional form fields
        var additionalFields: [String: String] = [:]
        if let title = recording.title {
            additionalFields["title"] = title
        }
        if let notes = recording.notes {
            additionalFields["notes"] = notes
        }

        // Build multipart request
        let request = try buildMultipartRequest(
            endpoint: "api/v1/analyze",
            fileURL: fileURL,
            fileName: fileURL.lastPathComponent,
            mimeType: mimeType,
            additionalFields: additionalFields
        )

        print("📤 Uploading recording: \(recording.id)")

        // Execute request (progress tracking would require URLSessionDelegate)
        let (data, response) = try await session.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(0, "Invalid response")
        }

        try validateResponse(httpResponse)

        // Decode response
        do {
            let analysisResult = try jsonDecoder.decode(AnalysisResult.self, from: data)
            print("✅ Analysis received: \(analysisResult.id)")
            return analysisResult
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    /// Fetch existing analysis result by ID
    /// - Parameter id: Analysis UUID
    /// - Returns: AnalysisResult from backend
    /// - Throws: APIError if fetch fails
    func fetchAnalysis(id: UUID) async throws -> AnalysisResult {
        let request = buildRequest(endpoint: "api/v1/recordings/\(id.uuidString)/analysis")
        return try await execute(request)
    }

    // MARK: - Reports Endpoints

    /// Fetch daily report for a specific date
    /// - Parameter date: Report date (YYYY-MM-DD)
    /// - Returns: Report from backend
    /// - Throws: APIError if fetch fails or report not found
    func fetchReport(for date: Date) async throws -> Report {
        // Format date as YYYY-MM-DD
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let request = buildRequest(endpoint: "api/v1/reports/\(dateString)")
        return try await execute(request)
    }

    /// Fetch reports for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Array of Report objects
    /// - Throws: APIError if fetch fails
    func fetchReports(from startDate: Date, to endDate: Date) async throws -> [Report] {
        // Format dates as YYYY-MM-DD
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        let request = buildRequest(endpoint: "api/v1/reports?start=\(startString)&end=\(endString)")
        return try await execute(request)
    }

    // MARK: - Recordings Endpoints

    /// Fetch all recordings from backend
    /// - Returns: Array of Recording objects
    /// - Throws: APIError if fetch fails
    func fetchRecordings() async throws -> [Recording] {
        struct RecordingsListResponse: Codable {
            let recordings: [Recording]
            let total: Int
        }

        let request = buildRequest(endpoint: "api/v1/recordings")
        let response: RecordingsListResponse = try await execute(request)
        return response.recordings
    }

    /// Delete recording on backend
    /// - Parameter id: Recording UUID to delete
    /// - Throws: APIError if deletion fails
    func deleteRecording(id: UUID) async throws {
        let request = buildRequest(endpoint: "api/v1/recordings/\(id.uuidString)", method: "DELETE")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(0, "Invalid response")
        }

        try validateResponse(httpResponse)

        print("🗑️ Deleted recording on server: \(id)")
    }

    // MARK: - Health Check

    /// Check backend health and connectivity
    /// - Returns: True if backend is reachable and healthy
    func checkHealth() async -> Bool {
        do {
            let request = buildRequest(endpoint: "health")

            // Add timeout for health check
            var timeoutRequest = request
            timeoutRequest.timeoutInterval = 5.0

            let (data, response) = try await session.data(for: timeoutRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            // Try to parse health response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                return status == "healthy"
            }

            return true
        } catch {
            print("⚠️ Health check failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - OPTIONAL FEATURE: CEO Voice Synthesis

    /// Request CEO-style comparison for a transcript
    // func fetchCEOComparison(transcript: String) async throws -> [CEOComparison] {
    //     TODO: Build POST request to /premium/ceo-voice/compare
    //     TODO: Send transcript in request body
    //     TODO: Decode response to [CEOComparison]
    //     TODO: Return comparisons
    // }

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode

    /// Start live audio streaming session
    // func startLiveGuardianSession() async throws -> UUID {
    //     TODO: Build POST request to /premium/live-guardian/start
    //     TODO: Return session ID
    // }

    /// Stream audio chunk for real-time analysis
    // func streamAudioChunk(sessionID: UUID, audioData: Data) async throws {
    //     TODO: Build POST request to /premium/live-guardian/stream
    //     TODO: Send audio chunk with session ID
    //     TODO: Handle real-time feedback
    // }

    /// End live streaming session
    // func endLiveGuardianSession(sessionID: UUID) async throws {
    //     TODO: Build POST request to /premium/live-guardian/end
    //     TODO: Get final session summary
    // }

    // MARK: - OPTIONAL FEATURE: Simulation Arena

    /// Fetch available simulation scenarios
    // func fetchSimulationScenarios() async throws -> [SimulationScenario] {
    //     TODO: Build GET request to /premium/simulation/scenarios
    //     TODO: Decode response to [SimulationScenario]
    // }

    /// Start a simulation session
    // func startSimulation(scenarioID: UUID, difficulty: String) async throws -> UUID {
    //     TODO: Build POST request to /premium/simulation/start
    //     TODO: Return session ID
    // }

    /// Submit simulation recording for evaluation
    // func submitSimulation(sessionID: UUID, recording: Recording) async throws -> SimulationPerformance {
    //     TODO: Upload recording to /premium/simulation/submit
    //     TODO: Decode performance evaluation
    // }

    // MARK: - OPTIONAL FEATURE: Gamification

    /// Fetch user's gamification progress
    // func fetchGamificationProgress() async throws -> GamificationProgress {
    //     TODO: Build GET request to /premium/gamification/progress
    //     TODO: Decode XP, level, achievements, streaks
    // }

    /// Fetch available achievements
    // func fetchAchievements() async throws -> [Achievement] {
    //     TODO: Build GET request to /premium/gamification/achievements
    //     TODO: Decode achievement list
    // }

    // MARK: - OPTIONAL FEATURE: Pre-Game Prep

    /// Fetch pre-game prep scenarios
    // func fetchPrepScenarios() async throws -> [PrepScenario] {
    //     TODO: Build GET request to /premium/prep/scenarios
    // }

    /// Generate pre-game prep briefing
    // func generatePrepBriefing(scenarioType: String, context: String) async throws -> PrepBriefing {
    //     TODO: Build POST request to /premium/prep/generate
    //     TODO: Send scenario type and context
    //     TODO: Decode briefing with talking points
    // }

    // MARK: - Private Helper Methods

    /// Build authenticated URLRequest
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/analyze")
    ///   - method: HTTP method
    ///   - body: Optional request body data
    /// - Returns: Configured URLRequest
    private func buildRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) -> URLRequest {
        // Combine baseURL with endpoint
        let url = baseURL.appendingPathComponent(endpoint)

        // Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add authentication header
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Add Content-Type header if body present
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        return request
    }

    /// Execute URLRequest and decode JSON response
    /// - Parameter request: URLRequest to execute
    /// - Returns: Decoded response of type T
    /// - Throws: APIError if request fails or JSON decoding fails
    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        // Check network connectivity
        guard networkMonitor.isConnected else {
            throw APIError.networkUnavailable
        }

        // Execute request
        let (data, response) = try await session.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(0, "Invalid response")
        }

        // Validate status code
        try validateResponse(httpResponse)

        // Decode JSON response
        do {
            let decoded = try jsonDecoder.decode(T.self, from: data)
            return decoded
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    /// Build multipart/form-data request for file upload
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - fileURL: Local file URL to upload
    ///   - fileName: Name to use for file in request
    ///   - mimeType: MIME type of file (e.g., "audio/m4a")
    ///   - additionalFields: Optional form fields to include
    /// - Returns: Configured URLRequest with multipart body
    private func buildMultipartRequest(
        endpoint: String,
        fileURL: URL,
        fileName: String,
        mimeType: String,
        additionalFields: [String: String] = [:]
    ) throws -> URLRequest {
        // Generate boundary string
        let boundary = "Boundary-\(UUID().uuidString)"

        // Create URLRequest
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Add authentication header
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Set Content-Type
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build multipart body
        var body = Data()

        // Add additional form fields
        for (key, value) in additionalFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Add file data
        guard let fileData = try? Data(contentsOf: fileURL) else {
            throw APIError.fileNotFound
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return request
    }

    /// Validate HTTP response status code
    /// - Parameter response: HTTPURLResponse to validate
    /// - Throws: APIError if status code indicates error
    private func validateResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            // Success
            return
        case 401:
            throw APIError.authenticationFailed
        case 400...499:
            throw APIError.requestFailed(response.statusCode, "Client error")
        case 500...599:
            throw APIError.serverError("Server returned status \(response.statusCode)")
        default:
            throw APIError.requestFailed(response.statusCode, "Unknown error")
        }
    }

    // MARK: - Error Handling

    /// API errors
    enum APIError: LocalizedError {
        case networkUnavailable
        case invalidURL
        case requestFailed(Int, String?)  // Status code, message
        case decodingFailed(Error)
        case encodingFailed(Error)
        case fileNotFound
        case uploadFailed(String)
        case authenticationFailed
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .networkUnavailable:
                return "No internet connection available."
            case .invalidURL:
                return "Invalid API endpoint URL."
            case .requestFailed(let code, let message):
                return "Request failed with status \(code): \(message ?? "Unknown error")"
            case .decodingFailed(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .encodingFailed(let error):
                return "Failed to encode request: \(error.localizedDescription)"
            case .fileNotFound:
                return "Audio file not found for upload."
            case .uploadFailed(let reason):
                return "Upload failed: \(reason)"
            case .authenticationFailed:
                return "Authentication failed. Please check credentials."
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: Core API implementation:
 1. Implement buildRequest() with proper header configuration
 2. Implement execute() with async/await URLSession
 3. Implement buildMultipartRequest() for file uploads
 4. Add response validation and error mapping
 5. Test with mock backend endpoints

 TODO: Error handling:
 1. Map HTTP status codes to specific errors
 2. Parse error messages from JSON responses
 3. Add retry logic for transient failures
 4. Implement exponential backoff for rate limiting

 TODO: Upload progress:
 1. Implement progress tracking for multipart uploads
 2. Use URLSessionDelegate for progress callbacks
 3. Support upload cancellation
 4. Add resume capability for interrupted uploads

 TODO: Caching:
 1. Integrate with CacheService for response caching
 2. Add cache headers (ETag, If-None-Match)
 3. Implement offline-first strategy
 4. Cache reports and analysis results

 TODO: Testing:
 1. Write unit tests with URLProtocol mocking
 2. Test JSON encoding/decoding edge cases
 3. Test multipart upload with sample files
 4. Test error handling for all status codes
 5. Test authentication header inclusion

 TODO: When implementing OPTIONAL FEATURE: CEO Voice Synthesis:
 1. Uncomment fetchCEOComparison() method
 2. Add request/response models
 3. Test with backend premium endpoint

 TODO: When implementing OPTIONAL FEATURE: Live Guardian Mode:
 1. Uncomment live streaming methods
 2. Implement WebSocket or chunked HTTP streaming
 3. Handle real-time feedback callbacks
 4. Test latency and buffering

 TODO: When implementing OPTIONAL FEATURE: Simulation Arena:
 1. Uncomment simulation methods
 2. Fetch and cache simulation scenarios
 3. Handle session lifecycle
 4. Parse performance evaluations

 TODO: When implementing OPTIONAL FEATURE: Gamification:
 1. Uncomment gamification methods
 2. Sync progress to UI
 3. Handle achievement unlocks
 4. Display XP and level progression
 */
