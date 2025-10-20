import SwiftUI

struct DispositionsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Child's Disposition")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Help us understand \(viewModel.childName.isEmpty ? "your child" : viewModel.childName)'s disposition")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)

            // Pagination dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentDispositionPage ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 8)

            Spacer()

            // Disposition slider
            TabView(selection: $viewModel.currentDispositionPage) {
                // Page 1: Talkative
                DispositionSliderPage(
                    title: "Communication Style",
                    leftLabel: "Quiet",
                    rightLabel: "Talkative",
                    value: $viewModel.talkativeScore,
                    accessibilityId: "talkativeSlider"
                )
                .tag(0)

                // Page 2: Sensitive
                DispositionSliderPage(
                    title: "Emotional Response",
                    leftLabel: "Argumentative",
                    rightLabel: "Sensitive",
                    value: $viewModel.sensitiveScore,
                    accessibilityId: "sensitiveSlider"
                )
                .tag(1)

                // Page 3: Accountable
                DispositionSliderPage(
                    title: "Responsibility",
                    leftLabel: "Denial of Responsibility",
                    rightLabel: "Accountable",
                    value: $viewModel.accountableScore,
                    accessibilityId: "accountableSlider"
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: 300)

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                // Back button
                if viewModel.currentDispositionPage > 0 {
                    Button {
                        withAnimation {
                            viewModel.currentDispositionPage -= 1
                        }
                    } label: {
                        Text("Back")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }

                // Next/Finish button
                Button {
                    if viewModel.currentDispositionPage < 2 {
                        withAnimation {
                            viewModel.currentDispositionPage += 1
                        }
                    } else {
                        Task {
                            await viewModel.moveToNextStep()
                        }
                    }
                } label: {
                    Text(viewModel.currentDispositionPage < 2 ? "Next" : "Finish")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .accessibilityIdentifier(viewModel.currentDispositionPage < 2 ? "nextButton" : "finishButton")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct DispositionSliderPage: View {
    let title: String
    let leftLabel: String
    let rightLabel: String
    @Binding var value: Int
    let accessibilityId: String

    var body: some View {
        VStack(spacing: 32) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 24) {
                // Current value display
                Text("\(value)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.accentColor)

                // Slider
                VStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { Double(value) },
                            set: { value = Int($0.rounded()) }
                        ),
                        in: 1...10,
                        step: 1
                    )
                    .tint(.accentColor)
                    .accessibilityIdentifier(accessibilityId)

                    // Labels
                    HStack {
                        Text(leftLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(rightLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    DispositionsView(viewModel: {
        let vm = OnboardingViewModel()
        vm.childName = "Emma"
        return vm
    }())
}
