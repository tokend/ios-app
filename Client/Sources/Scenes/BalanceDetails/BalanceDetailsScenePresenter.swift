import Foundation
import UIKit

public protocol BalanceDetailsScenePresentationLogic {
    
    typealias Event = BalanceDetailsScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
}

extension BalanceDetailsScene {
    
    public typealias PresentationLogic = BalanceDetailsScenePresentationLogic
    
    @objc(BalanceDetailsScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = BalanceDetailsScene.Event
        public typealias Model = BalanceDetailsScene.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch
        ) {
            
            self.presenterDispatch = presenterDispatch
        }
    }
}

// MARK: - Private methods

private extension BalanceDetailsScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let cells = sceneModel.transactions.map {
            $0.mapToViewModel()
        }
        
        let content: Model.SceneViewModel.Content = .content(
            sections: [
                .init(
                    id: "section",
                    header: nil,
                    cells: cells
                )
            ]
        )
        
        let icon: TokenDUIImage?
        let balanceNameAbbreviation: String?
        let assetName: String?
        let balance: String?
        let rate: String?
        
        if let balanceModel = sceneModel.balance {
            icon = balanceModel.icon
            balanceNameAbbreviation = String(balanceModel.name.prefix(1))
            assetName = balanceModel.name
            balance = ["\(balanceModel.balance)", balanceModel.asset].joined(separator: " ")
            if let rateAmount = balanceModel.rate,
               let asset = balanceModel.rateAsset {
                rate = ["\(rateAmount)", asset].joined(separator: " ")
            } else {
                rate = nil
            }
        } else {
            icon = nil
            balanceNameAbbreviation = nil
            assetName = nil
            balance = nil
            rate = nil
        }
        
        return .init(
            balanceIcon: icon,
            balanceNameAbbreviation: balanceNameAbbreviation,
            assetName: assetName,
            balance: balance,
            rate: rate,
            isLoading: sceneModel.loadingStatus == .loading,
            content: content
        )
    }
}

// MARK: - Mappers

extension BalanceDetailsScene.Model.Transaction {
    
    func mapToViewModel(
    ) -> BalanceDetailsScene.TransactionCell.ViewModel {
        
        let counterparty: String?
        let type: String
        
        // TODO: - Localize
        switch action {
        
        case .locked:
            type = "Locked"
        case .unlocked:
            type = "Unlocked"
            
        case .charged:
            
            switch transactionType {
            
            case .payment:
                type = "Sent"
            case .withdrawalRequest:
                type = "Charged"
                
            case .amlAlert,
                 .assetPairUpdate,
                 .atomicSwapAskCreation,
                 .atomicSwapBidCreation,
                 .investment,
                 .issuance,
                 .matchedOffer,
                 .offer,
                 .offerCancellation,
                 .saleCancellation:
                type = "Charged"
            }
        case .chargedFromLocked:
            type = "Charged"
        case .funded:
            type = "Received"
        case .issued:
            type = "Issued"
        case .matched:
            type = "Matched"
        case .withdrawn:
            type = "Withdrawn"
        }
        
        // TODO: - Localize
        switch transactionType {
        
        case .payment(let accountId, let name):
            
            if let isReceived = isReceived {
                counterparty = [(isReceived == true ? "From" : "To"), name ?? accountId.formattedAccountId()].joined(separator: " ")
            } else {
                counterparty = "Payment"
            }
            
        case .withdrawalRequest(let accountId):
            
            if let isReceived = isReceived {
                counterparty = [(isReceived == true ? "From" : "To"), accountId.formattedAccountId()].joined(separator: " ")
            } else {
                counterparty = "Withdrawal request"
            }
        case .amlAlert:
            counterparty = "AML alert"
        case .assetPairUpdate:
            counterparty = "Asset pair update"
        case .atomicSwapAskCreation:
            counterparty = "Direct buy offer creation"
        case .atomicSwapBidCreation:
            counterparty = "Direct buy"
        case .investment:
            counterparty = "Investment"
        case .issuance:
            counterparty = "Issuance/deposit"
        case .matchedOffer:
            counterparty = "Order"
        case .offer(let isInvestment):
            if isInvestment {
                counterparty = "Pending investment"
            } else {
                counterparty = "Pending order"
            }
        case .offerCancellation:
            counterparty = "Order cancellation"
        case .saleCancellation:
            counterparty = "Sale cancellation"
        }
        
        let amountColor: UIColor
        
        if isReceived == true {
            amountColor = .systemGreen
        } else if isReceived == false {
            amountColor = .systemRed
        } else {
            amountColor = .darkGray
        }
        
        return .init(
            id: id,
            icon: .uiImage(Assets.buy_toolbar_icon.image),
            type: type,
            // TODO: - Add formatter
            amount: [(isReceived == false ? "-" : ""), "\(amount) \(asset)"].joined(),
            amountColor: amountColor,
            counterparty: counterparty,
            // TODO: - Add formatter
            date: "\(date)"
        )
    }
}

private extension String {
    
    // TODO: - Add formatter
    func formattedAccountId() -> String {
        [self[0..<4], "...", self[count - 4..<count]].joined()
    }
}

extension String {
    
    subscript(_ range: Range<Int>) -> String {
        
        let start: Index = index(startIndex, offsetBy: range.startIndex)
        let end: Index = index(start, offsetBy: range.count)
        
        return String(self[start..<end])
    }
}

// MARK: - PresenterLogic

extension BalanceDetailsScene.Presenter: BalanceDetailsScene.PresentationLogic {
    
    public func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneDidUpdate(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
    
    public func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displaySceneDidUpdateSync(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
}
