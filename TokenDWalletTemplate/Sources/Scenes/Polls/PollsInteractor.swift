import Foundation
import RxSwift

public protocol PollsBusinessLogic {
    typealias Event = Polls.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onSelectBalance(request: Event.SelectBalance.Request)
    func onBalanceSelected(request: Event.BalanceSelected.Request)
}

extension Polls {
    public typealias BusinessLogic = PollsBusinessLogic
    
    @objc(PollsInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = Polls.Event
        public typealias Model = Polls.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let balancesFetcher: BalancesFetcherProtocol
        private let pollsFetcher: PollsFetcherProtocol
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            balancesFetcher: BalancesFetcherProtocol,
            pollsFetcher: PollsFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.balancesFetcher = balancesFetcher
            self.pollsFetcher = pollsFetcher
            self.sceneModel = Model.SceneModel(
                balances: [],
                selectedBalance: nil,
                polls: []
            )
        }
        
        // MARK: - Private
        
        private func updateScene() {
            guard let selectedBalance = self.sceneModel.selectedBalance else {
                return
            }
            let response = Event.SceneUpdated.Response(
                polls: self.sceneModel.polls,
                selectedBalance: selectedBalance
            )
            self.presenter.presentSceneUpdated(response: response)
        }
        
        // MARK: - Observe
        
        private func observeBalances() {
            self.balancesFetcher
                .observeBalances()
                .subscribe(onNext: { (balances) in
                    self.sceneModel.balances = balances
                    self.updateSelectedBalance()
                    self.updatePolls()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observePolls() {
            self.pollsFetcher
                .observePolls()
                .subscribe(onNext: { [weak self] (polls) in
                    self?.sceneModel.polls = polls
                    self?.updateScene()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updatePolls() {
            guard let selectedBalance = self.sceneModel.selectedBalance else {
                return
            }
            self.pollsFetcher.setBalanceId(balanceId: selectedBalance.balanceId)
        }
        
        private func updateSelectedBalance() {
            if let selectedBalance = self.sceneModel.selectedBalance {
                guard !self.sceneModel.balances.contains(selectedBalance) else {
                    return
                }
                self.selectFirstBalance()
            } else {
                self.selectFirstBalance()
            }
        }
        
        private func selectFirstBalance() {
            self.sceneModel.selectedBalance = self.sceneModel.balances.first
        }
    }
}

extension Polls.Interactor: Polls.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeBalances()
        self.observePolls()
    }
    
    public func onSelectBalance(request: Event.SelectBalance.Request) {
        let response = Event.SelectBalance.Response(balances: self.sceneModel.balances)
        self.presenter.presentSelectBalance(response: response)
    }
    
    public func onBalanceSelected(request: Event.BalanceSelected.Request) {
        guard let balance = self.sceneModel.balances.first(where: { (balance) -> Bool in
            return balance.balanceId == request.balanceId
        }) else { return }
        
        self.sceneModel.selectedBalance = balance
        self.updatePolls()
    }
}
