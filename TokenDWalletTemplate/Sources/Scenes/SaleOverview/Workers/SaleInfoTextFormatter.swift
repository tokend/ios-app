import Foundation

protocol SaleOverviewTextFormatterProtocol {
    
    func formatText(text: String) -> String
}

extension SaleOverview {
    
    class TextFormatter: SaleOverviewTextFormatterProtocol {
        
        func formatText(text: String) -> String {
            guard let textData = text.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(
                    with: textData,
                    options: .allowFragments
                ) else {
                    return text
            }
            
            return "\(jsonObject)"
        }
    }
}
