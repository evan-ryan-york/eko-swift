import Foundation
import AVFoundation
import EkoCore

// MARK: - WebRTC Conditional Import
// NOTE: WebRTC package has SPM dependency issues. See WEBRTC_SETUP.md for manual installation.
#if canImport(WebRTC)
import WebRTC
#endif

// MARK: - Voice Error
enum VoiceError: LocalizedError {
    case microphonePermissionDenied
    case realtimeError(String)
    case connectionFailed
    case sessionCreationFailed
    case timeout
    case webRTCNotAvailable

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required for voice conversations"
        case .realtimeError(let message):
            return "Voice error: \(message)"
        case .connectionFailed:
            return "Failed to connect voice session"
        case .sessionCreationFailed:
            return "Failed to create realtime session"
        case .timeout:
            return "Connection timeout - please try again"
        case .webRTCNotAvailable:
            return "Voice mode requires WebRTC framework. Please see WEBRTC_SETUP.md for installation instructions."
        }
    }
}

// MARK: - Realtime Voice Service
@MainActor
@Observable
final class RealtimeVoiceService: NSObject {
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

    // MARK: - WebRTC Components
    #if canImport(WebRTC)
    private var peerConnection: RTCPeerConnection?
    private var audioTrack: RTCAudioTrack?
    private var dataChannel: RTCDataChannel?
    private let factory: RTCPeerConnectionFactory
    #endif

    // MARK: - Dependencies
    private let supabase = SupabaseService.shared

    // MARK: - Initialization
    override init() {
        #if canImport(WebRTC)
        RTCInitializeSSL()
        self.factory = RTCPeerConnectionFactory()
        #endif
        super.init()
    }

    // MARK: - Session Management
    func startSession(conversationId: UUID, childId: UUID) async throws {
        #if canImport(WebRTC)
        status = .connecting

        // Start session without timeout for now (Swift 6 concurrency simplification)
        do {
            // 1. Request microphone permission
            let granted = await self.requestMicrophonePermission()
            guard granted else {
                await MainActor.run {
                    self.status = .disconnected
                }
                throw VoiceError.microphonePermissionDenied
            }

            // 2. Configure audio session
            try self.configureAudioSession()

            // 3. Get ephemeral key from backend
            let sessionResponse = try await self.supabase.createRealtimeSession(
                conversationId: conversationId,
                childId: childId
            )

            // 4. Create peer connection
            let config = RTCConfiguration()
            config.iceServers = [
                RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
            ]

            let constraints = RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            )

            await MainActor.run {
                self.peerConnection = self.factory.peerConnection(
                    with: config,
                    constraints: constraints,
                    delegate: self
                )
            }

            guard let peerConnection = self.peerConnection else {
                throw VoiceError.connectionFailed
            }

            // 5. Add local audio track
            let audioConstraints = RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            )
            let audioSource = self.factory.audioSource(with: audioConstraints)
            let audioTrack = self.factory.audioTrack(with: audioSource, trackId: "audio0")
            peerConnection.add(audioTrack, streamIds: ["stream0"])

            await MainActor.run {
                self.audioTrack = audioTrack
            }

            // 6. Create data channel for events
            let dataConfig = RTCDataChannelConfiguration()
            let dataChannel = peerConnection.dataChannel(
                forLabel: "oai-events",
                configuration: dataConfig
            )
            dataChannel?.delegate = self

            await MainActor.run {
                self.dataChannel = dataChannel
            }

            // 7. Create SDP offer
            let offerConstraints = RTCMediaConstraints(
                mandatoryConstraints: ["OfferToReceiveAudio": "true"],
                optionalConstraints: nil
            )
            let offer = try await peerConnection.offer(for: offerConstraints)
            try await peerConnection.setLocalDescription(offer)

            // 8. Connect to OpenAI using ephemeral key
            let answerSdp = try await self.connectToOpenAI(
                offer: offer.sdp,
                clientSecret: sessionResponse.clientSecret
            )

            // 9. Set remote description
            let answer = RTCSessionDescription(type: .answer, sdp: answerSdp)
            try await peerConnection.setRemoteDescription(answer)

            await MainActor.run {
                self.status = .connected
            }

