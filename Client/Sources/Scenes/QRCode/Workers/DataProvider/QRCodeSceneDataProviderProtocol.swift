import Foundation
import RxSwift

public protocol QRCodeSceneDataProviderProtocol {
    
    var data: String { get }
    var title: String { get }
    
    func observeData() -> Observable<String>
}

extension QRCodeScene {
    
    public typealias DataProviderProtocol = QRCodeSceneDataProviderProtocol
}
