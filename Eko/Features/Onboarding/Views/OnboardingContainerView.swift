import SwiftUI
import EkoCore

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    var onComplete: (() -> Void)?

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
                Color.clear // Trigger completion callback
                    .onAppear {
                        onComplete?()
                    }
            }
        }
        .task {
            await viewModel.loadOnboardingState()
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
}
