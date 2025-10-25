//
//  AudioSettings.swift
//  SpeechMastery
//
//  Configuration model for audio recording quality and format.
//  Provides presets (high, standard, compressed) and custom configurations.
//
//  Responsibilities:
//  - Define audio quality parameters (sample rate, bit rate, format)
//  - Provide preset configurations for different use cases
//  - Calculate estimated file sizes
//  - Support user customization via settings
//
//  Integration Points:
//  - AudioRecordingService: Configures AVAudioRecorder with these settings
//  - SettingsView: Allows user to select or customize audio quality
//  - Recording model: Stores settings used for each recording
//  - APIService: Sends settings metadata with uploads
//
//  Technical Details:
//  - Sample rates: 8kHz (phone quality), 16kHz (speech optimized), 44.1kHz (CD quality)
//  - Bit rates: 64kbps (compressed), 128kbps (standard), 256kbps (high quality)
//  - Formats: M4A (AAC), MP3, WAV (uncompressed)
//  - Channels: 1 (mono) for speech, 2 (stereo) if needed
//

import Foundation

/// Audio recording quality and format configuration
struct AudioSettings: Codable, Hashable, Equatable {
    // MARK: - Properties

    /// Sample rate in Hertz (Hz)
    /// - 8000: Phone call quality, smallest files
    /// - 16000: Speech optimized, recommended for transcription
    /// - 44100: CD quality, largest files
    let sampleRate: Int

    /// Bit rate in bits per second (bps)
    /// - 64000: Compressed, ~500KB per minute
    /// - 128000: Standard, ~1MB per minute
    /// - 256000: High quality, ~2MB per minute
    let bitRate: Int

    /// Audio format extension
    /// - "m4a": AAC compressed (recommended, iOS native)
    /// - "mp3": MP3 compressed (widely compatible)
    /// - "wav": Uncompressed (lossless, very large)
    let format: String

    /// Number of audio channels
    /// - 1: Mono (recommended for speech)
    /// - 2: Stereo
    let channels: Int

    // MARK: - OPTIONAL FEATURE: Configurable Noise Reduction
    /// Enable on-device noise reduction preprocessing
    // var noiseReductionEnabled: Bool = false
    // var noiseReductionLevel: Int = 0  // 0-10 scale

    // MARK: - OPTIONAL FEATURE: Voice Activity Detection
    /// Enable VAD to skip silence segments
    // var vadEnabled: Bool = false
    // var vadSensitivity: Double = 0.5  // 0.0-1.0

    // MARK: - OPTIONAL FEATURE: Live Guardian Mode
    /// Enable real-time on-device processing
    // var realTimeProcessing: Bool = false
    // var bufferSize: Int = 4096  // For real-time analysis

    // MARK: - Initialization

    init(
        sampleRate: Int,
        bitRate: Int,
        format: String,
        channels: Int = 1
    ) {
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.format = format
        self.channels = channels
    }

    // MARK: - Preset Configurations

    /// High quality: 44.1kHz, 256kbps, M4A
    /// Best transcription accuracy, larger file sizes (~2MB/min)
    /// Use for: Important recordings, presentations, critical analysis
    static var high: AudioSettings {
        AudioSettings(
            sampleRate: 44100,
            bitRate: 256000,
            format: "m4a",
            channels: 1
        )
    }

    /// Standard quality: 16kHz, 128kbps, M4A (DEFAULT)
    /// Speech-optimized, balanced size (~1MB/min)
    /// Use for: Daily recordings, general practice
    static var standard: AudioSettings {
        AudioSettings(
            sampleRate: 16000,
            bitRate: 128000,
            format: "m4a",
            channels: 1
        )
    }

    /// Compressed quality: 8kHz, 64kbps, M4A
    /// Phone-call quality, smallest files (~500KB/min)
    /// Use for: Quick notes, low storage situations
    /// Warning: May affect analysis accuracy
    static var compressed: AudioSettings {
        AudioSettings(
            sampleRate: 8000,
            bitRate: 64000,
            format: "m4a",
            channels: 1
        )
    }

    /// Custom WAV format (uncompressed)
    /// Lossless quality, very large files (~5MB/min)
    /// Use for: Maximum quality when storage isn't a concern
    static var wav: AudioSettings {
        AudioSettings(
            sampleRate: 44100,
            bitRate: 0,  // Uncompressed (bit rate not applicable)
            format: "wav",
            channels: 1
        )
    }

    // MARK: - AVFoundation Settings Dictionary

