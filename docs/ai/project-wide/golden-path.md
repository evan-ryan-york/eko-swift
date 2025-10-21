# Golden Path: Data Flow Best Practices

> **Purpose**: This document defines the **canonical data flow pattern** for the Eko iOS app. All features should follow these patterns for consistency, maintainability, and production-grade quality.

> **Audience**: Developers, AI agents, and code reviewers working on Eko

---

## Table of Contents

1. [Overview](#overview)
2. [The Golden Path Architecture](#the-golden-path-architecture)
3. [Layer Responsibilities](#layer-responsibilities)
4. [Complete Examples](#complete-examples)
5. [State Management Patterns](#state-management-patterns)
6. [Error Handling](#error-handling)
7. [Loading States](#loading-states)
8. [Common Pitfalls](#common-pitfalls)
9. [Checklist for New Features](#checklist-for-new-features)

---

## Overview

### What is the "Golden Path"?

The **Golden Path** is the standard, repeatable pattern for data flow in the Eko app. Following this pattern ensures:

- ✅ **Consistency** across all features
- ✅ **Testability** with clear dependency injection
- ✅ **Maintainability** with separation of concerns
- ✅ **Type safety** with Swift's strong typing
- ✅ **Reactive UI** with automatic updates
- ✅ **Error handling** at appropriate layers

### Quick Reference: The Five Layers

```
┌─────────────────────────────────────────────────────────┐
│ 1. VIEW LAYER (SwiftUI)                                 │
│    - Renders UI                                          │
│    - Captures user input                                 │
│    - Observes ViewModel state                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 2. VIEWMODEL LAYER (@Observable)                        │
│    - Business logic                                      │
│    - State management                                    │
│    - Coordinates service calls                           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 3. SERVICE LAYER (Protocol-based)                       │
│    - API communication                                   │
│    - Data transformation                                 │
│    - Authentication & authorization                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 4. API LAYER (Supabase Client)                          │
│    - HTTP requests                                       │
│    - Edge Function calls                                 │
│    - Real-time subscriptions                             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 5. DATABASE LAYER (PostgreSQL + Edge Functions)         │
│    - Data persistence                                    │
│    - Row Level Security                                  │
│    - Business logic (Edge Functions)                     │
└─────────────────────────────────────────────────────────┘
```

---

## The Golden Path Architecture

### Complete Flow Diagram

```
USER ACTION (Button Tap)
    ↓
┌───────────────────────────────────────────────────────┐
│ VIEW (SwiftUI)                                        │
│                                                       │
│ Button("Save") {                                      │
│     Task {                                            │
│         await viewModel.saveChild()                   │
│     }                                                 │
│ }                                                     │
└───────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────┐
│ VIEWMODEL (@Observable)                               │
│                                                       │
│ func saveChild() async {                              │
│     isLoading = true                                  │
│     errorMessage = nil                                │
│     do {                                              │
│         let child = try await service.createChild(…)  │
│         self.currentChild = child                     │
│     } catch {                                         │
│         errorMessage = error.localizedDescription     │
│     }                                                 │
│     isLoading = false                                 │
│ }                                                     │
└───────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────┐
│ SERVICE (Protocol-based)                              │
│                                                       │
│ func createChild(…) async throws -> Child {           │
│     let response = try await client.database          │
│         .from("children")                             │
│         .insert(childDTO)                             │
│         .select()                                     │
│         .single()                                     │
│         .execute()                                    │
│     return try decoder.decode(Child.self, from: …)    │
│ }                                                     │
└───────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────┐
│ API CLIENT (Supabase SDK)                             │
│                                                       │
│ - Adds authentication headers (JWT)                   │
│ - Makes HTTP POST to Supabase                         │
│ - Handles network errors                              │
└───────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────┐
│ SUPABASE BACKEND                                      │
│                                                       │
│ - Row Level Security checks (RLS)                     │
│ - Inserts row into PostgreSQL                         │
│ - Returns inserted data as JSON                       │
└───────────────────────────────────────────────────────┘
    ↓ (Response flows back up)
┌───────────────────────────────────────────────────────┐
│ SERVICE                                               │
│ - Decodes JSON to Child model                         │
│ - Returns Child instance                              │
└───────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────┐
│ VIEWMODEL                                             │
│ - Updates currentChild property                       │
│ - Sets isLoading = false                              │
│ - Property change triggers View update                │
└───────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────┐
│ VIEW                                                  │
│ - SwiftUI detects ViewModel change                    │
│ - Re-renders UI automatically                         │
│ - Shows success state / new data                      │
└───────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### 1. View Layer (SwiftUI)

**File Location**: `Eko/Features/{FeatureName}/Views/`

**Responsibilities**:
- ✅ Render UI based on ViewModel state
- ✅ Capture user input (text fields, buttons, gestures)
- ✅ Observe ViewModel using `@Environment` or `@State`
- ✅ Trigger ViewModel methods in response to user actions
- ✅ Handle local UI state (animations, focus, sheet presentation)

**DO**:
```swift
struct ChildInfoView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var isShowingDatePicker = false  // Local UI state only

    var body: some View {
        VStack {
            TextField("Child's Name", text: Binding(
                get: { viewModel.childName },
                set: { viewModel.childName = $0 }
            ))

            if viewModel.isLoading {
                ProgressView()
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Next") {
                Task {
                    await viewModel.saveChildAndProceed()
                }
            }
            .disabled(viewModel.isLoading)
        }
    }
}
```

**DON'T**:
```swift
// ❌ BAD: Business logic in View
Button("Next") {
    Task {
        do {
            let child = Child(name: childName, age: age)
            try await SupabaseService.shared.createChild(child)  // ❌ Direct service call
            // ❌ No loading state
            // ❌ No error handling UI
        } catch {
            print(error)  // ❌ No user feedback
        }
    }
}

// ❌ BAD: View directly accessing database
.onAppear {
    loadChildrenFromDatabase()  // ❌ Wrong layer
}
```

**Rules**:
1. **Never call services directly from Views** - Always go through ViewModel
2. **Keep Views thin** - Extract complex UI into subviews
3. **Only local UI state in @State** - Business state lives in ViewModel
4. **Always wrap async calls in Task blocks** - SwiftUI views are synchronous
5. **Disable interactions during loading** - Use `.disabled(viewModel.isLoading)`

---

### 2. ViewModel Layer (@Observable)

**File Location**: `Eko/Features/{FeatureName}/ViewModels/`

**Responsibilities**:
- ✅ Hold feature state (data, loading flags, errors)
- ✅ Execute business logic
- ✅ Coordinate service calls
- ✅ Transform data for presentation
- ✅ Validate user input
- ✅ Manage loading and error states

**DO**:
```swift
import Foundation
import Observation
import EkoCore

@MainActor  // ✅ Ensures all operations on main thread
@Observable  // ✅ Makes properties observable by SwiftUI
final class OnboardingViewModel {
    // MARK: - State Properties
    var currentState: OnboardingState = .notStarted
    var childName: String = ""
    var childAge: Int = 8
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Dependencies
    private let supabaseService: SupabaseServiceProtocol

    // MARK: - Initialization
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }

    // MARK: - Public Methods
    func saveChildAndProceed() async {
        // 1. Validate input
        guard validateChildInfo() else {
            errorMessage = "Please fill in all required fields"
            return
        }

        // 2. Set loading state
        isLoading = true
        errorMessage = nil

        // 3. Call service
        do {
            let userId = try await supabaseService.getCurrentUserId()
            let child = try await supabaseService.createChild(
                userId: userId,
                name: childName,
                age: childAge
            )

            // 4. Update state on success
            currentState = currentState.next() ?? currentState

        } catch {
            // 5. Handle error
            errorMessage = handleError(error)
        }

        // 6. Clear loading state
        isLoading = false
    }

    // MARK: - Private Helpers
    private func validateChildInfo() -> Bool {
        !childName.isEmpty && childAge > 0 && childAge <= 18
    }

    private func handleError(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.userFacingMessage
        }
        return "An unexpected error occurred. Please try again."
    }
}
```

**DON'T**:
```swift
// ❌ BAD: No @MainActor annotation
@Observable  // ❌ Could cause UI updates on background thread
class OnboardingViewModel {
    // ...
}

// ❌ BAD: Concrete dependency (hard to test)
class OnboardingViewModel {
    private let service = SupabaseService.shared  // ❌ Can't inject mock
}

// ❌ BAD: No loading/error state management
func saveChild() async {
    let child = try? await service.createChild(...)  // ❌ Silently fails
    // ❌ No isLoading flag
    // ❌ No error message
}

// ❌ BAD: UI logic in ViewModel
func showSuccessAlert() {  // ❌ ViewModels don't control UI
    UIAlertController.show(...)
}
```

**Rules**:
1. **Always mark @MainActor** - Ensures thread safety for UI updates
2. **Always use @Observable** - Enables reactive SwiftUI updates
3. **Inject dependencies via protocol** - Enables testing with mocks
4. **Always manage loading & error state** - Wrap all async operations
5. **Return early on validation failures** - Guard clauses at top of methods
6. **Never import UIKit/SwiftUI** - ViewModels should be UI-framework agnostic
7. **Make methods async, not completion handlers** - Use modern Swift concurrency

---

### 3. Service Layer

**File Location**: `Eko/Core/Services/`

**Responsibilities**:
- ✅ Communicate with backend APIs
- ✅ Transform DTOs ↔ Domain Models
- ✅ Manage authentication tokens
- ✅ Handle network errors
- ✅ Cache data (if needed)
- ✅ Abstract away API implementation details

**DO**:
```swift
import Foundation
import Supabase
import EkoCore

// ✅ Protocol for dependency injection
protocol SupabaseServiceProtocol {
    func createChild(userId: UUID, name: String, age: Int) async throws -> Child
    func fetchChildren(userId: UUID) async throws -> [Child]
    func updateChild(_ child: Child) async throws -> Child
    func deleteChild(id: UUID) async throws
}

@MainActor
final class SupabaseService: SupabaseServiceProtocol {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Child Operations

    func createChild(userId: UUID, name: String, age: Int) async throws -> Child {
        // 1. Create DTO for API
        let dto = ChildDTO(
            userId: userId.uuidString,
            name: name,
            age: age
        )

        // 2. Make API call
        let response = try await client.database
            .from("children")
            .insert(dto)
            .select()
            .single()
            .execute()

        // 3. Decode response to domain model
        let child = try decoder.decode(Child.self, from: response.data)

        // 4. Return domain model
        return child
    }

    func fetchChildren(userId: UUID) async throws -> [Child] {
        let response = try await client.database
            .from("children")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()

        let children = try decoder.decode([Child].self, from: response.data)
        return children
    }

    // MARK: - Error Handling

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
```

**DON'T**:
```swift
// ❌ BAD: No protocol abstraction
final class SupabaseService {  // ❌ Can't be mocked
    func createChild(...) { }
}

// ❌ BAD: Returning raw Supabase types
func createChild(...) async throws -> PostgrestResponse {  // ❌ Leaky abstraction
    return try await client.database.from("children").insert(...)
}

// ❌ BAD: No error transformation
func createChild(...) async throws -> Child {
    return try await client.database...  // ❌ Throws raw Supabase errors
    // ❌ ViewModel has to handle Supabase-specific errors
}

// ❌ BAD: Business logic in service
func createChild(...) async throws -> Child {
    if name.isEmpty {  // ❌ Validation belongs in ViewModel
        throw ValidationError.emptyName
    }
    // ...
}
```

**Rules**:
1. **Always define a protocol** - Enables dependency injection and testing
2. **Return domain models, not DTOs** - Hide API structure from ViewModels
3. **Transform errors** - Convert API errors to domain errors
4. **Keep services stateless** - No properties except client/dependencies
5. **One service per backend/domain** - SupabaseService, AudioService, etc.
6. **Use custom JSONDecoder** - Configure date/key strategies consistently

---

### 4. API Layer (Supabase Client)

**File Location**: External SDK (Supabase Swift)

**Responsibilities**:
- ✅ HTTP networking
- ✅ Authentication header injection
- ✅ Request/response serialization
- ✅ Network error handling
- ✅ Retry logic (built-in)

**You typically don't modify this layer**, but understanding it helps debug issues.

**Example API Call**:
```swift
// What happens inside Supabase SDK:
// 1. Adds Authorization header with JWT token
// 2. Makes POST https://fqecsmwycvltpnqawtod.supabase.co/rest/v1/children
// 3. Body: {"user_id": "...", "name": "...", "age": 8}
// 4. Handles HTTP errors (401, 403, 500, etc.)
// 5. Returns response data as Data

let response = try await client.database
    .from("children")
    .insert(dto)
    .execute()
```

**Common API Errors**:
- `401 Unauthorized` - Token expired or invalid
- `403 Forbidden` - RLS policy blocked access
- `409 Conflict` - Duplicate key violation
- `500 Internal Server Error` - Database or Edge Function error

---

### 5. Database Layer (PostgreSQL + Edge Functions)

**File Location**: `supabase/migrations/` and `supabase/functions/`

**Responsibilities**:
- ✅ Data persistence
- ✅ Row Level Security enforcement
- ✅ Data integrity (constraints, foreign keys)
- ✅ Complex business logic (Edge Functions)
- ✅ AI integration (Edge Functions calling OpenAI)

**Database Operation Example**:

```sql
-- When service calls .insert() on "children" table:

-- 1. RLS Check (before INSERT)
SELECT auth.uid();  -- Gets user ID from JWT
-- Checks policy: "Users can insert own children"
-- Policy: WITH CHECK (auth.uid() = user_id)

-- 2. Insert data (if RLS passes)
INSERT INTO children (user_id, name, age, ...)
VALUES ('...', 'Emma', 8, ...);

-- 3. Trigger fires (if exists)
-- update_updated_at() sets updated_at = NOW()

-- 4. Return inserted row
RETURNING *;
```

**Edge Function Example** (`send-message`):

```typescript
// When service calls client.functions.invoke("send-message")

export default async function handler(req: Request) {
  // 1. Extract JWT token from request
  const token = req.headers.get("Authorization")

  // 2. Verify user owns conversation (RLS)
  const { data: conversation } = await supabase
    .from("conversations")
    .select("*")
    .eq("id", conversationId)
    .single()

  // 3. Fetch child memory for AI context
  const { data: memory } = await supabase
    .from("child_memory")
    .select("*")
    .eq("child_id", conversation.child_id)
    .single()

  // 4. Call OpenAI with context
  const response = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [...conversationHistory, { role: "user", content: message }],
    stream: true
  })

  // 5. Stream response back to client
  return new Response(stream, {
    headers: { "Content-Type": "text/event-stream" }
  })
}
```

---

## Complete Examples

### Example 1: Simple CRUD - Create Child

**Scenario**: User fills out child info form and taps "Save"

#### 1. View Layer

```swift
// File: Eko/Features/Onboarding/Views/ChildInfoView.swift

import SwiftUI
import EkoKit

struct ChildInfoView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Tell us about your child")
                .font(Typography.title1())

            FormTextField(
                label: "Name",
                text: Binding(
                    get: { viewModel.childName },
                    set: { viewModel.childName = $0 }
                ),
                placeholder: "Enter child's name",
                keyboardType: .default,
                error: nil
            )

            HStack {
                Text("Age")
                Spacer()
                Picker("Age", selection: Binding(
                    get: { viewModel.childAge },
                    set: { viewModel.childAge = $0 }
                )) {
                    ForEach(1...18, id: \.self) { age in
                        Text("\(age)").tag(age)
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(Typography.footnote())
                    .foregroundColor(.red)
            }

            PrimaryButton(
                title: "Next",
                action: {
                    Task {
                        await viewModel.saveChildAndProceed()
                    }
                },
                isLoading: viewModel.isLoading
            )
            .disabled(viewModel.isLoading)
        }
        .padding(Spacing.lg)
    }
}
```

#### 2. ViewModel Layer

```swift
// File: Eko/Features/Onboarding/ViewModels/OnboardingViewModel.swift

import Foundation
import Observation
import EkoCore

@MainActor
@Observable
final class OnboardingViewModel {
    // State
    var currentState: OnboardingState = .notStarted
    var childName: String = ""
    var childAge: Int = 8
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var currentChild: Child? = nil

    // Dependencies
    private let supabaseService: SupabaseServiceProtocol

    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }

    func saveChildAndProceed() async {
        // Validate
        guard validateChildInfo() else {
            errorMessage = "Please enter a valid name and age"
            return
        }

        // Start loading
        isLoading = true
        errorMessage = nil

        do {
            // Get current user
            let userId = try await supabaseService.getCurrentUserId()

            // Create child
            let child = try await supabaseService.createChild(
                userId: userId,
                name: childName,
                age: childAge,
                birthday: calculateBirthday(age: childAge)
            )

            // Update state
            currentChild = child
            currentState = currentState.next() ?? currentState

        } catch {
            errorMessage = handleError(error)
        }

        isLoading = false
    }

    private func validateChildInfo() -> Bool {
        !childName.trimmingCharacters(in: .whitespaces).isEmpty
            && childAge > 0
            && childAge <= 18
    }

    private func calculateBirthday(age: Int) -> Date {
        let now = Date()
        return Calendar.current.date(byAdding: .year, value: -age, to: now) ?? now
    }

    private func handleError(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.userFacingMessage
        }
        return "Something went wrong. Please try again."
    }
}
```

#### 3. Service Layer

```swift
// File: Eko/Core/Services/SupabaseService.swift

import Foundation
import Supabase
import EkoCore

extension SupabaseService {
    func createChild(
        userId: UUID,
        name: String,
        age: Int,
        birthday: Date
    ) async throws -> Child {
        // Build DTO
        struct ChildCreateDTO: Encodable {
            let userId: String
            let name: String
            let age: Int
            let birthday: String
            let goals: [String]
            let topics: [String]

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case name, age, birthday, goals, topics
            }
        }

        let dto = ChildCreateDTO(
            userId: userId.uuidString,
            name: name,
            age: age,
            birthday: ISO8601DateFormatter().string(from: birthday),
            goals: [],
            topics: []
        )

        // Make API call
        let response = try await client.database
            .from("children")
            .insert(dto)
            .select()
            .single()
            .execute()

        // Decode to domain model
        let child = try decoder.decode(Child.self, from: response.data)
        return child
    }
}
```

#### 4. Database Layer

```sql
-- PostgreSQL automatically handles this insert

-- 1. RLS check
-- Verifies: auth.uid() = '...' (from JWT)

-- 2. Insert row
INSERT INTO children (
    id,
    user_id,
    name,
    age,
    birthday,
    goals,
    topics,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),  -- Auto-generated
    '...',               -- From DTO
    'Emma',              -- From DTO
    8,                   -- From DTO
    '2016-01-15',        -- From DTO
    '{}',                -- Empty array
    '{}',                -- Empty array
    NOW(),               -- Auto-set
    NOW()                -- Auto-set
);

