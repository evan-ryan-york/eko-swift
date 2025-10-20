# Onboarding Implementation Plan

**Version**: 1.1
**Last Updated**: January 20, 2025
**Feature**: User Onboarding Flow
**Status**: Planning Phase

> **📚 Related Documentation:**
> - [Testing Strategy](/docs/ai/project-wide/testing-strategy.md) - Comprehensive testing approach for the entire app
> - [Feature Details](/docs/ai/features/onboarding/feature-details.md) - Detailed onboarding specifications

---

## Overview

This document provides a step-by-step implementation plan for building the Eko onboarding flow. When complete, new users will:

1. Sign in with Google
2. Be automatically detected as new users
3. Progress through the onboarding flow (7 steps)
4. Resume onboarding if they log out or uninstall before completing
5. Skip onboarding if already completed

**Testing Approach**: This implementation follows the testing pyramid strategy with 50% unit tests, 30% integration tests, 15% UI tests, and 5% manual testing. See Phase 7 for detailed testing implementation.

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
ADD COLUMN IF NOT EXISTS topics TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS temperament_talkative INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS temperament_sensitivity INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS temperament_accountability INTEGER DEFAULT 5;

-- Add validation constraints
ALTER TABLE children
ADD CONSTRAINT valid_birthday CHECK (birthday <= CURRENT_DATE),
ADD CONSTRAINT valid_temperament_talkative CHECK (temperament_talkative BETWEEN 1 AND 10),
ADD CONSTRAINT valid_temperament_sensitivity CHECK (temperament_sensitivity BETWEEN 1 AND 10),
ADD CONSTRAINT valid_temperament_accountability CHECK (temperament_accountability BETWEEN 1 AND 10);

COMMENT ON COLUMN children.birthday IS 'Child''s date of birth (ISO date)';
COMMENT ON COLUMN children.goals IS 'Parent conversation goals (1-3 items from onboarding)';
COMMENT ON COLUMN children.topics IS 'Selected conversation topic IDs (minimum 3 from onboarding)';
COMMENT ON COLUMN children.temperament_talkative IS 'Communication style: 1 (Quiet) to 10 (Talkative)';
COMMENT ON COLUMN children.temperament_sensitivity IS 'Emotional response: 1 (Argumentative) to 10 (Sensitive)';
COMMENT ON COLUMN children.temperament_accountability IS 'Responsibility: 1 (Denial) to 10 (Accountable)';

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

### **Phase 7: Automated Testing**

> **Reference**: See `/docs/ai/project-wide/testing-strategy.md` for comprehensive testing strategy

This phase implements automated tests following the testing pyramid: Unit Tests (50%) → Integration Tests (30%) → UI Tests (15%) → Manual Testing (5%).

---

#### Step 7.1: Test Infrastructure Setup

**Goal**: Create test targets and mock services

**File**: Create Xcode test targets

1. **Create Unit Test Target**:
   - File → New → Target → iOS Unit Testing Bundle
   - Name: `EkoTests`
   - Add to Eko project
   - Link `EkoCore` framework to test target

2. **Create Mock Services**:

**File**: `/Eko/EkoTests/Mocks/MockSupabaseService.swift`

```swift
import Foundation
import EkoCore
@testable import Eko

final class MockSupabaseService: SupabaseServiceProtocol {
    // Control behavior
    var shouldSucceed = true
    var networkError: Error?

    // Track calls
    var updateDisplayNameCalled = false
    var updateOnboardingStateCalled = false
    var createChildCalled = false

    // Mock data
    var mockUserProfile: UserProfile?
    var mockUser: User?
    var mockChild: Child?
    var mockChildren: [Child] = []

    // MARK: - User Profile Methods

    func getUserProfile() async throws -> UserProfile {
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        return mockUserProfile ?? UserProfile(
            id: UUID(),
            onboardingState: .notStarted,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateOnboardingState(_ state: OnboardingState, currentChildId: UUID?) async throws {
        updateOnboardingStateCalled = true
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        mockUserProfile?.onboardingState = state
        mockUserProfile?.currentChildId = currentChildId
    }

    func updateDisplayName(_ displayName: String) async throws {
        updateDisplayNameCalled = true
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        mockUser?.displayName = displayName
    }

    func getCurrentUserWithProfile() async throws -> User? {
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }
        return mockUser
    }

    // MARK: - Child Methods

    func createChild(
        name: String,
        age: Int,
        birthday: Date,
        goals: [String],
        topics: [String],
        temperament: Temperament,
        temperamentTalkative: Int,
        temperamentSensitivity: Int,
        temperamentAccountability: Int
    ) async throws -> Child {
        createChildCalled = true
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        let child = Child(
            id: UUID(),
            userId: mockUser?.id ?? UUID(),
            name: name,
            age: age,
            birthday: birthday,
            goals: goals,
            topics: topics,
            temperament: temperament,
            temperamentTalkative: temperamentTalkative,
            temperamentSensitivity: temperamentSensitivity,
            temperamentAccountability: temperamentAccountability,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockChild = child
        mockChildren.append(child)
        return child
    }

    func fetchChildren(forUserId userId: UUID) async throws -> [Child] {
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }
        return mockChildren
    }
}

enum TestError: Error {
    case operationFailed
}
```

