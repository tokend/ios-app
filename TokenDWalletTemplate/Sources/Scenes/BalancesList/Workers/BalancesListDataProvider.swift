import UIKit
import RxCocoa
import RxSwift

protocol BalancesListDataProviderProtocol {
    func observeData() -> Observable<[BalancesList.Model.SectionModel]>
    func observeLoadingStatus() -> Observable<BalancesList.Model.LoadingStatus>
}

extension BalancesList {
    typealias DataProviderProtocol = BalancesListDataProviderProtocol
    
    class DataProvider {
        
        // MARK: - Private properties
        
        private let balancesFetcher: BalancesFetcherProtocol
        
        private let sections: BehaviorRelay<[Model.SectionModel]> = BehaviorRelay(value: [])
        private var balances: [Model.Balance] = []
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let convertedAsset: String = "USD"
        
        // MARK: -
        
        init(balancesFetcher: BalancesFetcherProtocol) {
            self.balancesFetcher = balancesFetcher
        }
        
        // MARK: - Private
        
        private func updateSections() {
            let convertedBalance = self.balances
                .reduce(0) { (convertedAmount, balance) -> Decimal in
                    return convertedAmount + balance.convertedBalance
            }
            
            let headerModel = Model.Header(
                balance: convertedBalance,
                asset: self.convertedAsset,
                cellIdentifier: .header
            )
            let headerCell = Model.CellModel.header(headerModel)
            let headerSection = Model.SectionModel(cells: [headerCell])
            
            var cells: [Model.CellModel] = []
            self.balances.forEach { (balance) in
                cells.append(.balance(balance))
            }
            let balancesSection = Model.SectionModel(cells: cells)
            self.sections.accept([headerSection, balancesSection])
        }
    }
}

extension BalancesList.DataProvider: BalancesList.DataProviderProtocol {
    
    func observeData() -> Observable<[BalancesList.Model.SectionModel]> {
        self.balancesFetcher
            .observeBalances()
            .subscribe(onNext: { [weak self] (balances) in
                self?.balances = balances
                self?.updateSections()
            })
            .disposed(by: self.disposeBag)
        
        return self.sections.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<BalancesList.Model.LoadingStatus> {
        return self.balancesFetcher.observeLoadingStatus()
    }
}