-- 3. Return row
RETURNING *;
```

#### 5. Response Flow Back

```
Database → Service → ViewModel → View

1. PostgreSQL returns inserted row as JSON
   ↓
2. SupabaseService decodes JSON → Child model
   ↓
3. OnboardingViewModel sets currentChild = child
   ↓
4. @Observable triggers view update
   ↓
5. ChildInfoView re-renders with new state
```

---

### Example 2: Complex Flow - Send Message to AI (Streaming)

**Scenario**: User types message in Lyra chat and taps send

#### 1. View Layer

```swift
// File: Eko/Features/AIGuide/Views/LyraView.swift

struct LyraView: View {
    @Environment(LyraViewModel.self) private var viewModel

    var body: some View {
        VStack {
            // Messages list
            ScrollView {
                ForEach(viewModel.messages) { message in
                    MessageBubbleView(message: message)
                }

                // Typing indicator (while streaming)
                if viewModel.isStreaming {
                    TypingIndicatorView()
                }
            }

            // Input bar
            ChatInputBar(
                text: $viewModel.messageText,
                isSending: viewModel.isSending,
                onSend: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            )
        }
    }
}
```

#### 2. ViewModel Layer

```swift
// File: Eko/Features/AIGuide/ViewModels/LyraViewModel.swift

