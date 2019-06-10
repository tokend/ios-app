import UIKit

enum Theme {
    
    enum Colors {
        
        private static let disabledColorAlpha: CGFloat = 0.3
        
        static let mainColor: UIColor = UIColor.white
        static let accentColor: UIColor = UIColor(red: 0.39, green: 0.33, blue: 0.93, alpha: 1.0)
        static let darkAccentColor: UIColor = UIColor(red: 0.28, green: 0.27, blue: 0.42, alpha: 1.0)
        
        static let textOnMainColor: UIColor = UIColor.black
        static let textOnAccentColor: UIColor = UIColor.white
        static let separatorOnMainColor: UIColor = UIColor.lightGray
        
        static let negativeColor: UIColor = UIColor(red: 0.835, green: 0.0, blue: 0.0, alpha: 1.0)
        static let positiveColor: UIColor = UIColor(red: 0.0, green: 0.7, blue: 0.46, alpha: 1.0)
        static let warningColor: UIColor = UIColor(red: 0.94, green: 0.63, blue: 0.15, alpha: 1.0)
        static let neutralColor: UIColor = warningColor
        
        static let containerBackgroundColor: UIColor = UIColor(white: 0.91, alpha: 1.0)
        static let textOnContainerBackgroundColor: UIColor = UIColor.black
        static let sideTextOnContainerBackgroundColor: UIColor = UIColor.gray
        
        static let contentBackgroundColor: UIColor = UIColor.white
        static let textOnContentBackgroundColor: UIColor = UIColor.black
        static let sideTextOnContentBackgroundColor: UIColor = UIColor.gray
        static let separatorOnContentBackgroundColor: UIColor = UIColor.lightGray
        
        static let sideMenuSectionSeparatorColor: UIColor = UIColor.lightGray.withAlphaComponent(0.3)
        static let textOnSideMenuBackgroundColor: UIColor = Theme.Colors.textOnContainerBackgroundColor
        static let iconOnSideMenuBackgroundColor: UIColor = Theme.Colors.iconColor
        
        static let textFieldBackgroundColor: UIColor = UIColor.white
        static let textFieldForegroundColor: UIColor = UIColor.black
        static let textFieldForegroundDisabledColor: UIColor = UIColor.lightGray
        static let textFieldForegroundErrorColor: UIColor = negativeColor
        
        static let actionButtonColor: UIColor = accentColor
        static let actionTitleButtonColor: UIColor = Theme.Colors.textOnAccentColor
        static let disabledActionButtonColor: UIColor = Theme.Colors
            .actionButtonColor.withAlphaComponent(Theme.Colors.disabledColorAlpha)
        static let disabledActionTitleButtonColor: UIColor = Theme.Colors
            .actionTitleButtonColor.withAlphaComponent(Theme.Colors.disabledColorAlpha)
        
        static let statusBarStyleOnMain: UIStatusBarStyle = .default
        static let statusBarStyleOnContentBackground: UIStatusBarStyle = .default
        
        static let activitiIndicatorTintColor: UIColor = Theme.Colors.textOnMainColor

        static let iconColor: UIColor = UIColor.gray
        
        static let negativeAmountColor: UIColor = negativeColor
        static let positiveAmountColor: UIColor = positiveColor
        static let neutralAmountColor: UIColor = UIColor.gray
        
        static let stickyHeaderBackgroundColor: UIColor = UIColor.gray
        static let stickyHeaderTitleColor: UIColor = UIColor.white
        
        static let negativeSeedValidationColor: UIColor = negativeColor
        static let positiveSeedValidationColor: UIColor = positiveColor
        static let neutralSeedValidationColor: UIColor = neutralColor
        
        static let orderBookVolumeColor: UIColor = UIColor.lightGray.withAlphaComponent(0.25)
        static let clear: UIColor = UIColor.clear
    }
    
    enum Fonts {
        
        static let largeAssetFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize + 10)
        static let largeTitleFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize + 2)
        
        static let hugeTitleFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize + 15)
        
        static let plainTextFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        static let largePlainTextFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize + 7)
        static let plainBoldTextFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        
        static let menuCellTextFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize + 1)
        
        static let smallTextFont: UIFont = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        
        static let textFieldTitleFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        static let textFieldTextFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        
        static let actionButtonFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        
        static let navigationBarBoldFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        
        static let flexibleHeaderTitleFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize + 10)
    }
}
