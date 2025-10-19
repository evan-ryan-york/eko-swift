# Onboarding Implementation Plan

**Version**: 1.0
**Last Updated**: October 19, 2025
**Feature**: User Onboarding Flow
**Status**: Planning Phase

---

## Overview

This document provides a step-by-step implementation plan for building the Eko onboarding flow. When complete, new users will:

1. Sign in with Google
2. Be automatically detected as new users
3. Progress through the onboarding flow (7 steps)
4. Resume onboarding if they log out or uninstall before completing
5. Skip onboarding if already completed

---

## Prerequisites

Before starting implementation, ensure you understand:

- Supabase database migrations
- Swift + SwiftUI app architecture
- Eko's current authentication flow (`AuthViewModel`, `SupabaseService`)
- Row Level Security (RLS) policies in PostgreSQL
- PostgREST API patterns

---

## Implementation Steps

### **Phase 1: Database Foundation**

#### Step 1.1: Create Database Migration

**File**: `/supabase/migrations/20251019000000_create_onboarding_tables.sql`

**What to create:**

1. **`user_profiles` table** to store onboarding state
2. **Alter `children` table** to add onboarding fields
3. **Trigger** to auto-create user profile on auth signup
4. **RLS policies** for security

**Details:**

```sql
-- ============================================================================
-- 1. Create user_profiles table
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    onboarding_state TEXT NOT NULL DEFAULT 'NOT_STARTED',
    current_child_id UUID REFERENCES children(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add constraint for valid onboarding states
ALTER TABLE user_profiles
ADD CONSTRAINT valid_onboarding_state CHECK (
    onboarding_state IN (
        'NOT_STARTED',
        'USER_INFO',
        'CHILD_INFO',
        'GOALS',
        'TOPICS',
        'DISPOSITIONS',
        'REVIEW',
        'COMPLETE'
    )
);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding_state
ON user_profiles(onboarding_state);

-- Add updated_at trigger
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE user_profiles IS 'Extended user data including onboarding state';
COMMENT ON COLUMN user_profiles.onboarding_state IS 'Current step in onboarding flow';
COMMENT ON COLUMN user_profiles.current_child_id IS 'Temporary field tracking which child is being edited during onboarding';

-- ============================================================================
-- 2. Add onboarding fields to children table
-- ============================================================================

ALTER TABLE children
ADD COLUMN IF NOT EXISTS birthday DATE,
ADD COLUMN IF NOT EXISTS goals TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS topics TEXT[] DEFAULT '{}';

-- Add validation
ALTER TABLE children
ADD CONSTRAINT valid_birthday CHECK (birthday <= CURRENT_DATE);

COMMENT ON COLUMN children.birthday IS 'Child''s date of birth (ISO date)';
COMMENT ON COLUMN children.goals IS 'Parent conversation goals (1-3 items from onboarding)';
COMMENT ON COLUMN children.topics IS 'Selected conversation topic IDs (minimum 3 from onboarding)';

-- ============================================================================
-- 3. Auto-create user_profile on signup (trigger function)
-- ============================================================================

CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, onboarding_state)
    VALUES (NEW.id, 'NOT_STARTED')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile();

COMMENT ON FUNCTION create_user_profile IS 'Automatically creates user_profile record when new user signs up';

-- ============================================================================
-- 4. Row Level Security (RLS) Policies
-- ============================================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Note: No delete policy - user_profiles cascade deletes with auth.users

-- ============================================================================
-- 5. Helper function to get user profile with onboarding state
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_with_profile(p_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    display_name TEXT,
    onboarding_state TEXT,
    current_child_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        au.id,
        au.email,
        au.raw_user_meta_data->>'full_name' as display_name,
        COALESCE(up.onboarding_state, 'NOT_STARTED') as onboarding_state,
        up.current_child_id
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON up.id = au.id
    WHERE au.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_with_profile IS 'Fetches user data combined with profile/onboarding state';
```

**Action Items:**
- [ ] Create migration file
- [ ] Test migration locally: `supabase migration up`
- [ ] Verify trigger works: Sign up test user, check `user_profiles` created
- [ ] Verify RLS policies: Test SELECT/UPDATE as authenticated user

---

#### Step 1.2: Backfill Existing Users (Optional)

If you have existing users in the database, create a one-time script:

