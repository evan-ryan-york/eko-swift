# Lyra Voice Mode Implementation Plan

**Created:** October 12, 2025
**Status:** Phase 1 Complete - Ready for Phase 2
**Est. Total Time:** 3-4 hours

---

## 📋 Overview

This document outlines the complete implementation plan for building Lyra's voice mode feature, which enables real-time voice conversations between parents and the AI parenting coach using native iOS WebRTC + OpenAI Realtime API.

### What's Already Built

From the text chat implementation (Phases 1-5), we have:

- ✅ **RealtimeVoiceService.swift** - Complete skeleton with commented WebRTC code
- ✅ **LyraViewModel** - Full voice mode integration (startVoiceMode, endVoiceMode, interruptAI)
- ✅ **Voice UI Components** - VoiceBannerView, ChatInputBar with mic button
- ✅ **Edge Function** - `create-realtime-session` (needs API update)
- ✅ **Data Models** - All DTOs for voice session creation
- ✅ **Audio Logic** - AVAudioSession configuration and permissions

### What Needs to Be Built

1. ✅ **Phase 1:** Add WebRTC package + permissions (COMPLETE)
2. ⏳ **Phase 2:** Update Edge Function for OpenAI Realtime API GA
3. ⏳ **Phase 3:** Implement iOS WebRTC connection
4. ⏳ **Phase 4:** Testing & validation
5. ⏳ **Phase 5:** Polish & optimization

---

## 🎯 Phase 1: Environment Setup (✅ COMPLETE - 15 minutes)

### 1.1 Add Info.plist Permissions ✅

**File:** `Eko/Info.plist`

**Added:**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Lyra needs microphone access for voice conversations with your AI parenting coach.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Lyra uses speech recognition to transcribe your voice conversations.</string>
```

**Why:** iOS requires explicit permission descriptions before accessing microphone.

**Status:** ✅ Complete

---

### 1.2 Add WebRTC Package via SPM ✅

**Package URL:** `https://github.com/stasel/WebRTC`
**Version:** 141.0.0
**Status:** ✅ Successfully added and resolved

**Installation:**
1. Xcode → File → Add Package Dependencies
2. Enter URL: `https://github.com/stasel/WebRTC`
3. Select "Up to Next Major Version"
4. Add to "Eko" target

**Why:** Native WebRTC for peer-to-peer audio connection with OpenAI Realtime API.

---

### 1.3 Build Verification ✅

**Status:** ✅ Package dependencies resolved successfully

**Command:**
```bash
xcodebuild -list -project Eko.xcodeproj
```

**Result:** WebRTC package appears in resolved packages.

---

## 🔧 Phase 2: Backend API Update (⏳ PENDING - 30 minutes)

### Problem Statement

The current Edge Function uses OpenAI's **Beta API** endpoint which has been deprecated. We need to migrate to the **GA (General Availability) API**.

**Key Differences:**

| Feature | Beta API | GA API |
|---------|----------|--------|
| Endpoint | `/v1/realtime/sessions` | `/v1/realtime/client_secrets` |
| Auth Method | Multipart SDP exchange | Ephemeral keys |
| Model Name | `gpt-4o-realtime-preview-2024-12-17` | `gpt-realtime` |
| Connection | Backend negotiates SDP | Client connects directly with key |

---

### 2.1 Update Edge Function

**File:** `supabase/functions/create-realtime-session/index.ts`

**Current Implementation Issues:**
- Uses Beta endpoint: `/v1/realtime/sessions`
- Accepts SDP offer from iOS
- Returns SDP answer via multipart form data

**New GA Implementation:**

