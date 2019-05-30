import UIKit
import TokenDWallet

protocol TransactionListSceneActionProviderProtocol {
    func getActions(asset: String) -> [TransactionsListScene.ActionModel]
    func getActions(balanceId: String) -> [TransactionsListScene.ActionModel]
}
extension TransactionsListScene {
    typealias ActionProviderProtocol = TransactionListSceneActionProviderProtocol
    
    struct ActionModel {
        let title: String
        let image: UIImage
        let type: Model.ActionType
    }
    
    class ActionProvider {
        
        // MARK: - Private properties
        
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        
        // MARK: -
        
        init(
            assetsRepo: AssetsRepo,
            balancesRepo: BalancesRepo
            ) {
            
            self.assetsRepo = assetsRepo
            self.balancesRepo = balancesRepo
        }
    }
}

extension TransactionsListScene.ActionProvider: TransactionsListScene.ActionProviderProtocol {
    
    func getActions(asset: String) -> [TransactionsListScene.ActionModel] {
        var actions: [TransactionsListScene.ActionModel] = []
        guard let asset = self.assetsRepo.assetsValue
            .first(where: { (storedAsset) -> Bool in
                return storedAsset.code == asset
            }) else {
                return []
        }
        
        let receiveAction = TransactionsListScene.ActionModel(
            title: Localized(.receive),
            image: Assets.receive.image,
            type: .receive
        )
        if let state = balancesRepo.balancesDetailsValue
            .first(where: { (state) -> Bool in
                return state.asset == asset.code
            }) {
            
            switch state {
                
            case .created(let details):
                if details.balance > 0 {
                    let sendAction = TransactionsListScene.ActionModel(
                        title: Localized(.send),
                        image: Assets.paymentAction.image,
                        type: .send(balanceId: details.balanceId)
                    )
                    actions.append(sendAction)
                    actions.append(receiveAction)
                    
                    if Int32(asset.policy) & AssetPolicy.withdrawable.rawValue == AssetPolicy.withdrawable.rawValue {
                        let withdrawAction = TransactionsListScene.ActionModel(
                            title: Localized(.withdraw),
                            image: Assets.withdrawAction.image,
                            type: .withdraw(balanceId: details.balanceId)
                        )
                        actions.append(withdrawAction)
                    }
                }
            case .creating:
                break
            }
        } else {
            actions.append(receiveAction)
        }
        
        if let details = asset.defaultDetails,
            details.externalSystemType != nil {
            let depositAction = TransactionsListScene.ActionModel(
                title: Localized(.deposit),
                image: Assets.depositAction.image,
                type: .deposit(assetId: asset.identifier)
            )
            actions.append(depositAction)
        }
        
        return actions
    }
    
    func getActions(balanceId: String) -> [TransactionsListScene.ActionModel] {
        var actions: [TransactionsListScene.ActionModel] = []
        guard let details = self.balancesRepo.balancesDetailsValue
            .compactMap({ (state) -> BalancesRepo.BalanceDetails? in
                switch state {
                case .created(let details):
                    return details
                    
                case .creating:
                    return nil
                }
            }).first(where: { (details) -> Bool in
                return details.balanceId == balanceId
            }) else {
                return []
        }
        
        let receiveAction = TransactionsListScene.ActionModel(
            title: Localized(.receive),
            image: Assets.receive.image,
            type: .receive
        )
        
        if details.balance > 0 {
            let sendAction = TransactionsListScene.ActionModel(
                title: Localized(.send),
                image: Assets.paymentAction.image,
                type: .send(balanceId: details.balanceId)
            )
            actions.append(sendAction)
            actions.append(receiveAction)
            
            if let asset = self.assetsRepo.assetsValue.first(where: { (asset) -> Bool in
                return asset.code == details.asset
            }),
                Int32(asset.policy) & AssetPolicy.withdrawable.rawValue == AssetPolicy.withdrawable.rawValue {
                let withdrawAction = TransactionsListScene.ActionModel(
                    title: Localized(.withdraw),
                    image: Assets.withdrawAction.image,
                    type: .withdraw(balanceId: details.balanceId)
                )
                actions.append(withdrawAction)
                
                if let assetDetails = asset.defaultDetails,
                    assetDetails.externalSystemType != nil {
                    let depositAction = TransactionsListScene.ActionModel(
                        title: Localized(.deposit),
                        image: Assets.depositAction.image,
                        type: .deposit(assetId: asset.identifier)
                    )
                    actions.append(depositAction)
                }
            }
        } else {
            actions.append(receiveAction)
        }
        
        return actions
    }
}
