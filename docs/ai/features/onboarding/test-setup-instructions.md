# Onboarding Tests - Setup Instructions

**Date**: January 20, 2025
**Status**: Tests Created - Requires Xcode Setup
**Test Count**: 88 automated tests

---

## Test Suite Overview

### Tests Created (88 total)

**Unit Tests (71 tests):**
- `OnboardingViewModelTests.swift` - 43 tests
  - User info validation (4 tests)
  - Child info validation (3 tests)
  - Goals validation (8 tests)
  - Topics validation (5 tests)
  - Dispositions validation (2 tests)
  - State transitions (9 tests)
  - Child data save (5 tests)
  - Multiple children (3 tests)
  - Completion (2 tests)
  - Load state (3 tests)
  - Helper methods (2 tests)

- `OnboardingStateTests.swift` - 18 tests
  - Raw value tests (1 test)
  - Description tests (1 test)
  - isComplete tests (2 tests)
  - next() tests (2 tests)
  - previous() tests (3 tests)
  - Codable tests (3 tests)
  - Flow validation tests (2 tests)

- `ConversationTopicTests.swift` - 10 tests
  - All topics tests (3 tests)
  - Display name tests (2 tests)
  - Helper function tests (2 tests)
  - Topic structure tests (2 tests)
  - Feature spec validation (1 test)

**Integration Tests (17 tests):**
- `SupabaseServiceIntegrationTests.swift` - 17 tests
  - User profile tests (5 tests)
  - Child CRUD tests (6 tests)
  - Error handling tests (3 tests)
  - Multiple operations tests (3 tests)

---

## File Structure

```
Eko/
├── EkoTests/                           # ← Created, needs Xcode target
│   ├── Mocks/
│   │   └── MockSupabaseService.swift  # Mock implementation with 200+ LOC
│   ├── Fixtures/
│   │   └── TestFixtures.swift         # Test data fixtures
│   ├── Features/
│   │   └── Onboarding/
│   │       ├── OnboardingViewModelTests.swift
│   │       ├── OnboardingStateTests.swift
│   │       └── ConversationTopicTests.swift
│   └── Core/
│       └── Services/
│           └── SupabaseServiceIntegrationTests.swift
│
├── Eko/                                # Main app
│   ├── Core/
│   │   └── Services/
│   │       ├── SupabaseService.swift
│   │       └── SupabaseServiceProtocol.swift  # ← Created for testability
│   └── Features/
│       └── Onboarding/
│           └── ViewModels/
│               └── OnboardingViewModel.swift  # ← Updated to use protocol
│
└── EkoCore/                            # Swift Package
    └── Sources/EkoCore/Models/
        └── (All models already exist)
```

---

## Setup Instructions

### Step 1: Create Test Target in Xcode

Since the test files were created manually, you need to add them to an Xcode test target:

1. **Open Xcode**
   ```bash
   open /Users/ryanyork/Software/Eko/Eko/Eko.xcodeproj
   ```

2. **Create Test Target**
   - File → New → Target
   - Select "iOS Unit Testing Bundle"
   - Product Name: `EkoTests`
   - Language: Swift
   - Project: Eko
   - Target to be Tested: Eko
   - Click "Finish"

3. **Add Test Files to Target**
   - In Xcode's Project Navigator, locate the `EkoTests/` folder
   - If it's not visible, drag the `EkoTests` folder from Finder into Xcode
   - Select all test files (`.swift` files in EkoTests/)
   - In File Inspector (right panel), check the box next to "EkoTests" target

4. **Configure Test Target Dependencies**
   - Select the Eko project in Project Navigator
   - Select the "EkoTests" target
   - Go to "Build Phases" tab
   - Under "Dependencies", click "+" and add "Eko" app target
   - Under "Link Binary With Libraries", click "+" and add:
     - `EkoCore` framework

