import SwiftUI

extension Color {
    static let modernBackground = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "121212")  // Material Design 표준 ✅
        default:
            return UIColor(hex: "F8F9FA")  // 밝은 회색빛 배경
        }
    })
    
    static let modernSurfacePrimary = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "1E1E1E")  // +1 elevation
        default:
            return UIColor(hex: "FFFFFF")  // 순수 흰색
        }
    })
    
    static let modernSurfaceSecondary = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "282828")  // +2 elevation
        default:
            return UIColor(hex: "F2F3F5")  // 연한 회색
        }
    })
    
    // 추가: Tertiary (선택사항)
    static let modernSurfaceTertiary = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: "323232")  // +3 elevation
        default:
            return UIColor(hex: "E9ECEF")  // 더 진한 회색
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
