import Foundation
import RxSwift

public protocol MoreSceneUserDataProviderProtocol {
    
    var userData: MoreScene.Model.UserData? { get }
    
    func observeUserData() -> Observable<MoreScene.Model.UserData?>
}

extension MoreScene {
    
    typealias UserDataProviderProtocol = MoreSceneUserDataProviderProtocol
}
