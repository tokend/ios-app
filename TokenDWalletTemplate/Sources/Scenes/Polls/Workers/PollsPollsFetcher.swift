import Foundation
import RxSwift
import RxCocoa

public protocol PollsPollsFetcherProtocol {
    func observePolls() -> Observable<[Polls.Model.Poll]>
    func setBalanceId(balanceId: String)
}

extension Polls {
    public typealias PollsFetcherProtocol = PollsPollsFetcherProtocol
    
    public class PollsFetcher {
        public typealias Model = Polls.Model
        
        // MARK: - Private properties
        
        private let polls: BehaviorRelay<[Model.Poll]> = BehaviorRelay(value: [])
        
        private var balanceId: String?
        private let reposController: ReposController
        
        // MARK: -
        
        init(reposController: ReposController) {
            self.reposController = reposController
        }
        
        // MARK: - Private
        
        private func observeRepoPolls() {
            let macPoll = Model.Poll(topic: "McDonalds")
            let pizzaPoll = Model.Poll(topic: "Pizza")
            let buhloPoll = Model.Poll(topic: "Buhlo")
            self.polls.accept([
                macPoll,
                pizzaPoll,
                buhloPoll
                ]
            )
        }
    }
}

extension Polls.PollsFetcher: Polls.PollsFetcherProtocol {
    
    public func observePolls() -> Observable<[Model.Poll]> {
        self.observeRepoPolls()
        return self.polls.asObservable()
    }
    
    public func setBalanceId(balanceId: String) {
        self.balanceId = balanceId
        let pizzaPoll = Model.Poll(topic: "Pizza")
        let buhloPoll = Model.Poll(topic: "Buhlo")
        self.polls.accept([
            pizzaPoll,
            buhloPoll
            ]
        )
    }
}
