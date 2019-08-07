import Foundation
import TokenDSDK

extension TransactionsRepo {
    class CheckSaleStateOperation: Operation {
        
        let baseSubOperation: TokenDSDK.CheckSaleStateSubOperation
        
        let feeAmount: Decimal
        let feeAsset: String
        let match: TokenDSDK.CheckSaleStateSubOperation.Match
        let parentId: UInt64
        
        // MARK: -
        
        init(subOperation: TokenDSDK.CheckSaleStateSubOperation) {
            self.baseSubOperation = subOperation
            
            self.feeAsset = subOperation.feeAsset
            self.feeAmount = subOperation.feeAmount
            self.match = subOperation.match
            self.parentId = subOperation.parentId
            
            let hashedId = CheckSaleStateOperation.getHashedId(subOperation: subOperation)
            
            super.init(
                base: subOperation.base,
                amount: subOperation.amount,
                asset: subOperation.asset,
                id: hashedId,
                ledgerCloseTime: subOperation.base.ledgerCloseTime,
                pagingToken: subOperation.base.pagingToken,
                stateValue: subOperation.base.stateValue,
                type: subOperation.base.type,
                typeValue: subOperation.base.typeValue
            )
        }
        
        // MARK: - Public
        
        static func getHashedId(subOperation subOp: TokenDSDK.CheckSaleStateSubOperation) -> UInt64 {
            let match = subOp.match
            let hashableMatch = "\(match.isBuy)\(match.price)\(match.quoteAmount)\(match.quoteAsset)"
            let hashableString = "\(subOp.feeAmount)\(subOp.feeAsset)\(hashableMatch)\(subOp.parentId)"
            
            let hash = UInt64(abs(hashableString.hashValue))
            
            return hash
        }
    }
}
