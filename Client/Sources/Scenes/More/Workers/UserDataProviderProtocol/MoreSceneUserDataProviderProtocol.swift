import Foundation
import RxSwift

public protocol MoreSceneUserDataProviderProtocol {
    
    var login: String { get }
    var userData: MoreScene.Model.UserType? { get }
    var accountType: AccountType { get }
    
    func observeLogin() -> Observable<String>
    func observeUserData() -> Observable<MoreScene.Model.UserType?>
    func observeAccountType() -> Observable<AccountType>
}

public extension MoreScene {
    
    typealias UserDataProviderProtocol = MoreSceneUserDataProviderProtocol
}