3. **Create Test Fixtures**:

**File**: `/Eko/EkoTests/Fixtures/TestFixtures.swift`

```swift
import Foundation
import EkoCore

enum TestFixtures {
    static let testUserId = UUID()
    static let testChildId = UUID()

    static var testUser: User {
        User(
            id: testUserId,
            email: "test@example.com",
            createdAt: Date(),
            updatedAt: Date(),
            displayName: "Test Parent",
            onboardingState: .notStarted
        )
    }

    static var testChild: Child {
        Child(
            id: testChildId,
            userId: testUserId,
            name: "Test Child",
            age: 10,
            birthday: Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
            goals: ["Understanding their thoughts and feelings better"],
            topics: ["emotions", "friends", "school"],
            temperament: .easygoing,
            temperamentTalkative: 7,
            temperamentSensitivity: 5,
            temperamentAccountability: 8,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var testUserProfile: UserProfile {
        UserProfile(
            id: testUserId,
            onboardingState: .notStarted,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
```

**Action Items:**
- [ ] Create `EkoTests` target in Xcode
- [ ] Create `MockSupabaseService.swift`
- [ ] Create `TestFixtures.swift`
- [ ] Verify test target builds successfully

---

#### Step 7.2: Unit Tests - OnboardingViewModel

**Goal**: Test all business logic and validation rules (Target: 30 tests, 80%+ coverage)

**File**: `/Eko/EkoTests/Features/Onboarding/OnboardingViewModelTests.swift`

