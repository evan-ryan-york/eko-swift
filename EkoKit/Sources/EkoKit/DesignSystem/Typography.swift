import SwiftUI

// MARK: - Typography
public extension Font {
    // Display styles (largest)
    static let ekoDisplay = Font.system(size: 34, weight: .bold, design: .rounded)

    // Title styles
    static let ekoTitle1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let ekoTitle2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let ekoTitle3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // Headline and Body
    static let ekoHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let ekoBody = Font.system(size: 17, weight: .regular, design: .default)
    static let ekoBodyEmphasized = Font.system(size: 17, weight: .semibold, design: .default)

    // Subheadline and Callout
    static let ekoSubheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let ekoCallout = Font.system(size: 16, weight: .regular, design: .default)

    // Footnote and Caption
    static let ekoFootnote = Font.system(size: 13, weight: .regular, design: .default)
    static let ekoCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let ekoCaption2 = Font.system(size: 11, weight: .regular, design: .default)
}

// Text style modifiers for convenience
public extension View {
    func ekoDisplayStyle() -> some View {
        self.font(.ekoDisplay)
            .foregroundStyle(Color.ekoLabel)
    }

    func ekoTitle1Style() -> some View {
        self.font(.ekoTitle1)
            .foregroundStyle(Color.ekoLabel)
    }

    func ekoTitle2Style() -> some View {
        self.font(.ekoTitle2)
            .foregroundStyle(Color.ekoLabel)
    }

    func ekoTitle3Style() -> some View {
        self.font(.ekoTitle3)
            .foregroundStyle(Color.ekoLabel)
    }

    func ekoBodyStyle() -> some View {
        self.font(.ekoBody)
            .foregroundStyle(Color.ekoLabel)
    }

    func ekoSubheadlineStyle() -> some View {
        self.font(.ekoSubheadline)
            .foregroundStyle(Color.ekoSecondaryLabel)
    }
}
