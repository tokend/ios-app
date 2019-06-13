import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

public protocol SaleInvestBusinessLogic {
    typealias Event = SaleInvest.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onSelectBalance(request: Event.SelectBalance.Request)
    func onBalanceSelected(request: Event.BalanceSelected.Request)
    func onInvestAction(request: Event.InvestAction.Request)
    func onEditAmount(request: Event.EditAmount.Request)
    func onShowPreviousInvest(request: Event.ShowPreviousInvest.Request)
    func onPrevOfferCanceled(request: Event.PrevOfferCancelled.Request)
}

extension SaleInvest {
    public typealias BusinessLogic = SaleInvestBusinessLogic
    
    @objc(SaleInvestInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SaleInvest.Event
        public typealias Model = SaleInvest.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let dataProvider: DataProvider
        private let cancelInvestWorker: CancelInvestWorkerProtocol
        private let balanceCreator: InvestBalanceCreatorProtocol
        private let feeLoader: FeeLoader
        private var sceneModel: Model.SceneModel
        
        private let queue: DispatchQueue = DispatchQueue(
            label: NSStringFromClass(Interactor.self).queueLabel,
            qos: .userInteractive
        )
        private let updateRelay: BehaviorRelay<Bool> = BehaviorRelay(value: true)
        private let errors: PublishRelay<Swift.Error> = PublishRelay()
        
        private var sale: Model.SaleModel? {
            didSet {
                self.updateRelay.emitEvent()
                
                self.observeAsset()
                self.observeSaleBalance()
            }
        }
        private var saleBalance: Model.BalanceDetails?
        private var assetModel: Model.AssetModel? {
            didSet {
                self.updateRelay.emitEvent()
            }
        }
        
        private var balances: [Model.BalanceDetails] = [] {
            didSet {
                self.updateSelectedBalance()
                self.updateRelay.emitEvent()
            }
        }
        
        private var offers: [Model.InvestmentOffer] = [] {
            didSet {
                self.updateSelectedBalance()
                self.updateRelay.emitEvent()
            }
        }
        
        private var assetDisposable: Disposable? {
            willSet {
                self.assetDisposable?.dispose()
            }
        }
        
        private var saleBalanceDisposable: Disposable? {
            willSet {
                self.saleBalanceDisposable?.dispose()
            }
        }
        
        private var offersDisposable: Disposable? {
            willSet {
                self.offersDisposable?.dispose()
            }
        }
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            dataProvider: DataProvider,
            cancelInvestWorker: CancelInvestWorkerProtocol,
            balanceCreator: InvestBalanceCreatorProtocol,
            feeLoader: FeeLoader,
            sceneModel: Model.SceneModel
            ) {
            
            self.presenter = presenter
            self.dataProvider = dataProvider
            self.cancelInvestWorker = cancelInvestWorker
            self.balanceCreator = balanceCreator
            self.feeLoader = feeLoader
            self.sceneModel = sceneModel
        }
        
        // MARK: - Private
        
        private func observeSaleBalance() {
            guard let sale = self.sale else {
                self.saleBalanceDisposable = nil
                return
            }
            
            self.saleBalanceDisposable = self.dataProvider
                .observeBalances()
                .map({ (balances) -> Model.BalanceDetails? in
                    return balances.first(where: { (balance) -> Bool in
                        balance.asset == sale.baseAsset
                    })
                })
                .subscribe(onNext: { [weak self] (optionalBalance) in
                    self?.saleBalance = optionalBalance
                })
        }
        
        private func observeAsset() {
            guard let assetCode = self.sale?.baseAsset else {
                self.assetDisposable = nil
                return
            }
            
            self.assetDisposable = self.dataProvider
                .observeAsset(assetCode: assetCode)
                .subscribe(onNext: { [weak self] (asset) in
                    self?.assetModel = asset
                })
        }
        
        private func observeOffers() {
            self.offersDisposable = self.dataProvider
                .observeOffers()
                .subscribe(onNext: { [weak self] (offers) in
                    self?.offers = offers
                })
        }
        