```swift
import XCTest
@testable import Eko
import EkoCore

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    var sut: OnboardingViewModel!
    var mockService: MockSupabaseService!

    override func setUp() {
        super.setUp()
        mockService = MockSupabaseService()
        sut = OnboardingViewModel(supabaseService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - User Info Validation Tests

    func test_canProceedFromUserInfo_returnsFalse_whenNameIsEmpty() {
        // Given
        sut.parentName = ""

        // When
        let canProceed = sut.canProceedFromUserInfo

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromUserInfo_returnsFalse_whenNameIsWhitespace() {
        // Given
        sut.parentName = "   "

        // When
        let canProceed = sut.canProceedFromUserInfo

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromUserInfo_returnsTrue_whenNameIsValid() {
        // Given
        sut.parentName = "John Doe"

        // When
        let canProceed = sut.canProceedFromUserInfo

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - Child Info Validation Tests

    func test_canProceedFromChildInfo_returnsFalse_whenNameIsEmpty() {
        // Given
        sut.childName = ""

        // When
        let canProceed = sut.canProceedFromChildInfo

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromChildInfo_returnsTrue_whenNameIsValid() {
        // Given
        sut.childName = "Jane Doe"

        // When
        let canProceed = sut.canProceedFromChildInfo

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - Goals Validation Tests

    func test_canProceedFromGoals_returnsFalse_whenNoGoalsSelected() {
        // Given
        sut.selectedGoals = []
        sut.customGoal = ""

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenOneGoalSelected() {
        // Given
        sut.selectedGoals = ["Understanding their thoughts and feelings better"]

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenThreeGoalsSelected() {
        // Given
        sut.selectedGoals = [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges",
            "Connecting with them on a deeper level"
        ]

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromGoals_returnsFalse_whenMoreThanThreeGoalsSelected() {
        // Given
        sut.selectedGoals = [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges",
            "Connecting with them on a deeper level",
            "Encouraging them to open up more"
        ]

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenCustomGoalProvided() {
        // Given
        sut.selectedGoals = []
        sut.customGoal = "Building trust"

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - Topics Validation Tests

    func test_canProceedFromTopics_returnsFalse_whenLessThanThreeTopicsSelected() {
        // Given
        sut.selectedTopics = ["emotions", "friends"]

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromTopics_returnsTrue_whenThreeTopicsSelected() {
        // Given
        sut.selectedTopics = ["emotions", "friends", "school"]

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromTopics_returnsTrue_whenMoreThanThreeTopicsSelected() {
        // Given
        sut.selectedTopics = ["emotions", "friends", "school", "family", "conflict"]

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - State Transition Tests

    func test_moveToNextStep_transitionsFromUserInfoToChildInfo() async {
        // Given
        sut.currentState = .userInfo
        sut.parentName = "John Doe"
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .childInfo)
        XCTAssertTrue(mockService.updateDisplayNameCalled)
    }

    func test_moveToNextStep_transitionsFromChildInfoToGoals() async {
        // Given
        sut.currentState = .childInfo
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .goals)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
    }

    func test_moveToNextStep_transitionsFromDispositionsToReview() async {
        // Given
        sut.currentState = .dispositions
        sut.childName = "Jane Doe"
        sut.childBirthday = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        sut.selectedGoals = ["Understanding feelings"]
        sut.selectedTopics = ["emotions", "friends", "school"]
        mockService.shouldSucceed = true
        mockService.mockUser = TestFixtures.testUser

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .review)
        XCTAssertTrue(mockService.createChildCalled)
    }

    func test_moveToNextStep_setsErrorMessage_whenServiceFails() async {
        // Given
        sut.currentState = .userInfo
        sut.parentName = "John Doe"
        mockService.shouldSucceed = false

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.currentState, .userInfo) // Should not transition on error
    }

    // MARK: - Child Data Save Tests

    func test_saveChildData_createsChild_withAllData() async throws {
        // Given
        sut.childName = "Jane Doe"
        sut.childBirthday = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        sut.selectedGoals = ["Understanding feelings"]
        sut.selectedTopics = ["emotions", "friends", "school"]
        sut.talkativeScore = 7
        sut.sensitiveScore = 5
        sut.accountableScore = 8
        mockService.shouldSucceed = true
        mockService.mockUser = TestFixtures.testUser

        // When
        try await sut.saveChildData()

        // Then
        XCTAssertTrue(mockService.createChildCalled)
        XCTAssertNotNil(mockService.mockChild)
        XCTAssertEqual(mockService.mockChild?.name, "Jane Doe")
        XCTAssertEqual(mockService.mockChild?.goals, ["Understanding feelings"])
        XCTAssertEqual(mockService.mockChild?.topics.count, 3)
    }

    func test_saveChildData_includesCustomGoal_whenProvided() async throws {
        // Given
        sut.childName = "Jane Doe"
        sut.childBirthday = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        sut.selectedGoals = ["Understanding feelings"]
        sut.customGoal = "Building confidence"
        sut.selectedTopics = ["emotions", "friends", "school"]
        mockService.shouldSucceed = true
        mockService.mockUser = TestFixtures.testUser

        // When
        try await sut.saveChildData()

        // Then
        XCTAssertEqual(mockService.mockChild?.goals.count, 2)
        XCTAssertTrue(mockService.mockChild?.goals.contains("Building confidence") ?? false)
    }

    func test_saveChildData_throwsError_whenNameIsEmpty() async {
        // Given
        sut.childName = "   "

        // When/Then
        do {
            try await sut.saveChildData()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    // MARK: - Multiple Children Tests

    func test_addAnotherChild_resetsForm_andTransitionsToChildInfo() async {
        // Given
        sut.currentState = .review
        sut.childName = "First Child"
        sut.selectedGoals = ["Goal 1"]
        mockService.shouldSucceed = true

        // When
        await sut.addAnotherChild()

        // Then
        XCTAssertEqual(sut.currentState, .childInfo)
        XCTAssertEqual(sut.childName, "")
        XCTAssertTrue(sut.selectedGoals.isEmpty)
        XCTAssertNotNil(sut.currentChildId)
    }

    // MARK: - Completion Tests

    func test_completeOnboarding_updatesStateToComplete() async {
        // Given
        mockService.shouldSucceed = true

        // When
        await sut.completeOnboarding()

        // Then
        XCTAssertEqual(sut.currentState, .complete)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
    }

    // MARK: - Error Handling Tests

    func test_loadOnboardingState_setsErrorMessage_onNetworkFailure() async {
        // Given
        mockService.networkError = URLError(.notConnectedToInternet)

        // When
        await sut.loadOnboardingState()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to load"))
    }
}
```