```sql
-- Backfill user_profiles for existing users
INSERT INTO user_profiles (id, onboarding_state)
SELECT id, 'COMPLETE' -- Assume existing users already "completed" onboarding
FROM auth.users
ON CONFLICT (id) DO NOTHING;
```

**Action Items:**
- [ ] Decide if existing users should show onboarding or skip it
- [ ] Run backfill script if needed

---

### **Phase 2: Swift Models & DTOs**

#### Step 2.1: Create OnboardingState Enum

**File**: `/EkoCore/Sources/EkoCore/Models/OnboardingState.swift`

```swift
import Foundation

/// Represents the current step in the user onboarding flow
public enum OnboardingState: String, Codable, Sendable {
    case notStarted = "NOT_STARTED"
    case userInfo = "USER_INFO"
    case childInfo = "CHILD_INFO"
    case goals = "GOALS"
    case topics = "TOPICS"
    case dispositions = "DISPOSITIONS"
    case review = "REVIEW"
    case complete = "COMPLETE"

    /// Human-readable description of the step
    public var description: String {
        switch self {
        case .notStarted: return "Not Started"
        case .userInfo: return "User Information"
        case .childInfo: return "Child Information"
        case .goals: return "Conversation Goals"
        case .topics: return "Conversation Topics"
        case .dispositions: return "Child's Disposition"
        case .review: return "Review"
        case .complete: return "Complete"
        }
    }

    /// Whether onboarding is finished
    public var isComplete: Bool {
        return self == .complete
    }

    /// Get next state in the flow (nil if at end)
    public func next() -> OnboardingState? {
        switch self {
        case .notStarted: return .userInfo
        case .userInfo: return .childInfo
        case .childInfo: return .goals
        case .goals: return .topics
        case .topics: return .dispositions
        case .dispositions: return .review
        case .review: return .complete
        case .complete: return nil
        }
    }

    /// Get previous state in the flow (nil if at beginning)
    public func previous() -> OnboardingState? {
        switch self {
        case .notStarted: return nil
        case .userInfo: return nil // Can't go back from first step
        case .childInfo: return .userInfo
        case .goals: return .childInfo
        case .topics: return .goals
        case .dispositions: return .topics
        case .review: return nil // Can't go back from review
        case .complete: return nil
        }
    }
}
```

**Action Items:**
- [ ] Create file in EkoCore module
- [ ] Add to Xcode project
- [ ] Build and verify no errors

---

#### Step 2.2: Create UserProfile Model

**File**: `/EkoCore/Sources/EkoCore/Models/UserProfile.swift`

```swift
import Foundation

/// Extended user profile data including onboarding state
public struct UserProfile: Codable, Identifiable, Sendable {
    public let id: UUID
    public var onboardingState: OnboardingState
    public var currentChildId: UUID?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        onboardingState: OnboardingState,
        currentChildId: UUID? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.onboardingState = onboardingState
        self.currentChildId = currentChildId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case onboardingState = "onboarding_state"
        case currentChildId = "current_child_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Action Items:**
- [ ] Create file in EkoCore module
- [ ] Add to Xcode project
- [ ] Import in SupabaseService

---

#### Step 2.3: Update User Model

**File**: `/EkoCore/Sources/EkoCore/Models/User.swift`

**Changes:**

```swift
import Foundation

public struct User: Codable, Identifiable, Sendable {
    public let id: UUID
    public let email: String
    public let createdAt: Date
    public var updatedAt: Date
    public var displayName: String?
    public var avatarURL: URL?

    // NEW: Onboarding-related fields
    public var onboardingState: OnboardingState
    public var currentChildId: UUID?

    public init(
        id: UUID,
        email: String,
        createdAt: Date,
        updatedAt: Date,
        displayName: String? = nil,
        avatarURL: URL? = nil,
        onboardingState: OnboardingState = .notStarted,
        currentChildId: UUID? = nil
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.onboardingState = onboardingState
        self.currentChildId = currentChildId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case onboardingState = "onboarding_state"
        case currentChildId = "current_child_id"
    }
}
```

**Action Items:**
- [ ] Update User.swift
- [ ] Update all existing User initializations throughout the app
- [ ] Build and fix any compilation errors

---

#### Step 2.4: Update Child Model

**File**: `/EkoCore/Sources/EkoCore/Models/Child.swift`

**Changes:**

```swift
import Foundation

