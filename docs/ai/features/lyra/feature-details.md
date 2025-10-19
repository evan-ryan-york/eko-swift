# Lyra: On-Demand AI Parenting Guide - Native iOS Implementation

**Version**: 3.1 (Native iOS + GA API)
**Last Updated**: October 19, 2025
**Platform**: iOS 17.0+ (Swift 6 + SwiftUI)
**Status**: ✅ Implemented & Working (GA API)

## Overview

Lyra is Eko's AI-powered parenting coach providing hyper-personalized support through **text chat** and **real-time voice conversations**. Built natively for iOS using Swift, SwiftUI, and modern concurrency patterns.

## Product Vision

**Goal**: Provide empathetic, expert-informed, and highly personalized support to help parents feel more confident and prepared for conversations with their children.

**Access**: Main tab navigation → "Lyra" tab (always accessible)

**Differentiator**: Deep personalization based on child profiles, conversation history, and behavioral patterns stored in Supabase Postgres.

---

## Core Features

### 1. Intelligent Chat Interface (Text Mode)

#### SwiftUI Architecture
- **LyraView.swift**: Main chat interface (NavigationStack)
- **MessageBubbleView.swift**: Individual message display
- **ChatInputBar.swift**: Text input with send button
- **VoiceBannerView.swift**: Voice mode status indicator
- **ChatHistorySheet.swift**: Completed conversations list

#### Direct Access & Conversation Flow
- **No barriers**: Direct access to chat interface
- **Auto-resume**: If active conversation exists, loads with full message history
- **Fresh start**: If no active conversation, shows empty chat
- **Child context**: Header displays current child's name and age
- **Real-time streaming**: Responses stream token-by-token using AsyncStream
- **Persistent**: After completion, immediately ready for new conversation