```typescript
// supabase/functions/create-realtime-session/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateRealtimeSessionRequest {
  conversationId: string
  childId: string
  // No more SDP in request
}

interface RealtimeSessionResponse {
  clientSecret: string
  model: string
  voice: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const { conversationId, childId }: CreateRealtimeSessionRequest = await req.json()

    if (!conversationId || !childId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: conversationId, childId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify conversation exists
    const { data: conversation, error: convError } = await supabase
      .from('conversations')
      .select('user_id, child_id')
      .eq('id', conversationId)
      .single()

    if (convError || !conversation) {
      return new Response(
        JSON.stringify({ error: 'Conversation not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch child context with memory
    const { data: child, error: childError } = await supabase
      .from('children')
      .select(`
        id,
        name,
        age,
        temperament,
        temperament_talkative,
        temperament_sensitivity,
        temperament_accountability
      `)
      .eq('id', childId)
      .single()

    if (childError || !child) {
      return new Response(
        JSON.stringify({ error: 'Child not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch child memory
    const { data: memory } = await supabase
      .from('child_memory')
      .select('behavioral_themes, communication_strategies, significant_events')
      .eq('child_id', childId)
      .single()

    // Build voice instructions
    const instructions = buildVoiceInstructions(child, memory)

    // Create ephemeral key using GA API
    const keyResponse = await fetch('https://api.openai.com/v1/realtime/client_secrets', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-realtime',
        voice: 'alloy',
        instructions: instructions,
        modalities: ['audio', 'text'],
        temperature: 0.8,
        turn_detection: {
          type: 'server_vad',
          threshold: 0.5,
          prefix_padding_ms: 300,
          silence_duration_ms: 500,
        },
        input_audio_transcription: {
          model: 'whisper-1'
        }
      }),
    })

    if (!keyResponse.ok) {
      const errorText = await keyResponse.text()
      console.error('OpenAI API error:', errorText)
      return new Response(
        JSON.stringify({ error: 'Failed to create realtime session', details: errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { client_secret } = await keyResponse.json()

    const response: RealtimeSessionResponse = {
      clientSecret: client_secret,
      model: 'gpt-realtime',
      voice: 'alloy'
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in create-realtime-session function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Build voice conversation instructions (KEEP EXISTING FUNCTION)
function buildVoiceInstructions(child: any, memory: any): string {
  const behavioralThemes = memory?.behavioral_themes || []
  const strategies = memory?.communication_strategies || []
  const events = memory?.significant_events || []

  const themesText = behavioralThemes.length > 0
    ? behavioralThemes.slice(0, 3).map((t: any) => t.theme).join(', ')
    : 'None observed yet'

  const strategiesText = strategies.length > 0
    ? strategies.slice(0, 3).map((s: any) => s.strategy).join(', ')
    : 'None identified yet'

  const recentEvents = events.length > 0
    ? events.slice(-2).map((e: any) => `${e.event} (${e.date})`).join('; ')
    : 'None recorded'

  return `You are Lyra, an empathetic AI parenting coach helping a parent with their child, ${child.name}, age ${child.age}.

# Personality & Voice

You're having a VOICE conversation. Speak naturally, warmly, and conversationally. Keep responses brief (2-4 sentences per turn) to maintain natural dialogue flow.

# Child Context

**Name:** ${child.name}
**Age:** ${child.age} years old
**Temperament:** ${child.temperament}

**Traits (1-10):**
- Talkativeness: ${child.temperament_talkative}/10
- Sensitivity: ${child.temperament_sensitivity}/10
- Accountability: ${child.temperament_accountability}/10

**Recent Themes:** ${themesText}
**Effective Strategies:** ${strategiesText}
**Recent Events:** ${recentEvents}

# Voice Conversation Guidelines

1. **Be Conversational:** Speak like you're talking to a friend who's asking for parenting advice. Use natural speech patterns, not essay-style responses.

2. **Keep It Short:** Voice conversations work best with brief exchanges. Aim for 2-4 sentences, then let the parent respond. Don't lecture.

3. **Be Specific:** Reference ${child.name} by name. Use their age and temperament in your suggestions.

4. **Ask Questions:** If you need more context, ask ONE clarifying question at a time.

5. **Natural Fillers:** It's okay to use phrases like "Hmm," "I see," "That makes sense" - it makes the conversation feel human.

6. **Empathize First:** Before jumping to advice, validate the parent's feelings. "That sounds really challenging" or "I can understand why that's frustrating."

