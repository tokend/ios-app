import UIKit

public class TokenColoringProvider {
    
    // MARK: - Public properties
    
    public static let shared: TokenColoringProvider = TokenColoringProvider()
    
    let colors: [UIColor]
    
    // MARK: - Private properties
    
    private var codeNumbers: [String: Int] = [:]
    
    // MARK: -
    
    init() {
        let colorHexs: [String] = [
            "#80CBC4",
            "#80DEEA",
            "#82B1FF",
            "#8C9EFF",
            "#90CAF9",
            "#9FA8DA",
            "#A5D6A7",
            "#B0BEC5",
            "#BCAAA4",
            "#C5E1A5",
            "#CE93D8",
            "#DCE775",
            "#EF9A9A",
            "#F48FB1",
            "#FBC02D",
            "#FF8A80",
            "#FFAB91",
            "#FFCC80",
            "#FFD54F"
        ]
        
        self.colors = colorHexs.map({ (hex) -> UIColor in
            return UIColor(hexString: hex)
        })
    }
    
    // MARK: - Public
    
    public func coloringForCode(_ code: String) -> UIColor {
        let codeNumber = self.numberForCode(code)
        let color = self.colors[codeNumber]
        
        return color
    }
    
    // MARK: - Private
    
    private func numberForCode(_ codeStr: String) -> Int {
        if let codeNumber = self.codeNumbers[codeStr] {
            return codeNumber
        }
        
        let code: Int = codeStr.utf8.reduce(0, { (result, char) in
            let newResult = (31 * result + Int(char)) % self.colors.count
            return newResult
        })
        
        self.codeNumbers[codeStr] = code
        
        return code
    }
}

extension TokenColoringProvider: ExploreTokensScene.TokenColoringProvider {}

extension TokenColoringProvider: TokenDetailsScene.TokenColoringProvider {}
