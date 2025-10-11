import SwiftUI

// MARK: - Spacing
public extension CGFloat {
    // Spacing scale
    static let ekoSpacingXXS: CGFloat = 4
    static let ekoSpacingXS: CGFloat = 8
    static let ekoSpacingSM: CGFloat = 12
    static let ekoSpacingMD: CGFloat = 16
    static let ekoSpacingLG: CGFloat = 24
    static let ekoSpacingXL: CGFloat = 32
    static let ekoSpacingXXL: CGFloat = 48
    static let ekoSpacingXXXL: CGFloat = 64

    // Corner radius
    static let ekoRadiusXS: CGFloat = 4
    static let ekoRadiusSM: CGFloat = 8
    static let ekoRadiusMD: CGFloat = 12
    static let ekoRadiusLG: CGFloat = 16
    static let ekoRadiusXL: CGFloat = 24
    static let ekoRadiusFull: CGFloat = 999 // For pill shapes
}

// Convenience modifiers
public extension View {
    func ekoPadding(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges, .ekoSpacingMD)
    }

    func ekoPaddingHorizontal() -> some View {
        self.padding(.horizontal, .ekoSpacingMD)
    }

    func ekoPaddingVertical() -> some View {
        self.padding(.vertical, .ekoSpacingMD)
    }

    func ekoCornerRadius(_ radius: CGFloat = .ekoRadiusMD) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