        private func observeErrors() {
            self.errors
                .subscribe(onNext: { [weak self] (error) in
                    let response = Event.Error.Response(error: error)
                    self?.presenter.presentError(response: response)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateScene() {
            let investingModel = self.getInvestingModel()
            let response = Event.SceneUpdated.Response(model: investingModel)
            self.presenter.presentSceneUpdated(response: response)
        }
        
        private func getInvestingModel() -> Model.InvestingModel {
            let availableAmount = self.getAvailableInputAmount()
            let isCancellable = self.sceneModel.inputAmount != 0.0
            let actionTitle = isCancellable ? Localized(.update) : Localized(.invest)
            
            let investingModel = Model.InvestingModel(
                selectedBalance: self.sceneModel.selectedBalance,
                amount: self.sceneModel.inputAmount,
                availableAmount: availableAmount,
                isCancellable: isCancellable,
                actionTitle: actionTitle,
                existingInvestment: self.offers
            )
            
            return investingModel
        }
        
        private func getAvailableInputAmount() -> Decimal {
            guard let selectedBalance = self.sceneModel.selectedBalance else {
                return 0.0
            }
            
            var availableInputAmount = selectedBalance.balance
            
            if let prevOffer = self.getPreviousOffer(selectedBalance: selectedBalance) {
                availableInputAmount += prevOffer.amount
            }
            
            return availableInputAmount
        }
        
        private func updateSelectedBalance() {
            var shouldUpdateInputAmount = false
            if let selectedBalance = self.sceneModel.selectedBalance {
                if !self.balances.contains(selectedBalance) {
                    self.sceneModel.selectedBalance = nil
                    shouldUpdateInputAmount = true
                }
            }
            
            for balance in self.balances {
                if let prevOffer = self.getPreviousOffer(selectedBalance: balance), prevOffer.amount > 0.0 {
                    self.sceneModel.selectedBalance = balance
                    self.sceneModel.selectedBalance?.prevOfferId = prevOffer.id
                    shouldUpdateInputAmount = true
                    break
                }
            }
            
            if let selectedBalance = self.sceneModel.selectedBalance {
                let prevOfferId = self.getPrevOfferId(selectedBalance: selectedBalance)
                if prevOfferId != selectedBalance.prevOfferId {
                    self.sceneModel.selectedBalance?.prevOfferId = prevOfferId
                    shouldUpdateInputAmount = true
                }
            }
            
            if self.sceneModel.selectedBalance == nil {
                self.sceneModel.selectedBalance = self.balances.first
                shouldUpdateInputAmount = true
            }
            
            if shouldUpdateInputAmount {
                self.updateInputAmountFromSelectedBalance()
            }
        }
        
        private func updateInputAmountFromSelectedBalance() {
            guard let selectedBalance = self.sceneModel.selectedBalance else {
                self.sceneModel.inputAmount = 0.0
                return
            }
            
            guard let prevOffer = self.getPreviousOffer(selectedBalance: selectedBalance) else {
                self.sceneModel.inputAmount = 0.0
                return
            }
            
            self.sceneModel.inputAmount = prevOffer.amount
        }
        
        private func getPreviousOffer(selectedBalance: Model.BalanceDetails) -> Model.InvestmentOffer? {
            guard let prevOffer = self.offers.first(where: { (offer) -> Bool in
                return offer.asset == selectedBalance.asset
            }) else {
                return nil
            }
            
            return prevOffer
        }
        
        private func getPrevOfferId(selectedBalance: Model.BalanceDetails) -> UInt64? {
            guard let prevOffer = self.getPreviousOffer(selectedBalance: selectedBalance) else {
                return nil
            }
            
            return prevOffer.id
        }
        
        private func getBalanceWith(balanceId: String) -> Model.BalanceDetails? {
            return self.balances.first(where: { (balanceDetails) in
                return balanceDetails.balanceId == balanceId
            })
        }
        
        private func filterQuoteBalances(from balances: [Model.BalanceDetails]) -> [Model.BalanceDetails] {
            guard let sale = self.sale, sale.quoteAssets.count > 0, balances.count > 0 else {
                return []
            }
            
            var filtered: [Model.BalanceDetails] = []
            
            for balance in balances {
                if sale.quoteAssets.contains(where: { quoteAsset in
                    return balance.asset == quoteAsset.asset
                }) {
                    filtered.append(balance)
                }
            }
            
            let sorted = filtered.sorted { (balance1, balance2) -> Bool in
                return balance1.asset.caseInsensitiveCompare(balance2.asset) == .orderedAscending
            }
            
            return sorted
        }
        
        private func loadFee(
            quoteAsset: String,
            investAmount: Decimal,
            completion: @escaping (FeeResult) -> Void
            ) {
            
            self.feeLoader.loadFee(
                accountId: self.sceneModel.investorAccountId,
                asset: quoteAsset,
                feeType: .investFee,
                amount: investAmount) { (feeResponse) in
                    switch feeResponse {
                        
                    case .succeeded(let response):
                        completion(.success(fee: response))
                        
                    case .failed(let error) :
                        completion(.failed(error: error))
                    }
            }
        }
        
        private func finishInvestAction(
            sale: Model.SaleModel,
            quoteAsset: Model.SaleModel.QuoteAsset,
            baseBalance: Model.BalanceDetails,
            selectedBalance: Model.BalanceDetails,
            quoteAmount: Decimal,
            orderBookId: UInt64
            ) {
            
            self.loadFee(
                quoteAsset: quoteAsset.asset,
                investAmount: quoteAmount) { [weak self] (result) in
                    
                    switch result {
                        
                    case .failed(let error):
                        let response = Event.InvestAction.Response.failed(.feeError(error))
                        self?.presenter.presentInvestAction(response: response)
                        
                    case .success(let fee):
                        let prevOfferId = self?.getPrevOfferId(selectedBalance: selectedBalance)
                        let baseAmount = quoteAmount/quoteAsset.price
                        
                        let saleInvestModel = Model.SaleInvestModel(
                            baseAsset: sale.baseAsset,
                            quoteAsset: quoteAsset.asset,
                            baseBalance: baseBalance.balanceId,
                            quoteBalance: selectedBalance.balanceId,
                            isBuy: true,
                            baseAmount: baseAmount,
                            quoteAmount: quoteAmount,
                            baseAssetName: sale.baseAssetName,
                            price: quoteAsset.price,
                            fee: fee.percent,
                            type: sale.type,
                            offerId: 0,
                            prevOfferId: prevOfferId,
                            orderBookId: orderBookId
                        )
                        let response = Event.InvestAction.Response.succeeded(saleInvestModel)
                        self?.presenter.presentInvestAction(response: response)
                    }
            }
        }
    }
}

extension SaleInvest.Interactor: SaleInvest.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let scheduler = SerialDispatchQueueScheduler(
            queue: self.queue,
            internalSerialQueueName: self.queue.label
        )
        
        self.updateRelay
            .asObservable()
            .throttle(0.2, scheduler: scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.updateScene()
            }).disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeSale()
            .subscribe(onNext: { [weak self] (sale) in
                self?.sale = sale
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeBalances()
            .subscribe(onNext: { [weak self] (balances) in
                let filteredBalances: [Model.BalanceDetails]
                if let filtered = self?.filterQuoteBalances(from: balances) {
                    filteredBalances = filtered
                } else {
                    filteredBalances = []
                }
                
                self?.balances = filteredBalances
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeErrors()
            .subscribe(onNext: { [weak self] (error) in
                self?.errors.accept(error)
            })
            .disposed(by: self.disposeBag)
        
        self.offersDisposable = self.dataProvider
            .observeOffers()
            .subscribe(onNext: { [weak self] (offers) in
                self?.offers = offers
            })
        
        self.observeErrors()
    }
    
    public func onSelectBalance(request: Event.SelectBalance.Request) {
        let response = Event.SelectBalance.Response(balances: self.balances)
        self.presenter.presentSelectBalance(response: response)
    }
    
    public func onBalanceSelected(request: Event.BalanceSelected.Request) {
        guard let balance = self.getBalanceWith(balanceId: request.balanceId) else { return }
        
        self.sceneModel.selectedBalance = balance
        self.updateInputAmountFromSelectedBalance()
        
        let investingTabModel = self.getInvestingModel()
        let response = Event.BalanceSelected.Response(updatedTab: investingTabModel)
        self.presenter.presentBalanceSelected(response: response)
    }
    
    public func onInvestAction(request: Event.InvestAction.Request) {
        let investAmount = self.sceneModel.inputAmount
        self.presenter.presentInvestAction(response: .loading)
        
        guard let sale = self.sale else {
            let response = Event.InvestAction.Response.failed(.saleIsNotFound)
            self.presenter.presentInvestAction(response: response)
            return
        }
        guard sale.ownerId != self.sceneModel.investorAccountId else {
            let response = Event.InvestAction.Response.failed(.investInOwnSaleIsForbidden)
            self.presenter.presentInvestAction(response: response)
            return
        }
        guard let selectedBalance = self.sceneModel.selectedBalance else {
            let response = Event.InvestAction.Response.failed(.quoteBalanceIsNotFound)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        guard let quoteAsset = sale.quoteAssets.first(where: { (quoteAsset) -> Bool in
            return quoteAsset.asset == selectedBalance.asset
        }) else {
            let response = Event.InvestAction.Response.failed(.quoteAssetIsNotFound)
            self.presenter.presentInvestAction(response: response)
            return
        }
        guard investAmount > 0 else {
            let response = Event.InvestAction.Response.failed(.inputIsEmpty)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        let availableAmount = self.getAvailableInputAmount()
        guard investAmount <= availableAmount else {
            let response = Event.InvestAction.Response.failed(.insufficientFunds)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        guard let orderBookId = UInt64(sale.id) else {
            let response = Event.InvestAction.Response.failed(.formatError)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        if let baseBalance = self.saleBalance {
            self.finishInvestAction(
                sale: sale,
                quoteAsset: quoteAsset,
                baseBalance: baseBalance,
                selectedBalance: selectedBalance,
                quoteAmount: investAmount,
                orderBookId: orderBookId
            )
        } else {
            self.balanceCreator.createBalance(
                asset: sale.baseAsset,
                completion: { (result) in
                    switch result {
                        
                    case .failure:
                        let response = Event.InvestAction.Response.failed(
                            .failedToCreateBaseBalance(asset: sale.baseAsset)
                        )
                        self.presenter.presentInvestAction(response: response)
                        return
                        
                    case .success(let baseBalance):
                        self.finishInvestAction(
                            sale: sale,
                            quoteAsset: quoteAsset,
                            baseBalance: baseBalance,
                            selectedBalance: selectedBalance,
                            quoteAmount: investAmount,
                            orderBookId: orderBookId
                        )
                    }
            })
        }
    }
    
    public func onEditAmount(request: Event.EditAmount.Request) {
        self.sceneModel.inputAmount = request.amount ?? 0.0
        
        let availableInputAmount = self.getAvailableInputAmount()
        let isAmountValid = availableInputAmount >= (request.amount ?? 0.0)
        let response = Event.EditAmount.Response(isAmountValid: isAmountValid)
        self.presenter.presentEditAmount(response: response)
    }
    
    public func onShowPreviousInvest(request: Event.ShowPreviousInvest.Request) {
        guard let baseAsset = self.sale?.baseAsset else {
            return
        }
        let response = Event.ShowPreviousInvest.Response(baseAsset: baseAsset)
        self.presenter.presentShowPreviousInvest(response: response)
    }
    
    public func onPrevOfferCanceled(request: Event.PrevOfferCancelled.Request) {
        self.offersDisposable?.dispose()
        self.observeOffers()
    }
}

extension SaleInvest.Interactor {
    enum FeeResult {
        case failed(error: Swift.Error)
        case success(fee: FeeResponse)
    }
}