**Additional Test Files to Create:**

1. **`OnboardingStateTests.swift`** - Test state machine logic
2. **`ConversationTopicTests.swift`** - Test topic constants
3. **`UserProfileTests.swift`** - Test model encoding/decoding
4. **`ChildValidationTests.swift`** - Test child model validation

**Action Items:**
- [ ] Create `OnboardingViewModelTests.swift` (30 tests)
- [ ] Create `OnboardingStateTests.swift` (10 tests)
- [ ] Create `ConversationTopicTests.swift` (5 tests)
- [ ] Run tests: `Cmd+U` in Xcode
- [ ] Verify all tests pass and coverage ≥ 70%

---

#### Step 7.3: Integration Tests - SupabaseService

**Goal**: Test API integration with mock responses (Target: 10 tests)

**File**: `/Eko/EkoTests/Core/Services/SupabaseServiceIntegrationTests.swift`

```swift
import XCTest
@testable import Eko
import EkoCore

final class SupabaseServiceIntegrationTests: XCTestCase {

    var sut: SupabaseService!

    override func setUp() async throws {
        try await super.setUp()
        // Use test Supabase instance or mock responses
        // For MVP: Can skip if using MockSupabaseService throughout
    }

    // MARK: - User Profile Tests

    func test_getUserProfile_returnsProfile_forAuthenticatedUser() async throws {
        // Given: User is authenticated

        // When
        let profile = try await sut.getUserProfile()

        // Then
        XCTAssertNotNil(profile.id)
        XCTAssertNotNil(profile.onboardingState)
    }

    func test_updateOnboardingState_updatesDatabase() async throws {
        // Given
        let newState = OnboardingState.childInfo

        // When
        try await sut.updateOnboardingState(newState)

        // Then
        let profile = try await sut.getUserProfile()
        XCTAssertEqual(profile.onboardingState, newState)
    }

    // MARK: - Child CRUD Tests

    func test_createChild_savesChildToDatabase() async throws {
        // Given
        let childData = TestFixtures.testChild

        // When
        let createdChild = try await sut.createChild(
            name: childData.name,
            age: childData.age,
            birthday: childData.birthday,
            goals: childData.goals,
            topics: childData.topics,
            temperament: childData.temperament,
            temperamentTalkative: childData.temperamentTalkative,
            temperamentSensitivity: childData.temperamentSensitivity,
            temperamentAccountability: childData.temperamentAccountability
        )

        // Then
        XCTAssertNotNil(createdChild.id)
        XCTAssertEqual(createdChild.name, childData.name)
        XCTAssertEqual(createdChild.goals, childData.goals)
        XCTAssertEqual(createdChild.topics.count, 3)

        // Cleanup
        // try await sut.deleteChild(id: createdChild.id)
    }

    func test_fetchChildren_returnsAllUserChildren() async throws {
        // Given: User has created children
        let userId = TestFixtures.testUserId

        // When
        let children = try await sut.fetchChildren(forUserId: userId)

        // Then
        XCTAssertGreaterThanOrEqual(children.count, 0)
    }

    // MARK: - Error Handling Tests

    func test_createChild_throwsError_whenBirthdayInFuture() async {
        // Given
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        // When/Then
        do {
            _ = try await sut.createChild(
                name: "Test",
                age: -1,
                birthday: futureDate,
                goals: ["Goal"],
                topics: ["topic1", "topic2", "topic3"],
                temperament: .easygoing
            )
            XCTFail("Should have thrown database constraint error")
        } catch {
            // Expected error
            XCTAssertTrue(true)
        }
    }
}
```

