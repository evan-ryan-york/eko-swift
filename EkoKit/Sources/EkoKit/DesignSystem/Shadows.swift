import SwiftUI

// MARK: - Shadow Style
public struct ShadowStyle: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Shadows
public struct EkoShadow {
    public static let small = ShadowStyle(
        color: .black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )

    public static let medium = ShadowStyle(
        color: .black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 4
    )

    public static let large = ShadowStyle(
        color: .black.opacity(0.16),
        radius: 16,
        x: 0,
        y: 8
    )
}

// Convenience modifiers for shadows
public extension View {
    func ekoShadow(_ style: ShadowStyle = EkoShadow.medium) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}
