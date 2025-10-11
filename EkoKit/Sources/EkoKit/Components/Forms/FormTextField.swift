import SwiftUI

public struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let errorMessage: String?

    public init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.errorMessage = errorMessage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingXS) {
            Text(title)
                .font(.ekoSubheadline)
                .foregroundStyle(Color.ekoLabel)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                }
            }
            .font(.ekoBody)
            .padding(.ekoSpacingMD)
            .background(Color.ekoSecondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: .ekoRadiusSM)
                    .stroke(errorMessage != nil ? Color.ekoError : Color.ekoSeparator, lineWidth: 1)
            )
            .ekoCornerRadius(.ekoRadiusSM)

            if let errorMessage {
                Text(errorMessage)
                    .font(.ekoFootnote)
                    .foregroundStyle(Color.ekoError)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FormTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant(""),
            keyboardType: .emailAddress
        )

        FormTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            isSecure: true
        )

        FormTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant("invalid"),
            keyboardType: .emailAddress,
            errorMessage: "Please enter a valid email address"
        )
    }
    .padding()
}
