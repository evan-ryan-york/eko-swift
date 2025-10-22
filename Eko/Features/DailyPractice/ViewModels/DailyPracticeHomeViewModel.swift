// Daily Practice Home View Model
// Manages the home screen state for daily practice activities

import Foundation
import Observation
import EkoCore

@MainActor
@Observable
final class DailyPracticeHomeViewModel {
    // MARK: - Loading State

    enum LoadingState {
        case idle
        case loading
        case loaded
        case alreadyCompleted
        case noneAvailable
        case error(String)
    }

    // MARK: - Properties

    var loadingState: LoadingState = .idle
    var activity: DailyPracticeActivity?
    var dayNumber: Int?
    var lastCompletedDay: Int = 0
    var completedAt: String?

    private let supabase: SupabaseService

    // MARK: - Initialization

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Load today's available activity
    func loadTodayActivity() async {
        loadingState = .loading

        do {
            let response = try await supabase.getTodayActivity()

            // Handle already completed
            if let error = response.error, error == "already_completed" {
                lastCompletedDay = response.lastCompleted ?? 0
                completedAt = response.completedAt
                loadingState = .alreadyCompleted
                return
            }

            // Handle not found
            if let error = response.error, error == "not_found" {
                loadingState = .noneAvailable
                return
            }

            // Handle success
            if let activity = response.activity, let dayNumber = response.dayNumber {
                self.activity = activity
                self.dayNumber = dayNumber
                self.lastCompletedDay = response.userProgress?.lastCompleted ?? 0
                loadingState = .loaded
            } else {
                loadingState = .error("Unexpected response format")
            }

        } catch {
            print("❌ [DailyPracticeHome] Error loading activity: \(error)")
            loadingState = .error(error.localizedDescription)
        }
    }

    /// Retry loading the activity
    func retry() async {
        await loadTodayActivity()
    }

    // MARK: - Debug/Testing Methods

    #if DEBUG
    /// Reset daily practice progress (current day only) - DEBUG ONLY
    func resetCurrentDay() async {
        do {
            try await supabase.resetDailyPractice(resetAll: false)
            // Reload after reset
            await loadTodayActivity()
        } catch {
            print("❌ [DailyPracticeHome] Error resetting: \(error)")
            loadingState = .error(error.localizedDescription)
        }
    }

    /// Reset all daily practice progress - DEBUG ONLY
    func resetAllProgress() async {
        do {
            try await supabase.resetDailyPractice(resetAll: true)
            // Reload after reset
            await loadTodayActivity()
        } catch {
            print("❌ [DailyPracticeHome] Error resetting all: \(error)")
            loadingState = .error(error.localizedDescription)
        }
    }

    /// Load a specific day for testing - DEBUG ONLY
    func loadDay(_ dayNumber: Int) async {
        loadingState = .loading

        do {
            let response = try await supabase.getActivityByDay(dayNumber)

            // Handle not found
            if let error = response.error, error == "not_found" {
                loadingState = .error("No activity found for day \(dayNumber)")
                return
            }

            // Handle success
            if let activity = response.activity, let dayNumber = response.dayNumber {
                self.activity = activity
                self.dayNumber = dayNumber
                self.lastCompletedDay = response.userProgress?.lastCompleted ?? 0
                loadingState = .loaded
            } else {
                loadingState = .error("Unexpected response format")
            }

        } catch {
            print("❌ [DailyPracticeHome] Error loading day \(dayNumber): \(error)")
            loadingState = .error(error.localizedDescription)
        }
    }
    #endif
}