#### Message Types
```swift
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var sources: [Citation]?
}

struct Citation: Codable, Identifiable {
    let id: UUID
    let title: String
    let url: URL?
    let excerpt: String
}
Starting a New Chat Flow

Parent opens Lyra tab
LyraViewModel checks for active conversation via Supabase:

sql   SELECT * FROM conversations
   WHERE user_id = $1 AND child_id = $2 AND status = 'active'
   ORDER BY updated_at DESC LIMIT 1

If exists → Load messages; If none → Empty state
Parent selects child from header picker (if multiple)
Parent types first message
System creates conversation:

swift   struct CreateConversationDTO: Codable {
       let userId: UUID
       let childId: UUID
   }

   // POST to Supabase Edge Function
   let conversation = try await supabase.functions
       .invoke("create-conversation", body: dto)

Message sends to Edge Function for AI processing
Response streams back via Server-Sent Events (SSE)

During Text Conversation

User types question in ChatInputBar
LyraViewModel.sendMessage() called:

swift   @MainActor
   func sendMessage(_ text: String) async throws {
       let userMessage = Message(
           id: UUID(),
           role: .user,
           content: text,
           timestamp: Date()
       )
       messages.append(userMessage)

       // Stream AI response
       let stream = try await supabase.functions
           .invoke("send-message", body: SendMessageDTO(
               conversationId: conversationId,
               message: text,
               childId: childId
           ))

       var assistantMessage = Message(
           id: UUID(),
           role: .assistant,
           content: "",
           timestamp: Date()
       )

       for try await chunk in stream {
           assistantMessage.content += chunk
           // Update UI in real-time
           if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
               messages[index] = assistantMessage
           } else {
               messages.append(assistantMessage)
           }
       }
   }

Backend (Supabase Edge Function) builds context:

Child profile from Postgres
Conversation history
Long-term memory
RAG knowledge base (via Weaviate)


Streaming response updates UI token-by-token
All messages persist in Supabase Postgres

2. Real-Time Voice Mode (Native iOS)
Architecture Overview
Uses native iOS WebRTC + OpenAI Realtime API for ultra-low latency voice.
iOS App (native WebRTC)
    ↓ Creates RTCPeerConnection
    ↓ Generates SDP offer
    ↓ POST to Supabase Edge Function
Supabase Edge Function
    ↓ Adds child context & config
    ↓ POST to OpenAI Realtime API
    ↓ Returns SDP answer
iOS App
    ↓ Sets remote description
    ↓ WebRTC connects
    ↓ Bidirectional audio flows
OpenAI Realtime API
    ↓ Live transcription
    ↓ Voice responses
Native iOS WebRTC Implementation
Dependencies:
swift// Add via SPM: https://github.com/stasel/WebRTC
import WebRTC
Service Class: LiveKitService.swift → Rename to RealtimeVoiceService.swift
swiftimport WebRTC
import AVFoundation

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

    // MARK: - Initialization
    init() {
        // Initialize WebRTC
        RTCInitializeSSL()
        self.factory = RTCPeerConnectionFactory()
    }

    // MARK: - Session Management
    func startSession(conversationId: UUID, childId: UUID) async throws {
        status = .connecting

        // 1. Request microphone permission
        let granted = await requestMicrophonePermission()
        guard granted else {
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
        let response: RealtimeSessionResponse = try await supabase.functions
            .invoke("create-realtime-session", body: CreateRealtimeSessionDTO(
                sdp: offer.sdp,
                conversationId: conversationId,
                childId: childId
            ))

        // 8. Set remote description
        let answer = RTCSessionDescription(type: .answer, sdp: response.sdp)
        try await peerConnection!.setRemoteDescription(answer)

        status = .connected
    }

    func interrupt() {
        // Send cancel event via data channel
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
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCIceConnectionState) {
        print("ICE connection state: \(state)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // ICE candidates handled automatically in our setup
    }

    // Implement other required delegate methods...
}

// MARK: - RTCDataChannelDelegate
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
            // GA API event names (updated October 2025)
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

enum VoiceError: LocalizedError {
    case microphonePermissionDenied
    case realtimeError(String)
    case connectionFailed

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required for voice conversations"
        case .realtimeError(let message):
            return "Voice error: \(message)"
        case .connectionFailed:
            return "Failed to connect voice session"
        }
    }
}
ViewModel Integration
swift// Eko/Features/AIGuide/ViewModels/LyraViewModel.swift

@MainActor
@Observable
final class LyraViewModel {
    // Text chat state
    var messages: [Message] = []
    var isLoading = false
    var error: Error?

    // Voice state
    var isVoiceMode = false
    private let voiceService = RealtimeVoiceService()

    var voiceStatus: RealtimeVoiceService.Status {
        voiceService.status
    }

    var userTranscript: String {
        voiceService.userTranscript
    }

    var aiTranscript: String {
        voiceService.aiTranscript
    }

    // Services
    private let supabase = SupabaseService.shared
    private var conversationId: UUID?

    // MARK: - Voice Mode
    func startVoiceMode(childId: UUID) async {
        do {
            isVoiceMode = true

            // Create conversation if needed
            if conversationId == nil {
                conversationId = try await createConversation(childId: childId)
            }

            try await voiceService.startSession(
                conversationId: conversationId!,
                childId: childId
            )
        } catch {
            self.error = error
            isVoiceMode = false
        }
    }

    func endVoiceMode() {
        voiceService.endSession()
        isVoiceMode = false

        // Add voice transcripts to text chat
        if !voiceService.userTranscript.isEmpty {
            messages.append(Message(
                id: UUID(),
                role: .user,
                content: voiceService.userTranscript,
                timestamp: Date()
            ))
        }

        if !voiceService.aiTranscript.isEmpty {
            messages.append(Message(
                id: UUID(),
                role: .assistant,
                content: voiceService.aiTranscript,
                timestamp: Date()
            ))
        }
    }

    func interruptAI() {
        voiceService.interrupt()
    }
}
SwiftUI View Integration
swift// Eko/Features/AIGuide/Views/LyraView.swift

struct LyraView: View {
    @State private var viewModel: LyraViewModel
    @State private var inputText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Voice mode banner
                if viewModel.isVoiceMode {
                    VoiceBannerView(
                        status: viewModel.voiceStatus,
                        userTranscript: viewModel.userTranscript,
                        aiTranscript: viewModel.aiTranscript,
                        onInterrupt: { viewModel.interruptAI() },
                        onEnd: { viewModel.endVoiceMode() }
                    )
                }

                // Message list
                ScrollView {
                    LazyVStack(spacing: .ekoSpacingMD) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    .padding()
                }

                // Input bar
                if !viewModel.isVoiceMode {
                    ChatInputBar(
                        text: $inputText,
                        onSend: {
                            Task {
                                try await viewModel.sendMessage(inputText)
                                inputText = ""
                            }
                        },
                        onVoiceTap: {
                            Task {
                                await viewModel.startVoiceMode(childId: selectedChild.id)
                            }
                        }
                    )
                }
            }
            .navigationTitle("Chat with Lyra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Child picker
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Complete") {
                        Task {
                            try await viewModel.completeConversation()
                        }
                    }
                }
            }
        }
    }
}
3. Conversation History & Management
Database Schema (Supabase Postgres)
sql-- conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users NOT NULL,
    child_id UUID REFERENCES children NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'completed')),
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    sources JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access their own conversations"
    ON conversations FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access messages in their conversations"
    ON messages FOR ALL
    USING (
        conversation_id IN (
            SELECT id FROM conversations WHERE user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_conversations_user_child ON conversations(user_id, child_id);
CREATE INDEX idx_conversations_status ON conversations(status);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
Completing Conversation
swiftfunc completeConversation() async throws {
    guard let conversationId else { return }

    // Call Edge Function to generate summary and update memory
    let result: CompletedConversation = try await supabase.functions
        .invoke("complete-conversation", body: CompleteConversationDTO(
            conversationId: conversationId
        ))

    // Update local state
    self.conversationId = nil
    self.messages = []

    // Conversation now available in history
}
4. Hyper-Personalization System
Child Context Models
swift// EkoCore/Sources/EkoCore/Models/Child.swift (already exists, enhance it)

public extension Child {
    var lyraContext: LyraChildContext {
        LyraChildContext(
            id: id,
            name: name,
            age: age,
            temperament: temperament,
            recentThemes: [], // Loaded from memory
            effectiveStrategies: [] // Loaded from memory
        )
    }
}

public struct LyraChildContext: Codable {
    let id: UUID
    let name: String
    let age: Int
    let temperament: Temperament
    let recentThemes: [String]
    let effectiveStrategies: [String]
}
Backend System Prompt (Supabase Edge Function)
typescript// supabase/functions/send-message/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { conversationId, message, childId } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Get child context
  const { data: child } = await supabase
    .from('children')
    .select('*, memory(*)')
    .eq('id', childId)
    .single()

  // Build personalized system prompt
  const systemPrompt = `You are Lyra, helping parent with ${child.name}, age ${child.age}.