public struct Child: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var name: String
    public var age: Int
    public var birthday: Date  // NEW
    public var goals: [String]  // NEW
    public var topics: [String]  // NEW
    public var temperament: Temperament
    public var temperamentTalkative: Int
    public var temperamentSensitivity: Int
    public var temperamentAccountability: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        userId: UUID,
        name: String,
        age: Int,
        birthday: Date,
        goals: [String] = [],
        topics: [String] = [],
        temperament: Temperament,
        temperamentTalkative: Int = 5,
        temperamentSensitivity: Int = 5,
        temperamentAccountability: Int = 5,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.age = age
        self.birthday = birthday
        self.goals = goals
        self.topics = topics
        self.temperament = temperament
        self.temperamentTalkative = temperamentTalkative
        self.temperamentSensitivity = temperamentSensitivity
        self.temperamentAccountability = temperamentAccountability
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case age
        case birthday
        case goals
        case topics
        case temperament
        case temperamentTalkative = "temperament_talkative"
        case temperamentSensitivity = "temperament_sensitivity"
        case temperamentAccountability = "temperament_accountability"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Action Items:**
- [ ] Update Child.swift
- [ ] Update existing Child initializations
- [ ] Update `AddChildView.swift` to collect birthday
- [ ] Build and fix compilation errors

---

#### Step 2.5: Create Topic Constants

**File**: `/EkoCore/Sources/EkoCore/Models/ConversationTopic.swift`

```swift
import Foundation

/// Represents a conversation topic that can be selected during onboarding
public struct ConversationTopic: Identifiable, Sendable {
    public let id: String
    public let displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

/// All available conversation topics
public enum ConversationTopics {
    public static let all: [ConversationTopic] = [
        ConversationTopic(id: "emotions", displayName: "Emotions & Feelings"),
        ConversationTopic(id: "friends", displayName: "Friendship & Relationships"),
        ConversationTopic(id: "school", displayName: "School & Learning"),
        ConversationTopic(id: "family", displayName: "Family Dynamics"),
        ConversationTopic(id: "conflict", displayName: "Conflict Resolution"),
        ConversationTopic(id: "values", displayName: "Values & Ethics"),
        ConversationTopic(id: "confidence", displayName: "Self-Confidence"),
        ConversationTopic(id: "health", displayName: "Health & Wellness"),
        ConversationTopic(id: "diversity", displayName: "Diversity & Inclusion"),
        ConversationTopic(id: "future", displayName: "Future & Goals"),
        ConversationTopic(id: "technology", displayName: "Technology & Screen Time"),
        ConversationTopic(id: "creativity", displayName: "Creativity & Imagination")
    ]

    /// Get display name from topic ID
    public static func displayName(for id: String) -> String {
        return all.first { $0.id == id }?.displayName ?? id
    }
}
```

**Action Items:**
- [ ] Create file in EkoCore module
- [ ] Add to Xcode project

---

### **Phase 3: Service Layer Updates**

#### Step 3.1: Add Methods to SupabaseService

**File**: `/Eko/Core/Services/SupabaseService.swift`

**Add these new methods:**