@MainActor
@Observable
final class LyraViewModel {
    var messages: [Message] = []
    var messageText: String = ""
    var isSending: Bool = false
    var isStreaming: Bool = false
    var errorMessage: String? = nil

    private let supabaseService: SupabaseServiceProtocol
    private var currentChild: Child

    init(
        child: Child,
        supabaseService: SupabaseServiceProtocol = SupabaseService.shared
    ) {
        self.currentChild = child
        self.supabaseService = supabaseService
    }

    func sendMessage() async {
        guard !messageText.isEmpty else { return }

        // Store user message locally
        let userMessage = Message(
            id: UUID(),
            conversationId: currentConversationId,
            role: .user,
            content: messageText,
            sources: nil,
            createdAt: Date()
        )
        messages.append(userMessage)

        // Clear input
        let textToSend = messageText
        messageText = ""

        // Set loading states
        isSending = true
        isStreaming = true
        errorMessage = nil

        do {
            // Call service with streaming
            for try await chunk in try await supabaseService.sendMessageStream(
                conversationId: currentConversationId,
                message: textToSend,
                childContext: buildChildContext()
            ) {
                // Handle streaming chunk
                handleStreamChunk(chunk)
            }

        } catch {
            errorMessage = "Failed to send message"
            // Remove optimistic user message on error
            messages.removeLast()
        }

        isSending = false
        isStreaming = false
    }

