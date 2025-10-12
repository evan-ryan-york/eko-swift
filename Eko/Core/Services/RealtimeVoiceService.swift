import Foundation
import AVFoundation
// TODO: Add WebRTC Package via SPM: https://github.com/stasel/WebRTC
// import WebRTC

// MARK: - Voice Error
enum VoiceError: LocalizedError {
    case microphonePermissionDenied
    case realtimeError(String)
    case connectionFailed
    case webRTCNotAvailable

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required for voice conversations"
        case .realtimeError(let message):
            return "Voice error: \(message)"
        case .connectionFailed:
            return "Failed to connect voice session"
        case .webRTCNotAvailable:
            return "WebRTC package not yet installed. Add via SPM: https://github.com/stasel/WebRTC"
        }
    }
}

// MARK: - Realtime Voice Service
@MainActor
@Observable
final class RealtimeVoiceService {
    // MARK: - State
    enum Status {
        case disconnected
        case connecting
        case connected
        case error(Error)
    }

    var status: Status = .disconnected
    var userTranscript: String = ""
    var aiTranscript: String = ""

    // MARK: - WebRTC Components (Placeholder - requires WebRTC package)
    // private var peerConnection: RTCPeerConnection?
    // private var audioTrack: RTCAudioTrack?
    // private var dataChannel: RTCDataChannel?
    // private let factory: RTCPeerConnectionFactory

    // MARK: - Dependencies
    private let supabase = SupabaseService.shared

    // MARK: - Initialization
    init() {
        // TODO: Initialize WebRTC after adding package
        // RTCInitializeSSL()
        // self.factory = RTCPeerConnectionFactory()
    }

    // MARK: - Session Management
    func startSession(conversationId: UUID, childId: UUID) async throws {
        status = .connecting

        // TODO: Implement full WebRTC flow after adding package
        // This is a placeholder implementation
        throw VoiceError.webRTCNotAvailable

        /*
        // 1. Request microphone permission
        let granted = await requestMicrophonePermission()
        guard granted else {
            status = .disconnected
            throw VoiceError.microphonePermissionDenied
        }

        // 2. Configure audio session
        try configureAudioSession()

        // 3. Create peer connection
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        )

        peerConnection = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )

        // 4. Add audio track
        let audioSource = factory.audioSource(with: nil)
        audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        peerConnection?.add(audioTrack!, streamIds: ["stream0"])

        // 5. Create data channel for events
        let dataConfig = RTCDataChannelConfiguration()
        dataChannel = peerConnection?.dataChannel(
            forLabel: "oai-events",
            configuration: dataConfig
        )
        dataChannel?.delegate = self

        // 6. Create SDP offer
        let offer = try await peerConnection!.offer(for: RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "true"],
            optionalConstraints: nil
        ))
        try await peerConnection!.setLocalDescription(offer)

        // 7. Send to backend
        let response = try await supabase.createRealtimeSession(
            sdp: offer.sdp,
            conversationId: conversationId,
            childId: childId
        )

        // 8. Set remote description
        let answer = RTCSessionDescription(type: .answer, sdp: response.sdp)
        try await peerConnection!.setRemoteDescription(answer)

        status = .connected
        */
    }

    func interrupt() {
        // TODO: Implement after adding WebRTC package
        /*
        // Send cancel event via data channel
        let event = ["type": "response.cancel"]
        if let data = try? JSONSerialization.data(withJSONObject: event) {
            let buffer = RTCDataBuffer(data: data, isBinary: false)
            dataChannel?.sendData(buffer)
        }
        */
    }

    func endSession() {
        // TODO: Implement after adding WebRTC package
        /*
        audioTrack = nil
        dataChannel = nil
        peerConnection?.close()
        peerConnection = nil
        */
        status = .disconnected
        userTranscript = ""
        aiTranscript = ""
    }

    // MARK: - Audio Configuration
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
        try session.setActive(true)
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

// MARK: - RTCPeerConnectionDelegate (Placeholder)
// TODO: Uncomment after adding WebRTC package
/*
extension RealtimeVoiceService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCIceConnectionState) {
        print("ICE connection state: \(state)")
        if state == .failed || state == .disconnected {
            Task { @MainActor in
                status = .error(VoiceError.connectionFailed)
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // ICE candidates handled automatically in our setup
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        // Handle incoming audio stream
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        // Handle stream removal
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // Handle negotiation
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCSignalingState) {
        print("Signaling state: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // Handle removed candidates
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // Handle opened data channel
    }
}

// MARK: - RTCDataChannelDelegate (Placeholder)
extension RealtimeVoiceService: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state: \(dataChannel.readyState)")
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let json = try? JSONSerialization.jsonObject(with: buffer.data) as? [String: Any],
              let eventType = json["type"] as? String else {
            return
        }

        Task { @MainActor in
            switch eventType {
            case "conversation.item.input_audio_transcription.completed":
                if let transcript = json["transcript"] as? String {
                    userTranscript = transcript
                }

            case "response.output_audio_transcript.delta":
                if let delta = json["delta"] as? String {
                    aiTranscript += delta
                }

            case "response.output_audio_transcript.done":
                // AI finished speaking
                break

            case "error":
                if let error = json["error"] as? String {
                    status = .error(VoiceError.realtimeError(error))
                }

            default:
                break
            }
        }
    }
}
*/
