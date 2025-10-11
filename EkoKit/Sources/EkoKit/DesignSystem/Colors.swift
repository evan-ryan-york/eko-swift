import SwiftUI

// MARK: - Brand Colors
public extension Color {
    // Primary brand colors
    static let ekoPrimary = Color(red: 0.4, green: 0.2, blue: 0.8) // Purple
    static let ekoSecondary = Color(red: 0.2, green: 0.7, blue: 0.9) // Light Blue
    static let ekoAccent = Color(red: 1.0, green: 0.6, blue: 0.2) // Orange

    // Semantic colors
    static let ekoSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let ekoWarning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let ekoError = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let ekoInfo = Color(red: 0.3, green: 0.6, blue: 1.0)

    // Neutral colors
    static let ekoBackground = Color(UIColor.systemBackground)
    static let ekoSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let ekoTertiaryBackground = Color(UIColor.tertiarySystemBackground)

    static let ekoLabel = Color(UIColor.label)
    static let ekoSecondaryLabel = Color(UIColor.secondaryLabel)
    static let ekoTertiaryLabel = Color(UIColor.tertiaryLabel)

    static let ekoSeparator = Color(UIColor.separator)
}