    private func handleStreamChunk(_ chunk: MessageChunk) {
        // Find or create assistant message
        if let lastMessage = messages.last,
           lastMessage.role == .assistant {
            // Append to existing
            messages[messages.count - 1].content += chunk.text
        } else {
            // Create new message
            let assistantMessage = Message(
                id: UUID(),
                conversationId: currentConversationId,
                role: .assistant,
                content: chunk.text,
                sources: chunk.sources,
                createdAt: Date()
            )
            messages.append(assistantMessage)
        }
    }

    private func buildChildContext() -> ChildContext {
        ChildContext(
            age: currentChild.age,
            temperament: currentChild.temperament.rawValue,
            goals: currentChild.goals,
            topics: currentChild.topics
        )
    }
}
```

#### 3. Service Layer (Streaming)

```swift
// File: Eko/Core/Services/SupabaseService.swift

extension SupabaseService {
    func sendMessageStream(
        conversationId: UUID,
        message: String,
        childContext: ChildContext
    ) async throws -> AsyncThrowingStream<MessageChunk, Error> {
        // Build request
        struct SendMessageRequest: Encodable {
            let conversationId: String
            let message: String
            let childContext: ChildContext
        }

        let request = SendMessageRequest(
            conversationId: conversationId.uuidString,
            message: message,
            childContext: childContext
        )

        // Call Edge Function with streaming
        let response = try await client.functions
            .invoke(
                "send-message",
                options: FunctionInvokeOptions(
                    body: try encoder.encode(request)
                )
            )

        // Return async stream
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Parse SSE stream
                    for try await line in response.data.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8) {
                                let chunk = try decoder.decode(
                                    MessageChunk.self,
                                    from: data
                                )
                                continuation.yield(chunk)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

struct MessageChunk: Decodable {
    let text: String
    let sources: [Citation]?
    let isDone: Bool
}
```

#### 4. Edge Function (TypeScript)

```typescript
// File: supabase/functions/send-message/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { conversationId, message, childContext } = await req.json()
  const authHeader = req.headers.get("Authorization")!

  // Create Supabase client with user's JWT
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  )