7. **Actionable & Concrete:** Give specific strategies the parent can try today, not generic advice.

8. **Safety First:** If you hear anything about child safety, abuse, or severe crisis, immediately provide:
   - "I'm concerned about what you've shared. Please call 911 if there's immediate danger, or reach out to the National Child Abuse Hotline at 1-800-4-A-CHILD."

# Tone Examples

❌ Wrong (too formal): "Based on the developmental stage of a ${child.age}-year-old, I recommend implementing a structured bedtime routine with consistent expectations and positive reinforcement mechanisms."

✅ Right (conversational): "At ${child.age}, kids really thrive on predictability. What if you tried keeping bedtime the same every night and maybe adding a small reward when ${child.name} cooperates?"

# Remember

You're a trusted parenting expert having a real-time conversation. Be warm, be brief, be specific to ${child.name}. The parent is probably multitasking or feeling stressed - make your advice easy to understand and remember.`
}
```

**Key Changes:**
1. ✅ Removed SDP from request/response
2. ✅ Changed endpoint to `/v1/realtime/client_secrets`
3. ✅ Updated model name to `gpt-realtime`
4. ✅ Return ephemeral key instead of SDP answer
5. ✅ Kept existing `buildVoiceInstructions()` function

---

### 2.2 Update iOS DTOs

**File:** `EkoCore/Sources/EkoCore/Models/LyraModels.swift`

**Current DTOs:**
```swift
public struct CreateRealtimeSessionDTO: Codable {
    public let sdp: String
    public let conversationId: UUID
    public let childId: UUID
}

public struct RealtimeSessionResponse: Codable {
    public let sdp: String
    public let callId: String?
}
```

**Updated DTOs:**
```swift
public struct CreateRealtimeSessionDTO: Codable {
    public let conversationId: UUID
    public let childId: UUID
    // Removed: sdp field

    public init(conversationId: UUID, childId: UUID) {
        self.conversationId = conversationId
        self.childId = childId
    }
}

public struct RealtimeSessionResponse: Codable {
    public let clientSecret: String
    public let model: String
    public let voice: String

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case model
        case voice
    }
}
```

---

### 2.3 Deploy Edge Function

**Commands:**
```bash
cd supabase/functions/create-realtime-session
supabase functions deploy create-realtime-session
```

**Verify Deployment:**
```bash
curl -X POST https://fqecsmwycvltpnqawtod.supabase.co/functions/v1/create-realtime-session \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "test-uuid",
    "childId": "test-child-uuid"
  }'
```

Expected response should include `clientSecret`, `model`, and `voice`.

---

## 🎙️ Phase 3: iOS WebRTC Implementation (⏳ PENDING - 1-2 hours)

### 3.1 Update SupabaseService Method

**File:** `Eko/Core/Services/SupabaseService.swift`

**Location:** Around line 232

**Current Implementation:**
```swift
func createRealtimeSession(
    sdp: String,
    conversationId: UUID,
    childId: UUID
) async throws -> RealtimeSessionResponse {
    let dto = CreateRealtimeSessionDTO(
        sdp: sdp,
        conversationId: conversationId,
        childId: childId
    )
    // ...
}
```

**Updated Implementation:**
```swift
func createRealtimeSession(
    conversationId: UUID,
    childId: UUID
) async throws -> RealtimeSessionResponse {
    let dto = CreateRealtimeSessionDTO(
        conversationId: conversationId,
        childId: childId
    )

    let response: RealtimeSessionResponse = try await functionsClient
        .invoke("create-realtime-session", options: FunctionInvokeOptions(
            body: dto
        ))
        .value

    return response
}
```

**Changes:**
- ❌ Removed `sdp` parameter
- ✅ Simplified DTO initialization

---

### 3.2 Rewrite RealtimeVoiceService

**File:** `Eko/Core/Services/RealtimeVoiceService.swift`

**Implementation Strategy:**

The GA API uses a different connection pattern:
1. Get ephemeral key from backend
2. Connect directly to OpenAI's WebRTC endpoint using the key
3. OpenAI handles SDP negotiation

**Complete Implementation:**

```swift
import Foundation
import AVFoundation
import WebRTC

