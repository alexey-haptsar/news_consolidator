import UIKit

enum Theme {
    
    // MARK: - Background Colors
    static let gradientTopColor = UIColor(red: 0.22, green: 0.24, blue: 0.35, alpha: 1.0)
    static let gradientBottomColor = UIColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1.0)
    static let backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0)
    static let cardBackground = UIColor(red: 0.14, green: 0.14, blue: 0.22, alpha: 1.0)
    static let cardBackgroundRead = UIColor(red: 0.12, green: 0.12, blue: 0.19, alpha: 1.0)
    
    // MARK: - Text Colors
    static let primaryText = UIColor.white
    static let secondaryText = UIColor(red: 0.68, green: 0.68, blue: 0.75, alpha: 1.0)
    static let tertiaryText = UIColor(red: 0.50, green: 0.50, blue: 0.58, alpha: 1.0)
    
    // MARK: - Accent Colors
    static let accent = UIColor(red: 0.30, green: 0.56, blue: 0.88, alpha: 1.0)
    static let destructive = UIColor(red: 0.90, green: 0.30, blue: 0.30, alpha: 1.0)
    static let separator = UIColor(red: 0.20, green: 0.20, blue: 0.30, alpha: 1.0)
    
    // MARK: - Bar Colors
    static let navBarColor = UIColor(red: 0.20, green: 0.22, blue: 0.33, alpha: 0.95)
    static let tabBarColor = UIColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 0.95)
    
    // MARK: - Fonts
    static let titleFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
    static let bodyFont = UIFont.systemFont(ofSize: 13, weight: .regular)
    static let captionFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    static let headerFont = UIFont.systemFont(ofSize: 17, weight: .bold)
    
    // MARK: - Bar Appearance
    static func configureNavigationBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navBarColor
        appearance.titleTextAttributes = [
            .foregroundColor: primaryText,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: primaryText
        ]
        return appearance
    }
    
    static func configureTabBarAppearance() -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = tabBarColor
        let normalAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: secondaryText]
        let selectedAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: accent]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
        appearance.stackedLayoutAppearance.normal.iconColor = secondaryText
        appearance.stackedLayoutAppearance.selected.iconColor = accent
        return appearance
    }
    
    // MARK: - Source Colors
    static func sourceColor(for name: String) -> UIColor {
        switch name.lowercased() {
        case "vedomosti":
            return UIColor(red: 0.85, green: 0.35, blue: 0.25, alpha: 1.0)
        case "rbc":
            return UIColor(red: 0.25, green: 0.65, blue: 0.45, alpha: 1.0)
        default:
            return accent
        }
    }
    
}
