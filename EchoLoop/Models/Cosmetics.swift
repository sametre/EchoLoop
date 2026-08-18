import SwiftUI
import UIKit

struct OrbCosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
    let premiumOnly: Bool
    let primaryHex: String
    let secondaryHex: String

    var primaryColor: Color { Color(hex: primaryHex) }
    var secondaryColor: Color { Color(hex: secondaryHex) }
    var uiPrimary: UIColor { UIColor(hex: primaryHex) }
    var uiSecondary: UIColor { UIColor(hex: secondaryHex) }

    static let all: [OrbCosmetic] = [
        .init(id: "core", name: "CORE", price: 0, premiumOnly: false, primaryHex: "EAF7FF", secondaryHex: "55C8FF"),
        .init(id: "pulse", name: "PULSE", price: 350, premiumOnly: false, primaryHex: "FF5FC8", secondaryHex: "8A5CFF"),
        .init(id: "mint", name: "MINT", price: 500, premiumOnly: false, primaryHex: "7CFFD1", secondaryHex: "42C6FF"),
        .init(id: "solar", name: "SOLAR", price: 700, premiumOnly: false, primaryHex: "FFD764", secondaryHex: "FF7A45"),
        .init(id: "void", name: "VOID", price: 900, premiumOnly: false, primaryHex: "C48BFF", secondaryHex: "5940FF"),
        .init(id: "prism", name: "PRISM", price: 1100, premiumOnly: false, primaryHex: "FFFFFF", secondaryHex: "FF54DA")
    ]

    static func item(_ id: String) -> OrbCosmetic { all.first(where: { $0.id == id }) ?? all[0] }
}

struct TrailCosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
    let premiumOnly: Bool
    let hex: String
    let birthRate: CGFloat
    let lifetime: CGFloat

    var color: Color { Color(hex: hex) }
    var uiColor: UIColor { UIColor(hex: hex) }

    static let all: [TrailCosmetic] = [
        .init(id: "ice", name: "ICE", price: 0, premiumOnly: false, hex: "6CD8FF", birthRate: 54, lifetime: 0.42),
        .init(id: "rose", name: "ROSE", price: 250, premiumOnly: false, hex: "FF5BAA", birthRate: 62, lifetime: 0.48),
        .init(id: "lime", name: "LIME", price: 400, premiumOnly: false, hex: "79FF8E", birthRate: 68, lifetime: 0.45),
        .init(id: "ember", name: "EMBER", price: 550, premiumOnly: false, hex: "FF8B4D", birthRate: 72, lifetime: 0.52),
        .init(id: "ultraviolet", name: "ULTRAVIOLET", price: 750, premiumOnly: false, hex: "A765FF", birthRate: 76, lifetime: 0.56),
        .init(id: "nova", name: "NOVA", price: 950, premiumOnly: false, hex: "FFF4A8", birthRate: 90, lifetime: 0.62)
    ]

    static func item(_ id: String) -> TrailCosmetic { all.first(where: { $0.id == id }) ?? all[0] }
}

struct ArenaCosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
    let premiumOnly: Bool
    let backgroundHex: String
    let accentHex: String
    let glowHex: String

    var backgroundColor: Color { Color(hex: backgroundHex) }
    var accentColor: Color { Color(hex: accentHex) }
    var glowColor: Color { Color(hex: glowHex) }
    var uiBackground: UIColor { UIColor(hex: backgroundHex) }
    var uiAccent: UIColor { UIColor(hex: accentHex) }
    var uiGlow: UIColor { UIColor(hex: glowHex) }

    static let all: [ArenaCosmetic] = [
        .init(id: "deep_space", name: "DEEP SPACE", price: 0, premiumOnly: false, backgroundHex: "040711", accentHex: "3D8BFF", glowHex: "8B5CFF"),
        .init(id: "neon_grid", name: "NEON GRID", price: 600, premiumOnly: false, backgroundHex: "070611", accentHex: "00E8FF", glowHex: "FF4FD8"),
        .init(id: "emerald", name: "EMERALD", price: 850, premiumOnly: false, backgroundHex: "03100D", accentHex: "5DFFB4", glowHex: "00B8A9"),
        .init(id: "solar", name: "SOLAR CORE", price: 1050, premiumOnly: false, backgroundHex: "100806", accentHex: "FFC552", glowHex: "FF5C45"),
        .init(id: "royal", name: "ROYAL VOID", price: 1250, premiumOnly: false, backgroundHex: "080313", accentHex: "A86BFF", glowHex: "5A48FF"),
        .init(id: "singularity", name: "SINGULARITY", price: 1500, premiumOnly: false, backgroundHex: "05050A", accentHex: "FFFFFF", glowHex: "FF62DA")
    ]

    static func item(_ id: String) -> ArenaCosmetic { all.first(where: { $0.id == id }) ?? all[0] }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: UInt64
        switch cleaned.count {
        case 8:
            r = (value >> 24) & 0xFF; g = (value >> 16) & 0xFF; b = (value >> 8) & 0xFF; a = value & 0xFF
        default:
            r = (value >> 16) & 0xFF; g = (value >> 8) & 0xFF; b = value & 0xFF; a = 0xFF
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension Color {
    init(hex: String) { self.init(uiColor: UIColor(hex: hex)) }
}
