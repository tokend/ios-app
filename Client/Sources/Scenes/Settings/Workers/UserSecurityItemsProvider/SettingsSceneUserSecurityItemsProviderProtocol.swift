//import Foundation
//import RxSwift
//
//public protocol UserSecurityItemsProviderProtocol {
//
//    var securitySection: [SettingsScene.Model.SecurityTab] { get }
//
//    func observeSecuritySection(
//    ) -> Observable<[SettingsScene.Model.SecurityTab]>
//    
//    func transition(to id: String)
//    func switcherValueChanged(
//        in id: String,
//        to value: Bool,
//        completion: @escaping (Result<Void, Swift.Error>) -> Void
//        )
//}
//
//extension SettingsScene {
//    public typealias SecurityItemsProviderProtocol = UserSecurityItemsProviderProtocol
//}
