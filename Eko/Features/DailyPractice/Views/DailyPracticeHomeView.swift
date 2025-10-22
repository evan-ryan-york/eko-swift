// Daily Practice Home View
// Entry point for the Daily Practice feature

import SwiftUI
import EkoKit
import EkoCore

struct DailyPracticeHomeView: View {
    @State private var viewModel = DailyPracticeHomeViewModel()
    @State private var navigateToActivity = false
    #if DEBUG
    @State private var showDebugSheet = false
    @State private var selectedDay = 1
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                Group {
                    switch viewModel.loadingState {
                    case .idle, .loading:
                        loadingView

                    case .loaded:
                        if let activity = viewModel.activity, let dayNumber = viewModel.dayNumber {
                            readyToStartView(dayNumber: dayNumber, title: activity.title)
                        }

                    case .alreadyCompleted:
                        completedTodayView

                    case .noneAvailable:
                        noneAvailableView

                    case .error(let message):
                        errorView(message: message)
                    }
                }
            }
            .navigationTitle("Daily Practice")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $navigateToActivity) {
                if let activity = viewModel.activity, let dayNumber = viewModel.dayNumber {
                    DailyPracticeActivityView(
                        activity: activity,
                        dayNumber: dayNumber
                    )
                }
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDebugSheet = true
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundStyle(Color.ekoWarning)
                    }
                }
            }
            .sheet(isPresented: $showDebugSheet) {
                debugSheet
            }
            #endif
        }
        .task {
            await viewModel.loadTodayActivity()
        }
        .onChange(of: navigateToActivity) { oldValue, newValue in
            // When returning from activity view, reload to check completion status
            if oldValue == true && newValue == false {
                Task {
                    await viewModel.loadTodayActivity()
                }
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: .ekoSpacingMD) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading daily practice...")
                .font(.ekoBody)
                .foregroundColor(.secondary)
        }
    }

    private func readyToStartView(dayNumber: Int, title: String) -> some View {
        VStack(spacing: .ekoSpacingLG) {
            Spacer()

            // Day Number
            Text("Day \(dayNumber)")
                .font(.ekoDisplay)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.ekoPrimary, .ekoSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Icon
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.ekoPrimary)
                .padding(.vertical, .ekoSpacingMD)

            // Title
            Text(title)
                .font(.ekoTitle3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .ekoSpacingLG)

            Spacer()

            // Start Button
            PrimaryButton(title: "Start Today's Daily Practice") {
                navigateToActivity = true
            }
            .padding(.horizontal, .ekoSpacingLG)
            .padding(.bottom, .ekoSpacingLG)
        }
    }

    private var completedTodayView: some View {
        VStack(spacing: .ekoSpacingLG) {
            Text("🎉")
                .font(.system(size: 80))

            Text("Great work!")
                .font(.ekoTitle1)

            Text("You've finished your daily practice for today. Come back tomorrow for a new challenge.")
                .font(.ekoBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, .ekoSpacingLG)

            if viewModel.lastCompletedDay > 0 {
                Text("You've completed Day \(viewModel.lastCompletedDay)")
                    .font(.ekoCaption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.ekoSpacingLG)
    }

    private var noneAvailableView: some View {
        VStack(spacing: .ekoSpacingLG) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.ekoSuccess)

            Text("You're all caught up!")
                .font(.ekoTitle1)

            Text("Please check back later for new activities.")
                .font(.ekoBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, .ekoSpacingLG)
        }
        .padding(.ekoSpacingLG)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: .ekoSpacingLG) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.ekoWarning)

            Text("Something went wrong")
                .font(.ekoTitle3)

            Text(message)
                .font(.ekoBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, .ekoSpacingLG)

            PrimaryButton(title: "Try Again") {
                Task {
                    await viewModel.retry()
                }
            }
            .padding(.horizontal, .ekoSpacingLG)
        }
        .padding(.ekoSpacingLG)
    }

    // MARK: - Debug Controls

    #if DEBUG
    private var debugSheet: some View {
        NavigationStack {
            Form {
                Section("Current Progress") {
                    HStack {
                        Text("Last Completed Day:")
                        Spacer()
                        Text("\(viewModel.lastCompletedDay)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Reset Progress") {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.resetCurrentDay()
                            showDebugSheet = false
                        }
                    } label: {
                        Label("Reset Current Day", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.resetAllProgress()
                            showDebugSheet = false
                        }
                    } label: {
                        Label("Reset All Progress", systemImage: "trash")
                    }
                }

                Section("Load Specific Day") {
                    Picker("Day Number", selection: $selectedDay) {
                        ForEach(1...60, id: \.self) { day in
                            Text("Day \(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)

                    Button {
                        Task {
                            await viewModel.loadDay(selectedDay)
                            showDebugSheet = false
                        }
                    } label: {
                        Label("Load Day \(selectedDay)", systemImage: "play.circle.fill")
                    }
                }

                Section {
                    Text("These controls are only available in DEBUG builds and will not appear in production.")
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Debug Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showDebugSheet = false
                    }
                }
            }
        }
    }
    #endif
}

#Preview {
    DailyPracticeHomeView()
}
