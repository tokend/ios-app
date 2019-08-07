import Foundation
import TokenDSDK

extension TransactionsRepo {
    class Operation {
        
        let base: OperationResponseBase
        
        let amount: Decimal
        let asset: String
        let id: UInt64
        let ledgerCloseTime: Date
        let pagingToken: String
        let stateValue: OperationResponseUnified.OperationState
        let type: String
        let typeValue: OperationResponseUnified.OperationType
        
        // MARK: -
        
        init(base: OperationResponseBase) {
            self.base = base
            
            self.amount = base.amount
            self.asset = base.asset
            self.id = base.id
            self.ledgerCloseTime = base.ledgerCloseTime
            self.pagingToken = base.pagingToken
            self.stateValue = base.stateValue
            self.type = base.type
            self.typeValue = base.typeValue
        }
        
        init(
            base: OperationResponseBase,
            amount: Decimal,
            asset: String,
            id: UInt64,
            ledgerCloseTime: Date,
            pagingToken: String,
            stateValue: OperationResponseUnified.OperationState,
            type: String,
            typeValue: OperationResponseUnified.OperationType
            ) {
            self.base = base
            
            self.amount = amount
            self.asset = asset
            self.id = id
            self.ledgerCloseTime = ledgerCloseTime
            self.pagingToken = pagingToken
            self.stateValue = stateValue
            self.type = type
            self.typeValue = typeValue
        }
    }
}