**Action Items:**
- [ ] Create `SupabaseServiceIntegrationTests.swift` (10 tests)
- [ ] Set up test Supabase instance or comprehensive mocks
- [ ] Run integration tests: `Cmd+U`
- [ ] Verify database operations work correctly

**Note**: For MVP, integration tests can use `MockSupabaseService` instead of real database calls. Real integration tests can be added post-MVP.

---

#### Step 7.4: UI Tests - Critical Paths Only

**Goal**: Automate 2-3 critical user journeys (Target: 3 tests max for MVP)

**Setup**:
1. File → New → Target → iOS UI Testing Bundle
2. Name: `EkoUITests`
3. Configure app launch arguments for testing

**File**: `/Eko/EkoUITests/OnboardingFlowUITests.swift`

```swift
import XCTest

final class OnboardingFlowUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Configure app for UI testing
        app.launchArguments = ["UI-TESTING", "DISABLE-ANIMATIONS"]
        app.launch()
    }

    // MARK: - Happy Path Test

    func testOnboardingFlow_completesSuccessfully_withOneChild() {
        // Note: This test assumes mock authentication for UI testing
        // You'll need to set up test authentication in your app when UI-TESTING flag is set

        // Given: User is authenticated and at onboarding start

        // Step 1: User Info
        let nameField = app.textFields["parentNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test Parent")

        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        // Step 2: Child Info
        let childNameField = app.textFields["childNameField"]
        XCTAssertTrue(childNameField.waitForExistence(timeout: 2))
        childNameField.tap()
        childNameField.typeText("Test Child")

        // Select birthday (simplified - adjust based on your date picker implementation)
        let datePicker = app.datePickers["childBirthdayPicker"]
        if datePicker.exists {
            // Interact with date picker
        }

        app.buttons["nextButton"].tap()

        // Step 3: Goals
        let goal1 = app.buttons["goal_understanding"]
        XCTAssertTrue(goal1.waitForExistence(timeout: 2))
        goal1.tap()

        XCTAssertTrue(app.buttons["nextButton"].isEnabled)
        app.buttons["nextButton"].tap()

        // Step 4: Topics
        let topic1 = app.buttons["topic_emotions"]
        let topic2 = app.buttons["topic_friends"]
        let topic3 = app.buttons["topic_school"]

        XCTAssertTrue(topic1.waitForExistence(timeout: 2))
        topic1.tap()
        topic2.tap()
        topic3.tap()

        XCTAssertTrue(app.buttons["nextButton"].isEnabled)
        app.buttons["nextButton"].tap()

        // Step 5: Dispositions (navigate through 3 pages)
        XCTAssertTrue(app.sliders["talkativeSlider"].waitForExistence(timeout: 2))
        app.buttons["nextButton"].tap() // Page 2

        XCTAssertTrue(app.sliders["sensitiveSlider"].exists)
        app.buttons["nextButton"].tap() // Page 3

        XCTAssertTrue(app.sliders["accountableSlider"].exists)
        app.buttons["finishButton"].tap() // Complete dispositions

        // Step 6: Review
        let completeButton = app.buttons["completeSetupButton"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 2))

        // Verify child is displayed in review
        XCTAssertTrue(app.staticTexts["Test Child"].exists)

        completeButton.tap()

        // Then: Should navigate to main app
        // Verify main app screen appears (adjust based on your app)
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 3))
    }

    // MARK: - Validation Tests

    func testOnboarding_disablesNextButton_whenNameIsEmpty() {
        // Given: User is on User Info step
        let nextButton = app.buttons["nextButton"]

        // When: Name field is empty
        // (default state)

        // Then: Next button should be disabled
        XCTAssertFalse(nextButton.isEnabled)
    }

    func testTopicsSelection_requiresMinimumThree() {
        // Given: User navigates to Topics step
        // (Navigate through previous steps first - abbreviated for brevity)

        // When: User selects only 2 topics
        let topic1 = app.buttons["topic_emotions"]
        let topic2 = app.buttons["topic_friends"]

        topic1.tap()
        topic2.tap()

        // Then: Next button should be disabled
        XCTAssertFalse(app.buttons["nextButton"].isEnabled)

        // When: User selects 3rd topic
        app.buttons["topic_school"].tap()

        // Then: Next button should be enabled
        XCTAssertTrue(app.buttons["nextButton"].isEnabled)
    }
}
```

