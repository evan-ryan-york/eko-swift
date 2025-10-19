import SwiftUI

// MARK: - Typography
public extension Font {
    // Display styles (largest)
    static let ekoDisplay = Font.custom("Urbanist", size: 34).weight(.bold)

    // Title styles
    static let ekoTitle1 = Font.custom("Urbanist", size: 28).weight(.bold)
    static let ekoTitle2 = Font.custom("Urbanist", size: 22).weight(.bold)
    static let ekoTitle3 = Font.custom("Urbanist", size: 20).weight(.semibold)

    // Headline and Body
    static let ekoHeadline = Font.custom("Urbanist", size: 17).weight(.semibold)
    static let ekoBody = Font.custom("Urbanist", size: 17).weight(.regular)
    static let ekoBodyEmphasized = Font.custom("Urbanist", size: 17).weight(.semibold)

    // Subheadline and Callout
    static let ekoSubheadline = Font.custom("Urbanist", size: 15).weight(.regular)
    static let ekoCallout = Font.custom("Urbanist", size: 16).weight(.regular)

    // Footnote and Caption
    static let ekoFootnote = Font.custom("Urbanist", size: 13).weight(.regular)
    static let ekoCaption = Font.custom("Urbanist", size: 12).weight(.regular)
    static let ekoCaption2 = Font.custom("Urbanist", size: 11).weight(.regular)
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
