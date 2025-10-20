//
//  RootView.swift
//  Eko
//
//  Created by Claude Code on 10/20/25.
//

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
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let state = onboardingState, !state.isComplete {
                    // Show onboarding if incomplete
                    OnboardingContainerView {
                        // Re-check onboarding status when complete
                        Task {
                            await checkOnboardingStatus()
                        }
                    }
                } else {
                    // Show main app if onboarding complete
                    ContentView()
                }
            } else {
                // Show authentication screen
                LoginView(viewModel: authViewModel)
            }
        }
        .task(id: authViewModel.isAuthenticated) {
            if authViewModel.isAuthenticated {
                await checkOnboardingStatus()
            } else {
                // Reset onboarding state when logged out
                isCheckingOnboarding = true
                onboardingState = nil
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
            // Default to showing onboarding on error
            onboardingState = .notStarted
        }
    }
}

#Preview {
    RootView()
        .environment(AuthViewModel())
}
