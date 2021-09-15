import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class PaymentSender {
    
    // MARK: - Private properties
    
    private let networkInfoRepo: NetworkInfoRepo
    private let transactionCreator: TransactionCreator
    private let transactionSender: TransactionSender
    private let amountConverter: AmountConverterProtocol
    
    private let originalAccountId: String
    
    // MARK: -
    
    init(
        networkInfoRepo: NetworkInfoRepo,
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        amountConverter: AmountConverterProtocol,
        originalAccountId: String
    ) {
        
        self.networkInfoRepo = networkInfoRepo
        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.amountConverter = amountConverter
        
        self.originalAccountId = originalAccountId
    }
}

// MARK: - Private properties

private extension PaymentSender {
    
    func createTransaction(
        sourceBalanceId: String,
        destinationAccountId: String,
        amount: Decimal,
        senderFee: Horizon.CalculatedFeeResource,
        recipientFee: Horizon.CalculatedFeeResource,
        isPayingFeeForRecipient: Bool,
        description: String,
        reference: String,
        networkInfo: NetworkInfoModel,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {
        
        guard let sourceAccountId = AccountID(
            base32EncodedString: self.originalAccountId,
            expectedVersion: .accountIdEd25519
        ) else {
            completion(.failure(SendPaymentWorkerError.noSenderAccountId))
            return
        }
        
        guard let sourceBalanceId = BalanceID(
            base32EncodedString: sourceBalanceId,
            expectedVersion: .balanceIdEd25519
        ) else {
            completion(.failure(SendPaymentWorkerError.noBalanceId))
            return
        }
        
        guard let destinationAccountId = AccountID(
            base32EncodedString: destinationAccountId,
            expectedVersion: .accountIdEd25519
        ) else {
            completion(.failure(SendPaymentWorkerError.noDestinationAccountId))
            return
        }
        
        let sourceFee: Fee = .init(
            fixed: amountConverter.convertDecimalToUInt64(value: senderFee.fixed, precision: networkInfo.precision),
            percent: amountConverter.convertDecimalToUInt64(value: senderFee.calculatedPercent, precision: networkInfo.precision),
            ext: .emptyVersion
        )
        
        let destinationFee: Fee = .init(
            fixed: amountConverter.convertDecimalToUInt64(value: recipientFee.fixed, precision: networkInfo.precision),
            percent: amountConverter.convertDecimalToUInt64(value: recipientFee.calculatedPercent, precision: networkInfo.precision),
            ext: .emptyVersion
        )
        
        let paymentFeeData: PaymentFeeData = .init(
            sourceFee: sourceFee,
            destinationFee: destinationFee,
            sourcePaysForDest: isPayingFeeForRecipient,
            ext: .emptyVersion
        )
        
        let paymentOp = PaymentOp(
            sourceBalanceID: sourceBalanceId,
            destination: .account(destinationAccountId),
            amount: amountConverter.convertDecimalToUInt64(value: amount, precision: networkInfo.precision),
            feeData: paymentFeeData,
            subject: description,
            reference: reference,
            ext: .emptyVersion
        )
        
        
        transactionCreator.createTransaction(
            sourceAccountId: sourceAccountId,
            operations: [
                .payment(paymentOp)
            ],
            sendDate: Date(),
            completion: { [weak self] (result) in
                
                switch result {
                
                case .success(let transactionModel):
                    self?.transactionSender.sendTransactionV3(
                        transactionModel,
                        completion: { (result) in
                            
                            switch result {
                            
                            case .succeeded:
                                completion(.success(()))
                                
                            case .failed(let error):
                                completion(.failure(error))
                            }
                        }
                    )
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
}

// MARK: - SendPaymentWorkerProtocol

extension PaymentSender: PaymentSenderProtocol {
    func sendPayment(
        sourceBalanceId: String,
        destinationAccountId: String,
        amount: Decimal,
        senderFee: Horizon.CalculatedFeeResource,
        recipientFee: Horizon.CalculatedFeeResource,
        isPayingFeeForRecipient: Bool,
        description: String,
        reference: String,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {
        
        networkInfoRepo.fetchNetworkInfo { [weak self] (result) in
            
            switch result {
            
            case .success(let networkInfo):
                self?.createTransaction(
                    sourceBalanceId: sourceBalanceId,
                    destinationAccountId: destinationAccountId,
                    amount: amount,
                    senderFee: senderFee,
                    recipientFee: recipientFee,
                    isPayingFeeForRecipient: isPayingFeeForRecipient,
                    description: description,
                    reference: reference,
                    networkInfo: networkInfo,
                    completion: completion
                )
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
