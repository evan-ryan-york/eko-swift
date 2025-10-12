Lyra Implementation Plan

  Project Context

  Current State:
  - New Swift 6 iOS app with SwiftUI
  - Modular architecture: EkoCore (models/DTOs), EkoKit (UI components), Eko (main app)
  - Authentication flow complete with Supabase
  - Design system established (colors, spacing, typography)
  - Supabase backend configured with migrations/functions folders ready
  - ContentView is a placeholder - needs to be replaced with main navigation

  Lyra Feature Goal:
  - AI-powered parenting coach with text and voice chat
  - Accessible via bottom tab bar navigation
  - Hyper-personalized based on child profiles
  - Conversation history and long-term memory
  - Native iOS WebRTC for voice mode

  ---
  Implementation Plan

  Phase 1: Database Schema & Backend (Supabase)

  Dependencies: None - Start here first

  1.1 Database Migrations

  Create SQL migration files in supabase/migrations/:

  - 20251011000001_create_lyra_tables.sql
    - Create conversations table (id, user_id, child_id, status, title, timestamps)
    - Create messages table (id, conversation_id, role, content, sources, timestamp)
    - Create child_memory table (id, child_id, behavioral_themes, communication_strategies, significant_events)
    - Add Row Level Security (RLS) policies for all tables
    - Create indexes for performance optimization
    - Update children table to add temperament fields (talkative, sensitivity, accountability as integers)

  1.2 Edge Functions

  Create Supabase Edge Functions in supabase/functions/:

  - send-message/index.ts - Text chat streaming
    - Accept conversationId, message, childId
    - Fetch child context from Postgres
    - Build personalized system prompt
    - Call OpenAI GPT-4 with streaming
    - Return Server-Sent Events (SSE) stream
    - Save messages to database
  - create-conversation/index.ts - Start new conversation
    - Create conversation record
    - Return conversation ID
  - complete-conversation/index.ts - End conversation
    - Fetch all messages
    - Use GPT-4 to extract insights (behavioral themes, strategies)
    - Update child_memory table
    - Generate conversation title
    - Mark conversation as completed
  - create-realtime-session/index.ts - Voice mode setup
    - Accept SDP offer, conversationId, childId
    - Build voice system prompt with child context
    - Create multipart form request to OpenAI Realtime API
    - Return SDP answer and call ID

  Testing: Use Postman/cURL to test each endpoint independently

  ---
  Phase 2: Core iOS Services & Models

  Dependencies: Phase 1 complete (for integration testing)

  2.1 Extend EkoCore Models

  Location: EkoCore/Sources/EkoCore/Models/

  - Enhance Child.swift
    - Add computed property for LyraChildContext
    - Add temperament properties (if not using enum)
  - Create Message.swift
    - Message struct: id, role, content, timestamp, sources
    - MessageRole enum: user, assistant, system
    - Citation struct: id, title, url, excerpt
  - Create Conversation.swift
    - Conversation struct: id, userId, childId, status, title, timestamps
    - ConversationStatus enum: active, completed
  - Create LyraModels.swift
    - LyraChildContext struct for AI context
    - DTOs: CreateConversationDTO, SendMessageDTO, CompleteConversationDTO, CreateRealtimeSessionDTO

  2.2 iOS Services

  Location: Eko/Core/Services/

  - Enhance SupabaseService.swift
    - Add Supabase Functions client initialization
    - Add conversation methods:
        - createConversation(userId:childId:) async throws -> Conversation
      - getActiveConversation(userId:childId:) async throws -> Conversation?
      - getMessages(conversationId:) async throws -> [Message]
      - completeConversation(conversationId:) async throws
    - Add streaming method:
        - sendMessage(conversationId:message:childId:) async throws -> AsyncThrowingStream<String, Error>
  - Create RealtimeVoiceService.swift (rename from LiveKitService)
    - Add WebRTC iOS SDK via SPM: https://github.com/stasel/WebRTC
    - Implement WebRTC peer connection setup
    - @Observable class with status, transcripts
    - Methods: startSession(), endSession(), interrupt()
    - RTCPeerConnectionDelegate implementation
    - RTCDataChannelDelegate for OpenAI events
    - Audio session configuration (AVAudioSession)
    - Microphone permission handling
  - Create ModerationService.swift
    - Crisis keyword detection
    - Crisis resources (phone numbers, text lines)
    - checkForCrisis(_ text: String) -> Bool
    - getCrisisResources() -> String

  Testing: Unit tests for each service method

  ---
  Phase 3: SwiftUI Views & Components

  Dependencies: Phase 2 complete (services available)

  3.1 Core Lyra Views

  Location: Eko/Features/AIGuide/Views/

  - LyraView.swift - Main chat interface
    - NavigationStack wrapper
    - ScrollViewReader for auto-scroll
    - Voice banner (conditional)
    - Message list (LazyVStack)
    - Chat input bar
    - Toolbar with menu (history, complete conversation)
    - Sheet for conversation history
    - Task modifier to load active conversation
  - MessageBubbleView.swift - Individual message display
    - Different styling for user vs assistant
    - Citation/sources button
    - Timestamp
    - Expandable sources section
    - Animations for sources toggle
  - ChatInputBar.swift - Text input with controls
    - TextField with multi-line support
    - Voice button (microphone icon)
    - Send button (arrow icon)
    - Loading state (ProgressView)
    - Disabled states
  - VoiceBannerView.swift - Voice mode status
    - Status indicator (colored circle)
    - Live transcripts (user + AI)
    - Interrupt button
    - End session button
    - Color-coded status bar
  - ChatHistorySheet.swift - Completed conversations
    - List of past conversations
    - Conversation title and date
    - Navigation to past messages (read-only)
    - Pull-to-refresh
  - CitationView.swift - Source display
    - Link to source
    - Title and excerpt
    - Tappable for external navigation

  3.2 Supporting Components

  Location: EkoKit/Sources/EkoKit/Components/

  - TypingIndicatorView.swift - Loading animation
    - Animated dots (bounce effect)
    - Consistent with message bubbles

  ---
  Phase 4: ViewModel & Business Logic

  Dependencies: Phase 2 & 3 complete

  4.1 LyraViewModel

  Location: Eko/Features/AIGuide/ViewModels/

  - LyraViewModel.swift
    - @MainActor @Observable class
    - Properties:
        - messages: [Message]
      - isLoading: Bool
      - error: Error?
      - isVoiceMode: Bool
      - conversationId: UUID?
      - childId: UUID
    - Voice state computed properties:
        - voiceStatus, userTranscript, aiTranscript
    - Methods:
        - loadActiveConversation() async
      - sendMessage(_ text: String) async throws
      - startVoiceMode() async
      - endVoiceMode()
      - interruptAI()
      - completeConversation() async throws
    - Integration with RealtimeVoiceService
    - Crisis detection via ModerationService
    - Stream handling with AsyncThrowingStream

  Testing: ViewModel unit tests with mocked services

  ---
  Phase 5: Main App Navigation Integration

  Dependencies: Phase 3 & 4 complete

  5.1 Create Main TabView

  Location: Eko/

  - Replace ContentView.swift with main navigation:
    - TabView with bottom tabs
    - Home Tab - Dashboard/feed (placeholder for now)
    - Lyra Tab - LyraView with child picker
    - Library Tab - Content library (placeholder)
    - Profile Tab - Settings/profile (placeholder)
    - SF Symbol icons for each tab
    - Selection state management

  5.2 Child Profile Selection

  - Add child picker to Lyra navigation bar
    - Fetch children via SupabaseService
    - Header menu/picker for selecting active child
    - Pass selected childId to LyraViewModel

  5.3 Update EkoApp

  - Update EkoApp.swift to show new TabView after authentication

  ---
  Phase 6: Polish & Testing

  Dependencies: Phase 5 complete

  6.1 UX Enhancements

  - Haptic feedback on message send
  - Pull-to-refresh for chat history
  - Keyboard avoidance for input bar
  - Auto-scroll to newest message
  - Empty state when no active conversation
  - Error state UI with retry
  - Loading states throughout

  6.2 Error Handling

  - Network error recovery
  - WebRTC connection failures
  - Microphone permission denied
  - OpenAI API errors
  - User-friendly error messages
  - Retry mechanisms

  6.3 Info.plist Configuration

  Add to Eko/Info.plist:
  <key>NSMicrophoneUsageDescription</key>
  <string>Lyra needs microphone access for voice conversations.</string>

  <key>NSSpeechRecognitionUsageDescription</key>
  <string>Lyra uses speech recognition for voice conversations.</string>

  6.4 Analytics & Monitoring

  - Track conversation starts
  - Track message counts
  - Track voice mode usage
  - Track errors and crashes
  - Performance monitoring

  6.5 Testing

  - Unit tests for services
  - Unit tests for ViewModels
  - UI tests for critical flows
  - Test on physical device (voice mode)
  - Test different child profiles
  - Test error scenarios

  ---
  File Structure (New Files to Create)

  Eko/
  ├── Eko/
  │   ├── ContentView.swift (REPLACE - create TabView)
  │   ├── Core/Services/
  │   │   ├── RealtimeVoiceService.swift (NEW - rename LiveKitService)
  │   │   ├── ModerationService.swift (NEW)
  │   │   └── SupabaseService.swift (ENHANCE - add methods)
  │   └── Features/AIGuide/
  │       ├── Views/
  │       │   ├── LyraView.swift (NEW)
  │       │   ├── MessageBubbleView.swift (NEW)
  │       │   ├── ChatInputBar.swift (NEW)
  │       │   ├── VoiceBannerView.swift (NEW)
  │       │   ├── ChatHistorySheet.swift (NEW)
  │       │   └── CitationView.swift (NEW)
  │       └── ViewModels/
  │           └── LyraViewModel.swift (NEW)
  │
  ├── EkoCore/Sources/EkoCore/
  │   ├── Models/
  │   │   ├── Child.swift (ENHANCE)
  │   │   ├── Message.swift (NEW)
  │   │   ├── Conversation.swift (NEW)
  │   │   └── LyraModels.swift (NEW)
  │   └── DTOs/
  │       └── LyraDTO.swift (NEW)
  │
  ├── EkoKit/Sources/EkoKit/
  │   └── Components/
  │       └── TypingIndicatorView.swift (NEW)
  │
  └── supabase/
      ├── migrations/
      │   └── 20251011000001_create_lyra_tables.sql (NEW)
      └── functions/
          ├── send-message/ (NEW)
          ├── create-conversation/ (NEW)
          ├── complete-conversation/ (NEW)
          └── create-realtime-session/ (NEW)

  ---
  External Dependencies to Add

  Add via Xcode → File → Add Package Dependencies:

  1. WebRTC for iOS
    - URL: https://github.com/stasel/WebRTC
    - Version: Latest
    - For native voice mode

  ---
  Testing Strategy

  Development Testing

  1. Backend First: Test Edge Functions with Postman before iOS integration
  2. Services Layer: Unit test each service independently with mocks
  3. ViewModel: Test business logic with mocked services
  4. UI: Build views incrementally, test in SwiftUI previews

  Integration Testing

  1. Text chat flow end-to-end
  2. Voice mode on physical device (simulator doesn't support microphone well)
  3. Conversation completion and memory updates
  4. History viewing
  5. Child context personalization

  Edge Cases

  - Network failures mid-conversation
  - Voice connection drops
  - Microphone permission denied
  - Long conversations (performance)
  - Multiple children switching
  - Crisis keyword detection

  ---
  Implementation Order Summary

  1. ✅ Phase 1: Database & Edge Functions (backend ready)
  2. ✅ Phase 2: iOS Services & Models (infrastructure)
  3. ✅ Phase 3: SwiftUI Views (UI components)
  4. ✅ Phase 4: ViewModel (business logic)
  5. ✅ Phase 5: Navigation Integration (wire it up)
  6. ✅ Phase 6: Polish & Testing (production-ready)

  ---
  Estimated Timeline

  - Phase 1: 2-3 hours (SQL + Edge Functions)
  - Phase 2: 3-4 hours (Services + Models)
  - Phase 3: 3-4 hours (SwiftUI Views)
  - Phase 4: 2-3 hours (ViewModel)
  - Phase 5: 1-2 hours (Navigation)
  - Phase 6: 2-3 hours (Polish + Testing)

  Total: 13-19 hours of focused development time

  ---
  Critical Success Factors

  1. Backend First: Get Edge Functions working before iOS integration
  2. Incremental: Build and test each layer independently
  3. Services: Keep business logic in services, ViewModels stay thin
  4. Async/Await: Use modern Swift concurrency throughout
  5. Error Handling: Every async call needs proper error handling
  6. Voice Testing: Test voice mode on real device early
  7. Child Context: Ensure temperament data flows from DB → AI prompts
