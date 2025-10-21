# Eko App - Architecture Documentation

> **Last Updated**: January 2025
> **Status**: Phase 2 - iOS Implementation In Progress

## Table of Contents

1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Project Layout](#project-layout)
4. [Core Architectural Patterns](#core-architectural-patterns)
5. [Data Models & Domain](#data-models--domain)
6. [Database Schema](#database-schema)
7. [Backend Architecture](#backend-architecture)
8. [Design System](#design-system)
9. [Key Features & Status](#key-features--status)
10. [Configuration & Environment](#configuration--environment)

---

## Overview

Eko is a production-grade iOS application built with modern Swift patterns, targeting parents of children ages 6-16 with AI-powered conversation coaching. The app uses a clean MVVM architecture with SwiftUI, backed by Supabase (PostgreSQL) and integrating OpenAI's Realtime API for conversational AI features.

**Core Philosophy**:
- Modern Swift 6 with strict concurrency
- Protocol-oriented design for testability
- Unidirectional data flow
- Feature-based module organization
- Comprehensive state management

---

## Tech Stack

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| **Swift** | 6.0 | Primary language |
| **SwiftUI** | iOS 17.0+ | UI framework |
| **Observation Framework** | Native | State management (@Observable) |
| **Swift Package Manager** | Native | Dependency management |

### Backend & Services

| Service | Version | Purpose |
|---------|---------|---------|
| **Supabase** | v2.5.1+ | Backend platform (Auth, Database, Functions) |
| **PostgreSQL** | 17 | Primary database |
| **OpenAI Realtime API** | Latest | AI conversation engine |
| **WebRTC** | 120.0.0 | Real-time communication |
| **LiveKit SDK** | Latest | Voice conversation infrastructure |
| **RevenueCat** | Latest | Subscription management |

### Key SDKs

```swift
// Swift Package Dependencies
- Supabase Swift SDK (Auth, PostgREST, Functions, Realtime, Storage)
- WebRTC (120.0.0)
- EkoCore (local) - Models & DTOs
- EkoKit (local) - UI Components & Design System
```

---

## Project Layout

```
Eko/
├── Eko.xcodeproj/                        # Xcode project configuration
│
├── Eko/                                   # Main iOS app target
│   ├── EkoApp.swift                       # App entry point (@main)
│   ├── RootView.swift                     # Root navigation coordinator
│   ├── ContentView.swift                  # Main app view
│   │
│   ├── Core/                              # Shared infrastructure
│   │   ├── Services/                      # Business logic services
│   │   │   ├── SupabaseService.swift      # Central backend service (singleton)
│   │   │   ├── SupabaseServiceProtocol.swift  # Service interface for DI
│   │   │   ├── AudioService.swift         # Audio input/output management
│   │   │   ├── LiveKitService.swift       # LiveKit WebRTC integration
│   │   │   ├── RealtimeVoiceService.swift # OpenAI Realtime API wrapper
│   │   │   └── ModerationService.swift    # Content safety checks
│   │   ├── Network/
│   │   │   └── NetworkError.swift         # Centralized error definitions
│   │   ├── Extensions/                    # Swift/SwiftUI extensions
│   │   ├── Config.swift                   # Environment configuration (.gitignored)
│   │   └── AuthError.swift                # Auth-specific errors
│   │
│   ├── Features/                          # Feature modules (organized by domain)
│   │   ├── Authentication/
│   │   │   ├── Views/
│   │   │   │   ├── LoginView.swift
│   │   │   │   └── SignUpView.swift
│   │   │   └── ViewModels/
│   │   │       └── AuthViewModel.swift    # Authentication business logic
│   │   │
│   │   ├── Onboarding/                    # Comprehensive onboarding flow
│   │   │   ├── Views/
│   │   │   │   ├── OnboardingContainerView.swift   # Container & navigation
│   │   │   │   ├── UserInfoView.swift              # Step 1: Parent name
│   │   │   │   ├── ChildInfoView.swift             # Step 2: Child details
│   │   │   │   ├── GoalsView.swift                 # Step 3: Parenting goals
│   │   │   │   ├── TopicsView.swift                # Step 4: Conversation topics
│   │   │   │   ├── DispositionsView.swift          # Step 5: Child temperament
│   │   │   │   └── ReviewView.swift                # Step 6: Final review
│   │   │   └── ViewModels/
│   │   │       └── OnboardingViewModel.swift       # State machine controller
│   │   │
│   │   ├── AIGuide/                       # Lyra feature (AI conversation coach)
│   │   │   ├── Views/
│   │   │   │   ├── LyraView.swift         # Main chat interface
│   │   │   │   ├── MessageBubbleView.swift
│   │   │   │   ├── ChatInputBar.swift
│   │   │   │   ├── ChatHistorySheet.swift
│   │   │   │   └── VoiceBannerView.swift  # Voice mode indicator
│   │   │   └── ViewModels/
│   │   │       └── LyraViewModel.swift    # Chat logic & AI interaction
│   │   │
│   │   └── Profile/
│   │       └── Views/
│   │           └── AddChildView.swift
│   │
│   ├── Assets/                            # Images, fonts, colors
│   │   ├── Fonts/                         # Urbanist variable fonts
│   │   └── Assets.xcassets/               # App icons, color sets
│   │
│   ├── Resources/
│   │   └── Info.plist                     # App configuration
│   │
│   └── Tests/                             # Unit & integration tests
│       ├── Features/
│       │   ├── OnboardingViewModelTests.swift
│       │   └── OnboardingStateTests.swift
│       ├── Core/
│       │   ├── ConversationTopicTests.swift
│       │   └── SupabaseServiceIntegrationTests.swift
│       ├── Mocks/
│       │   └── MockSupabaseService.swift
│       └── Fixtures/
│           └── TestFixtures.swift
│
├── EkoCore/                               # Swift Package: Core Models & DTOs
│   └── Sources/EkoCore/
│       ├── Models/                        # Domain models
│       │   ├── User.swift                 # User profile
│       │   ├── Child.swift                # Child data model
│       │   ├── Conversation.swift         # Chat conversations
│       │   ├── Message.swift              # Chat messages
│       │   ├── OnboardingState.swift      # Onboarding state machine enum
│       │   ├── ConversationTopic.swift    # Topic categories
│       │   ├── UserProfile.swift          # Extended profile
│       │   ├── LyraModels.swift           # AI context & DTOs
│       │   └── Temperament.swift          # Child personality traits enum
│       └── DTOs/                          # Data transfer objects
│           └── AuthDTO.swift              # Auth request/response shapes
│
├── EkoKit/                                # Swift Package: UI Components & Design System
│   └── Sources/EkoKit/
│       ├── Components/                    # Reusable UI components
│       │   ├── Buttons/
│       │   │   ├── PrimaryButton.swift
│       │   │   └── SecondaryButton.swift
│       │   ├── Forms/
│       │   │   └── FormTextField.swift
│       │   └── TypingIndicatorView.swift
│       └── DesignSystem/                  # Design tokens
│           ├── Colors.swift               # Brand color palette
│           ├── Typography.swift           # Urbanist font styles
│           ├── Spacing.swift              # Standard spacing constants
│           └── Shadows.swift              # Shadow definitions
│
├── supabase/                              # Backend configuration
│   ├── config.toml                        # Supabase CLI settings
│   ├── migrations/                        # Database schema versions
│   │   ├── 20251011000000_create_base_tables.sql
│   │   │   └── children table with RLS
│   │   ├── 20251011000001_create_lyra_tables.sql
│   │   │   ├── conversations table
│   │   │   ├── messages table
│   │   │   ├── child_memory table (long-term AI context)
│   │   │   └── Helper functions for memory management
│   │   └── 20251019000001_backfill_user_profiles.sql
│   └── functions/                         # Supabase Edge Functions (TypeScript/Deno)
│       ├── create-conversation/
│       ├── send-message/
│       ├── complete-conversation/
│       └── create-realtime-session/
│
└── docs/                                  # Project documentation
    ├── ai/
    │   ├── project-wide/
    │   │   ├── project-overview.md        # Feature roadmap
    │   │   ├── testing-strategy.md        # Testing approach
    │   │   └── architecture.md            # This file
    │   └── features/                      # Feature-specific docs
    │       ├── onboarding/
    │       ├── lyra/                      # AI chat feature docs
    │       └── daily-practice/
    └── design/                            # Design system documentation
```

---

## Core Architectural Patterns

### 1. Navigation & Routing Architecture

**RootView Coordinator Pattern** (`RootView.swift`):

Eko uses a centralized navigation coordinator that evaluates three hierarchical states to determine the app's routing:

```swift
@MainActor
struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        if !authViewModel.isAuthenticated {
            LoginView()  // State 1: Not authenticated
        } else if !authViewModel.hasCompletedOnboarding {
            OnboardingContainerView()  // State 2: Authenticated, incomplete onboarding
        } else {
            ContentView()  // State 3: Ready for main app
        }
    }
}
```

**State-Based Navigation**:
- Navigation flows are driven by state enums, not imperative navigation calls
- `OnboardingState` enum acts as a finite state machine
- Valid transitions enforced at compile-time

**OnboardingState State Machine**:
```swift
enum OnboardingState: String, Codable {
    case notStarted = "NOT_STARTED"
    case userInfo = "USER_INFO"
    case childInfo = "CHILD_INFO"
    case goals = "GOALS"
    case topics = "TOPICS"
    case dispositions = "DISPOSITIONS"
    case review = "REVIEW"
    case complete = "COMPLETE"

    func next() -> OnboardingState? { ... }
    func previous() -> OnboardingState? { ... }
}
```

### 2. State Management Pattern

**Modern Swift Observation Framework** (Swift 6):

Eko uses the `@Observable` macro (introduced in iOS 17) instead of the older `ObservableObject` protocol. This provides:
- Automatic dependency tracking
- Better performance (only observed properties trigger updates)
- Cleaner syntax (no `@Published` wrappers needed)

```swift
@MainActor
@Observable
final class AuthViewModel {
    var isAuthenticated: Bool = false
    var currentUser: User?
    var isLoading: Bool = false

    private let supabaseService: SupabaseServiceProtocol

    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }

    func signInWithGoogle() async throws { ... }
}
```

**Key Principles**:
- All ViewModels marked `@MainActor` to ensure UI updates on main thread
- ViewModels are the single source of truth for feature state
- Views are purely declarative and stateless (except for local UI state)
- Services are injected via protocols for testability

**ViewModel Responsibilities**:
- Business logic execution
- Service orchestration
- State management
- Error handling
- Validation

**View Responsibilities**:
- Rendering UI based on ViewModel state
- Capturing user input
- Triggering ViewModel methods
- Local animation state only

### 3. Service Layer Architecture

**SupabaseService Singleton Pattern**:

All backend communication flows through a centralized `SupabaseService` singleton:

```swift
@MainActor
final class SupabaseService: SupabaseServiceProtocol {
    static let shared = SupabaseService()

    private let client: SupabaseClient
    private var authClient: AuthClient { client.auth }
    private var postgrestClient: PostgrestClient { client.database }
    private var functionsClient: FunctionsClient { client.functions }

    // Authentication
    func signInWithGoogle() async throws -> User { ... }

    // Database Operations
    func fetchChildren(userId: UUID) async throws -> [Child] { ... }

    // Edge Functions
    func createConversation(childId: UUID) async throws -> Conversation { ... }
}
```

**Protocol-Based Dependency Injection**:

```swift
protocol SupabaseServiceProtocol {
    func signInWithGoogle() async throws -> User
    func fetchChildren(userId: UUID) async throws -> [Child]
    // ... all public methods
}

// ViewModels depend on protocol, not concrete implementation
class AuthViewModel {
    private let supabaseService: SupabaseServiceProtocol

    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
}

// Testing with mock
class MockSupabaseService: SupabaseServiceProtocol {
    func signInWithGoogle() async throws -> User {
        return TestFixtures.mockUser()
    }
}
```

**Service Responsibilities**:
- API communication (REST, Edge Functions)
- Authentication token management
- Row Level Security (RLS) enforcement
- Data transformation (JSON ↔ Model)
- Network error handling

**Other Specialized Services**:
- `AudioService` - Microphone/speaker permissions & management
- `LiveKitService` - WebRTC connection handling
- `RealtimeVoiceService` - OpenAI Realtime API integration
- `ModerationService` - Content safety & filtering

### 4. Data Flow Architecture

**Unidirectional Data Flow (MVVM)**:

```
┌─────────────────────────────────────────────────────────┐
│                     View (SwiftUI)                      │
│  - Renders UI based on ViewModel state                  │
│  - Captures user interactions                           │
└────────────────────┬────────────────────────────────────┘
                     │ User Actions (button taps, etc.)
                     ↓
┌─────────────────────────────────────────────────────────┐
│              ViewModel (@Observable)                     │
│  - Holds feature state                                   │
│  - Contains business logic                               │
│  - Orchestrates service calls                            │
└────────────────────┬────────────────────────────────────┘
                     │ Method Calls (async)
                     ↓
┌─────────────────────────────────────────────────────────┐
│          Service (SupabaseService, etc.)                 │
│  - Handles API communication                             │
│  - Manages authentication                                │
│  - Transforms data                                       │
└────────────────────┬────────────────────────────────────┘
                     │ API Calls (HTTP, WebSocket)
                     ↓
┌─────────────────────────────────────────────────────────┐
│           Supabase Backend (Database/Functions)          │
│  - PostgreSQL database                                   │
│  - Edge Functions (OpenAI integration)                   │
│  - Row Level Security                                    │
└────────────────────┬────────────────────────────────────┘
                     │ Responses
                     ↓
┌─────────────────────────────────────────────────────────┐
│              ViewModel (@Observable)                     │
│  - Updates state properties                              │
│  - Triggers reactive updates                             │
└────────────────────┬────────────────────────────────────┘
                     │ State Changes (automatic)
                     ↓
┌─────────────────────────────────────────────────────────┐
│                     View (SwiftUI)                       │
│  - Re-renders automatically                              │
└─────────────────────────────────────────────────────────┘
```

**Example Flow: Onboarding Progression**

1. **User Action**: User enters their name in `UserInfoView` and taps "Next"
   ```swift
   Button("Next") {
       Task { await viewModel.moveToNextStep() }
   }
   ```

2. **ViewModel Processing**: `OnboardingViewModel.moveToNextStep()` validates and saves
   ```swift
   func moveToNextStep() async {
       guard validateCurrentStep() else { return }
       await saveCurrentStepData()  // Calls SupabaseService
       currentState = currentState.next() ?? currentState
   }
   ```

3. **Service Call**: `SupabaseService.updateDisplayName()` hits API
   ```swift
   func updateDisplayName(userId: UUID, name: String) async throws {
       try await client.database
           .from("users")
           .update(["display_name": name])
           .eq("id", value: userId.uuidString)
           .execute()
   }
   ```

4. **State Update**: ViewModel updates `currentState`, triggering view re-render
   ```swift
   @Observable
   class OnboardingViewModel {
       var currentState: OnboardingState = .notStarted  // Change triggers UI update
   }
   ```

5. **View Re-render**: `OnboardingContainerView` switches to next step
   ```swift
   switch viewModel.currentState {
       case .userInfo: UserInfoView()
       case .childInfo: ChildInfoView()  // ← New view shown
       // ...
   }
   ```

### 5. Dependency Injection Pattern

**Environment-Based Injection**:

```swift
@main
struct EkoApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)  // Inject into environment
        }
    }
}

// Access in child views
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
}
```

**Constructor Injection (Services)**:

```swift
class OnboardingViewModel {
    private let supabaseService: SupabaseServiceProtocol

    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
}

// Testing with mock
let viewModel = OnboardingViewModel(supabaseService: MockSupabaseService())
```

---

## Data Models & Domain

### Core Models (EkoCore Package)

All domain models live in the `EkoCore` Swift Package for reusability and clear domain boundaries.

#### User Model

```swift
struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    var displayName: String?
    var onboardingState: OnboardingState
    var currentChildId: UUID?
    var avatarURL: URL?
    let createdAt: Date
    let updatedAt: Date
}
```

**Purpose**: Represents a parent user in the system.

#### Child Model

```swift
struct Child: Identifiable, Codable {
    let id: UUID
    let userId: UUID  // Foreign key to parent
    var name: String
    var age: Int
    var birthday: Date
    var goals: [String]
    var topics: [String]
    var temperament: Temperament
    var temperamentTalkative: Int  // 1-10 scale
    var temperamentSensitivity: Int  // 1-10 scale
    var temperamentAccountability: Int  // 1-10 scale
    let createdAt: Date
    let updatedAt: Date
}

enum Temperament: String, Codable, CaseIterable {
    case easygoing = "easygoing"
    case sensitive = "sensitive"
    case spirited = "spirited"
    case cautious = "cautious"
}
```

**Purpose**: Represents a child profile with personality traits for AI personalization.

#### Conversation Model (Lyra Feature)

```swift
struct Conversation: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let childId: UUID
    var status: ConversationStatus
    var title: String?
    let createdAt: Date
    var updatedAt: Date
}

enum ConversationStatus: String, Codable {
    case active = "active"
    case completed = "completed"
}
```

**Purpose**: Represents a chat session between parent and Lyra AI coach.

#### Message Model

```swift
struct Message: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let role: MessageRole
    let content: String
    let sources: [Citation]?  // Research citations from AI
    let createdAt: Date
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

struct Citation: Codable {
    let title: String
    let url: URL
    let excerpt: String?
}
```

**Purpose**: Individual chat messages with optional research citations.

#### Child Memory Model (AI Context)

```swift
struct ChildMemory: Identifiable, Codable {
    let id: UUID
    let childId: UUID  // One-to-one relationship
    var behavioralThemes: [BehavioralTheme]
    var communicationStrategies: [CommunicationStrategy]
    var significantEvents: [SignificantEvent]
    var updatedAt: Date
}

struct BehavioralTheme: Codable {
    let theme: String
    let observations: [String]
    let frequency: String  // "rare", "occasional", "frequent"
}

struct CommunicationStrategy: Codable {
    let strategy: String
    let context: String
    let effectiveness: String  // "low", "medium", "high"
}

struct SignificantEvent: Codable {
    let event: String
    let date: Date
    let impact: String
}
```

**Purpose**: Long-term memory for AI to personalize conversations based on past interactions.

### State Machine: OnboardingState

```swift
enum OnboardingState: String, Codable, CaseIterable {
    case notStarted = "NOT_STARTED"
    case userInfo = "USER_INFO"
    case childInfo = "CHILD_INFO"
    case goals = "GOALS"
    case topics = "TOPICS"
    case dispositions = "DISPOSITIONS"
    case review = "REVIEW"
    case complete = "COMPLETE"

    /// Returns next valid state, or nil if at end
    func next() -> OnboardingState? {
        let allCases = Self.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex + 1 < allCases.count else {
            return nil
        }
        return allCases[currentIndex + 1]
    }

    /// Returns previous valid state, or nil if at start
    func previous() -> OnboardingState? {
        let allCases = Self.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex > 0 else {
            return nil
        }
        return allCases[currentIndex - 1]
    }

    var canGoBack: Bool {
        self != .notStarted && self != .review
    }
}
```

**Flow**: NOT_STARTED → USER_INFO → CHILD_INFO → GOALS → TOPICS → DISPOSITIONS → REVIEW → COMPLETE

**Validation**: State transitions are validated. Cannot skip steps or move to invalid states.

---

## Database Schema

Eko uses **PostgreSQL 17** via Supabase with **Row Level Security (RLS)** enforced on all tables.

### Tables Overview

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `auth.users` | User accounts (Supabase Auth) | - |
| `children` | Child profiles | FK: `user_id` → `auth.users` |
| `conversations` | Chat sessions | FK: `user_id`, `child_id` |
| `messages` | Chat messages | FK: `conversation_id` |
| `child_memory` | AI long-term context | FK: `child_id` (UNIQUE) |

### Schema Details

#### children Table

```sql
CREATE TABLE children (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 0 AND age <= 18),
    birthday DATE NOT NULL,
    goals TEXT[] DEFAULT '{}',
    topics TEXT[] DEFAULT '{}',
    temperament TEXT NOT NULL CHECK (temperament IN ('easygoing', 'sensitive', 'spirited', 'cautious')),
    temperament_talkative INTEGER CHECK (temperament_talkative >= 1 AND temperament_talkative <= 10),
    temperament_sensitivity INTEGER CHECK (temperament_sensitivity >= 1 AND temperament_sensitivity <= 10),
    temperament_accountability INTEGER CHECK (temperament_accountability >= 1 AND temperament_accountability <= 10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_children_user_id ON children(user_id);
CREATE INDEX idx_children_age ON children(age);

-- Row Level Security
ALTER TABLE children ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own children"
    ON children FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own children"
    ON children FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own children"
    ON children FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own children"
    ON children FOR DELETE
    USING (auth.uid() = user_id);
```

#### conversations Table (Lyra Feature)

```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed')),
    title TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conversations_user_child_status
    ON conversations(user_id, child_id, status, updated_at DESC);

-- Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own conversations"
    ON conversations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversations"
    ON conversations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own conversations"
    ON conversations FOR UPDATE
    USING (auth.uid() = user_id);
```

#### messages Table

```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    sources JSONB,  -- Array of citations: [{title, url, excerpt}]
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_created
    ON messages(conversation_id, created_at DESC);

-- Row Level Security (inherit from parent conversation)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages from own conversations"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert messages to own conversations"
    ON messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- NOTE: No UPDATE or DELETE policies - messages are append-only for audit trail
```

#### child_memory Table (AI Context)

```sql
CREATE TABLE child_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL UNIQUE REFERENCES children(id) ON DELETE CASCADE,
    behavioral_themes JSONB NOT NULL DEFAULT '[]',
    communication_strategies JSONB NOT NULL DEFAULT '[]',
    significant_events JSONB NOT NULL DEFAULT '[]',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- GIN indexes for fast JSONB queries
CREATE INDEX idx_child_memory_behavioral_themes
    ON child_memory USING GIN (behavioral_themes);
CREATE INDEX idx_child_memory_communication_strategies
    ON child_memory USING GIN (communication_strategies);
CREATE INDEX idx_child_memory_significant_events
    ON child_memory USING GIN (significant_events);

-- Row Level Security
ALTER TABLE child_memory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view memory for own children"
    ON child_memory FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = child_memory.child_id
            AND children.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update memory for own children"
    ON child_memory FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM children
            WHERE children.id = child_memory.child_id
            AND children.user_id = auth.uid()
        )
    );
```

### Automatic Timestamp Updates

All tables with `updated_at` columns use this trigger:

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_children_updated_at
    BEFORE UPDATE ON children
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Similar triggers for conversations, child_memory, etc.
```

### Row Level Security (RLS) Strategy

**Principle**: Users can only access their own data, enforced at the database level.

**Implementation**:
1. All tables have RLS enabled
2. Policies check `auth.uid()` (current user's JWT token)
3. Foreign key relationships enforce cascading permissions
4. Supabase SDK automatically includes JWT in all requests

**Benefits**:
- Defense in depth (security at DB layer, not just app layer)
- Cannot be bypassed by malicious clients
- Centralized authorization logic
- Audit-friendly

---

## Backend Architecture

### Supabase Edge Functions

Eko uses **Supabase Edge Functions** (Deno/TypeScript) for server-side logic, particularly AI integration.

#### 1. create-conversation

**Purpose**: Initialize a new chat session and ensure child memory exists.

**Request**:
```typescript
{
  childId: string  // UUID
}
```

**Logic**:
1. Verify user owns the child (RLS check)
2. Create new conversation record (status: 'active')
3. Check if `child_memory` exists for child
4. If not, initialize empty memory record
5. Return conversation ID

**Response**:
```typescript
{
  conversationId: string,
  childMemory: ChildMemory
}
```

#### 2. send-message

**Purpose**: Process user message, get AI response, stream back to client.

**Request**:
```typescript
{
  conversationId: string,
  message: string,
  childContext: {
    age: number,
    temperament: string,
    goals: string[],
    topics: string[]
  }
}
```

**Logic**:
1. Verify user owns conversation (RLS check)
2. Fetch child_memory for context
3. Insert user message into `messages` table
4. Build OpenAI prompt with:
   - System prompt (Lyra persona)
   - Child context (age, temperament, goals)
   - Child memory (behavioral themes, strategies)
   - Conversation history (last N messages)
5. Call OpenAI Chat Completions API (streaming)
6. Stream response back to client (SSE)
7. Insert assistant message into `messages` table
8. Return final message

**Response**: Server-Sent Events (SSE) stream of text chunks

#### 3. complete-conversation

**Purpose**: Mark conversation complete, extract insights, update child memory.

**Request**:
```typescript
{
  conversationId: string
}
```

**Logic**:
1. Verify user owns conversation
2. Fetch all messages from conversation
3. Call OpenAI to analyze conversation and extract:
   - New behavioral themes
   - Effective communication strategies
   - Significant events mentioned
4. Merge insights into existing `child_memory` (JSONB update)
5. Update conversation status to 'completed'
6. Return updated memory

**Response**:
```typescript
{
  updatedMemory: ChildMemory
}
```

#### 4. create-realtime-session

**Purpose**: Initialize OpenAI Realtime API session for voice mode (future feature).

**Request**:
```typescript
{
  conversationId: string
}
```

**Logic**:
1. Verify user owns conversation
2. Create ephemeral token for OpenAI Realtime API
3. Return WebRTC SDP offer and token
4. Client establishes WebRTC connection
5. Voice audio streams directly to OpenAI

**Response**:
```typescript
{
  ephemeralKey: string,
  sdpOffer: string
}
```

### Edge Function Deployment

```bash
# Deploy single function
supabase functions deploy send-message

# Deploy all functions
supabase functions deploy
```

**Environment Variables** (set in Supabase Dashboard):
- `OPENAI_API_KEY` - OpenAI API key for AI responses
- `OPENAI_MODEL` - Model to use (e.g., "gpt-4o")

---

## Design System

### EkoKit Package

All UI components and design tokens are centralized in the `EkoKit` Swift Package for consistency and reusability.

### Typography (Urbanist Font)

```swift
public enum Typography {
    public static func display() -> Font {
        .custom("Urbanist-Bold", size: 34)
    }

    public static func title1() -> Font {
        .custom("Urbanist-Bold", size: 28)
    }

    public static func title2() -> Font {
        .custom("Urbanist-SemiBold", size: 22)
    }

    public static func title3() -> Font {
        .custom("Urbanist-SemiBold", size: 20)
    }

    public static func headline() -> Font {
        .custom("Urbanist-SemiBold", size: 17)
    }

    public static func body() -> Font {
        .custom("Urbanist-Regular", size: 17)
    }

    public static func subheadline() -> Font {
        .custom("Urbanist-Regular", size: 15)
    }

    public static func callout() -> Font {
        .custom("Urbanist-Regular", size: 16)
    }

    public static func footnote() -> Font {
        .custom("Urbanist-Regular", size: 13)
    }

    public static func caption() -> Font {
        .custom("Urbanist-Regular", size: 12)
    }
}
```

**Font Weights Available**:
- Regular (400)
- SemiBold (600)
- Bold (700)

**Variable Font**: Urbanist supports variable font axes for fluid weight adjustments.

### Colors

```swift
public enum Colors {
    // Primary brand colors
    public static let primary = Color("Primary")  // Main brand color
    public static let secondary = Color("Secondary")
    public static let tertiary = Color("Tertiary")

    // Text colors
    public static let labelPrimary = Color.primary
    public static let labelSecondary = Color.secondary

    // Background colors
    public static let backgroundPrimary = Color("BackgroundPrimary")
    public static let backgroundSecondary = Color("BackgroundSecondary")

    // Semantic colors
    public static let success = Color.green
    public static let error = Color.red
    public static let warning = Color.orange
}
```

**Light/Dark Mode**: All colors defined in `Assets.xcassets` with separate light/dark variants.

### Spacing

```swift
public enum Spacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}
```

### Shadows

```swift
public enum Shadows {
    public static let small = Shadow(
        color: .black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )

    public static let medium = Shadow(
        color: .black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )

    public static let large = Shadow(
        color: .black.opacity(0.2),
        radius: 16,
        x: 0,
        y: 8
    )
}
```

### Reusable Components

#### PrimaryButton

```swift
public struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool

    public var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
                    .font(Typography.headline())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Colors.primary)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(isLoading)
    }
}
```

#### FormTextField

```swift
public struct FormTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let error: String?

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.subheadline())
                .foregroundColor(Colors.labelSecondary)

            TextField(placeholder, text: $text)
                .font(Typography.body())
                .padding(Spacing.md)
                .background(Colors.backgroundSecondary)
                .cornerRadius(8)
                .keyboardType(keyboardType)
                .autocapitalization(.none)

            if let error = error {
                Text(error)
                    .font(Typography.footnote())
                    .foregroundColor(Colors.error)
            }
        }
    }
}
```

---

## Key Features & Status

### Phase 1: Backend Foundation ✅ COMPLETE

**Completed**:
- PostgreSQL database schema with RLS
- Authentication (email/password, Google OAuth)
- Edge Functions (create-conversation, send-message, complete-conversation)
- Database migrations
- Child memory system

**Deployed**: Production Supabase instance

### Phase 2: iOS Implementation 🚧 IN PROGRESS

#### 1. Authentication ✅ COMPLETE

**Features**:
- Google OAuth login
- Email/password signup/login
- Session persistence
- Automatic token refresh

**Implementation**: `Features/Authentication/`

#### 2. Onboarding ✅ COMPLETE

**Features**:
- 8-step guided flow
- Parent name collection
- Child profile creation (name, age, birthday)
- Goals selection (predefined + custom)
- Topics selection (conversation subjects)
- Temperament assessment (4 types + 3 sliders)
- Review & confirmation
- State persistence across app launches

**Implementation**: `Features/Onboarding/`

**State Machine**: `OnboardingState` enum enforces valid transitions

#### 3. Lyra (AI Conversation Coach) 🚧 IN PROGRESS

**Text Chat** ✅ COMPLETE:
- Real-time chat interface
- Message streaming
- Conversation history
- Child context integration
- Memory-based personalization
- Research citations

**Voice Mode** 📋 PLANNED:
- WebRTC integration
- OpenAI Realtime API
- Voice input/output
- Real-time transcription
- Interruption handling

**Implementation**: `Features/AIGuide/`

### Phase 3: Core Features 📋 PLANNED

#### 1. Conversation Playbook

**Description**: Library of 11 conversation categories with age-appropriate scenarios.

**Categories**:
- Empathy & Emotional Intelligence
- Communication & Listening
- Problem-Solving & Decision Making
- Resilience & Coping
- Values & Ethics
- Relationships & Boundaries
- Identity & Self-Esteem
- Responsibility & Accountability
- Growth Mindset & Learning
- Health & Wellness
- Digital Literacy & Safety

**Features**:
- Browse by category
- Filter by child age
- Bookmark favorites
- Track completed conversations

#### 2. Daily Practice

**Description**: Gamified scenarios for skill-building.

**Features**:
- Daily scenario generation
- Skill progression tracking
- Streaks & achievements
- XP and leveling system
- Practice reminders

#### 3. Practice Simulator (Voice)

**Description**: AI-generated child voice for safe practice.

**Features**:
- Voice synthesis (child voice)
- Scenario-based practice
- Real-time feedback
- Replay & analysis
- Age-appropriate responses

#### 4. Post-Conversation Reflection

**Description**: Guided reflection after real conversations.

**Features**:
- Structured prompts
- Insight extraction
- Progress tracking
- Memory updates

#### 5. Push Notifications

**Features**:
- Daily practice reminders
- Conversation suggestions
- Achievement notifications
- Personalized tips

#### 6. Subscription & Payments (RevenueCat)

**Tiers**:
- Free: Limited daily practice
- Premium: Unlimited access + advanced features

### Testing Status ✅ ESTABLISHED

**Current Coverage**:
- OnboardingViewModel tests
- OnboardingState state machine tests
- SupabaseService integration tests
- Conversation model tests

**Infrastructure**:
- Test fixtures for consistent data
- Mock services for unit testing
- XCTest framework

---

## Configuration & Environment

### Supabase Configuration

**Project Details**:
- URL: `https://fqecsmwycvltpnqawtod.supabase.co`
- Project Name: "Eko"
- Region: US East
- Database: PostgreSQL 17