```swift
// MARK: - User Profile / Onboarding

/// Fetch user profile including onboarding state
func getUserProfile() async throws -> UserProfile {
    let session = try await authClient.session
    let userId = session.user.id

    let response: [UserProfile] = try await postgrestClient
        .from("user_profiles")
        .select()
        .eq("id", value: userId.uuidString)
        .execute()
        .value

    guard let profile = response.first else {
        // If profile doesn't exist, create it (fallback)
        return try await createUserProfile(userId: userId)
    }

    return profile
}

/// Create user profile (fallback if trigger didn't fire)
private func createUserProfile(userId: UUID) async throws -> UserProfile {
    let newProfile = [
        "id": userId.uuidString,
        "onboarding_state": OnboardingState.notStarted.rawValue
    ]

    let response: UserProfile = try await postgrestClient
        .from("user_profiles")
        .insert(newProfile)
        .select()
        .single()
        .execute()
        .value

    return response
}

/// Update user's onboarding state
func updateOnboardingState(_ state: OnboardingState, currentChildId: UUID? = nil) async throws {
    let session = try await authClient.session
    let userId = session.user.id

    var updates: [String: Any] = [
        "onboarding_state": state.rawValue
    ]

    if let childId = currentChildId {
        updates["current_child_id"] = childId.uuidString
    } else {
        updates["current_child_id"] = NSNull()
    }

    try await postgrestClient
        .from("user_profiles")
        .update(updates)
        .eq("id", value: userId.uuidString)
        .execute()
}

/// Update user's display name in auth metadata
func updateDisplayName(_ displayName: String) async throws {
    try await authClient.update(user: UserAttributes(data: ["full_name": .string(displayName)]))
}

/// Get combined user data (auth + profile)
func getCurrentUserWithProfile() async throws -> User? {
    do {
        let session = try await authClient.session
        let profile = try await getUserProfile()

        guard let email = session.user.email else {
            throw AuthError.unknown(NSError(domain: "No email", code: -1))
        }

        return User(
            id: session.user.id,
            email: email,
            createdAt: session.user.createdAt,
            updatedAt: session.user.updatedAt,
            displayName: session.user.userMetadata["full_name"] as? String,
            avatarURL: {
                if let avatarString = session.user.userMetadata["avatar_url"] as? String {
                    return URL(string: avatarString)
                }
                return nil
            }(),
            onboardingState: profile.onboardingState,
            currentChildId: profile.currentChildId
        )
    } catch {
        return nil
    }
}
```

**Update existing `createChild` method:**

```swift
func createChild(
    name: String,
    age: Int,
    birthday: Date,
    goals: [String],
    topics: [String],
    temperament: Temperament,
    temperamentTalkative: Int = 5,
    temperamentSensitivity: Int = 5,
    temperamentAccountability: Int = 5
) async throws -> Child {
    let session = try await authClient.session
    let userId = session.user.id

    let newChild: [String: Any] = [
        "user_id": userId.uuidString,
        "name": name,
        "age": age,
        "birthday": ISO8601DateFormatter().string(from: birthday),
        "goals": goals,
        "topics": topics,
        "temperament": temperament.rawValue,
        "temperament_talkative": temperamentTalkative,
        "temperament_sensitivity": temperamentSensitivity,
        "temperament_accountability": temperamentAccountability
    ]

    let response: Child = try await postgrestClient
        .from("children")
        .insert(newChild)
        .select()
        .single()
        .execute()
        .value

    return response
}
```

**Action Items:**
- [ ] Add methods to SupabaseService.swift
- [ ] Update `getCurrentUser()` to use `getCurrentUserWithProfile()`
- [ ] Build and test methods with a sample user

---

### **Phase 4: Onboarding View Models**

#### Step 4.1: Create OnboardingViewModel

**File**: `/Eko/Features/Onboarding/ViewModels/OnboardingViewModel.swift`