    /// Convert to AVAudioRecorder settings dictionary
    func toAVSettings() -> [String: Any] {
        var settings: [String: Any] = [:]

        // Format ID
        switch format {
        case "m4a":
            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
        case "mp3":
            settings[AVFormatIDKey] = kAudioFormatMPEGLayer3
        case "wav":
            settings[AVFormatIDKey] = kAudioFormatLinearPCM
        default:
            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC  // Default to M4A
        }

        // Sample rate
        settings[AVSampleRateKey] = Float(sampleRate)

        // Channels
        settings[AVNumberOfChannelsKey] = channels

        // Bit rate (not applicable for WAV)
        if format != "wav" {
            settings[AVEncoderBitRateKey] = bitRate
        }

        // Audio quality
        settings[AVEncoderAudioQualityKey] = AVAudioQuality.high.rawValue

        // Linear PCM settings (for WAV)
        if format == "wav" {
            settings[AVLinearPCMBitDepthKey] = 16
            settings[AVLinearPCMIsBigEndianKey] = false
            settings[AVLinearPCMIsFloatKey] = false
        }

        return settings
    }

    // MARK: - Helper Methods

    /// Estimate file size for a given duration in seconds
    /// Returns size in bytes
    func estimatedFileSize(forDuration duration: Double) -> Int64 {
        if format == "wav" {
            // WAV: sample_rate * channels * bit_depth (16 bits = 2 bytes) * duration
            return Int64(Double(sampleRate) * Double(channels) * 2.0 * duration)
        } else {
            // Compressed formats: bit_rate / 8 * duration
            return Int64(Double(bitRate) / 8.0 * duration)
        }
    }

    /// Human-readable quality description
    var qualityDescription: String {
        if self == .high {
            return "High Quality"
        } else if self == .standard {
            return "Standard Quality"
        } else if self == .compressed {
            return "Compressed Quality"
        } else if self == .wav {
            return "Lossless (WAV)"
        } else {
            return "Custom"
        }
    }

    /// Human-readable size estimate per minute
    var sizePerMinute: String {
        let bytesPerMinute = estimatedFileSize(forDuration: 60)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytesPerMinute) + "/min"
    }

    /// Check if these settings are recommended for speech analysis
    var isRecommendedForSpeech: Bool {
        // 16kHz sample rate is optimal for speech
        // Compressed formats below 16kHz may reduce accuracy
        return sampleRate >= 16000
    }

    /// Get quality level as percentage (0-100)
    var qualityPercentage: Int {
        // Rough quality scoring based on sample rate and bit rate
        let sampleRateScore = min(100, (sampleRate / 441)) // 44.1kHz = 100%
        let bitRateScore: Int
        if format == "wav" {
            bitRateScore = 100  // Lossless
        } else {
            bitRateScore = min(100, (bitRate / 2560))  // 256kbps = 100%
        }
        return (sampleRateScore + bitRateScore) / 2
    }

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case sampleRate = "sample_rate"
        case bitRate = "bit_rate"
        case format
        case channels

        // OPTIONAL FEATURE: Uncomment when implementing
        // case noiseReductionEnabled = "noise_reduction_enabled"
        // case noiseReductionLevel = "noise_reduction_level"
        // case vadEnabled = "vad_enabled"
        // case vadSensitivity = "vad_sensitivity"
        // case realTimeProcessing = "real_time_processing"
        // case bufferSize = "buffer_size"
    }
}

// MARK: - Extensions

extension AudioSettings: CustomStringConvertible {
    var description: String {
        "\(qualityDescription): \(sampleRate/1000)kHz, \(format.uppercased()), \(sizePerMinute)"
    }
}

// MARK: - User Defaults Storage

extension AudioSettings {
    /// Key for storing user's preferred audio settings
    private static let userDefaultsKey = "userAudioSettings"

    /// Save these settings as user's default preference
    func saveAsDefault() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    /// Load user's preferred audio settings (or standard if not set)
    static func loadUserDefault() -> AudioSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(AudioSettings.self, from: data) else {
            return .standard  // Default to standard quality
        }
        return settings
    }

    /// Reset to standard quality
    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - TODO: Implementation Tasks
/*
 TODO: When implementing audio quality selection UI:
 1. Add SettingsView with quality preset picker
 2. Allow custom configuration (advanced settings)
 3. Show real-time preview of estimated file sizes
 4. Warn users if selecting low quality that may affect analysis

 TODO: When implementing OPTIONAL FEATURE: Noise Reduction:
 1. Uncomment noise reduction properties
 2. Integrate AVAudioEngine for preprocessing
 3. Add AudioUnit effects for noise gate/suppression
 4. Test impact on transcription accuracy

 TODO: When implementing OPTIONAL FEATURE: VAD:
 1. Uncomment VAD properties
 2. Implement on-device voice activity detection
 3. Buffer only speech segments to reduce file size
 4. Add UI toggle in settings

 TODO: When implementing OPTIONAL FEATURE: Live Guardian Mode:
 1. Uncomment real-time processing properties
 2. Configure low-latency audio buffers
 3. Implement streaming audio analysis
 4. Test on physical device (not simulator)

 TODO: Performance optimizations:
 1. Test different sample rates with Whisper accuracy
 2. Profile battery impact of different settings
 3. Measure upload times for various file sizes
 4. Add adaptive quality based on network conditions
 */
