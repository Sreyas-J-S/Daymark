import SwiftUI

public struct Theme {
    // Premium Color Palette (Classic Apple Blue & Minimalist White)
    public static let backgroundDark = Color(hex: "#0A0F1D") // Deep Dark Navy
    public static let cardBackgroundDark = Color(hex: "#162035") // Dark Navy Card
    
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#007AFF"), Color(hex: "#007AFF")], // Solid Apple Blue
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let successGradient = LinearGradient(
        colors: [Color(hex: "#34C759"), Color(hex: "#34C759")], // Solid Apple Green
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let warningGradient = LinearGradient(
        colors: [Color(hex: "#FF9500"), Color(hex: "#FF9500")], // Solid Apple Orange
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let dangerGradient = LinearGradient(
        colors: [Color(hex: "#FF3B30"), Color(hex: "#FF3B30")], // Solid Apple Red
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Core brand color
    public static let brandPrimary = Color(hex: "#007AFF") // Apple Blue
    public static let brandSecondary = Color(hex: "#30B0C7") // Apple Teal
    
    // Glassmorphism card utility
    public static func glassCardModifier<S: Shape>(shape: S) -> some ViewModifier {
        GlassCardModifier(shape: shape)
    }
}

// Custom Glassmorphic Modifier
struct GlassCardModifier<S: Shape>: ViewModifier {
    var shape: S
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                shape
                    .fill(colorScheme == .dark ? Color(hex: "#162035").opacity(0.8) : Color.white.opacity(0.95))
            )
            .background(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.4),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.08),
                radius: 10,
                x: 0,
                y: 4
            )
    }
}

// Color Hex Extension
extension Color {
    public init(hex: String) {
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
    
    public func toHex() -> String? {
        let uic = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uic.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let a = Int(alpha * 255)
        
        if a == 255 {
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            return String(format: "#%02X%02X%02X%02X", a, r, g, b)
        }
    }
}

// SwiftUI Visual Customizations
extension View {
    public func glassCard<S: Shape>(shape: S) -> some View {
        modifier(GlassCardModifier(shape: shape))
    }
}
