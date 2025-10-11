import SwiftUI

public struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool

    public init(
        title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: .ekoSpacingSM) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.ekoHeadline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isDisabled ? Color.ekoSecondaryLabel : Color.ekoPrimary)
            .ekoCornerRadius(.ekoRadiusMD)
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Continue") {
            print("Tapped")
        }

        PrimaryButton(title: "Loading", isLoading: true) {
            print("Tapped")
        }

        PrimaryButton(title: "Disabled", isDisabled: true) {
            print("Tapped")
        }
    }
    .padding()
}