```swift
import Foundation
import SwiftUI
import EkoCore

@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: - State
    var currentState: OnboardingState = .notStarted
    var isLoading = false
    var errorMessage: String?

    // MARK: - User Info Step
    var parentName: String = ""

    // MARK: - Child Info Step
    var currentChildId: UUID?
    var childName: String = ""
    var childBirthday: Date = Date()

    // MARK: - Goals Step
    var selectedGoals: [String] = []
    var customGoal: String = ""

    let availableGoals = [
        "Understanding their thoughts and feelings better",
        "Helping them navigate challenges",
        "Connecting with them on a deeper level",
        "Encouraging them to open up more",
        "Teaching them life skills or values",
        "Supporting their mental and emotional well-being"
    ]

    // MARK: - Topics Step
    var selectedTopics: [String] = []

    // MARK: - Dispositions Step
    var talkativeScore: Int = 5
    var sensitiveScore: Int = 5
    var accountableScore: Int = 5
    var currentDispositionPage: Int = 0

    // MARK: - Review Step
    var completedChildren: [Child] = []

    // MARK: - Dependencies
    private let supabaseService: SupabaseService

    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
    }

    // MARK: - State Management

    func loadOnboardingState() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await supabaseService.getUserProfile()
            currentState = profile.onboardingState
            currentChildId = profile.currentChildId

            // Load completed children if in review state
            if currentState == .review {
                await loadCompletedChildren()
            }
        } catch {
            errorMessage = "Failed to load onboarding state: \(error.localizedDescription)"
        }
    }

    func loadCompletedChildren() async {
        do {
            let user = try await supabaseService.getCurrentUser()
            guard let userId = user?.id else { return }
            completedChildren = try await supabaseService.fetchChildren(forUserId: userId)
        } catch {
            errorMessage = "Failed to load children: \(error.localizedDescription)"
        }
    }

    // MARK: - Navigation

    func moveToNextStep() async {
        guard let nextState = currentState.next() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Save current step data before transitioning
            try await saveCurrentStepData()

            // Update state in database
            try await supabaseService.updateOnboardingState(nextState, currentChildId: currentChildId)

            currentState = nextState

            // Load data for next step if needed
            if nextState == .review {
                await loadCompletedChildren()
            }
        } catch {
            errorMessage = "Failed to proceed: \(error.localizedDescription)"
        }
    }

    func moveToPreviousStep() {
        guard let prevState = currentState.previous() else { return }
        currentState = prevState
    }

    // MARK: - Step-specific Actions

    func saveParentName() async throws {
        try await supabaseService.updateDisplayName(parentName)
    }

    func startChildEntry() async {
        // Generate new child ID for tracking
        currentChildId = UUID()
        resetChildForm()
    }

    func saveChildData() async throws {
        guard !childName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }

        // Calculate age from birthday
        let age = calculateAge(from: childBirthday)

        // Collect all goals
        var allGoals = selectedGoals
        if !customGoal.isEmpty {
            allGoals.append(customGoal)
        }

        // Create child in database
        let child = try await supabaseService.createChild(
            name: childName,
            age: age,
            birthday: childBirthday,
            goals: allGoals,
            topics: selectedTopics,
            temperament: .easygoing, // Default, not collected in onboarding
            temperamentTalkative: talkativeScore,
            temperamentSensitivity: sensitiveScore,
            temperamentAccountability: accountableScore
        )

        // Update current child ID
        currentChildId = child.id
    }

    func completeOnboarding() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Mark onboarding as complete
            try await supabaseService.updateOnboardingState(.complete, currentChildId: nil)
            currentState = .complete
        } catch {
            errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
        }
    }

    func addAnotherChild() async {
        // Reset to CHILD_INFO with a new child ID
        currentChildId = UUID()
        resetChildForm()

        do {
            try await supabaseService.updateOnboardingState(.childInfo, currentChildId: currentChildId)
            currentState = .childInfo
        } catch {
            errorMessage = "Failed to start new child: \(error.localizedDescription)"
        }
    }

    // MARK: - Validation

    var canProceedFromUserInfo: Bool {
        !parentName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canProceedFromChildInfo: Bool {
        !childName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canProceedFromGoals: Bool {
        let totalGoals = selectedGoals.count + (customGoal.isEmpty ? 0 : 1)
        return totalGoals >= 1 && totalGoals <= 3
    }

    var canProceedFromTopics: Bool {
        selectedTopics.count >= 3
    }

    var canProceedFromDispositions: Bool {
        true // Always valid (has defaults)
    }

    // MARK: - Helpers

    private func saveCurrentStepData() async throws {
        switch currentState {
        case .userInfo:
            try await saveParentName()
        case .dispositions:
            try await saveChildData()
        default:
            break
        }
    }

    private func resetChildForm() {
        childName = ""
        childBirthday = Date()
        selectedGoals = []
        customGoal = ""
        selectedTopics = []
        talkativeScore = 5
        sensitiveScore = 5
        accountableScore = 5
        currentDispositionPage = 0
    }

    private func calculateAge(from birthday: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year ?? 0
    }
}

enum ValidationError: LocalizedError {
    case emptyName

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Name cannot be empty"
        }
    }
}
```

**Action Items:**
- [ ] Create OnboardingViewModel.swift
- [ ] Add to Xcode project
- [ ] Build and verify no errors

---

### **Phase 5: Onboarding Views**

#### Step 5.1: Create Main Onboarding Container View

**File**: `/Eko/Features/Onboarding/Views/OnboardingContainerView.swift`

```swift
import SwiftUI
import EkoCore

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        Group {
            switch viewModel.currentState {
            case .notStarted, .userInfo:
                UserInfoView(viewModel: viewModel)
            case .childInfo:
                ChildInfoView(viewModel: viewModel)
            case .goals:
                GoalsView(viewModel: viewModel)
            case .topics:
                TopicsView(viewModel: viewModel)
            case .dispositions:
                DispositionsView(viewModel: viewModel)
            case .review:
                ReviewView(viewModel: viewModel)
            case .complete:
                Color.clear // Should navigate to main app
            }
        }
        .task {
            await viewModel.loadOnboardingState()
        }
    }
}
```

