import Foundation
import TokenDSDK

protocol DepositSceneErrorFormatterProtocol {
    func getLocalizedDescription(error: Error) -> String
}

extension DepositScene {
    
    typealias PaymentError = TransactionsApi.PaymentSendResult.PaymentError
    typealias ErrorFormatterProtocol = DepositSceneErrorFormatterProtocol
    
    class ErrorFormatter: ErrorFormatterProtocol {
        
        // MARK: - Public
        
        func getLocalizedDescription(error: Error) -> String {
            if let apiErrors = error as? ApiErrors {
                return self.formatApiErrors(apiErrors: apiErrors)
            } else if let paymentError = error as? PaymentError {
                
                switch paymentError {
                    
                case .other(let apiErrors):
                    return self.formatApiErrors(apiErrors: apiErrors)
                    
                case .tfaFailed:
                    return Localized(.twofactor_authentication_failed)
                }
            }
            
            return error.localizedDescription
        }
        
        // MARK: - Private
        
        private func formatApiErrors(apiErrors: ApiErrors) -> String {
            var finalMessage: [String] = []
            
            for apiError in apiErrors.errors {
                if let horrizonError = apiError.horizonError,
                    let extras = horrizonError.extras,
                    let messages = extras.resultCodes.messages {
                    
                    finalMessage.appendUniques(contentsOf: messages)
                } else if let horrizonErrorV2 = apiError.horizonErrorV2,
                    let extras = horrizonErrorV2.meta.extras,
                    let messages = extras.resultCodes.messages {
                    
                    finalMessage.appendUniques(contentsOf: messages)
                }
            }
            
            return finalMessage.isEmpty ?
                apiErrors.localizedDescription :
                finalMessage.joined(separator: "\n")
        }
    }
}