**Authentication Providers**:
- Email/Password
- Google OAuth 2.0

**OAuth Callback URL**: `com.estuarystudios.eko://oauth/callback`

### iOS Project Configuration

**Xcode Settings**:
- Swift Version: 6.0
- iOS Deployment Target: 17.6+
- Bundle ID: `com.estuarystudios.Eko`
- Development Team: WDDXQKN8VJ

**Info.plist Keys**:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.estuarystudios.eko</string>
        </array>
    </dict>
</array>
```

### Environment Variables (Config.swift)

```swift
enum Config {
    static let supabaseURL = "https://fqecsmwycvltpnqawtod.supabase.co"
    static let supabaseAnonKey = "..." // From Supabase dashboard

    static let googleOAuthRedirectURL = "com.estuarystudios.eko://oauth/callback"

    // Future integrations
    static let liveKitURL = ""  // TBD
    static let revenueCatAPIKey = ""  // TBD
    static let openAIAPIKey = ""  // Server-side only
}
```

**Security**: `Config.swift` is `.gitignored` to prevent credential leaks.

### Build Configuration

**Debug**:
- Logging enabled
- Network request logging
- Fast builds (no optimizations)

**Release**:
- Optimizations enabled
- Logging disabled
- Code signing for App Store

---

## Development Workflow

### Local Development

1. **Backend**: Run local Supabase instance
   ```bash
   npx supabase start
   npx supabase db reset  # Reset local database
   ```

2. **iOS**: Build and run in Xcode
   - Select simulator/device
   - Cmd+R to build and run
   - Use breakpoints for debugging

3. **Edge Functions**: Test locally
   ```bash
   npx supabase functions serve send-message
   ```

### Testing

```bash
# Run all tests
xcodebuild test -scheme Eko -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test
xcodebuild test -scheme Eko -only-testing:EkoTests/OnboardingViewModelTests
```

### Deployment

**Backend** (Supabase):
```bash
# Push database migrations
npx supabase db push

