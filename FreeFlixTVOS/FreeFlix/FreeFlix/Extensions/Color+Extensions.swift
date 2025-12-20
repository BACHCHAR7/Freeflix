import SwiftUI

extension Color {
    static let ffBackground = Color(red: 0, green: 0, blue: 0)
    static let ffSecondaryBg = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let ffCard = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let ffHover = Color(red: 0.16, green: 0.16, blue: 0.16)
    static let ffAccent = Color(red: 0.89, green: 0.1, blue: 0.1)
    static let ffAccentGlow = Color(red: 0.89, green: 0.1, blue: 0.1).opacity(0.4)
    static let ffSecondary = Color.white.opacity(0.7)
    static let ffMuted = Color.white.opacity(0.4)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

