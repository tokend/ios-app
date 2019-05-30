import Foundation
import RxSwift
import RxCocoa

protocol TransactionsListSceneBusinessLogic {
    func onViewDidLoad(request: TransactionsListScene.Event.ViewDidLoad.Request)
    func onDidInitiateRefresh(request: TransactionsListScene.Event.DidInitiateRefresh.Request)
    func onDidInitiateLoadMore(request: TransactionsListScene.Event.DidInitiateLoadMore.Request)
    func onAssetDidChange(request: TransactionsListScene.Event.AssetDidChange.Request)
    func onBalanceDidChange(request: TransactionsListScene.Event.BalanceDidChange.Request)
    func onScrollViewDidScroll(request: TransactionsListScene.Event.ScrollViewDidScroll.Request)
    func onSendAction(request: TransactionsListScene.Event.SendAction.Request)
}

extension TransactionsListScene {
    typealias BusinessLogic = TransactionsListSceneBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let transactionsFetcher: TransactionsFetcherProtocol
        private let actionProvider: ActionProviderProtocol
        
        private var sceneModel: Model.SceneModel
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            transactionsFetcher: TransactionsFetcherProtocol,
            actionProvider: ActionProviderProtocol
            ) {
            
            self.sceneModel = Model.SceneModel(
                asset: "",
                balanceId: nil,
                sections: [],
                sectionTitleIndex: nil,
                sectionTitleDate: nil,
                loadingStatus: .loaded
            )
            
            self.presenter = presenter
            self.transactionsFetcher = transactionsFetcher
            self.actionProvider = actionProvider
        }
        
        private func observeTransactions() {
            self.transactionsFetcher
                .observeTransactions()
                .subscribe(onNext: { [weak self] (transactions) in
                    self?.processTransactions(transactions)
                    self?.transactionsDidUpdate()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeErrorStatus() {
            self.transactionsFetcher
                .observeErrorStatus()
                .subscribe ( onNext: { [weak self] (error) in
                    let response = Event.TransactionsDidUpdate.Response.failed(error: error)
                    self?.presenter.presentTransactionsDidUpdate(response: response)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeLoadingStatus() {
            self.transactionsFetcher
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (loadingStatus) in
                    self?.sceneModel.loadingStatus = loadingStatus
                    self?.loadingStatusDidUpdate()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func loadingStatusDidUpdate() {
            let response = self.sceneModel.loadingStatus
            self.presenter.presentLoadingStatusDidChange(response: response)
        }
        
        private func processTransactions(_ transactions: [Model.Transaction]) {
            let sortedTransactions = transactions.sorted { (left, right) -> Bool in
                return left.date > right.date
            }
            
            var sections: [Model.SectionModel] = []
            var date: Date?
            var sectionTransactions: [Model.Transaction] = []
            
            for transaction in sortedTransactions {
                let transactionDate = self.dateToGroupTransactionsByFromTransaction(transaction)
                if date != transactionDate {
                    if !sectionTransactions.isEmpty {
                        let section = Model.SectionModel(
                            date: date,
                            transactions: sectionTransactions
                        )
                        sections.append(section)
                    }
                    sectionTransactions = []
                    date = transactionDate
                }
                sectionTransactions.append(transaction)
            }
            
            if !sectionTransactions.isEmpty {
                let section = Model.SectionModel(
                    date: date,
                    transactions: sectionTransactions
                )
                sections.append(section)
            }
            self.sceneModel.sections = sections
        }
        
        private func transactionsDidUpdate() {
            let sections = self.sceneModel.sections
            let response = Event.TransactionsDidUpdate.Response.success(sections: sections)
            self.presenter.presentTransactionsDidUpdate(response: response)
        }
        
        private func dateToGroupTransactionsByFromTransaction(_ transaction: Model.Transaction) -> Date {
            let startOfTheTransactionTimeDay = Calendar.current.startOfDay(for: transaction.date)
            let date: Date = Calendar.current.date(
                from: Calendar.current.dateComponents(
                    [.year, .month],
                    from: startOfTheTransactionTimeDay)
                ) ?? Date()
            return date
        }
        
        private func onAssetDidChange() {
            self.updateActions(filter: .asset)
            self.updateSectionTitle(0, animated: false)
        }
        
        private func updateActions(filter: Model.ActionFilter) {
            var actions: [ActionModel]
            switch filter {
                
            case .asset:
                actions = self.actionProvider.getActions(asset: self.sceneModel.asset)
                
            case .balanceId:
                if let balanceId = self.sceneModel.balanceId {
                    actions = self.actionProvider.getActions(balanceId: balanceId)
                } else {
                    actions = []
                }
            }
            
            let response = Event.ActionsDidChange.Response(actions: actions)
            self.presenter.presentActionsDidChange(response: response)
        }
        
        private func updateSectionTitle(_ newSection: Int, animated: Bool) {
            let titleDate: Date? = self.titleDateForSection(newSection)
            guard self.sceneModel.sectionTitleDate != titleDate else {
                return
            }
            self.sceneModel.sectionTitleDate = titleDate
            
            var animate: Bool = animated
            let animateDown: Bool
            if let sectionTitleIndex = self.sceneModel.sectionTitleIndex {
                animateDown = sectionTitleIndex < newSection
            } else {
                animateDown = false
                animate = false
            }
            self.sceneModel.sectionTitleIndex = newSection
            
            let response = TransactionsListScene.Event.HeaderTitleDidChange.Response(
                date: titleDate,
                animated: titleDate != nil && animate,
                animateDown: animateDown
            )
            self.presenter.presentHeaderTitleDidChange(response: response)
        }
        
        private func titleDateForSection(_ section: Int) -> Date? {
            let sections = self.sceneModel.sections
            
            if sections.indexInBounds(section) {
                return sections[section].date
            } else {
                return nil
            }
        }
    }
}

extension TransactionsListScene.Interactor: TransactionsListScene.BusinessLogic {
    func onViewDidLoad(request: TransactionsListScene.Event.ViewDidLoad.Request) {
        self.observeLoadingStatus()
        self.observeTransactions()
        self.observeErrorStatus()
    }
    
    func onDidInitiateRefresh(request: TransactionsListScene.Event.DidInitiateRefresh.Request) {
        guard !self.isLoading else {
            self.loadingStatusDidUpdate()
            return
        }
        self.transactionsFetcher.reloadTransactions()
    }
    
    func onDidInitiateLoadMore(request: TransactionsListScene.Event.DidInitiateLoadMore.Request) {
        guard !self.isLoading else {
            return
        }
        self.transactionsFetcher.loadMoreTransactions()
    }
    
    func onAssetDidChange(request: TransactionsListScene.Event.AssetDidChange.Request) {
        self.sceneModel.asset = request.asset
        self.onAssetDidChange()
    }
    
    private var isLoading: Bool {
        return self.transactionsFetcher.loadingStatusValue == .loading
            || self.transactionsFetcher.loadingMoreStatusValue == .loading
    }
    
    func onBalanceDidChange(request: TransactionsListScene.Event.BalanceDidChange.Request) {
        self.sceneModel.balanceId = request.balanceId
        self.updateActions(filter: .balanceId)
        if let balanceId = request.balanceId {
            self.transactionsFetcher.setBalanceId(balanceId)
        }
    }

    func onScrollViewDidScroll(request: TransactionsListScene.Event.ScrollViewDidScroll.Request) {
        let indexPath = request.indexPath
        let section = indexPath.section
        
        self.updateSectionTitle(section, animated: true)
    }
    
    func onSendAction(request: TransactionsListScene.Event.SendAction.Request) {
        let response = TransactionsListScene.Event.SendAction.Response(balanceId: self.sceneModel.balanceId)
        self.presenter.presentSendAction(response: response)
    }
}
