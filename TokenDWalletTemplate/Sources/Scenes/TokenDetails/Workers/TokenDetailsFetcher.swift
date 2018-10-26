import Foundation
import UIKit
import RxSwift
import RxCocoa
import TokenDSDK

extension TokenDetailsScene {
    class TokenDetailsFetcher: TokenDetailsFetcherProtocol {
        
        // MARK: - Private properties
        
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        private let imagesUtility: ImagesUtility
        private let documentURLBuilder: DocumentURLBuilderProtocol
        
        private let tokensBehaviorRelay: BehaviorRelay<[Token]> = BehaviorRelay(value: [])
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            assetsRepo: AssetsRepo,
            balancesRepo: BalancesRepo,
            imagesUtility: ImagesUtility,
            documentURLBuilder: DocumentURLBuilderProtocol
            ) {
            
            self.assetsRepo = assetsRepo
            self.balancesRepo = balancesRepo
            self.imagesUtility = imagesUtility
            self.documentURLBuilder = documentURLBuilder
            
            self.observeAssets()
            self.observeBalances()
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
                let imageKey: ImagesUtility.ImageKey? = asset.details.logo?.imageKey
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
            self.tokensBehaviorRelay.accept(tokens)
        }
        
        private func findTokenWithIdentifier(_ identifier: TokenIdentifier, in tokens: [Token]) -> Token? {
            return tokens.first(where: { (token) -> Bool in
                return token.identifier == identifier
            })
        }
        
        private func createTokenWithAsset(
            _ asset: TokenDSDK.Asset,
            iconUrl: URL?,
            balanceState: Token.BalanceState
            ) -> Token {
            
            typealias Document = TokenDetailsScene.Model.Token.Document
            let termsOfUse: Document? = {
                if let termsDocument = asset.details.terms {
                    guard termsDocument.key.isEmpty == false,
                        let termsDocumentUrl = self.documentURLBuilder.getURLForTerms(termsDocument),
                        UIApplication.shared.canOpenURL(termsDocumentUrl)
                        else {
                            return nil
                    }
                    return Document(name: termsDocument.name, link: termsDocumentUrl)
                } else {
                    return nil
                }
            }()
            
            return Token(
                identifier: asset.identifier,
                iconUrl: iconUrl,
                code: asset.code,
                name: asset.details.name,
                balanceState: balanceState,
                availableForIssuance: asset.availableForIssuance,
                issued: asset.issued,
                maximumIssuanceAmount: asset.maxIssuanceAmount,
                termsOfUse: termsOfUse
            )
        }
        
        // MARK: - Public
        
        public func observeTokenWithIdentifier(_ identifier: TokenIdentifier) -> Observable<Token?> {
            return self.tokensBehaviorRelay
                .asObservable()
                .map({ [weak self] (tokens) -> Token? in
                    return self?.findTokenWithIdentifier(identifier, in: tokens)
                })
        }
        
        public func tokenForIdentifier(_ identifier: TokenIdentifier) -> Token? {
            return self.findTokenWithIdentifier(identifier, in: self.tokensBehaviorRelay.value)
        }
    }
}

private extension BalancesRepo.BalanceState {
    var tokenBalanceState: TokenDetailsScene.Model.Token.BalanceState {
        switch self {
            
        case .creating:
            return .creating
            
        case .created(let details):
            return .created(balanceId: details.balanceId)
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
