import UIKit

enum Theme { }

extension Theme {
    enum Colors {
        static let white: UIColor = .init(hexString: "#FFFFFF")
        static let red: UIColor = .init(hexString: "#FF1744")
        static let darkRed: UIColor = .init(hexString: "#C2243B")
        static let dark: UIColor = .init(hexString: "#212121")
        static let grey: UIColor = .init(hexString: "#8D8D8D")
        static let lightBlue: UIColor = .init(hexString: "#DADDE9")
        static let green: UIColor = .init(hexString: "#33A494")
        static let orange: UIColor = .init(hexString: "#EF6C00")
        static let violet: UIColor = .init(hexString: "6052E4")
        
        static let mainBackgroundColor: UIColor = white
        static let errorColor: UIColor = red
        
        static let textFieldTintColor: UIColor = dark
        static let textFieldPlaceholderColor: UIColor = grey
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

        static let regularFont: UIFont = font(for: .regular)
        static let mediumFont: UIFont = font(for: .medium)
        static let semiboldFont: UIFont = font(for: .semibold)
        static let bold: UIFont = font(for: .bold)
    }
}