5. **Update Test Target Settings**
   - Select "EkoTests" target
   - Go to "Build Settings"
   - Search for "Swift Language Version"
   - Ensure it's set to "Swift 6" (or match main app)
   - Search for "Enable Testing Search Paths"
   - Set to "Yes"

### Step 2: Verify Build

Build the test target to ensure everything compiles:

```bash
cd /Users/ryanyork/Software/Eko/Eko
xcodebuild -scheme Eko -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build-for-testing
```

Expected output: `BUILD SUCCEEDED`

If you see errors, verify:
- All test files are added to the EkoTests target
- EkoCore is linked
- `@testable import Eko` statements work

### Step 3: Run Tests

**Option A: Run All Tests in Xcode**
1. Open Xcode
2. Press `Cmd + U` to run all tests
3. View results in Test Navigator (Cmd + 6)

**Option B: Run Tests via Command Line**

```bash
# Run all tests
xcodebuild test \
  -scheme Eko \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES

# Run specific test class
xcodebuild test \
  -scheme Eko \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:EkoTests/OnboardingViewModelTests

# Run specific test method
xcodebuild test \
  -scheme Eko \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:EkoTests/OnboardingViewModelTests/test_canProceedFromUserInfo_returnsFalse_whenNameIsEmpty
```

**Option C: Run Tests in Xcode on Specific Files**
1. Open a test file (e.g., `OnboardingViewModelTests.swift`)
2. Click the diamond icon next to `class OnboardingViewModelTests` to run all tests in that file
3. Click the diamond icon next to individual test methods to run single tests

---

## Expected Results

### Test Execution Time

- **Unit Tests**: ~2-5 seconds total (71 tests)
- **Integration Tests**: ~3-5 seconds total (17 tests)
- **Total**: < 10 seconds for all 88 tests

### Code Coverage Target

**Target: 70-80% coverage for onboarding code**

To generate code coverage report:

```bash
xcodebuild test \
  -scheme Eko \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -derivedDataPath ./build

# View coverage report
open ./build/Logs/Test/*.xcresult
```

In Xcode:
1. Run tests with code coverage enabled
2. Go to Report Navigator (Cmd + 9)
3. Select latest test run
4. Click "Coverage" tab
5. Verify onboarding files have ≥70% coverage:
   - `OnboardingViewModel.swift` - Target: 80%+
   - `OnboardingState.swift` - Target: 90%+
   - Individual view files - Target: 60%+ (views are harder to unit test)

---

## Test Architecture

### Protocol-Based Mocking

Tests use **protocol-based dependency injection** for testability:

1. **SupabaseServiceProtocol** defines the interface
2. **SupabaseService** (real) conforms to protocol
3. **MockSupabaseService** (test) conforms to protocol
4. **OnboardingViewModel** accepts protocol, not concrete class

This allows:
- Fast unit tests (no network calls)
- Controlled test scenarios (success/failure)
- Easy verification of method calls

### Mock Capabilities

`MockSupabaseService` provides:
- ✅ Success/failure control
- ✅ Method call tracking
- ✅ Captured parameter verification
- ✅ Network error simulation
- ✅ Custom return values
- ✅ State reset between tests

### Test Fixtures

`TestFixtures` provides consistent test data:
- Predefined UUIDs for reproducibility
- Sample users (new, in-progress, complete)
- Sample children (multiple variants)
- Date helpers for birthday calculations

---

## Troubleshooting

### Issue: "Module 'Eko' not found"

**Solution:**
- Ensure test files have `@testable import Eko` at the top
- Verify "Enable Testing Search Paths" is YES in test target settings
- Clean and rebuild: `Cmd + Shift + K`, then `Cmd + B`

### Issue: "Cannot find 'TestFixtures' in scope"

**Solution:**
- Verify `TestFixtures.swift` is added to EkoTests target
- Check File Inspector (right panel) shows EkoTests checkbox selected

### Issue: "Cannot find type 'EkoCore' in scope"

**Solution:**
- Add EkoCore to "Link Binary With Libraries" in Build Phases
- Import it: `import EkoCore` at top of test files

