import Foundation
import TokenDSDK
import TokenDWallet
import RxSwift
import RxCocoa

class ExternalSystemBalancesManager {
    
    typealias ExternalSystemAccountType = Int32
    
    enum BindingStatus {
        case binding
        case binded
        case notBinded
    }
    
    // MARK: - Private properties
    
    private var bindingStatuses: [ExternalSystemAccountType: BehaviorRelay<BindingStatus>] = [:]
    private let bindingStatusesBehaviorRelay: BehaviorRelay<Void> = BehaviorRelay(value: ())
    private let bindingStatusesErrors: PublishRelay<Swift.Error> = PublishRelay()
    private let accountRepo: AccountRepo
    private let networkInfoFetcher: NetworkInfoFetcher
    private let userDataProvider: UserDataProviderProtocol
    private let transactionSender: TransactionSender
    
    // MARK: -
    
    init(
        accountRepo: AccountRepo,
        networkInfoFetcher: NetworkInfoFetcher,
        userDataProvider: UserDataProviderProtocol,
        transactionSender: TransactionSender
        ) {
        
        self.accountRepo = accountRepo
        self.networkInfoFetcher = networkInfoFetcher
        self.userDataProvider = userDataProvider
        self.transactionSender = transactionSender
    }
    
    // MARK: - Private
    
    private func bind(
        externalSystemType: ExternalSystemAccountType,
        networkInfo: NetworkInfoModel,
        oldBindingStatus: BindingStatus,
        completion: @escaping (BindBalanceWithAccountResult) -> Void
        ) {
        
        let operation = BindExternalSystemAccountIdOp(
            externalSystemType: externalSystemType,
            ext: .emptyVersion()
        )
        let transactionBuilder: TransactionBuilder = TransactionBuilder(
            networkParams: networkInfo.networkParams,
            sourceAccountId: self.userDataProvider.accountId,
            params: networkInfo.getTxBuilderParams(sendDate: Date())
        )
        
        transactionBuilder.add(
            operationBody: .bindExternalSystemAccountId(operation),
            operationSourceAccount: self.userDataProvider.accountId
        )
        
        do {
            let transaction = try transactionBuilder.buildTransaction()
            
            try self.transactionSender.sendTransaction(
                transaction,
                walletId: self.userDataProvider.walletId
            ) { [weak self] (result) in
                switch result {
                case .succeeded:
                    self?.accountRepo.updateAccount({ [weak self] (_) in
                        self?.bindingStatusBehaviorRelayForAccount(externalSystemType).accept(.binded)
                        self?.bindingStatusesBehaviorRelay.accept(())
                    })
                    completion(.succeeded)
                case .failed(let error):
                    self?.bindingStatusesErrors.accept(error)
                    self?.bindingStatusBehaviorRelayForAccount(externalSystemType).accept(oldBindingStatus)
                    self?.bindingStatusesBehaviorRelay.accept(())
                    completion(.failed(error))
                }
            }
        } catch let error {
            completion(.failed(error))
        }
    }
    
    private func bindingStatusBehaviorRelayForAccount(
        _ type: ExternalSystemAccountType
        ) -> BehaviorRelay<BindingStatus> {
        
        guard let status = self.bindingStatuses[type] else {
            if self.accountRepo.accountValue?.externalSystemAccounts.first(where: { (account) -> Bool in
                return account.type.value == type
            }) != nil {
                self.bindingStatuses[type] = BehaviorRelay(value: .binded)
            } else {
                self.bindingStatuses[type] = BehaviorRelay(value: .notBinded)
            }
            return self.bindingStatusBehaviorRelayForAccount(type)
        }
        
        return status
    }
    
    // MARK: - Public
    
    func bindingStatusValueForAccount(
        _ type: ExternalSystemAccountType
        ) -> BindingStatus {
        
        return self.bindingStatusBehaviorRelayForAccount(type).value
    }
    
    func observeBindingStatusForAccount(
        _ type: ExternalSystemAccountType
        ) -> Observable<BindingStatus> {
        
        return self.bindingStatusBehaviorRelayForAccount(type).asObservable()
    }
    
    func observeBindingStatuses() -> Observable<Void> {
        return self.bindingStatusesBehaviorRelay.asObservable()
    }
    
    func observeBindingStatusesErrors() -> Observable<Swift.Error> {
        return self.bindingStatusesErrors.asObservable()
    }
    
    enum BindBalanceWithAccountResult {
        case succeeded
        case failed(Swift.Error)
    }
    func bindBalanceWithAccount(
        _ type: ExternalSystemAccountType,
        completion: @escaping (BindBalanceWithAccountResult) -> Void
        ) {
        
        let bindingStatusBehaviorRelay = self.bindingStatusBehaviorRelayForAccount(type)
        let oldBindingStatus = bindingStatusBehaviorRelay.value
        
        guard oldBindingStatus != .binding else {
            return
        }
        
        bindingStatusBehaviorRelay.accept(.binding)
        self.bindingStatusesBehaviorRelay.accept(())
        
        self.networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in
            switch result {
                
            case .failed(let error):
                self?.bindingStatusesErrors.accept(error)
                bindingStatusBehaviorRelay.accept(oldBindingStatus)
                self?.bindingStatusesBehaviorRelay.accept(())
                completion(.failed(error))
                
            case .succeeded(let networkInfo):
                self?.bind(
                    externalSystemType: type,
                    networkInfo: networkInfo,
                    oldBindingStatus: oldBindingStatus,
                    completion: completion
                )
            }
        }
    }
}