**Action Items:**
- [ ] Create `EkoUITests` target
- [ ] Create `OnboardingFlowUITests.swift` (3 tests)
- [ ] Add accessibility identifiers to all interactive elements in views
- [ ] Set up test authentication for UI testing
- [ ] Run UI tests: `Cmd+U` (select EkoUITests scheme)

**Note**: UI tests are slow. Only add critical path coverage for MVP. Expand post-launch.

---

#### Step 7.5: Manual Test Scenarios

**Goal**: Document manual testing checklist for QA and release testing

**Test Scenarios to Execute Manually**:

**Scenario 1: New User - Complete Flow**
- [ ] Fresh install → Google sign in → Complete all onboarding steps → Reach main app
- [ ] Verify user profile created in database
- [ ] Verify child created with all data (goals, topics, dispositions)
- [ ] Verify onboarding state = COMPLETE

**Scenario 2: Incomplete Onboarding - Resume**
- [ ] Start onboarding → Stop at GOALS step → Force quit app
- [ ] Reopen app → Verify resumes at GOALS step
- [ ] Complete onboarding → Verify reaches main app

**Scenario 3: Multiple Children**
- [ ] Complete onboarding with 1st child → Reach REVIEW
- [ ] Tap "Add Another Child" → Complete 2nd child
- [ ] Verify REVIEW shows both children
- [ ] Complete setup → Verify main app

**Scenario 4: Network Failure Handling**
- [ ] Enable airplane mode during onboarding
- [ ] Attempt to proceed to next step
- [ ] Verify error message appears
- [ ] Disable airplane mode → Retry → Verify success

**Scenario 5: Validation Enforcement**
- [ ] Try to proceed with empty name → Verify button disabled
- [ ] Try to proceed with < 3 topics → Verify button disabled
- [ ] Try to proceed with 0 goals → Verify button disabled
- [ ] Try to proceed with > 3 goals → Verify button disabled

**Scenario 6: Edge Cases**
- [ ] Enter very long name (100+ characters) → Verify handles gracefully
- [ ] Select child birthday as today → Verify age = 0 accepted
- [ ] Add custom goal with special characters → Verify saves correctly
- [ ] Select all 12 topics → Verify all save correctly

**Scenario 7: Existing User (Post-Migration)**
- [ ] User who completed onboarding previously
- [ ] Login → Verify skips onboarding → Goes to main app

**Test Devices**:
- [ ] iPhone SE 3rd Gen (smallest screen) - iOS 17.2
- [ ] iPhone 15 Pro (latest) - iOS 17.2
- [ ] iPad Pro (tablet layout) - iOS 17.2

**Action Items:**
- [ ] Execute all manual test scenarios before TestFlight release
- [ ] Document any bugs found in GitHub issues
- [ ] Retest after bug fixes
- [ ] Get sign-off from QA/Product before production deployment

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

**Database & Backend:**
- [ ] All migration files created and tested locally
- [ ] Database migration tested on staging Supabase instance
- [ ] RLS policies verified (users can only access own data)
- [ ] Trigger functions tested (user_profile auto-creation)
- [ ] Backfill script prepared for existing users

**Code & Implementation:**
- [ ] All Swift models created and building successfully
- [ ] All views implemented with proper accessibility identifiers
- [ ] Routing logic implemented (auth → onboarding → main app)
- [ ] Error handling implemented for all API calls
- [ ] Loading states added to all async operations

**Testing:**
- [ ] Unit tests passing: ≥40 tests, ≥70% coverage
- [ ] Integration tests passing: ≥10 tests
- [ ] UI tests passing: ≥3 critical path tests
- [ ] All manual test scenarios executed successfully (7 scenarios)
- [ ] Tested on iPhone SE 3rd Gen, iPhone 15 Pro, iPad Pro
- [ ] Tested with poor network conditions (airplane mode)
- [ ] No flaky tests (all tests run 3x successfully)
- [ ] Code coverage report generated and reviewed

