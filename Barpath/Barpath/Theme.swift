//
//  Theme.swift
//  Barpath
//
//  Design tokens and theme system
//

import SwiftUI

/// Design tokens following Apple HIG patterns
struct Theme {

    // MARK: - Colors
    struct Colors {
        // Base
        static let baseCanvas = Color(hex: "#FFFFFF")
        static let baseInk = Color(hex: "#0D1117")
        static let inkSubtle = Color(hex: "#6B7280")

        // Semantic
        static let primary = Color(hex: "#2F80ED")
        static let success = Color(hex: "#22C55E")
        static let warning = Color(hex: "#F59E0B")
        static let danger = Color(hex: "#EF4444")

        // UI Elements
        static let stroke = Color(hex: "#E5E7EB")
        static let fill = Color(hex: "#F3F4F6")
    }

    // MARK: - Typography
    struct Typography {
        static let display = Font.system(size: 28, weight: .bold)
        static let title = Font.system(size: 22, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let label = Font.system(size: 14, weight: .medium)
        static let caption = Font.system(size: 12, weight: .regular)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    // MARK: - Radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