### Issue: Tests fail with "Operation failed"

**Solution:**
- Check if `mockService.shouldSucceed = true` in test setup
- Verify mock data is set correctly (e.g., `mockService.mockUser = ...`)
- Review test expectations match mock behavior

### Issue: Code coverage shows 0%

**Solution:**
- Enable code coverage: Product → Scheme → Edit Scheme → Test → Options → Check "Code Coverage"
- Run tests again
- Coverage report appears in Report Navigator (Cmd + 9)

---

## Next Steps: UI Tests (Phase 7.4)

**Status**: Not yet created - Requires manual Xcode setup

UI tests should be created in Xcode's UI Testing framework. To create them:

1. **Create UI Test Target**
   - File → New → Target → iOS UI Testing Bundle
   - Product Name: `EkoUITests`

2. **Record UI Tests**
   - Open test file
   - Add test method
   - Click red record button
   - Interact with app to record test

3. **Implement Critical Path Tests** (from implementation plan):
   - `test_onboardingFlow_completesSuccessfully_withOneChild`
   - `test_onboarding_disablesNextButton_whenNameIsEmpty`
   - `test_topicsSelection_requiresMinimumThree`

**Estimated Time**: 2-3 hours for UI test setup and implementation

---

## Test Maintenance

### Running Tests Regularly

**Best Practices:**
- Run tests before every commit: `xcodebuild test -scheme Eko`
- Run tests in CI/CD pipeline
- Monitor flaky tests (tests that fail intermittently)
- Keep test execution time under 15 seconds

### Updating Tests

**When to update tests:**
- When business logic changes (e.g., minimum topics changes from 3 to 5)
- When new validation rules are added
- When API contracts change
- When bugs are found (add regression test)

**How to update:**
1. Update test expectations to match new behavior
2. Add new tests for new features
3. Remove obsolete tests
4. Keep mock service in sync with real service

---

## Test Metrics

### Current Status

| Metric | Target | Status |
|--------|--------|--------|
| Unit Tests | 30+ | ✅ 71 tests |
| Integration Tests | 10+ | ✅ 17 tests |
| UI Tests | 3+ | ⏳ Pending |
| Total Tests | 50+ | ✅ 88 tests |
| Code Coverage | 70% | ⏳ To be measured |
| Test Speed | < 15s | ✅ ~10s estimated |

### Test Coverage by Component

| Component | Tests | Coverage Target |
|-----------|-------|-----------------|
| OnboardingViewModel | 43 | 80%+ |
| OnboardingState | 18 | 90%+ |
| ConversationTopics | 10 | 100% |
| SupabaseService (onboarding methods) | 17 | 70%+ |

---

## Additional Resources

### Related Documentation

- [Implementation Plan](./implementation-plan.md) - Full Phase 7 details (lines 1125-2018)
- [Testing Strategy](../../project-wide/testing-strategy.md) - App-wide testing approach
- [Feature Details](./feature-details.md) - Onboarding specifications

### Testing Tools

- **Xcode Test Navigator** (Cmd + 6) - View and run tests
- **Xcode Report Navigator** (Cmd + 9) - View test results and coverage
- **Instruments** - Profile test performance
- **xcresulttool** - Parse .xcresult files from command line

### Swift Testing Resources

- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Code Coverage in Xcode](https://developer.apple.com/documentation/xcode/code-coverage)

---

## Summary

✅ **88 automated tests created**
✅ **Test infrastructure complete** (mocks, fixtures, protocols)
✅ **Protocol-based architecture** for testability
⏳ **Pending**: Add files to Xcode test target
⏳ **Pending**: Run tests and verify coverage
⏳ **Pending**: Create UI tests (3 tests)

**Next Action**: Follow Step 1 above to create the EkoTests target in Xcode and add the test files.

---

**Last Updated**: January 20, 2025
**Created By**: Claude Code (Automated Testing - Phase 7)
