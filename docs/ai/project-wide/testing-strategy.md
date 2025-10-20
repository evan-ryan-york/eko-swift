# Eko Testing Strategy

**Version**: 1.0
**Last Updated**: January 20, 2025
**Status**: Active
**Platform**: iOS (Swift + SwiftUI)

---

## Executive Summary

This document defines Eko's testing strategy for achieving **long-term durability without sacrificing development velocity**. As an MVP launching to real customers in months, we prioritize high-value tests that catch critical bugs while avoiding test maintenance overhead that slows iteration.

**Key Principle**: Test what matters, skip what doesn't.

---

## Testing Philosophy

### Core Principles

1. **Critical Path First**: Focus on flows that directly impact user experience and data integrity
2. **Business Logic > UI Details**: Prioritize ViewModel/Service testing over pixel-perfect UI testing
3. **Fast Feedback Loops**: Tests should run in seconds, not minutes
4. **Maintainable > Comprehensive**: 50 maintainable tests beat 500 brittle ones
5. **Test at the Right Level**: Use the testing pyramid to guide effort distribution

### What We Test

✅ **Always Test**:
- Authentication flows (login, logout, session management)
- Data persistence (creating/updating/deleting records)
- Critical business logic (age calculations, validation rules)
- API integration with Supabase (mocked for unit tests)
- State management in ViewModels
- Payment/subscription flows (when implemented)
- Onboarding completion logic
- Data model transformations

⚠️ **Selectively Test**:
- Complex UI interactions (multi-step forms, sliders)
- Navigation flows (critical paths only)
- Error handling and recovery
- Offline behavior for key features

