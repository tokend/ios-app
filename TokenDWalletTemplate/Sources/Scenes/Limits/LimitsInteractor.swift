import Foundation

public protocol LimitsBusinessLogic {
    
    typealias Event = Limits.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onPullToRefresh(request: Event.PullToRefresh.Request)
    func onAssetSelected(request: Event.AssetSelected.Request)
}

extension Limits {
    
    public typealias BusinessLogic = LimitsBusinessLogic
    
    @objc(LimitsInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = Limits.Event
        public typealias Model = Limits.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let accountId: String
        private let dataFetcher: LimitsDataFetcher
        
        private var isLoading: Bool = false {
            didSet {
                self.presenter.presentLoadingStatus(response: .init(isLoading: self.isLoading))
            }
        }
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            accountId: String,
            dataFetcher: LimitsDataFetcher
            ) {
            
            self.presenter = presenter
            self.accountId = accountId
            self.dataFetcher = dataFetcher
        }
        
        // MARK: - Private
        
        private func loadLimits() {
            guard !self.isLoading else {
                return
            }
            
            self.isLoading = true
            
            self.dataFetcher.fetchLimits(
                accountId: self.accountId,
                completion: { [weak self] (result) in
                    self?.isLoading = false
                    
                    switch result {
                        
                    case .failure(let error):
                        let response = Event.Error.Response(error: error)
                        self?.presenter.presentError(response: response)
                        
                    case .success(let limits):
                        self?.onLimitsLoaded(limits)
                    }
            })
        }
        
        private func onLimitsLoaded(_ limits: [Model.Asset: [Model.LimitsModel]]) {
            
        }
    }
}

extension Limits.Interactor: Limits.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.loadLimits()
    }
    
    public func onPullToRefresh(request: Event.PullToRefresh.Request) {
        self.loadLimits()
    }
    
    public func onAssetSelected(request: Event.AssetSelected.Request) {
        
    }
}