Child characteristics:
- Talkative: ${child.temperament.talkative}/10
- Sensitivity: ${child.temperament.sensitivity}/10
- Accountability: ${child.temperament.accountability}/10

Recent behavioral themes: ${child.memory?.behavioral_themes?.join(', ') || 'None yet'}
Effective strategies: ${child.memory?.effective_strategies?.join(', ') || 'None yet'}

Provide warm, concise, actionable advice tailored to this specific child.
`

  // Call OpenAI with streaming
  const openai = new OpenAI({ apiKey: Deno.env.get('OPENAI_API_KEY') })

  const stream = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [
      { role: 'system', content: systemPrompt },
      // ... conversation history
      { role: 'user', content: message }
    ],
    stream: true
  })

  // Return SSE stream
  const encoder = new TextEncoder()
  const readable = new ReadableStream({
    async start(controller) {
      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content
        if (content) {
          controller.enqueue(encoder.encode(`data: ${content}\n\n`))
        }
      }
      controller.close()
    }
  })

  return new Response(readable, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache'
    }
  })
})
5. Long-Term Memory System
Memory Schema
sql-- child_memory table
CREATE TABLE child_memory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID REFERENCES children UNIQUE NOT NULL,
    behavioral_themes JSONB DEFAULT '[]',
    communication_strategies JSONB DEFAULT '[]',
    significant_events JSONB DEFAULT '[]',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example structure:
{
  "behavioral_themes": [
    {
      "theme": "bedtime resistance",
      "frequency": 5,
      "first_observed": "2025-01-15",
      "last_observed": "2025-02-10"
    }
  ],
  "communication_strategies": [
    {
      "strategy": "choice framework",
      "effectiveness": "high",
      "used_count": 3,
      "notes": "Works well before bedtime"
    }
  ],
  "significant_events": [
    {
      "event": "Started new school",
      "date": "2025-01-08",
      "impact": "Increased anxiety around transitions"
    }
  ]
}
Memory Update (Edge Function)
typescript// supabase/functions/complete-conversation/index.ts

serve(async (req) => {
  const { conversationId } = await req.json()

  // Get full conversation
  const { data: messages } = await supabase
    .from('messages')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })

  // Use GPT-4 to analyze and extract insights
  const analysis = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [
      {
        role: 'system',
        content: `Analyze this parent-child conversation and extract:
1. Behavioral themes mentioned
2. Communication strategies discussed
3. Significant events shared

Return as structured JSON.`
      },
      {
        role: 'user',
        content: JSON.stringify(messages)
      }
    ],
    response_format: { type: 'json_object' }
  })

  const insights = JSON.parse(analysis.choices[0].message.content)

  // Update child memory
  await supabase.rpc('update_child_memory', {
    p_child_id: childId,
    p_new_insights: insights
  })

  // Generate conversation title
  const title = await generateConversationTitle(messages)

  // Mark conversation complete
  await supabase
    .from('conversations')
    .update({ status: 'completed', title })
    .eq('id', conversationId)

  return new Response(JSON.stringify({ success: true, title }))
})
6. Safety & Crisis Support
Content Moderation Service
swift// Eko/Core/Services/ModerationService.swift

final class ModerationService {
    static let shared = ModerationService()

    private let crisisKeywords = [
        "suicide", "self-harm", "kill myself", "end it all",
        "abuse", "hitting", "hurt", "unsafe"
    ]

    func checkForCrisis(_ text: String) -> Bool {
        let lowercase = text.lowercased()
        return crisisKeywords.contains { lowercase.contains($0) }
    }

    func getCrisisResources() -> String {
        """
        If you or your child are in immediate danger, please call:

        • 911 (Emergency)
        • 988 (Suicide & Crisis Lifeline)
        • 1-800-4-A-CHILD (Child Abuse Hotline)

        You can also text HOME to 741741 (Crisis Text Line)
        """
    }
}
Integration in ViewModel
swiftfunc sendMessage(_ text: String) async throws {
    // Check for crisis content
    if ModerationService.shared.checkForCrisis(text) {
        let crisisMessage = Message(
            id: UUID(),
            role: .system,
            content: """
            I'm concerned about what you've shared. \(ModerationService.shared.getCrisisResources())

            Would you like to talk about what's happening?
            """,
            timestamp: Date()
        )
        messages.append(crisisMessage)

        // Log crisis event
        try await logCrisisEvent(conversationId: conversationId, message: text)
        return
    }

    // Normal message flow...
}

SwiftUI Components
Main Chat View
swift// Eko/Features/AIGuide/Views/LyraView.swift

struct LyraView: View {
    @State private var viewModel: LyraViewModel
    @State private var inputText = ""
    @State private var showingHistory = false

    init(childId: UUID) {
        _viewModel = State(initialValue: LyraViewModel(childId: childId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Voice mode banner
                if viewModel.isVoiceMode {
                    VoiceBannerView(viewModel: viewModel)
                        .transition(.move(edge: .top))
                }

                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: .ekoSpacingMD) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isLoading {
                                TypingIndicatorView()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input bar
                if !viewModel.isVoiceMode {
                    ChatInputBar(
                        text: $inputText,
                        isLoading: viewModel.isLoading,
                        onSend: {
                            Task {
                                try await viewModel.sendMessage(inputText)
                                inputText = ""
                            }
                        },
                        onVoiceTap: {
                            Task {
                                await viewModel.startVoiceMode()
                            }
                        }
                    )
                    .padding()
                }
            }
            .navigationTitle("Chat with Lyra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("View History", systemImage: "clock") {
                            showingHistory = true
                        }

                        Button("Complete Conversation", systemImage: "checkmark.circle") {
                            Task {
                                try await viewModel.completeConversation()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                ChatHistorySheet(childId: viewModel.childId)
            }
            .task {
                await viewModel.loadActiveConversation()
            }
        }
    }
}
Message Bubble
swift// Eko/Features/AIGuide/Views/MessageBubbleView.swift

struct MessageBubbleView: View {
    let message: Message
    @State private var showingSources = false

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: .ekoSpacingXS) {
                Text(message.content)
                    .font(.ekoBody)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .padding(.ekoSpacingMD)
                    .background(
                        RoundedRectangle(cornerRadius: .ekoRadiusMD)
                            .fill(message.role == .user ? Color.ekoPrimary : Color.ekoSurface)
                    )

                if let sources = message.sources, !sources.isEmpty {
                    Button {
                        showingSources.toggle()
                    } label: {
                        Label("\(sources.count) source\(sources.count == 1 ? "" : "s")",
                              systemImage: "book.fill")
                            .font(.ekoCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                if showingSources, let sources = message.sources {
                    VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                        ForEach(sources) { source in
                            CitationView(citation: source)
                        }
                    }
                    .transition(.opacity)
                }

                Text(message.timestamp, style: .time)
                    .font(.ekoCaption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 300, alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user {
                Spacer()
            }
        }
        .animation(.easeInOut, value: showingSources)
    }
}
Voice Banner
swift// Eko/Features/AIGuide/Views/VoiceBannerView.swift

struct VoiceBannerView: View {
    @Bindable var viewModel: LyraViewModel

    var body: some View {
        VStack(spacing: .ekoSpacingSM) {
            // Status indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.ekoCaption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Controls
                Button(action: { viewModel.interruptAI() }) {
                    Image(systemName: "hand.raised.fill")
                }
                .disabled(viewModel.voiceStatus != .connected)

                Button(action: { viewModel.endVoiceMode() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }

            // Live transcripts
            if !viewModel.userTranscript.isEmpty || !viewModel.aiTranscript.isEmpty {
                VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                    if !viewModel.userTranscript.isEmpty {
                        Text("You: \(viewModel.userTranscript)")
                            .font(.ekoCaption)
                            .foregroundStyle(.primary)
                    }

                    if !viewModel.aiTranscript.isEmpty {
                        Text("Lyra: \(viewModel.aiTranscript)")
                            .font(.ekoCaption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.ekoSurface)
        .overlay(
            Rectangle()
                .fill(statusColor)
                .frame(height: 2),
            alignment: .bottom
        )
    }

    private var statusColor: Color {
        switch viewModel.voiceStatus {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }

    private var statusText: String {
        switch viewModel.voiceStatus {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Voice Active - Speak Naturally"
        case .error: return "Connection Error"
        }
    }
}
Chat Input Bar
swift// Eko/Features/AIGuide/Views/ChatInputBar.swift

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onVoiceTap: () -> Void

    var body: some View {
        HStack(spacing: .ekoSpacingSM) {
            TextField("Ask Lyra anything...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(isLoading)

            Button(action: onVoiceTap) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.ekoPrimary)
                    .font(.title2)
            }
            .disabled(isLoading)

            Button(action: onSend) {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(Color.ekoPrimary)
                        .font(.title2)
                }
            }
            .disabled(text.isEmpty || isLoading)
        }
    }
}

Supabase Edge Functions
Create Realtime Session (GA API)
**Note**: Uses ephemeral key approach (not SDP proxy). The iOS client handles WebRTC SDP exchange directly with OpenAI.

typescript// supabase/functions/create-realtime-session/index.ts
// Updated for OpenAI Realtime GA API (October 2025)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { conversationId, childId } = await req.json()

    // Get child context
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: child } = await supabase
      .from('children')
      .select('*, memory(*)')
      .eq('id', childId)
      .single()

    // Build voice instructions (used in Edge Function only, not in ephemeral key)
    const instructions = buildVoiceInstructions(child, child.memory)

    // Create ephemeral key using GA API endpoint
    // https://platform.openai.com/docs/api-reference/realtime-sessions/create-realtime-client-secret
    const keyResponse = await fetch('https://api.openai.com/v1/realtime/client_secrets', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        session: {
          type: 'realtime',
          model: 'gpt-realtime',
          audio: {
            output: { voice: 'alloy' }
          }
        }
      }),
    })

    if (!keyResponse.ok) {
      const errorText = await keyResponse.text()
      console.error('OpenAI API error:', errorText)
      throw new Error('Failed to create realtime session')
    }

    const openaiResponse = await keyResponse.json()

    // GA API returns {value: "ek_..."} directly
    const clientSecretValue = openaiResponse.value

    return new Response(
      JSON.stringify({
        clientSecret: clientSecretValue,
        model: 'gpt-realtime',
        voice: 'alloy'
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

function buildVoiceInstructions(child: any, memory: any): string {
  // Build personalized voice instructions for session configuration
  // (sent via data channel after WebRTC connection)
  return `You are Lyra, helping parent with ${child.name}, age ${child.age}...`
}

### iOS WebRTC Implementation (GA API)

The iOS client uses the **ephemeral key approach** to connect to OpenAI's Realtime API:

```swift
// 1. Get ephemeral key from Edge Function
let sessionResponse = try await supabase.createRealtimeSession(
    conversationId: conversationId,
    childId: childId
)