❌ **Don't Test**:
- SwiftUI view layout/appearance (trust Apple's framework)
- Third-party library internals (Supabase SDK, WebRTC)
- Trivial computed properties or formatting
- Constants and enums without logic
- Generated code or boilerplate

---

## Testing Pyramid for iOS

Our testing distribution follows the mobile testing pyramid:

```
              ┌─────────────┐
              │   Manual    │  5% - Exploratory testing, edge devices
              │   Testing   │
              └─────────────┘
           ┌──────────────────┐
           │   UI/E2E Tests   │  15% - Critical user journeys
           │   (XCUITest)     │
           └──────────────────┘
        ┌────────────────────────┐
        │  Integration Tests     │  30% - API + Database + Services
        │  (XCTest)              │
        └────────────────────────┘
    ┌─────────────────────────────────┐
    │    Unit Tests                   │  50% - ViewModels, Models, Utils
    │    (XCTest)                     │
    └─────────────────────────────────┘
```

### Target Coverage by Layer

| Layer | Tool | Coverage Goal | Speed | Priority |
|-------|------|---------------|-------|----------|
| Unit Tests | XCTest | 70-80% of business logic | < 5 sec | **High** |
| Integration Tests | XCTest | Key API operations | < 30 sec | **Medium** |
| UI Tests | XCUITest | 3-5 critical paths | < 2 min | **Low** (MVP) |
| Manual Tests | Human QA | Full feature validation | Variable | **Medium** |

---

## Testing Tools & Frameworks

### Native iOS Testing Stack

We use Apple's native testing frameworks to minimize dependencies and maximize long-term stability:

#### 1. **XCTest** (Unit & Integration Testing)
- **Purpose**: Test business logic, ViewModels, services, models
- **Location**: `EkoTests/`, `EkoCoreTests/`
- **Why**: Native, fast, well-documented, zero setup cost

#### 2. **XCUITest** (UI Testing)
- **Purpose**: Test critical user flows end-to-end
- **Location**: `EkoUITests/`
- **Why**: Native, handles accessibility automatically, integrates with Xcode

#### 3. **Swift Testing** (Future)
- **Purpose**: Eventual migration from XCTest for better Swift syntax
- **Status**: Monitor for iOS 18+ adoption
- **Why**: Modern Swift-first API, better async support

### Supporting Tools

#### **Mocking/Stubbing**
- **Manual Protocols**: Create `MockSupabaseService` conforming to `SupabaseServiceProtocol`
- **Avoid**: Heavy mocking frameworks (add complexity for little value)
- **Strategy**: Protocol-based dependency injection

```swift
// Example
protocol SupabaseServiceProtocol {
    func getCurrentUser() async throws -> User?
    func createChild(...) async throws -> Child
}

// Production
class SupabaseService: SupabaseServiceProtocol { ... }

// Testing
class MockSupabaseService: SupabaseServiceProtocol {
    var mockUser: User?
    func getCurrentUser() async throws -> User? { return mockUser }
}
```

#### **Snapshot Testing** (Optional, Post-MVP)
- **Tool**: [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
- **Use Case**: Verify complex UI layouts (charts, conversation bubbles)
- **When**: After MVP when UI is stabilized

#### **Test Data Builders**
- **Pattern**: Builder pattern for creating test fixtures
- **Location**: `EkoTests/Fixtures/`
- **Benefit**: Consistent, readable test data

```swift
struct ChildBuilder {
    static func build(
        name: String = "Test Child",
        age: Int = 10,
        birthday: Date = Date(),
        goals: [String] = ["Understanding feelings"],
        topics: [String] = ["emotions", "friends", "school"]
    ) -> Child {
        return Child(...)
    }
}
```

---

## Test Organization

### Directory Structure

```
Eko/
├── Eko/                          # Main app target
├── EkoTests/                     # Unit & Integration tests
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingViewModelTests.swift
│   │   │   ├── OnboardingValidationTests.swift
│   │   ├── Authentication/
│   │   │   ├── AuthViewModelTests.swift
│   │   ├── Lyra/
│   │   │   ├── LyraViewModelTests.swift
│   ├── Core/
│   │   ├── Services/
│   │   │   ├── SupabaseServiceTests.swift
│   │   ├── Models/
│   │   │   ├── UserTests.swift
│   │   │   ├── ChildTests.swift
│   ├── Mocks/
│   │   ├── MockSupabaseService.swift
│   │   ├── MockAuthService.swift
│   ├── Fixtures/
│   │   ├── ChildBuilder.swift
│   │   ├── UserBuilder.swift
│   │   ├── ConversationBuilder.swift
├── EkoCoreTests/                 # Tests for EkoCore package
│   ├── Models/
│   │   ├── OnboardingStateTests.swift
│   │   ├── ConversationTopicTests.swift
├── EkoUITests/                   # UI/E2E tests (XCUITest)
│   ├── OnboardingFlowUITests.swift
│   ├── AuthenticationFlowUITests.swift
│   ├── LyraChatUITests.swift
```

### Naming Conventions

```swift
// Unit Test Class Names
class OnboardingViewModelTests: XCTestCase { }

// Test Method Names - Use descriptive, behavior-driven names
func test_canProceedFromUserInfo_returnsFalse_whenNameIsEmpty() { }
func test_canProceedFromGoals_returnsTrue_whenOneGoalSelected() { }
func test_moveToNextStep_updatesState_toChildInfo_afterUserInfo() { }

// UI Test Method Names
func testOnboardingFlow_completesSuccessfully_forNewUser() { }
func testLogin_showsErrorMessage_withInvalidCredentials() { }
```

---

## Implementation Strategy

### Phase 1: Foundation (Week 1)

**Goal**: Set up test infrastructure and create first tests

- [ ] Create test targets in Xcode (`EkoTests`, `EkoCoreTests`)
- [ ] Add test bundle to CI pipeline (GitHub Actions)
- [ ] Create `MockSupabaseService` protocol implementation
- [ ] Write first 3-5 unit tests for existing features
- [ ] Document test running instructions in README

**Deliverable**: Working test suite with ≥5 passing tests

---

### Phase 2: Critical Path Coverage (Weeks 2-3)

**Goal**: Test business-critical features before MVP launch

**Priority 1 - Onboarding** (30 tests)
- [ ] `OnboardingViewModelTests` (state transitions, validation)
- [ ] `OnboardingStateTests` (next/previous navigation)
- [ ] Child creation with complete data
- [ ] Multiple children support
- [ ] Resume incomplete onboarding

**Priority 2 - Authentication** (15 tests)
- [ ] `AuthViewModelTests` (login, logout, session management)
- [ ] User profile creation on first login
- [ ] Token refresh handling
- [ ] Error states (network failure, invalid credentials)

**Priority 3 - Data Models** (10 tests)
- [ ] User, Child, Conversation model encoding/decoding
- [ ] Date calculations (age from birthday)
- [ ] Validation rules (birthday not in future)

**Deliverable**: 55+ unit tests covering critical business logic

---

### Phase 3: Integration & Services (Week 4)

**Goal**: Verify API integration contracts

- [ ] `SupabaseServiceTests` with mock responses
- [ ] Database operation tests (create, read, update)
- [ ] Error handling for network failures
- [ ] RLS policy validation (cannot access other user's data)

**Deliverable**: 20+ integration tests with mocked Supabase

---

### Phase 4: UI Tests - Critical Paths Only (Week 5)

**Goal**: Automate happy path validation

**UI Tests to Implement** (3-5 tests max for MVP):
1. Complete onboarding flow (new user → review → complete)
2. Login → View existing profile
3. Create a new conversation with Lyra
4. _(Post-MVP)_ Complete a Daily Practice session
5. _(Post-MVP)_ Navigate through Conversation Playbook

**Deliverable**: 3 UI tests covering authentication and onboarding

---

### Phase 5: Continuous Improvement (Post-MVP)

**Goal**: Increase coverage based on production issues

- Monitor crash reports and user-reported bugs
- Add regression tests for every critical bug fixed
- Gradually increase coverage to 80%+ for core features
- Add performance tests for slow operations

---

## CI/CD Integration

### GitHub Actions Workflow

**On Every Pull Request**:
- Run unit tests (`xcodebuild test`)
- Report coverage to PR
- Block merge if tests fail

**On Main Branch**:
- Run full test suite (unit + integration + UI)
- Generate code coverage report
- Upload to TestFlight if tests pass

### Example GitHub Actions Config

```yaml
name: Test

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -scheme Eko \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
            -enableCodeCoverage YES \
            | xcpretty

      - name: Generate Coverage Report
        run: |
          xcrun xccov view --report --json \
            DerivedData/Logs/Test/*.xcresult > coverage.json

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage.json
```

### Test Execution Targets

| Environment | When | Tests Run | Timeout |
|-------------|------|-----------|---------|
| Local (Developer) | Pre-commit | Unit tests only | 10 sec |
| CI (Pull Request) | On push | Unit + Integration | 1 min |
| CI (Main Branch) | On merge | All tests | 5 min |
| Nightly | Scheduled | All + Performance | 15 min |

---

## Coverage Goals

### Overall Targets

| Phase | Unit Coverage | Integration Coverage | UI Coverage |
|-------|---------------|---------------------|-------------|
| MVP Launch | 60% | 40% | 20% |
| 3 Months Post-Launch | 75% | 60% | 30% |
| 6 Months Post-Launch | 80% | 70% | 40% |

### Coverage by Component

**Must Have 80%+ Coverage**:
- ViewModels (business logic)
- SupabaseService operations
- Data validation functions
- State machine logic (OnboardingState)
- Payment/subscription logic (when implemented)

**Target 50-70% Coverage**:
- Models with computed properties
- View-level logic (if any)
- Utility functions

**Can Skip Coverage**:
- SwiftUI Views (layout-only)
- Boilerplate/generated code
- Third-party library wrappers

---

## Writing Effective Tests

### Unit Test Template

```swift
import XCTest
@testable import Eko
import EkoCore

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

    // MARK: - User Info Validation

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

    // MARK: - State Transitions

    @MainActor
    func test_moveToNextStep_transitionsFromUserInfoToChildInfo() async throws {
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
}
```

### Integration Test Template

```swift
import XCTest
@testable import Eko
import EkoCore

final class SupabaseServiceIntegrationTests: XCTestCase {

    var sut: SupabaseService!

    override func setUp() async throws {
        try await super.setUp()
        // Use test Supabase instance
        sut = SupabaseService(
            url: URL(string: "https://test.supabase.co")!,
            key: "test-anon-key"
        )
    }

    func test_createChild_savesToDatabase_andReturnsChild() async throws {
        // Given
        let childData = ChildBuilder.build(
            name: "Test Child",
            age: 10,
            birthday: Date(),
            goals: ["Understanding feelings"],
            topics: ["emotions", "friends", "school"]
        )

        // When
        let createdChild = try await sut.createChild(
            name: childData.name,
            age: childData.age,
            birthday: childData.birthday,
            goals: childData.goals,
            topics: childData.topics,
            temperament: .easygoing
        )

        // Then
        XCTAssertNotNil(createdChild.id)
        XCTAssertEqual(createdChild.name, "Test Child")
        XCTAssertEqual(createdChild.goals.count, 1)
        XCTAssertEqual(createdChild.topics.count, 3)

        // Cleanup
        try await sut.deleteChild(id: createdChild.id)
    }
}
```

### UI Test Template

```swift
import XCTest

final class OnboardingFlowUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["UI-TESTING"]
        app.launch()
    }

    func testOnboardingFlow_completesSuccessfully_forNewUser() {
        // Given - User is on login screen
        let loginButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(loginButton.exists)
        loginButton.tap()

        // Mock auth response (requires UI test setup)

        // Step 1: User Info
        let nameField = app.textFields["What's your name?"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Test Parent")

        app.buttons["Next"].tap()

        // Step 2: Child Info
        let childNameField = app.textFields["Child's Name"]
        XCTAssertTrue(childNameField.waitForExistence(timeout: 2))
        childNameField.tap()
        childNameField.typeText("Test Child")

        // Select birthday (simplified)
        app.buttons["Next"].tap()

        // Step 3: Goals
        let goalCard = app.buttons["Understanding their thoughts and feelings better"]
        XCTAssertTrue(goalCard.waitForExistence(timeout: 2))
        goalCard.tap()

        app.buttons["Next"].tap()

        // Step 4: Topics (select 3)
        app.buttons["Emotions & Feelings"].tap()
        app.buttons["Friendship & Relationships"].tap()
        app.buttons["School & Learning"].tap()

        app.buttons["Next"].tap()

        // Step 5: Dispositions (skip to last page)
        app.buttons["Next"].tap()
        app.buttons["Next"].tap()
        app.buttons["Finish"].tap()

        // Step 6: Review
        let completeButton = app.buttons["Complete Setup"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 2))
        completeButton.tap()

        // Then - Should be on main app screen
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 2))
    }
}
```

---

## Mobile-Specific Testing Considerations

### Device & OS Fragmentation

**Target Test Devices**:
- **Primary**: iPhone 15 Pro (iOS 17.2) - Latest
- **Secondary**: iPhone SE 3rd Gen (iOS 17.2) - Smallest screen
- **Tertiary**: iPad Pro (iOS 17.2) - Tablet layout

**OS Coverage**:
- iOS 17.0+ (minimum deployment target)
- Test on latest stable release only for MVP

### Offline/Network Conditions

**Test Scenarios**:
1. **No internet connection**: Show appropriate error messages
2. **Slow connection**: Operations should timeout gracefully (10s max)
3. **Connection interrupted mid-operation**: Retry or fail cleanly

**Implementation**:
```swift
// Use Network Link Conditioner in Xcode
// Or mock network failures in tests

func test_createChild_showsError_whenNetworkUnavailable() async {
    // Given
    mockService.networkError = URLError(.notConnectedToInternet)

    // When
    await sut.saveChildData()

    // Then
    XCTAssertNotNil(sut.errorMessage)
    XCTAssertTrue(sut.errorMessage!.contains("network"))
}
```

### Memory & Performance

**Test for Memory Leaks**:
- Use Xcode Instruments (Leaks tool)
- Test ViewModels are deallocated after navigation
- Test image caching doesn't grow unbounded

**Performance Tests** (Post-MVP):
```swift
func test_loadConversationHistory_completesWithin500ms() {
    measure {
        let _ = try? await sut.loadConversations()
    }
}
```

### Background/Foreground Transitions

**Test Scenarios**:
- App backgrounded during onboarding → Should resume
- App killed during API call → Should recover on relaunch
- Session expires while app in background → Redirect to login

### Push Notifications (Post-MVP)

**Test Scenarios**:
- Notification received while app in foreground
- Notification tap opens correct screen
- Permission request flow

---

## Test Data Management

### Test Supabase Instance

**Setup**:
- Create separate Supabase project for testing (`eko-test`)
- Use test credentials in `EkoTests/TestConfig.swift`
- Auto-cleanup test data after test runs

**Strategy**:
```swift
class TestConfig {
    static let testSupabaseURL = URL(string: "https://test-project.supabase.co")!
    static let testSupabaseKey = "test-anon-key"

    static func createTestService() -> SupabaseService {
        return SupabaseService(url: testSupabaseURL, key: testSupabaseKey)
    }
}
```

### Test Fixtures

**Location**: `EkoTests/Fixtures/`

**Example**:
```swift
enum TestFixtures {
    static let testUser = User(
        id: UUID(),
        email: "test@example.com",
        createdAt: Date(),
        updatedAt: Date(),
        displayName: "Test User",
        onboardingState: .complete
    )

    static let testChild = Child(
        id: UUID(),
        userId: testUser.id,
        name: "Test Child",
        age: 10,
        birthday: Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
        goals: ["Understanding feelings"],
        topics: ["emotions", "friends", "school"],
        temperament: .easygoing,
        temperamentTalkative: 7,
        temperamentSensitivity: 5,
        temperamentAccountability: 8,
        createdAt: Date(),
        updatedAt: Date()
    )
}
```

---

## Common Testing Pitfalls (And How to Avoid Them)

### ❌ Pitfall 1: Testing SwiftUI View Layout

**Bad**:
```swift
func test_childInfoView_hasTextField_andDatePicker() {
    let view = ChildInfoView(viewModel: viewModel)
    // Can't easily assert on SwiftUI view hierarchy
}
```

**Good**: Test the ViewModel logic instead
```swift
func test_canProceedFromChildInfo_returnsFalse_whenNameEmpty() {
    viewModel.childName = ""
    XCTAssertFalse(viewModel.canProceedFromChildInfo)
}
```

---

### ❌ Pitfall 2: Slow Tests (> 1 second)

**Bad**:
```swift
func test_dataLoad() async {
    try await Task.sleep(nanoseconds: 3_000_000_000) // 3 second delay
    let data = await viewModel.loadData()
}
```

**Good**: Mock async operations
```swift
func test_dataLoad() async {
    mockService.mockData = TestFixtures.testChild
    await viewModel.loadData()
    XCTAssertNotNil(viewModel.child)
}
```

---

### ❌ Pitfall 3: Brittle UI Tests

**Bad**: Using hardcoded coordinates or sleep()
```swift
app.tap(CGPoint(x: 100, y: 200))
sleep(3) // Wait for animation
```

**Good**: Use accessibility identifiers and proper waits
```swift
let button = app.buttons["nextButton"]
XCTAssertTrue(button.waitForExistence(timeout: 2))
button.tap()
```

---

### ❌ Pitfall 4: Testing Implementation, Not Behavior

**Bad**:
```swift
func test_moveToNextStep_callsUpdateOnboardingState() async {
    await viewModel.moveToNextStep()
    XCTAssertTrue(mockService.updateOnboardingStateCalled) // Implementation detail
}
```

**Good**: Test the outcome
```swift
func test_moveToNextStep_transitionsToNextState() async {
    viewModel.currentState = .userInfo
    await viewModel.moveToNextStep()
    XCTAssertEqual(viewModel.currentState, .childInfo)
}
```

---

### ❌ Pitfall 5: Not Isolating Tests

**Bad**: Tests depend on each other
```swift
var globalUser: User?

func test_1_createUser() {
    globalUser = createTestUser()
}

func test_2_updateUser() {
    updateUser(globalUser!) // Depends on test_1
}
```

**Good**: Each test is independent
```swift
func test_createUser() {
    let user = createTestUser()
    XCTAssertNotNil(user.id)
}

func test_updateUser() {
    let user = createTestUser() // Create fresh for this test
    let updated = updateUser(user)
    XCTAssertEqual(updated.displayName, "New Name")
}
```

---

## Testing Checklist for New Features

When implementing a new feature, use this checklist:

### Before Writing Code
- [ ] Identify critical user paths
- [ ] Determine what needs testing vs. can be skipped
- [ ] Decide on test level (unit, integration, UI)

### During Implementation
- [ ] Write tests alongside code (not after)
- [ ] Create mock services if needed
- [ ] Test happy path + 1-2 error cases
- [ ] Keep tests fast (< 1 second per test)

### Before Merging PR
- [ ] All tests passing locally
- [ ] Code coverage ≥ 60% for new code
- [ ] No flaky tests (run 3x to verify)
- [ ] Tests added to appropriate test suite
- [ ] Test names are descriptive and clear

### After Merging
- [ ] Tests pass in CI
- [ ] No new test failures in unrelated code
- [ ] Coverage report updated

---

## Resources & References

### Apple Documentation
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [UI Testing in Xcode](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Testing with Xcode (Book)](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)

### Testing Best Practices
- [iOS Unit Testing by Example](https://pragprog.com/titles/jrlegios/ios-unit-testing-by-example/)
- [Testing Swift Code](https://www.swiftbysundell.com/basics/unit-testing/)
- [Mobile Testing Guide](https://martinfowler.com/articles/mobile-testing/)

### Code Coverage Tools
- Xcode built-in coverage reports
- [Codecov](https://about.codecov.io/) for PR coverage visualization
- [SonarQube](https://www.sonarsource.com/products/sonarqube/) for comprehensive analysis

---

## Appendix: Test Environment Setup

### Xcode Test Targets Configuration

1. **Create Test Targets**:
   - File → New → Target → iOS Unit Testing Bundle
   - Name: `EkoTests`
   - Repeat for `EkoCoreTests`, `EkoUITests`

2. **Configure Test Plans** (optional):
   - Product → Scheme → Edit Scheme → Test
   - Add test plans for different environments (Local, CI, Integration)

3. **Link EkoCore to Test Targets**:
   - In test target settings
   - Frameworks, Libraries, and Embedded Content
   - Add `EkoCore.framework`

4. **Add Test Configuration**:
   ```swift
   // EkoTests/TestConfig.swift
   import Foundation

   enum TestConfig {
       static var isRunningUITests: Bool {
           ProcessInfo.processInfo.arguments.contains("UI-TESTING")
       }

       static var testSupabaseURL: URL {
           URL(string: "https://test-eko.supabase.co")!
       }
   }
   ```

5. **Configure CI Environment Variables**:
   ```bash
   # .github/workflows/test.yml
   env:
     TEST_SUPABASE_URL: ${{ secrets.TEST_SUPABASE_URL }}
     TEST_SUPABASE_KEY: ${{ secrets.TEST_SUPABASE_KEY }}
   ```

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | Jan 20, 2025 | Initial testing strategy | Engineering Team |

---

**End of Testing Strategy**