  // 1. Verify user owns conversation (RLS handles this)
  const { data: conversation, error: convError } = await supabase
    .from("conversations")
    .select("*")
    .eq("id", conversationId)
    .single()

  if (convError) throw convError

  // 2. Insert user message
  await supabase
    .from("messages")
    .insert({
      conversation_id: conversationId,
      role: "user",
      content: message
    })

  // 3. Fetch child memory
  const { data: memory } = await supabase
    .from("child_memory")
    .select("*")
    .eq("child_id", conversation.child_id)
    .single()

  // 4. Build OpenAI prompt
  const systemPrompt = buildSystemPrompt(childContext, memory)
  const conversationHistory = await fetchConversationHistory(
    supabase,
    conversationId
  )

  // 5. Call OpenAI (streaming)
  const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") })
  const stream = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [
      { role: "system", content: systemPrompt },
      ...conversationHistory,
      { role: "user", content: message }
    ],
    stream: true
  })

  // 6. Create SSE stream to client
  const encoder = new TextEncoder()
  let fullResponse = ""

  const responseStream = new ReadableStream({
    async start(controller) {
      for await (const chunk of stream) {
        const text = chunk.choices[0]?.delta?.content || ""
        fullResponse += text

        // Send chunk to client
        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify({ text, isDone: false })}\n\n`)
        )
      }

      // 7. Save complete assistant message
      await supabase
        .from("messages")
        .insert({
          conversation_id: conversationId,
          role: "assistant",
          content: fullResponse
        })

      // Done
      controller.enqueue(
        encoder.encode(`data: ${JSON.stringify({ text: "", isDone: true })}\n\n`)
      )
      controller.close()
    }
  })

  return new Response(responseStream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive"
    }
  })
})
```

#### 5. Complete Flow

```
User Types & Taps Send
    ↓
View wraps in Task { await viewModel.sendMessage() }
    ↓
ViewModel:
  - Adds optimistic user message to UI
  - Calls service.sendMessageStream()
    ↓
Service:
  - Calls Edge Function via Supabase client
  - Returns AsyncThrowingStream
    ↓
Edge Function:
  - Verifies ownership (RLS)
  - Inserts user message to DB
  - Fetches child memory
  - Calls OpenAI (streaming)
  - For each chunk:
      ↓
  - Sends SSE event to client
    ↓
Service receives chunk:
  - Parses SSE line
  - Decodes JSON
  - Yields MessageChunk to stream
    ↓
ViewModel receives chunk:
  - Appends text to last assistant message
  - @Observable triggers view update
    ↓
View re-renders:
  - Shows updated message text in real-time
    ↓
Stream completes:
  - Edge Function saves full message to DB
  - ViewModel sets isStreaming = false
  - View shows final message
```

---

### Example 3: Fetch & Display List

**Scenario**: Load and display list of children on profile screen

#### Complete Code

```swift
// VIEW
struct ProfileView: View {
    @Environment(ProfileViewModel.self) private var viewModel

    var body: some View {
        List {
            ForEach(viewModel.children) { child in
                ChildRowView(child: child)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadChildren()
        }
    }
}

// VIEWMODEL
@MainActor
@Observable
final class ProfileViewModel {
    var children: [Child] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let supabaseService: SupabaseServiceProtocol

    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }

    func loadChildren() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await supabaseService.getCurrentUserId()
            children = try await supabaseService.fetchChildren(userId: userId)
        } catch {
            errorMessage = "Failed to load children"
        }

        isLoading = false
    }
}

// SERVICE
extension SupabaseService {
    func fetchChildren(userId: UUID) async throws -> [Child] {
        let response = try await client.database
            .from("children")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()

        return try decoder.decode([Child].self, from: response.data)
    }
}
```

---

## State Management Patterns

### Pattern 1: @Observable for ViewModels (Primary Pattern)

**Use Case**: All ViewModels

```swift
@MainActor
@Observable
final class MyViewModel {
    var data: [Item] = []
    var isLoading = false

    // Properties automatically trigger view updates
}

// In View:
@Environment(MyViewModel.self) private var viewModel
// or
@State private var viewModel = MyViewModel()
```

**Why**: Modern, performant, automatic dependency tracking

### Pattern 2: @State for Local UI State

**Use Case**: Local view state (sheet presentation, focus, animations)

```swift
struct MyView: View {
    @State private var isShowingSheet = false
    @State private var searchText = ""

    var body: some View {
        Button("Show") {
            isShowingSheet = true  // Triggers view update
        }
        .sheet(isPresented: $isShowingSheet) {
            SheetContent()
        }
    }
}
```

**Why**: Simple, doesn't need to be shared

### Pattern 3: @Environment for Dependency Injection

**Use Case**: Injecting ViewModels down view hierarchy

```swift
// In App:
@main
struct EkoApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)  // Inject
        }
    }
}

// In any child view:
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    // Can now use authViewModel
}
```

**Why**: Avoids prop drilling, easy to override for testing

### Pattern 4: @Binding for Two-Way Data Flow

**Use Case**: Child view needs to modify parent's state

```swift
struct ParentView: View {
    @State private var text = ""

    var body: some View {
        ChildView(text: $text)  // Pass binding
    }
}

struct ChildView: View {
    @Binding var text: String  // Receives binding

    var body: some View {
        TextField("Enter text", text: $text)  // Modifies parent's state
    }
}
```

**Why**: Explicit data flow, clear ownership

---

## Error Handling

### Error Hierarchy

```swift
// Domain-level errors
enum AppError: LocalizedError {
    case network(NetworkError)
    case authentication(AuthError)
    case validation(ValidationError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.userFacingMessage
        case .authentication(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.message
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError
    case unauthorized

    var userFacingMessage: String {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError:
            return "Server error. Please try again later."
        case .unauthorized:
            return "Session expired. Please log in again."
        }
    }
}
```

### Error Handling at Each Layer

#### View Layer
```swift
// Display error to user
if let error = viewModel.errorMessage {
    Text(error)
        .foregroundColor(.red)
        .font(Typography.footnote())
}
```

#### ViewModel Layer
```swift
// Catch and transform errors
do {
    let result = try await service.doSomething()
    self.data = result
} catch {
    // Transform to user-friendly message
    if let networkError = error as? NetworkError {
        self.errorMessage = networkError.userFacingMessage
    } else {
        self.errorMessage = "An unexpected error occurred"
    }
}
```

#### Service Layer
```swift
// Throw specific errors
func fetchData() async throws -> Data {
    do {
        let response = try await client.database.from("table").select().execute()
        return try decoder.decode(Data.self, from: response.data)
    } catch let error as URLError where error.code == .notConnectedToInternet {
        throw NetworkError.noConnection
    } catch {
        throw NetworkError.serverError
    }
}
```

---

## Loading States

### Standard Loading Pattern

```swift
// ViewModel
@MainActor
@Observable
final class MyViewModel {
    var isLoading = false
    var data: [Item] = []

    func loadData() async {
        isLoading = true
        defer { isLoading = false }  // ✅ Always reset

        do {
            data = try await service.fetchData()
        } catch {
            // handle error
        }
    }
}

// View
if viewModel.isLoading {
    ProgressView()
} else {
    List(viewModel.data) { item in
        ItemRow(item: item)
    }
}
```

### Button Loading State

```swift
PrimaryButton(
    title: "Save",
    action: {
        Task {
            await viewModel.save()
        }
    },
    isLoading: viewModel.isLoading
)
.disabled(viewModel.isLoading)  // Prevent double-tap
```

### Skeleton Loading (Future Pattern)

```swift
if viewModel.isLoading {
    ForEach(0..<3) { _ in
        SkeletonRow()  // Placeholder UI
    }
} else {
    ForEach(viewModel.data) { item in
        ItemRow(item: item)
    }
}
```

---

## Common Pitfalls

### ❌ Pitfall 1: Calling Services from Views

```swift
// BAD
Button("Save") {
    Task {
        try? await SupabaseService.shared.saveChild(...)  // ❌
    }
}

// GOOD
Button("Save") {
    Task {
        await viewModel.saveChild()  // ✅
    }
}
```

### ❌ Pitfall 2: Forgetting @MainActor

```swift
// BAD
@Observable  // ❌ Could update UI from background thread
class MyViewModel {
    var data: [Item] = []
}

// GOOD
@MainActor  // ✅ All operations on main thread
@Observable
class MyViewModel {
    var data: [Item] = []
}
```

### ❌ Pitfall 3: Not Managing Loading State

```swift
// BAD
func loadData() async {
    let data = try? await service.fetch()  // ❌ No loading flag
    self.data = data ?? []
}

// GOOD
func loadData() async {
    isLoading = true  // ✅ Set loading
    defer { isLoading = false }  // ✅ Always clear

    do {
        data = try await service.fetch()
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### ❌ Pitfall 4: Silently Swallowing Errors

```swift
// BAD
func save() async {
    try? await service.save(data)  // ❌ User sees nothing
}

// GOOD
func save() async {
    do {
        try await service.save(data)
        successMessage = "Saved successfully"  // ✅ Feedback
    } catch {
        errorMessage = handleError(error)  // ✅ Show error
    }
}
```

### ❌ Pitfall 5: Hard-Coded Dependencies

```swift
// BAD
class MyViewModel {
    let service = SupabaseService.shared  // ❌ Can't test
}

// GOOD
class MyViewModel {
    private let service: SupabaseServiceProtocol  // ✅ Protocol

    init(service: SupabaseServiceProtocol = SupabaseService.shared) {
        self.service = service
    }
}
```

### ❌ Pitfall 6: Using Completion Handlers

```swift
// BAD (Old Pattern)
func loadData(completion: @escaping (Result<Data, Error>) -> Void) {
    service.fetch { result in
        completion(result)
    }
}

// GOOD (Modern Swift)
func loadData() async throws -> Data {
    return try await service.fetch()  // ✅ async/await
}
```

---

## Checklist for New Features

Use this checklist when implementing any new feature:

### View Layer
- [ ] View observes ViewModel using `@Environment` or `@State`
- [ ] All async calls wrapped in `Task { await ... }`
- [ ] Loading states displayed (`ProgressView`, disabled buttons)
- [ ] Error messages shown to user
- [ ] No business logic in view (all in ViewModel)
- [ ] No direct service calls from view

### ViewModel Layer
- [ ] Marked with `@MainActor`
- [ ] Marked with `@Observable`
- [ ] Has `isLoading` property
- [ ] Has `errorMessage` property (String?)
- [ ] Injects service via protocol (not concrete type)
- [ ] All public methods are `async`
- [ ] Sets loading state before/after async operations
- [ ] Transforms errors to user-friendly messages
- [ ] Validates input before calling service
- [ ] Does not import UIKit or SwiftUI

### Service Layer
- [ ] Has protocol definition
- [ ] Returns domain models (not DTOs or raw responses)
- [ ] Throws specific error types
- [ ] Uses custom JSONDecoder with proper strategies
- [ ] No business logic (validation, state management)
- [ ] Stateless (no properties except client/config)

### Testing
- [ ] ViewModel has unit tests
- [ ] Tests use mock service (via protocol)
- [ ] Test success case
- [ ] Test error cases
- [ ] Test loading states
- [ ] Test validation logic

### Documentation
- [ ] Add doc comments to public methods
- [ ] Update architecture.md if new pattern introduced
- [ ] Add example to golden-path.md if complex flow

---

## Quick Reference Card

### Flow Summary

```
User Taps Button
    ↓
View wraps in Task { await viewModel.method() }
    ↓
ViewModel:
  - Sets isLoading = true
  - Clears errorMessage
  - Calls service.method()
    ↓
Service:
  - Makes API call via Supabase client
  - Decodes response to domain model
  - Throws specific errors
    ↓
API/Database:
  - Enforces RLS
  - Executes query/function
  - Returns JSON
    ↓
Service decodes → returns model
    ↓
ViewModel:
  - Updates state properties
  - Sets isLoading = false
  - @Observable triggers update
    ↓
View automatically re-renders
```

### Code Template

```swift
// VIEW
struct MyView: View {
    @Environment(MyViewModel.self) private var viewModel

    var body: some View {
        VStack {
            // Content
            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }

            Button("Action") {
                Task { await viewModel.performAction() }
            }
            .disabled(viewModel.isLoading)
        }
    }
}

// VIEWMODEL
@MainActor
@Observable
final class MyViewModel {
    var isLoading = false
    var errorMessage: String? = nil
    var data: [Item] = []

    private let service: MyServiceProtocol

    init(service: MyServiceProtocol = MyService.shared) {
        self.service = service
    }

    func performAction() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            data = try await service.fetchData()
        } catch {
            errorMessage = "Failed to load data"
        }
    }
}

// SERVICE
protocol MyServiceProtocol {
    func fetchData() async throws -> [Item]
}

final class MyService: MyServiceProtocol {
    func fetchData() async throws -> [Item] {
        let response = try await client.database
            .from("items")
            .select()
            .execute()
        return try decoder.decode([Item].self, from: response.data)
    }
}
```

---

## Conclusion

Following the **Golden Path** ensures:

1. **Consistency** - All features use same patterns
2. **Testability** - Protocol-based DI enables mocking
3. **Maintainability** - Clear separation of concerns
4. **Type Safety** - Swift's compiler catches errors
5. **Performance** - Reactive updates only where needed
6. **User Experience** - Proper loading and error states

**Remember**: When in doubt, follow the examples in this document. If you encounter a case not covered here, follow the existing patterns in the codebase and consider updating this document.

---

**Document Maintenance**: Update this document when introducing new architectural patterns. Last review: January 2025.
