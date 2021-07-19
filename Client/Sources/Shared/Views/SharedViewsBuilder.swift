import UIKit

enum SharedViewsBuilder {
    
    public static func configureToolbar() -> UIToolbar {
        let toolbar: UIToolbar = .init(frame: .init(x: 0.0, y: 0.0, width: 100.0, height: 100.0))
        toolbar.barStyle = .default
        toolbar.tintColor = Theme.Colors.toolbarTintColor
        return toolbar
    }
}

