import UIKit

enum Theme { }

extension Theme {
    enum Colors {

    }
}

private extension UIFont.Weight {
    var projectFontName: String? {
        // TODO: - Set font name
        return nil
    }
}

extension Theme {
    enum Fonts {

        private static func font(for weight: UIFont.Weight, size: CGFloat = 17.0) -> UIFont {
            guard let name = weight.projectFontName,
                let font = UIFont(name: name, size: size)
                else {
                    return UIFont.systemFont(ofSize: size, weight: weight)
            }
            return font
        }

        static let mediumFont: UIFont = font(for: .medium)
        static let semiboldFont: UIFont = font(for: .semibold)
    }
}
