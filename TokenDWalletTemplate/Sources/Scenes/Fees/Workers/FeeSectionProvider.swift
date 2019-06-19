import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

protocol FeesProviderProtocol {
    func observeFees(target: Fees.Model.Target?) -> Observable<[(String, [Fees.Model.FeeModel])]>
    func observeFeesErrorStatus() -> Observable<Swift.Error>
    func observeFeesLoadingStatus() -> Observable<Fees.Model.LoadingStatus>
}

extension Fees {
    
    class FeesProvider {
        
        // MARK: - Private properties
        
        private let generalApi: GeneralApi
        private let accountId: String
        private let feesOverview: BehaviorRelay<[(String, [Fees.Model.FeeModel])]> = BehaviorRelay(value: [])
        private let feesOverviewLoadingStatus: BehaviorRelay<Model.LoadingStatus> = BehaviorRelay(value: .loaded)
        private let feesOverviewErrorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        // MARK: -
        
        init(
            generalApi: GeneralApi,
            accountId: String
            ) {
            
            self.generalApi = generalApi
            self.accountId = accountId
        }
        
        // MARK: - Private
        
        private func handle(response: FeesOverviewResponse, target: Fees.Model.Target?) {
            var fees = response.fees.mapValues { (feesResponse) -> [Model.FeeModel] in
                return feesResponse
                    .filter({ (response) -> Bool in
                        (response.accountId.isEmpty || response.accountId == self.accountId) && response.upperBound != 0
                    })
                    .map({ (response) -> Model.FeeModel in
                        let feeType = Model.OperationType(rawValue: response.feeType)
                        let subtype = Model.Subtype(rawValue: response.subtype)
                        return Model.FeeModel(
                            asset: response.asset,
                            feeAsset: response.feeAsset,
                            operationType: feeType,
                            subtype: subtype,
                            fixed: response.fixed,
                            percent: response.percent,
                            lowerBound: response.lowerBound,
                            upperBound: response.upperBound
                        )
                    })
                    .sorted()
                }
                .filter({ (pair) -> Bool in
                    return !pair.value.isEmpty
                })
                .sorted { (first, second) -> Bool in
                    return first.key < second.key
            }
            
            if let target = target,
                let assetFees = fees.first(where: { (asset, _) -> Bool in
                    return asset == target.asset
                }) {
                let targetFees = assetFees.value.filter { (fee) -> Bool in
                    guard let feeType = fee.operationType else {
                        return false
                    }
                    return target.feeType == feeType
                }
                fees = [(target.asset, targetFees)]
            }
            self.feesOverview.accept(fees)
        }
    }
}

extension Fees.FeesProvider: FeesProviderProtocol {
    
    func observeFees(target: Fees.Model.Target?) -> Observable<[(String, [Fees.Model.FeeModel])]> {
        self.feesOverviewLoadingStatus.accept(.loading)
        self.generalApi.requestFeesOverview { [weak self] (result) in
            self?.feesOverviewLoadingStatus.accept(.loaded)
            
            switch result {
                
            case .failed(let errors):
                self?.feesOverviewErrorStatus.accept(errors)
                
            case .succeeded(let response):
                self?.handle(response: response, target: target)
            }
        }
        
        return feesOverview.asObservable()
    }
    
    func observeFeesErrorStatus() -> Observable<Error> {
        return self.feesOverviewErrorStatus.asObservable()
    }
    
    func observeFeesLoadingStatus() -> Observable<Fees.Model.LoadingStatus> {
        return self.feesOverviewLoadingStatus.asObservable()
    }
}