            // 10. Send session configuration via data channel
            try await self.configureSession()
        } catch {
            await MainActor.run {
                self.status = .error(error)
            }
            throw error
        }
        #else
        throw VoiceError.webRTCNotAvailable
        #endif
    }

    private func connectToOpenAI(offer: String, clientSecret: String) async throws -> String {
        // Make direct call to OpenAI Realtime API with SDP offer (GA endpoint)
        guard let url = URL(string: "https://api.openai.com/v1/realtime/calls") else {
            throw VoiceError.connectionFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = offer.data(using: .utf8)

        print("🌐 [WebRTC] Connecting to OpenAI /v1/realtime/calls")
        print("🔑 [WebRTC] Using ephemeral key: \(clientSecret.prefix(20))...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [WebRTC] Invalid HTTP response")
            throw VoiceError.connectionFailed
        }

        print("📥 [WebRTC] OpenAI response status: \(httpResponse.statusCode)")

        if !(200...299).contains(httpResponse.statusCode) {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unable to decode error body"
            print("❌ [WebRTC] OpenAI error response: \(errorBody)")
            print("❌ [WebRTC] Response headers: \(httpResponse.allHeaderFields)")
            throw VoiceError.connectionFailed
        }

        guard let answerSdp = String(data: data, encoding: .utf8) else {
            print("❌ [WebRTC] Failed to decode SDP answer from OpenAI")
            throw VoiceError.connectionFailed
        }

        print("✅ [WebRTC] Successfully received SDP answer from OpenAI")
        return answerSdp
    }

    private func configureSession() async throws {
        #if canImport(WebRTC)
        // Wait a moment for data channel to be fully ready
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Send session.update event to configure the session
        let sessionConfig: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["audio", "text"],
                "instructions": "You are Lyra, an empathetic AI parenting coach. Speak naturally, warmly, and conversationally. Keep responses brief (2-4 sentences) to maintain natural dialogue flow.",
                "voice": "alloy",
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": "whisper-1"
                ],
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 500
                ]
            ] as [String: Any]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: sessionConfig) {
            let buffer = RTCDataBuffer(data: data, isBinary: false)
            dataChannel?.sendData(buffer)
            print("📤 Sent session.update configuration")
        }
        #endif
    }

    func interrupt() {
        #if canImport(WebRTC)
        // Send response.cancel event via data channel
        let event = ["type": "response.cancel"]
        if let data = try? JSONSerialization.data(withJSONObject: event) {
            let buffer = RTCDataBuffer(data: data, isBinary: false)
            dataChannel?.sendData(buffer)
        }
        #endif
    }

    func endSession() {
        #if canImport(WebRTC)
        audioTrack = nil
        dataChannel = nil
        peerConnection?.close()
        peerConnection = nil
        #endif
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

    // MARK: - Timeout Helper
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw VoiceError.timeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - RTCPeerConnectionDelegate
#if canImport(WebRTC)
extension RealtimeVoiceService: RTCPeerConnectionDelegate {
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCIceConnectionState) {
        print("ICE connection state: \(state)")
        if state == .failed || state == .disconnected {
            Task { @MainActor in
                status = .error(VoiceError.connectionFailed)
            }
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // ICE candidates handled automatically
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Added media stream")
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Removed media stream")
    }

    nonisolated func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Should negotiate")
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state: \(newState)")
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCSignalingState) {
        print("Signaling state: \(newState)")
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("Removed ICE candidates")
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened: \(dataChannel.label)")
    }
}

// MARK: - RTCDataChannelDelegate
extension RealtimeVoiceService: RTCDataChannelDelegate {
    nonisolated func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state: \(dataChannel.readyState)")
    }

    nonisolated func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let json = try? JSONSerialization.jsonObject(with: buffer.data) as? [String: Any],
              let eventType = json["type"] as? String else {
            return
        }

        Task { @MainActor in
            switch eventType {
            // GA API event names
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
                print("AI transcript complete: \(aiTranscript)")

            case "response.done":
                // Full response complete
                print("Response complete")

            case "error":
                if let errorDict = json["error"] as? [String: Any],
                   let message = errorDict["message"] as? String {
                    status = .error(VoiceError.realtimeError(message))
                }

            default:
                print("Unhandled event type: \(eventType)")
            }
        }
    }
}
#endif
