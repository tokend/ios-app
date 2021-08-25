import Foundation
import RxSwift
import RxCocoa

public protocol SendAssetSceneRecipientProviderProtocol {
    var recipientAddress: String? { get }
    
    func observeRecipientAddress() -> Observable<String?>
}

extension SendAssetScene {
    public typealias RecipientProviderProtocol = SendAssetSceneRecipientProviderProtocol
}
