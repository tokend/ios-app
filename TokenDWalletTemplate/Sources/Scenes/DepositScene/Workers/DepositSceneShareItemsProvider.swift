import UIKit

public protocol DepositSceneShareItemsProviderProtocol {
    func getShareItems(
        address: String?,
        payload: String?,
        completion: @escaping ([Any]) -> Void
    )
}

extension DepositScene {
    typealias ShareItemsProviderProtocol = DepositSceneShareItemsProviderProtocol
    
    public class ShareItemsProvider {
        
        // MARK: - Private properties
        
        private let qrCodeGenerator: DepositSceneQRCodeGeneratorProtocol
        private let shareQRCodeSize: CGSize = CGSize(width: 200, height: 200)
        
        // MARK: -
        
        init(
            qrCodeGenerator: DepositSceneQRCodeGeneratorProtocol
            ) {
            
            self.qrCodeGenerator = qrCodeGenerator
        }
    }
}

extension DepositScene.ShareItemsProvider: DepositScene.ShareItemsProviderProtocol {
    
    public func getShareItems(
        address: String?,
        payload: String?,
        completion: @escaping ([Any]) -> Void
        ) {
        
        var items: [Any] = []
        if let payload = payload {
            items.append(payload)
        }
        if let address = address {
            self.qrCodeGenerator.generateQRCodeFromString(
                address,
                withTintColor: UIColor.black,
                backgroundColor: UIColor.clear,
                size: self.shareQRCodeSize,
                completion: { (qrCode) in
                    items.insert(qrCode as Any, at: 0)
                    items.insert(address, at: 1)
                    completion(items)
            })
        }
    }
}
