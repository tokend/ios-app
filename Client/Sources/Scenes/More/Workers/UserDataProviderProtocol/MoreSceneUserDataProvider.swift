import Foundation
import RxSwift
import RxCocoa

extension MoreScene {
    
    class UserDataProvider {
        
        // MARK: Private properties
        
        private let userDataBehaviorRelay: BehaviorRelay<MoreScene.Model.UserData?>
        
        // MARK:

        init(
        ) {
            
            userDataBehaviorRelay = .init(
                value: .init(
                    avatarUrl: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Hammond_Slides_Russia_20.jpg/305px-Hammond_Slides_Russia_20.jpg")!,
                    name: "Yehor",
                    surname: "Miroshnychenko",
                    accountType: .unverified
                )
            )
        }
    }
}

extension MoreScene.UserDataProvider: MoreScene.UserDataProviderProtocol {
    
    var userData: MoreScene.Model.UserData? {
        userDataBehaviorRelay.value
    }
    
    func observeUserData() -> Observable<MoreScene.Model.UserData?> {
        userDataBehaviorRelay.asObservable()
    }
}