**Action Items:**
- [ ] Create file
- [ ] Will implement individual step views next

---

#### Step 5.2: Create Step Views

Create these view files (detailed implementation in separate step):

1. **UserInfoView.swift** - Parent name input
2. **ChildInfoView.swift** - Child name + birthday picker
3. **GoalsView.swift** - Goal selection (1-3)
4. **TopicsView.swift** - Topic grid (minimum 3)
5. **DispositionsView.swift** - Three paginated sliders
6. **ReviewView.swift** - Summary + add more children option

**See** `feature-details.md` for exact UI specifications for each view.

**Action Items:**
- [ ] Create UserInfoView.swift
- [ ] Create ChildInfoView.swift
- [ ] Create GoalsView.swift
- [ ] Create TopicsView.swift
- [ ] Create DispositionsView.swift
- [ ] Create ReviewView.swift
- [ ] Test each view independently with preview data

---

### **Phase 6: App Integration & Routing**

#### Step 6.1: Update App Entry Point

**File**: `/Eko/EkoApp.swift`

**Current structure:**
```swift
@main
struct EkoApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
        }
    }
}
```

**Updated structure:**
```swift
@main
struct EkoApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
        }
    }
}
```

**Create new RootView** to handle routing logic.

---

#### Step 6.2: Create RootView Router

**File**: `/Eko/RootView.swift`

```swift
import SwiftUI
import EkoCore

struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var onboardingState: OnboardingState?
    @State private var isCheckingOnboarding = true

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if isCheckingOnboarding {
                    // Loading state while checking onboarding
                    ProgressView("Loading...")
                } else if let state = onboardingState, !state.isComplete {
                    // Show onboarding if incomplete
                    OnboardingContainerView()
                } else {
                    // Show main app if onboarding complete
                    ContentView()
                }
            } else {
                // Show authentication screen
                AuthenticationView()
            }
        }
        .task(id: authViewModel.isAuthenticated) {
            if authViewModel.isAuthenticated {
                await checkOnboardingStatus()
            }
        }
    }

    private func checkOnboardingStatus() async {
        isCheckingOnboarding = true
        defer { isCheckingOnboarding = false }

        do {
            let user = try await SupabaseService.shared.getCurrentUserWithProfile()
            onboardingState = user?.onboardingState ?? .notStarted
        } catch {
            print("Error checking onboarding status: \(error)")
            onboardingState = .notStarted
        }
    }
}
```

**Action Items:**
- [ ] Create RootView.swift
- [ ] Update EkoApp.swift to use RootView
- [ ] Test routing: Unauthenticated → Auth → Onboarding → Main App
- [ ] Test resumption: Log out during onboarding, log back in

---

### **Phase 7: Testing & Edge Cases**

#### Step 7.1: Test Scenarios

**Scenario 1: New User**
1. User signs in with Google (first time)
2. Trigger creates `user_profiles` record with `NOT_STARTED`
3. RootView detects incomplete onboarding
4. User goes through all 7 steps
5. State updates to `COMPLETE`
6. RootView navigates to main app

**Scenario 2: Incomplete Onboarding - Logout**
1. User starts onboarding, reaches step 3 (GOALS)
2. User logs out
3. User logs back in
4. RootView detects `onboardingState = GOALS`
5. User resumes at GOALS step

**Scenario 3: Incomplete Onboarding - App Reinstall**
1. User starts onboarding, reaches step 5 (DISPOSITIONS)
2. User uninstalls app
3. User reinstalls and logs in
4. RootView fetches profile from database
5. User resumes at DISPOSITIONS step

**Scenario 4: Multiple Children**
1. User completes first child through DISPOSITIONS
2. Reaches REVIEW, sees first child
3. Taps "Add Another Child"
4. Returns to CHILD_INFO with new `currentChildId`
5. Completes second child
6. Returns to REVIEW, sees both children
7. Taps "Complete Setup"
8. Onboarding state → COMPLETE

**Scenario 5: Existing Users (Post-Migration)**
1. Existing user logs in
2. Backfill script already set them to `COMPLETE`
3. RootView skips onboarding, goes to main app

