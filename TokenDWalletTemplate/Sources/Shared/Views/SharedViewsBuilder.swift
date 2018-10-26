import UIKit

enum SharedViewsBuilder {
    
    // MARK: -
    
    public static func configureActionButton(_ button: UIButton, title: String? = nil) {
        let buttonImage = UIImage.resizableImageWithColor(Theme.Colors.actionButtonColor)
        button.setBackgroundImage(buttonImage, for: .normal)
        button.setTitleColor(Theme.Colors.actionTitleButtonColor, for: .normal)
        button.titleLabel?.font = Theme.Fonts.actionButtonFont
        if let title = title {
            button.setTitle(title, for: .normal)
        }
    }
    
    public static func createTextFieldView() -> TextFieldView {
        let textFielView = TextFieldView()
        textFielView.font = Theme.Fonts.textFieldTextFont
        textFielView.textColor = Theme.Colors.textOnContentBackgroundColor
        return textFielView
    }
    
    public static func createEmptyLabel() -> UILabel {
        let emptyLabel = UILabel()
        emptyLabel.textAlignment = .center
        emptyLabel.adjustsFontSizeToFitWidth = false
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
        emptyLabel.font = Theme.Fonts.smallTextFont
        return emptyLabel
    }
    
    // MARK: - Input Form
    
    public static func configureInputForm(titleLabel: UILabel) {
        titleLabel.font = Theme.Fonts.textFieldTitleFont
        titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
    }
    
    public static func configureInputForm(valueLabel: UILabel) {
        valueLabel.font = Theme.Fonts.textFieldTextFont
        valueLabel.textColor = Theme.Colors.textOnContentBackgroundColor
    }
    
    public static func configureInputForm(textView: UITextView) {
        textView.font = Theme.Fonts.textFieldTextFont
        textView.textColor = Theme.Colors.textOnContentBackgroundColor
        textView.contentInset = UIEdgeInsets(top: -8.0, left: -5.0, bottom: 0.0, right: 0.0)
    }
    
    public static func configureInputForm(placeholderLabel: UILabel) {
        placeholderLabel.font = Theme.Fonts.textFieldTextFont
        placeholderLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
    }
    
    public static func configureInputForm(subTitleLabel: UILabel) {
        subTitleLabel.font = Theme.Fonts.textFieldTextFont
        subTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
    }
}
