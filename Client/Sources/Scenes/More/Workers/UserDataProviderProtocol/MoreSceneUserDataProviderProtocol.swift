import Foundation
import RxSwift

public protocol MoreSceneUserDataProviderProtocol {
    
    var login: String { get }
    var userData: MoreScene.Model.UserData? { get }
    var accountType: AccountType { get }
    
    func observeLogin() -> Observable<String>
    func observeUserData() -> Observable<MoreScene.Model.UserData?>
    func observeAccountType() -> Observable<AccountType>
}

public extension MoreScene {
    
    typealias UserDataProviderProtocol = MoreSceneUserDataProviderProtocol
}
