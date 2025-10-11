import Foundation
import AVFoundation

// MARK: - Audio Service
// Handles microphone permissions, audio session configuration, and recording

@MainActor
final class AudioService: NSObject, @unchecked Sendable {
    static let shared = AudioService()

    private var audioSession: AVAudioSession {
        AVAudioSession.sharedInstance()
    }

    private override init() {
        super.init()
    }

    // MARK: - Permissions

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func checkMicrophonePermission() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied, .undetermined:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Audio Session

    func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try audioSession.setActive(true)
    }

    func deactivateAudioSession() throws {
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Recording (Basic)
    // Note: For real-time audio with LiveKit, this will be replaced with LiveKit's audio handling

    func startRecording() async throws {
        guard checkMicrophonePermission() else {
            throw AudioError.permissionDenied
        }

        try configureAudioSession()

        // TODO: Implement actual recording if needed for non-LiveKit scenarios
    }

    func stopRecording() async throws {
        // TODO: Implement stop recording
        try deactivateAudioSession()
    }
}

// MARK: - Audio Errors
enum AudioError: Error, LocalizedError {
    case permissionDenied
    case configurationFailed
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        case .configurationFailed:
            return "Failed to configure audio session."
        case .recordingFailed:
            return "Failed to start recording."
        }
    }
}
