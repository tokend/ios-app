import Foundation
import RxSwift
import RxCocoa

protocol FeesBusinessLogic {
    typealias Event = Fees.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onTabWasSelected(request: Event.TabWasSelected.Request)
}

extension Fees {
    typealias BusinessLogic = FeesBusinessLogic
    
    class Interactor {
        
        typealias Event = Fees.Event
        typealias Model = Fees.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let feesOverviewProvider: FeesProviderProtocol
        private var sceneModel: Model.SceneModel
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            feesOverviewProvider: FeesProviderProtocol,
            sceneModel: Model.SceneModel
            ) {
            
            self.presenter = presenter
            self.feesOverviewProvider = feesOverviewProvider
            self.sceneModel = sceneModel
        }
        
        // MARK: - Private
        
        private func observeFeesOverview() {
            self.feesOverviewProvider
                .observeFees(target: self.sceneModel.target)
                .subscribe(onNext: { [weak self] (fees) in
                    self?.sceneModel.fees = fees
                    self?.updateSelectedAsset()
                    self?.updateFees()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateSelectedAsset() {
            if self.sceneModel.selectedAsset == nil {
                if let fees = self.sceneModel.fees.first {
                    self.sceneModel.selectedAsset = fees.asset
                }
            }
        }
        
        private func updateFees() {
            let titles = self.sceneModel.fees.map { (asset, _) -> String in
                return asset
            }
            let fees: [Model.FeeModel]
            
            let selectedTabIndex = self.getSelectedFeeIndex()
            
            if let index = selectedTabIndex {
                fees = self.sceneModel.fees[index].fees
            } else {
                fees = []
            }
            
            let groupedFees = self.getGropuedFeesModels(fees: fees)
            let response = Event.TabsDidUpdate.Response(
                titles: titles,
                fees: groupedFees,
                selectedTabIndex: selectedTabIndex
            )
            self.presenter.presentTabsDidUpdate(response: response)
        }
        
        private func getGropuedFeesModels(fees: [Model.FeeModel]) -> [Model.GroupedFeesModel] {
            var groups: [Model.FeeType: [Model.FeeModel]] = [:]
            
            fees.forEach { (fee) in
                let feeType = Model.FeeType(
                    operationType: fee.operationType,
                    subType: fee.subtype
                )
                if var fees = groups[feeType] {
                    fees.append(fee)
                    groups[feeType] = fees
                } else {
                    groups[feeType] = [fee]
                }
            }
            let sortedKeys = groups.keys.sorted()
            let groupedModels = sortedKeys.compactMap { (feeType) -> Model.GroupedFeesModel? in
                guard let fees = groups[feeType] else {
                    return nil
                }
                return Model.GroupedFeesModel(
                    feeType: feeType,
                    feeModels: fees
                )
            }
            return groupedModels
        }
        
        private func getSelectedFeeIndex() -> Int? {
            guard let selectedAsset = self.sceneModel.selectedAsset else { return nil }
            
            return self.getIndex(for: selectedAsset)
        }
        
        private func getIndex(for asset: String) -> Int? {
            return self.sceneModel.fees.firstIndex(where: { (feeAsset, _) -> Bool in
                return feeAsset == asset
            })
        }
        
        private func updateSelectedTab(asset: String) {
            let fees: [Fees.Model.FeeModel]
            if let fee = self.sceneModel.fees.first(where: { (pair) -> Bool in
                return pair.asset == asset
            }) {
                fees = fee.fees
            } else {
                fees = []
            }
            
            self.sceneModel.selectedAsset = asset
            let groupedFees = self.getGropuedFeesModels(fees: fees)
            let response = Event.TabWasSelected.Response(models: groupedFees)
            self.presenter.presentTabWasSelected(response: response)
        }
        
        private func observeFeesOverviewLoadingStatus() {
            self.feesOverviewProvider
                .observeFeesLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    let response = Event.LoadingStatusDidChange.Response(status: status)
                    self?.presenter.presentLoadingStatusDidChange(response: response)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeFeesOverviewErrorStatus() {
            self.feesOverviewProvider
                .observeFeesErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    let response = Event.Error.Response(message: error.localizedDescription)
                    self?.presenter.presentError(response: response)
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension Fees.Interactor: Fees.BusinessLogic {
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeFeesOverview()
        self.observeFeesOverviewLoadingStatus()
        self.observeFeesOverviewErrorStatus()
    }
    
    func onTabWasSelected(request: Event.TabWasSelected.Request) {
        let asset = self.sceneModel.fees[request.selectedAssetIndex].asset
        self.updateSelectedTab(asset: asset)
    }
}