// MARK: - Voice Error
enum VoiceError: LocalizedError {
    case microphonePermissionDenied
    case realtimeError(String)
    case connectionFailed
    case sessionCreationFailed

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

    // MARK: - WebRTC Components
    private var peerConnection: RTCPeerConnection?
    private var audioTrack: RTCAudioTrack?
    private var dataChannel: RTCDataChannel?
    private let factory: RTCPeerConnectionFactory

    // MARK: - Dependencies
    private let supabase = SupabaseService.shared

    // MARK: - Initialization
    init() {
        RTCInitializeSSL()
        self.factory = RTCPeerConnectionFactory()
    }

    // MARK: - Session Management
    func startSession(conversationId: UUID, childId: UUID) async throws {
        status = .connecting

        // 1. Request microphone permission
        let granted = await requestMicrophonePermission()
        guard granted else {
            status = .disconnected
            throw VoiceError.microphonePermissionDenied
        }

        // 2. Configure audio session
        try configureAudioSession()

        // 3. Get ephemeral key from backend
        let sessionResponse = try await supabase.createRealtimeSession(
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

        peerConnection = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )

        guard let peerConnection = peerConnection else {
            throw VoiceError.connectionFailed
        }

        // 5. Add local audio track
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        )
        let audioSource = factory.audioSource(with: audioConstraints)
        audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        peerConnection.add(audioTrack!, streamIds: ["stream0"])

        // 6. Create data channel for events
        let dataConfig = RTCDataChannelConfiguration()
        dataChannel = peerConnection.dataChannel(
            forLabel: "oai-events",
            configuration: dataConfig
        )
        dataChannel?.delegate = self