// 2. Create SDP offer
let offer = try await peerConnection.offer(for: constraints)
try await peerConnection.setLocalDescription(offer)

// 3. POST SDP to OpenAI with ephemeral key
let answerSdp = try await connectToOpenAI(
    offer: offer.sdp,
    clientSecret: sessionResponse.clientSecret
)

private func connectToOpenAI(offer: String, clientSecret: String) async throws -> String {
    // GA API endpoint
    let url = URL(string: "https://api.openai.com/v1/realtime/calls")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
    request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
    request.httpBody = offer.data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw VoiceError.connectionFailed
    }

    // IMPORTANT: Accept 2xx range, OpenAI returns 201 Created
    guard (200...299).contains(httpResponse.statusCode) else {
        throw VoiceError.connectionFailed
    }

    guard let answerSdp = String(data: data, encoding: .utf8) else {
        throw VoiceError.connectionFailed
    }

    return answerSdp
}

// 4. Set remote description
let answer = RTCSessionDescription(type: .answer, sdp: answerSdp)
try await peerConnection.setRemoteDescription(answer)
```

**Key Implementation Notes (Learned during GA migration):**

1. **Ephemeral Key Endpoint**: Use `/v1/realtime/client_secrets` not `/v1/realtime/sessions`
2. **Request Format**: Must wrap config in `session` object
3. **Response Format**: OpenAI returns `{value: "ek_..."}` directly
4. **WebRTC SDP Endpoint**: Use `/v1/realtime/calls` not `/v1/realtime`
5. **HTTP Status**: Accept entire 2xx range (OpenAI returns 201 Created)
6. **Event Names**: Use `response.output_audio_transcript.*` not `response.audio_transcript.*`

Dependencies
iOS (Swift Package Manager)
Add via Xcode → File → Add Package Dependencies:
swift// Package URLs
"https://github.com/supabase/supabase-swift"           // Supabase SDK
"https://github.com/stasel/WebRTC"                     // Native WebRTC
"https://github.com/RevenueCat/purchases-ios"          // Subscriptions (later)
Supabase Edge Functions
json{
  "dependencies": {
    "@supabase/supabase-js": "^2.39.0",
    "openai": "^4.28.0"
  }
}

Implementation Checklist for Claude Code
markdown## Phase 1: Database & Backend Setup
- [ ] Create Supabase tables (conversations, messages, child_memory)
- [ ] Set up Row Level Security policies
- [ ] Create `send-message` Edge Function (text streaming)
- [ ] Create `create-realtime-session` Edge Function (voice)
- [ ] Create `complete-conversation` Edge Function
- [ ] Test Edge Functions with Postman

## Phase 2: Core iOS Services
- [ ] Enhance SupabaseService with conversation methods
- [ ] Create RealtimeVoiceService (WebRTC + OpenAI)
- [ ] Create ModerationService (crisis detection)
- [ ] Test services with unit tests

## Phase 3: SwiftUI Views
- [ ] Create LyraView (main chat interface)
- [ ] Create MessageBubbleView (messages)
- [ ] Create ChatInputBar (text input)
- [ ] Create VoiceBannerView (voice status)
- [ ] Create ChatHistorySheet (completed conversations)
- [ ] Create CitationView (research sources)

## Phase 4: ViewModel Logic
- [ ] Create LyraViewModel
  - [ ] loadActiveConversation()
  - [ ] sendMessage() with streaming
  - [ ] startVoiceMode()
  - [ ] endVoiceMode()
  - [ ] completeConversation()
- [ ] Integrate with RealtimeVoiceService
- [ ] Add error handling

## Phase 5: Integration
- [ ] Add Lyra tab to main navigation
- [ ] Connect to child profiles
- [ ] Test full text chat flow
- [ ] Test full voice chat flow
- [ ] Test conversation completion
- [ ] Test history viewing

## Phase 6: Polish
- [ ] Add typing indicators
- [ ] Add pull-to-refresh for history
- [ ] Add haptic feedback
- [ ] Add analytics tracking
- [ ] Error state UI
- [ ] Empty state UI

Success Metrics
Same as original:

Conversation initiation rate
Messages per conversation
Voice adoption rate
Return usage rate
Response latency (<200ms for voice)


This native iOS implementation of Lyra uses Swift 6, SwiftUI, modern concurrency, and Supabase for a production-grade AI parenting coach with both text and voice capabilities.