**Code Quality:**
- [ ] No compiler warnings
- [ ] No memory leaks detected (Instruments Leaks tool)
- [ ] Performance acceptable (loading < 3 seconds)
- [ ] Accessibility tested with VoiceOver

### Deployment

**Backend Deployment:**
- [ ] Run migration on production Supabase instance
- [ ] Verify migration succeeded (check tables exist)
- [ ] Run backfill script for existing users
- [ ] Verify existing users have onboardingState = COMPLETE

**App Deployment:**
- [ ] Deploy app update to TestFlight (internal testing)
- [ ] Internal team testing (2-3 people, 2-3 days)
- [ ] Fix any critical bugs found
- [ ] Deploy to TestFlight (external testing)
- [ ] Beta tester feedback collected

**Device Testing:**
- [ ] Test with fresh install on iPhone (physical device)
- [ ] Test with fresh install on iPad (physical device)
- [ ] Test with existing user account (upgrade flow)
- [ ] Test on iOS 17.0 (minimum version)
- [ ] Test on latest iOS version

**Verification:**
- [ ] Verify database records created correctly
- [ ] Verify analytics tracking onboarding events (if implemented)
- [ ] Verify no crashes in TestFlight crash logs
- [ ] Verify user can complete onboarding end-to-end

### Post-Deployment

**Monitoring (First Week):**
- [ ] Monitor error logs for onboarding failures (daily)
- [ ] Track onboarding completion rate (target: > 80%)
- [ ] Track onboarding drop-off points
- [ ] Monitor API error rates for onboarding endpoints
- [ ] Check user feedback in TestFlight comments

**Metrics to Track:**
- [ ] % of users who start onboarding
- [ ] % of users who complete onboarding
- [ ] Average time to complete onboarding
- [ ] Most common drop-off step
- [ ] Number of multiple children added

**Iteration:**
- [ ] Gather user feedback via TestFlight or support channels
- [ ] Create GitHub issues for any bugs or UX improvements
- [ ] Prioritize fixes for critical issues (blocking progress)
- [ ] Plan next iteration based on data

**Production Release:**
- [ ] All critical issues resolved
- [ ] Onboarding completion rate ≥ 75%
- [ ] No P0/P1 bugs remaining
- [ ] Product/QA sign-off obtained
- [ ] Submit to App Store review

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
| Unit test coverage target for onboarding? | 70-80% | Jan 20 | Balance between quality and velocity |
| Use protocol-based mocking or framework? | Protocol-based | Jan 20 | Simpler, faster, no external dependencies |
| Number of UI tests for MVP? | 3 critical paths | Jan 20 | UI tests are slow, focus on happy path |
| Test with real Supabase or mocks? | Mocks for MVP | Jan 20 | Faster, can add real integration tests later |

---

## Support & Resources

### Documentation
- **Feature Specification**: `/docs/ai/features/onboarding/feature-details.md`
- **Testing Strategy**: `/docs/ai/project-wide/testing-strategy.md`
- **Project Overview**: `/docs/ai/project-wide/project-overview.md`

### External Resources
- **Supabase Documentation**: https://supabase.com/docs
- **SwiftUI Documentation**: https://developer.apple.com/documentation/swiftui
- **XCTest Framework**: https://developer.apple.com/documentation/xctest
- **iOS Testing Guide**: https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/

### Testing Tools
- **Xcode Instruments**: For memory leak detection and performance profiling
- **TestFlight**: For beta testing and crash log analysis
- **GitHub Actions**: For CI/CD test automation

---

## Summary

This implementation plan covers:
- **8 Phases**: Database setup → Models → Services → ViewModels → Views → Integration → **Testing** → Polish
- **7 Onboarding Steps**: User Info → Child Info → Goals → Topics → Dispositions → Review → Complete
- **50+ Automated Tests**: Unit, integration, and UI tests for comprehensive coverage
- **7 Manual Test Scenarios**: Critical path validation before release
- **Comprehensive Deployment Checklist**: Pre-deployment → Deployment → Post-deployment monitoring

**Key Success Metrics**:
- ≥70% unit test coverage
- ≥80% onboarding completion rate
- < 5% error rate for onboarding API calls
- < 3 seconds average completion time per step

---

**End of Implementation Plan**
