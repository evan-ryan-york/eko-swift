import SwiftUI

public struct SecondaryButton: View {
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
                        .tint(Color.ekoPrimary)
                }
                Text(title)
                    .font(.ekoHeadline)
                    .foregroundStyle(isDisabled ? Color.ekoSecondaryLabel : Color.ekoPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.ekoSecondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: .ekoRadiusMD)
                    .stroke(isDisabled ? Color.ekoSeparator : Color.ekoPrimary, lineWidth: 2)
            )
            .ekoCornerRadius(.ekoRadiusMD)
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton(title: "Cancel") {
            print("Tapped")
        }

        SecondaryButton(title: "Loading", isLoading: true) {
            print("Tapped")
        }

        SecondaryButton(title: "Disabled", isDisabled: true) {
            print("Tapped")
        }
    }
    .padding()
}