        // 7. Create SDP offer
        let offerConstraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "true"],
            optionalConstraints: nil
        )
        let offer = try await peerConnection.offer(for: offerConstraints)
        try await peerConnection.setLocalDescription(offer)

        // 8. Connect to OpenAI using ephemeral key
        let answerSdp = try await connectToOpenAI(
            offer: offer.sdp,
            clientSecret: sessionResponse.clientSecret
        )

        // 9. Set remote description
        let answer = RTCSessionDescription(type: .answer, sdp: answerSdp)
        try await peerConnection.setRemoteDescription(answer)

        status = .connected
    }

    private func connectToOpenAI(offer: String, clientSecret: String) async throws -> String {
        // Make direct call to OpenAI Realtime API with SDP offer
        guard let url = URL(string: "https://api.openai.com/v1/realtime") else {
            throw VoiceError.connectionFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = offer.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VoiceError.connectionFailed
        }

        guard let answerSdp = String(data: data, encoding: .utf8) else {
            throw VoiceError.connectionFailed
        }

        return answerSdp
    }

    func interrupt() {
        // Send response.cancel event via data channel
        let event = ["type": "response.cancel"]
        if let data = try? JSONSerialization.data(withJSONObject: event) {
            let buffer = RTCDataBuffer(data: data, isBinary: false)
            dataChannel?.sendData(buffer)
        }
    }

    func endSession() {
        audioTrack = nil
        dataChannel = nil
        peerConnection?.close()
        peerConnection = nil
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

// MARK: - RTCPeerConnectionDelegate
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
        // Handle incoming audio stream if needed
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        // Handle stream removal
    }

    nonisolated func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // Handle negotiation
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state: \(newState)")
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCSignalingState) {
        print("Signaling state: \(newState)")
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // Handle removed candidates
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened")
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
            // GA API event names:
            case "conversation.item.input_audio_transcription.completed":
                if let transcript = json["transcript"] as? String {
                    userTranscript = transcript
                }

            case "response.audio_transcript.delta":
                if let delta = json["delta"] as? String {
                    aiTranscript += delta
                }

            case "response.audio_transcript.done":
                // AI finished speaking
                break

            case "response.done":
                // Full response complete
                break

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
```

**Key Features:**
- ✅ Uses ephemeral key from backend
- ✅ Direct connection to OpenAI WebRTC endpoint
- ✅ GA API event names
- ✅ Proper error handling
- ✅ @MainActor for UI updates
- ✅ nonisolated delegate methods for WebRTC callbacks

---

## 🧪 Phase 4: Testing & Validation (⏳ PENDING - 1 hour)

### 4.1 Prerequisites

**Required:**
1. Physical iOS device (Simulator doesn't support microphone properly)
2. OpenAI API key with Realtime API access
3. Test child profile in Supabase database
4. Valid Supabase authentication

**Environment Check:**
```bash
# Verify OpenAI API key is set
supabase secrets list

# Should show OPENAI_API_KEY
```

---

### 4.2 Unit Tests

**Create:** `EkoTests/Services/RealtimeVoiceServiceTests.swift`

```swift
import XCTest
@testable import Eko

@MainActor
final class RealtimeVoiceServiceTests: XCTestCase {
    var service: RealtimeVoiceService!

    override func setUp() async throws {
        service = RealtimeVoiceService()
    }

    override func tearDown() async throws {
        service = nil
    }

    func testInitialState() {
        XCTAssertEqual(service.status, .disconnected)
        XCTAssertTrue(service.userTranscript.isEmpty)
        XCTAssertTrue(service.aiTranscript.isEmpty)
    }

    func testEndSessionClearsState() {
        service.userTranscript = "Test user"
        service.aiTranscript = "Test AI"

        service.endSession()

        XCTAssertEqual(service.status, .disconnected)
        XCTAssertTrue(service.userTranscript.isEmpty)
        XCTAssertTrue(service.aiTranscript.isEmpty)
    }

    // Add more tests for permission handling, error states, etc.
}
```

---

### 4.3 Integration Testing Checklist

**Test Flow:**

1. **Pre-Launch Checks**
   - [ ] Physical device connected
   - [ ] OpenAI API key configured
   - [ ] Test child exists in database
   - [ ] User authenticated in app

2. **Voice Session Start**
   - [ ] Launch app
   - [ ] Navigate to Lyra tab
   - [ ] Tap microphone button
   - [ ] **Verify:** Permission prompt appears (first time only)
   - [ ] **Verify:** VoiceBannerView shows "Connecting..."
   - [ ] **Verify:** Status changes to green "Voice Active"
   - [ ] **Verify:** No crashes or errors

3. **Voice Interaction**
   - [ ] Speak a test phrase (e.g., "Hello, can you hear me?")
   - [ ] **Verify:** User transcript appears in banner
   - [ ] **Verify:** AI responds with voice
   - [ ] **Verify:** AI transcript appears in banner
   - [ ] **Verify:** Audio quality is clear

4. **Interrupt Functionality**
   - [ ] Start AI response
   - [ ] Tap interrupt button (hand icon)
   - [ ] **Verify:** AI stops speaking immediately
   - [ ] **Verify:** Can speak again after interruption

5. **Session End**
   - [ ] Tap end button (X icon)
   - [ ] **Verify:** Voice banner disappears
   - [ ] **Verify:** Transcripts persist to text chat
   - [ ] **Verify:** Can start new voice session

---

### 4.4 Edge Cases

**Test Scenarios:**

| Scenario | Expected Behavior | Test Status |
|----------|------------------|-------------|
| Microphone permission denied | Show error alert, return to text mode | [ ] |
| Network loss mid-session | Show connection error, close gracefully | [ ] |
| OpenAI API error | Display error message, allow retry | [ ] |
| WebRTC connection timeout | Show timeout error after 15s | [ ] |
| Background/foreground | Pause audio, resume on foreground | [ ] |
| Incoming phone call | Audio session interrupted, resume after | [ ] |
| Long conversation (10+ mins) | No memory leaks, stable connection | [ ] |
| Multiple rapid starts/stops | No crashes, clean state transitions | [ ] |

---

### 4.5 Performance Metrics

**Monitor:**
- **Connection Time:** Should be < 3 seconds
- **Audio Latency:** Should be < 500ms
- **Memory Usage:** Should not exceed 100MB
- **CPU Usage:** Should stay under 30%
- **Battery Impact:** Track battery drain during 5-min session

---

## ✨ Phase 5: Polish & Optimization (⏳ PENDING - 30 minutes)

### 5.1 Add Haptic Feedback

**File:** `Eko/Features/AIGuide/ViewModels/LyraViewModel.swift`

**Add to `startVoiceMode()`:**
```swift
func startVoiceMode() async {
    do {
        isVoiceMode = true

        // Haptic feedback on connection start
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        if conversationId == nil {
            conversationId = try await createConversation(childId: childId)
        }

        try await voiceService.startSession(
            conversationId: conversationId!,
            childId: childId
        )

        // Haptic feedback on successful connection
        generator.impactOccurred()

    } catch {
        self.error = error
        isVoiceMode = false

        // Error haptic
        let errorGenerator = UINotificationFeedbackGenerator()
        errorGenerator.notificationOccurred(.error)
    }
}
```

---

### 5.2 Add Connection Timeout

**File:** `Eko/Core/Services/RealtimeVoiceService.swift`

**Add timeout helper:**
```swift
private func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw VoiceError.connectionFailed
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

**Update `startSession()`:**
```swift
func startSession(conversationId: UUID, childId: UUID) async throws {
    status = .connecting

    try await withTimeout(seconds: 15) {
        // All connection logic here...
    }
}
```

---

### 5.3 Add Analytics Events

**File:** `Eko/Features/AIGuide/ViewModels/LyraViewModel.swift`

**Track voice usage:**
```swift
func startVoiceMode() async {
    // Track voice session start
    // Analytics.track("lyra_voice_started", properties: [
    //     "child_id": childId.uuidString,
    //     "conversation_id": conversationId?.uuidString ?? "new"
    // ])

    // ... existing code
}

func endVoiceMode() {
    let duration = Date().timeIntervalSince(voiceStartTime)

    // Track voice session end
    // Analytics.track("lyra_voice_ended", properties: [
    //     "duration_seconds": duration,
    //     "user_message_count": userMessageCount,
    //     "ai_message_count": aiMessageCount
    // ])

    voiceService.endSession()
    isVoiceMode = false

    // ... existing code
}
```

---

### 5.4 Improve Error Messages

**File:** `Eko/Features/AIGuide/Views/LyraView.swift`

**Better error alerts:**
```swift
.alert("Voice Error", isPresented: .constant(viewModel.error != nil)) {
    Button("Retry") {
        Task {
            viewModel.error = nil
            await viewModel.startVoiceMode()
        }
    }
    Button("Cancel", role: .cancel) {
        viewModel.error = nil
    }
} message: {
    if let error = viewModel.error {
        Text(getUserFriendlyErrorMessage(error))
    }
}

func getUserFriendlyErrorMessage(_ error: Error) -> String {
    switch error {
    case VoiceError.microphonePermissionDenied:
        return "Please enable microphone access in Settings to use voice mode."
    case VoiceError.connectionFailed:
        return "Couldn't connect to voice service. Please check your internet connection and try again."
    case VoiceError.realtimeError(let message):
        return "Voice error: \(message). Please try again."
    default:
        return error.localizedDescription
    }
}
```

---

## 📊 Implementation Checklist

### ✅ Phase 1: Setup (COMPLETE)
- [x] Add microphone permissions to Info.plist
- [x] Add WebRTC package via SPM (v141.0.0)
- [x] Verify package builds successfully

### ⏳ Phase 2: Backend (PENDING - 30 min)
- [ ] Update Edge Function to GA API endpoint
- [ ] Change to ephemeral key pattern
- [ ] Update model name to `gpt-realtime`
- [ ] Remove SDP negotiation logic
- [ ] Test with cURL/Postman
- [ ] Deploy to Supabase

### ⏳ Phase 3: iOS Implementation (PENDING - 1-2 hours)
- [ ] Update DTOs in LyraModels.swift
- [ ] Update SupabaseService method signature
- [ ] Implement new RealtimeVoiceService
- [ ] Add GA API event names
- [ ] Build and resolve compilation errors
- [ ] Test on device

### ⏳ Phase 4: Testing (PENDING - 1 hour)
- [ ] Create unit tests
- [ ] Test on physical device
- [ ] Test all edge cases
- [ ] Measure performance metrics
- [ ] Fix any bugs found

### ⏳ Phase 5: Polish (PENDING - 30 min)
- [ ] Add haptic feedback
- [ ] Add connection timeout
- [ ] Add analytics events
- [ ] Improve error messages
- [ ] Final QA pass

---

## ⏱️ Time Estimate

| Phase | Tasks | Est. Time | Status |
|-------|-------|-----------|--------|
| Phase 1 | Setup | 15 min | ✅ Complete |
| Phase 2 | Backend | 30 min | ⏳ Pending |
| Phase 3 | iOS | 1-2 hours | ⏳ Pending |
| Phase 4 | Testing | 1 hour | ⏳ Pending |
| Phase 5 | Polish | 30 min | ⏳ Pending |
| **Total** | | **3-4 hours** | **25% Complete** |

---

## 🚨 Critical Notes

### OpenAI API Access
- Requires OpenAI API key with Realtime API access
- May need to join waitlist or verify account
- Check quota limits for Realtime API usage

### Physical Device Required
- Voice mode **cannot** be fully tested in iOS Simulator
- Microphone input doesn't work properly in Simulator
- WebRTC audio requires real hardware

### WebRTC Debugging Tips
If connection issues arise:
1. Check STUN server accessibility
2. Verify network firewall rules
3. Check OpenAI WebRTC endpoint availability
4. Monitor ICE connection state changes
5. Review data channel events in console

### Supabase Secrets
Ensure environment variables are set:
```bash
supabase secrets list
```

Required:
- `OPENAI_API_KEY` ← Must be set manually
- `SUPABASE_URL` ← Auto-set
- `SUPABASE_SERVICE_ROLE_KEY` ← Auto-set

---

## 🎯 Success Criteria

Voice mode is complete when:

- ✅ User can tap mic button and start voice conversation
- ✅ User's speech is transcribed in real-time
- ✅ AI responds with voice and text transcription
- ✅ User can interrupt AI mid-response
- ✅ Session ends cleanly with transcripts saved to chat
- ✅ Error states are handled gracefully
- ✅ Works reliably on physical iOS device
- ✅ No memory leaks or performance issues
- ✅ Battery impact is reasonable
- ✅ Connection time < 3 seconds
- ✅ Audio latency < 500ms

---

## 📚 Related Documentation

- **Feature Spec:** `docs/ai/features/lyra/feature-details.md`
- **Build Plan:** `docs/ai/features/lyra/build-plan.md`
- **Status Update:** `docs/ai/features/lyra/build-status-update.md`
- **Voice Status:** `docs/ai/features/lyra/voice-status-update.md`
- **Backend Docs:** `supabase/functions/README.md`
- **Testing Guide:** `supabase/TESTING.md`

---

## 🔗 Useful Links

### Supabase Dashboard
- Main: https://supabase.com/dashboard/project/fqecsmwycvltpnqawtod
- Functions: https://supabase.com/dashboard/project/fqecsmwycvltpnqawtod/functions
- Secrets: https://supabase.com/dashboard/project/fqecsmwycvltpnqawtod/settings/vault

### OpenAI
- Realtime API Docs: https://platform.openai.com/docs/guides/realtime
- API Keys: https://platform.openai.com/api-keys

### WebRTC
- Package Repo: https://github.com/stasel/WebRTC
- WebRTC Docs: https://webrtc.org/getting-started/overview

---

**Last Updated:** October 12, 2025
**Author:** Claude Code
**Status:** Phase 1 Complete - Ready for Phase 2
