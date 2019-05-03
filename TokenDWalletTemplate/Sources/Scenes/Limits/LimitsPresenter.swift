import Foundation

public protocol LimitsPresentationLogic {
    
    typealias Event = Limits.Event
    
    func presentLoadingStatus(response: Event.LoadingStatus.Response)
    func presentError(response: Event.Error.Response)
    func presentLimitsUpdated(response: Event.LimitsUpdated.Response)
}

extension Limits {
    
    public typealias PresentationLogic = LimitsPresentationLogic
    
    @objc(LimitsPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = Limits.Event
        public typealias Model = Limits.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension Limits.Presenter: Limits.PresentationLogic {
    
    public func presentLoadingStatus(response: Event.LoadingStatus.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatus(viewModel: response)
        }
    }
    
    public func presentError(response: Event.Error.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayError(viewModel: .init(error: response.error.localizedDescription))
        }
    }
    
    public func presentLimitsUpdated(response: Event.LimitsUpdated.Response) {
        
    }
}
