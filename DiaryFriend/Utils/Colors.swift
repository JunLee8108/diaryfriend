import SwiftUI

extension Color {
    // MARK: - Brand Colors (Soft & Cozy Theme)
    /// Primary accent — 소프트 코랄 핑크
    static let brand = Color(hex: "FF8FAB")
    /// Secondary accent — 라이트 핑크
    static let brandLight = Color(hex: "FFB5C2")
    /// Tertiary accent — 블러시
    static let brandBlush = Color(hex: "FFDEE2")
    /// Point accent — 라벤더
    static let brandLavender = Color(hex: "B8A9E8")

    // MARK: - Semantic Colors
    static let sundayColor = Color(hex: "FF8FAB")
    static let saturdayColor = Color(hex: "B8A9E8")

    // MARK: - Backgrounds
    static let modernBackground = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "121212")
        default:
            return UIColor(hex: "FFF8F9")  // 웜 화이트
        }
    })

    static let modernSurfacePrimary = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "1E1E1E")
        default:
            return UIColor(hex: "FFFFFF")
        }
    })

    static let modernSurfaceSecondary = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "282828")
        default:
            return UIColor(hex: "FFF0F3")  // 연한 핑크 틴트
        }
    })

    static let modernSurfaceTertiary = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "323232")
        default:
            return UIColor(hex: "FFE4E9")  // 더 진한 핑크 틴트
        }
    })
}

// Hex helper
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