**Action Items:**
- [ ] Test Scenario 1 (new user flow)
- [ ] Test Scenario 2 (logout resume)
- [ ] Test Scenario 3 (reinstall resume)
- [ ] Test Scenario 4 (multiple children)
- [ ] Test Scenario 5 (existing users)

---

#### Step 7.2: Error Handling

**Handle these error cases:**

1. **Network failure during save** → Show error alert, allow retry
2. **Invalid data submission** → Show validation error, prevent navigation
3. **Session expires mid-onboarding** → Redirect to auth, preserve state
4. **Database constraint violation** → Show error message, log issue
5. **Missing user_profile record** → Auto-create via fallback in `getUserProfile()`

**Action Items:**
- [ ] Add try-catch blocks around all database calls
- [ ] Display user-friendly error messages
- [ ] Add retry mechanisms for network failures
- [ ] Test with airplane mode enabled

---

### **Phase 8: Polish & UX Improvements**

#### Step 8.1: Loading States

Add loading indicators for:
- Database save operations
- State transitions
- Child data fetching

**Action Items:**
- [ ] Add `ProgressView` overlays during async operations
- [ ] Disable buttons while loading

---

#### Step 8.2: Accessibility

**Action Items:**
- [ ] Add VoiceOver labels to all form fields
- [ ] Test with VoiceOver enabled
- [ ] Ensure proper focus management
- [ ] Add dynamic type support

---

#### Step 8.3: Analytics (Optional)

Track onboarding progress:
- Step completions
- Drop-off points
- Time spent per step
- Number of children added

**Action Items:**
- [ ] Add analytics events for each step transition
- [ ] Track completion rate
- [ ] Monitor drop-off points

---

## Deployment Checklist

### Pre-Deployment

- [ ] All migration files created and tested locally
- [ ] All Swift models created and building successfully
- [ ] All views implemented and tested
- [ ] Routing logic tested (auth → onboarding → main app)
- [ ] Resume logic tested (logout, reinstall)
- [ ] Error handling tested
- [ ] Backfill script prepared for existing users

### Deployment

- [ ] Run migration on production Supabase instance
- [ ] Run backfill script for existing users
- [ ] Deploy app update to TestFlight
- [ ] Test with fresh install on physical device
- [ ] Test with existing user account

### Post-Deployment

- [ ] Monitor error logs for onboarding failures
- [ ] Track onboarding completion rate
- [ ] Gather user feedback
- [ ] Iterate on UX improvements

---

## Key Dependencies & Constraints

### Database Dependencies
- Supabase Auth (`auth.users` table must exist)
- PostgREST API for CRUD operations
- Trigger functions for auto-creating `user_profiles`

### Swift Dependencies
- SwiftUI for view layer
- EkoCore module for models
- SupabaseService for API calls
- AuthViewModel for authentication state

### Constraints
- Must support iOS 17+ (SwiftUI @Observable)
- Must handle offline scenarios gracefully
- Must preserve state across app kills
- Must support multiple children per user
- Must validate all inputs before saving

---

## Future Enhancements

- [ ] Add onboarding skip option (with confirmation)
- [ ] Add edit profile feature to change child details post-onboarding
- [ ] Add onboarding progress bar UI
- [ ] Add animations between steps
- [ ] Add haptic feedback on successful saves
- [ ] Add onboarding restart option in settings
- [ ] Add A/B testing for different onboarding flows

---

## Questions & Decisions

### Decision Log

| Question | Decision | Date | Rationale |
|----------|----------|------|-----------|
| Store `displayName` in `user_profiles` or `auth.users.user_metadata`? | Keep in `user_metadata` | Oct 19 | Minimal migration, already working |
| Keep `age` field or compute from `birthday`? | Keep both | Oct 19 | `age` used elsewhere, redundancy acceptable |
| Allow skipping onboarding? | No (for MVP) | Oct 19 | All features require child profiles |
| Support deleting children during onboarding? | No | Oct 19 | Can be added to settings later |

---

## Support & Resources

- **Onboarding Spec**: `/docs/ai/features/onboarding/feature-details.md`
- **Project Overview**: `/docs/ai/project-wide/project-overview.md`
- **Supabase Docs**: https://supabase.com/docs
- **SwiftUI Docs**: https://developer.apple.com/documentation/swiftui

---

**End of Implementation Plan**
