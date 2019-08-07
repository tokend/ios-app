import Foundation

struct ClientRedirectModel {
    
    static let redirectionTypeEmailConfirmation: Int = 1
    
    enum RedirectionType {
        case unknown
        case emailConfirmation(EmailConfirmationMeta)
    }
    
    struct EmailConfirmationMeta {
        let token: String
        let walletId: String
    }
    
    // MARK: - Public properties
    
    let typeValue: Int
    let meta: [String: Any]
    
    let type: RedirectionType
    
    // MARK: -
    
    init?(string: String) {
        guard let data = string.dataFromBase64 else {
            return nil
        }
        
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
            return nil
        }
        
        guard
            let typeValue = json["type"] as? Int,
            let metaValue = json["meta"] as? [String: Any]
            else {
                return nil
        }
        
        self.typeValue = typeValue
        self.meta = metaValue
        
        switch typeValue {
            
        case ClientRedirectModel.redirectionTypeEmailConfirmation:
            guard
                let token = metaValue["token"] as? String,
                let walletId = metaValue["wallet_id"] as? String else {
                    self.type = .unknown
                    return
            }
            let emailConfirmationMeta = EmailConfirmationMeta(
                token: token,
                walletId: walletId
            )
            
            self.type = .emailConfirmation(emailConfirmationMeta)
            
        default:
            self.type = .unknown
        }
    }
}