# Deploy Edge Functions
npx supabase functions deploy
```

**iOS** (App Store):
1. Archive in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Submit for review

---

## Best Practices & Conventions

### Code Organization

1. **Feature Modules**: Group by feature, not layer (Views, ViewModels together)
2. **Shared Code**: Extract to EkoCore (models) or EkoKit (UI)
3. **Services**: Keep in `Core/Services/` for app-wide access

### SwiftUI Patterns

1. **Prefer Composition**: Build complex views from simple components
2. **Extract Subviews**: Keep body methods under ~10 lines
3. **Use Extensions**: Add view modifiers for common styles

### Async/Await

1. **Always use async/await** for asynchronous operations (no completion handlers)
2. **Handle errors explicitly** with do-catch blocks
3. **Run async code in Task** blocks from synchronous contexts

### Testing

1. **Test business logic first** (ViewModels, Services)
2. **Use protocols for DI** (easy mocking)
3. **Create fixtures** for consistent test data
4. **Test state transitions** (especially state machines)

### Error Handling

1. **Custom error types** for domain-specific errors
2. **User-friendly messages** (no raw error dumps)
3. **Log errors** for debugging (structured logging)

---

## Additional Resources

- [Project Overview](./project-overview.md) - Feature roadmap and product vision
- [Testing Strategy](./testing-strategy.md) - Comprehensive testing approach
- [Lyra Feature Docs](../features/lyra/) - Detailed Lyra AI coach documentation
- [Onboarding Workflow](../workflows/onboarding-workflow.md) - Onboarding implementation guide

---

**Document Maintenance**: This document should be updated whenever major architectural changes occur. Last review: January 2025.
