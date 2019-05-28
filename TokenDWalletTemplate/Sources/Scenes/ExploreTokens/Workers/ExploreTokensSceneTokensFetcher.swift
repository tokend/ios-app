import Foundation
import TokenDSDK
import RxCocoa
import RxSwift

extension ExploreTokensScene {
    class TokensFetcher: TokensFetcherProtocol {
        
        private let disposeBag: DisposeBag = DisposeBag()
        private var imagesDisposables: [Disposable] = []
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        private let imagesUtility: ImagesUtility
        private var filteredTokensObservable: Observable<[Token]> {
            return self.tokensBehaviorRelay
                .asObservable()
                .map({ [weak self] (tokens) -> [Token] in
                    guard let filter = self?.filter.lowercased(),
                        !filter.isEmpty
                        else {
                            return tokens
                    }
                    return tokens.filter({ (token) -> Bool in
                        return token.code.lowercased().contains(filter)
                            || (token.name?.lowercased().contains(filter) ?? false)
                    })
                })
        }
        
        private var filter: String = "" {
            didSet {
                self.tokensBehaviorRelay.emitEvent()
            }
        }
        
        private let tokensBehaviorRelay: BehaviorRelay<[Token]> = BehaviorRelay(value: [])
        private let loadingStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        init(
            assetsRepo: AssetsRepo,
            imagesUtility: ImagesUtility,
            balancesRepo: BalancesRepo
            ) {
            
            self.assetsRepo = assetsRepo
            self.imagesUtility = imagesUtility
            self.balancesRepo = balancesRepo
            
            self.observeAssets()
            self.observeAssetsLoadingStatus()
            self.observeAssetsError()
            self.observeBalances()
            self.observeBalancesError()
            self.observeBalancesLoadingStatus()
        }
        
        // MARK: - Private
        
        private func observeAssets() {
            self.assetsRepo
                .observeAssets()
                .subscribe(onNext: { [weak self] (_) in
                    self?.updateTokens()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsLoadingStatus() {
            self.assetsRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatusBehaviorRelay.accept(status.status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsError() {
            self.assetsRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.errorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalancesLoadingStatus() {
            self.balancesRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatusBehaviorRelay.accept(status.status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalancesError() {
            self.balancesRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.errorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalances() {
            self.balancesRepo
                .observeBalancesDetails()
                .subscribe(onNext: { [weak self] (_) in
                    self?.updateTokens()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateTokens() {
            let assets = self.assetsRepo.assetsValue
            let balances = self.balancesRepo.balancesDetailsValue
            
            let tokens = assets.map({ (asset) -> Token in
                
                let imageKey = asset.defaultDetails?.logo?.imageKey
                let iconUrl = self.imagesUtility.getImageURL(imageKey)
                
                let balanceState = balances.first(where: { (state) -> Bool in
                    return state.asset == asset.code
                })?.tokenBalanceState ?? .notCreated
                
                return self.createTokenWithAsset(
                    asset,
                    iconUrl: iconUrl,
                    balanceState: balanceState
                )
            })
            .sorted(by: { (left, right) -> Bool in
                if case Token.BalanceState.notCreated = left.balanceState {
                    return true
                } else if case Token.BalanceState.notCreated = right.balanceState {
                    return false
                } else {
                    return true
                }
            })
            self.tokensBehaviorRelay.accept(tokens)
        }
        
        private func createTokenWithAsset(
            _ asset: TokenDSDK.Asset,
            iconUrl: URL?,
            balanceState: Token.BalanceState
            ) -> Token {
            
            return Token(
                identifier: asset.identifier,
                iconUrl: iconUrl,
                code: asset.code,
                name: asset.defaultDetails?.name,
                balanceState: balanceState
            )
        }
        
        // MARK: - Public
        
        func observeTokens() -> Observable<[Token]> {
            return self.filteredTokensObservable
        }
        
        func observeLoadingStatus() -> Observable<LoadingStatus> {
            return self.loadingStatusBehaviorRelay.asObservable()
        }
        
        func observeErrorStatus() -> Observable<Error> {
            return self.errorStatus.asObservable()
        }
        
        func reloadTokens() {
            self.assetsRepo.reloadAssets()
            self.balancesRepo.reloadBalancesDetails()
        }
        
        func tokenForIdentifier(_ identifier: TokenIdentifier) -> Token? {
            return self.tokensBehaviorRelay.value.first(where: { (token) -> Bool in
                return token.identifier == identifier
            })
        }
        
        func changeFilter(_ filter: String) {
            self.filter = filter
        }
    }
}

private extension AssetsRepo.LoadingStatus {
    var status: ExploreTokensScene.TokensFetcherProtocol.LoadingStatus {
        switch self {
        case .loaded:
            return .loaded
        case .loading:
            return .loading
        }
    }
}

private extension BalancesRepo.LoadingStatus {
    var status: ExploreTokensScene.TokensFetcherProtocol.LoadingStatus {
        switch self {
        case .loaded:
            return .loaded
        case .loading:
            return .loading
        }
    }
}

private extension BalancesRepo.BalanceState {
    var tokenBalanceState: ExploreTokensScene.Model.Token.BalanceState {
        switch self {
        case .creating:
            return .creating
        case .created(let details):
            return .created(id: details.balanceId)
        }
    }
}

private extension Asset.Details.Logo {
    var imageKey: ImagesUtility.ImageKey? {
        if let key = self.key {
            return .key(key)
        } else if let url = self.url {
            return .url(url)
        }
        return nil
    }
}
