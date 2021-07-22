import Foundation
import RxCocoa
import RxSwift

public protocol TabContentContainerBusinessLogic {
    
    typealias Event = TabContentContainer.Event
}

extension TabContentContainer {
    
    public typealias BusinessLogic = TabContentContainerBusinessLogic
    
    @objc(TabContentContainerInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TabContentContainer.Event
        public typealias Model = TabContentContainer.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic
            ) {
            
            self.presenter = presenter
        }
    }
}

extension TabContentContainer.Interactor: TabContentContainer.BusinessLogic { }
