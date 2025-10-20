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
    private let supabaseService: SupabaseServiceProtocol

    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }

    // MARK: - State Management

    func loadOnboardingState() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await supabaseService.getUserProfile()
            print("🔵 Loaded profile state: \(profile.onboardingState.rawValue)")
            currentState = profile.onboardingState

            // Auto-transition from NOT_STARTED to USER_INFO on initial load
            // This prevents the confusing UX where both states show the same screen
            if currentState == .notStarted {
                print("🔵 Auto-transitioning from NOT_STARTED to USER_INFO")
                currentState = .userInfo
                do {
                    try await supabaseService.updateOnboardingState(.userInfo, currentChildId: nil)
                    print("✅ Successfully transitioned to USER_INFO")
                } catch {
                    print("❌ Failed to update state to USER_INFO: \(error)")
                    throw error
                }
            }

            currentChildId = profile.currentChildId

            // Load completed children if in review state
            if currentState == .review {
                await loadCompletedChildren()
            }
        } catch {
            print("❌ Failed to load onboarding state: \(error)")
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
            print("🔵 Moving from \(currentState.rawValue) to \(nextState.rawValue)")

            // Save current step data before transitioning
            try await saveCurrentStepData()

            // Update state in database
            try await supabaseService.updateOnboardingState(nextState, currentChildId: currentChildId)
            print("✅ Successfully updated to \(nextState.rawValue)")

            currentState = nextState

            // Load data for next step if needed
            if nextState == .review {
                await loadCompletedChildren()
            }
        } catch {
            print("❌ Failed to proceed to \(nextState.rawValue): \(error)")
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
            print("🔵 Completing onboarding...")
            // Mark onboarding as complete
            try await supabaseService.updateOnboardingState(.complete, currentChildId: nil)
            print("✅ Successfully marked onboarding as COMPLETE")
            currentState = .complete
        } catch {
            print("❌ Failed to complete onboarding: \(error)")
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
