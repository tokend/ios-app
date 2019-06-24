import Foundation
import TokenDSDK
import TokenDWallet

public enum PollsWorkerAddVoteResult {
    case failure(Swift.Error)
    case success
}
public enum PollsWorkerRemoveVoteResult {
    case failure(Swift.Error)
    case success
}
public protocol PollsVoteWorkerProtocol {
    func addVote(
        pollId: String,
        choice: Int,
        completion: @escaping(PollsWorkerAddVoteResult) -> Void
    )
    func removeVote(
        pollId: String,
        completion: @escaping(PollsWorkerRemoveVoteResult) -> Void
    )
}

extension Polls {
    public typealias VoteWorkerProtocol = PollsVoteWorkerProtocol
    
    public class VoteWorker {
        
        // MARK: - Private properties
        
        private let transactionSender: TransactionSender
        private let keychainDataProvider: KeychainDataProviderProtocol
        private let userDataProvider: UserDataProviderProtocol
        private let networkInfoFetcher: NetworkInfoFetcher
        
        // MARK: -
        
        init(
            transactionSender: TransactionSender,
            keychainDataProvider: KeychainDataProviderProtocol,
            userDataProvider: UserDataProviderProtocol,
            networkInfoFetcher: NetworkInfoFetcher
            ) {
            
            self.transactionSender = transactionSender
            self.keychainDataProvider = keychainDataProvider
            self.userDataProvider = userDataProvider
            self.networkInfoFetcher = networkInfoFetcher
        }
        
        // MARK: - Private
        
        private func processAddVote(
            pollId: String,
            choice: Int,
            networkInfo: NetworkInfoModel,
            completion: @escaping(PollsWorkerAddVoteResult) -> Void
            ) {
            
            guard let pollId = Uint64(pollId) else {
                    completion(.failure(Model.VoteError.failedToIdentifyPoll))
                    return
            }
            
            let singleChoiceVote = SingleChoiceVote(
                choice: Uint32(choice),
                ext: .emptyVersion()
            )
            let voteData = VoteData.singleChoice(singleChoiceVote)
            let createVoteData = CreateVoteData(
                pollID: pollId,
                data: voteData,
                ext: .emptyVersion()
            )
            let data = ManageVoteOp.ManageVoteOpData.create(createVoteData)
            
            let manageVoteOp = ManageVoteOp(
                data: data,
                ext: .emptyVersion()
            )
            
            let transactionBuilder = TransactionBuilder(
                networkParams: networkInfo.networkParams,
                sourceAccountId: self.userDataProvider.accountId,
                params: networkInfo.getTxBuilderParams(sendDate: Date())
            )
            
            transactionBuilder.add(operationBody: .manageVote(manageVoteOp))
            guard let transaction = try? transactionBuilder.buildTransaction() else {
                completion(.failure(Model.VoteError.failedToBuildTransaction))
                return
            }
            
            try? self.transactionSender.sendTransaction(
                transaction,
                walletId: self.userDataProvider.walletId,
                completion: { (result) in
                    switch result {
                        
                    case .failed(let error):
                        completion(.failure(error))
                        
                    case .succeeded:
                        completion(.success)
                    }
                })
        }
        
        private func processRemoveVote(
            pollId: String,
            networkInfo: NetworkInfoModel,
            completion: @escaping(PollsWorkerRemoveVoteResult) -> Void
            ) {
            
            guard let pollId = Uint64(pollId) else {
                completion(.failure(Model.VoteError.failedToIdentifyPoll))
                return
            }
            
            let removeVoteData = RemoveVoteData(
                pollID: pollId,
                ext: .emptyVersion()
            )
            let data = ManageVoteOp.ManageVoteOpData.remove(removeVoteData)
            let manageVoteOp = ManageVoteOp(
                data: data,
                ext: .emptyVersion()
            )
            
            let transactionBuilder = TransactionBuilder(
                networkParams: networkInfo.networkParams,
                sourceAccountId: self.userDataProvider.accountId,
                params: networkInfo.getTxBuilderParams(sendDate: Date())
            )
            
            transactionBuilder.add(operationBody: .manageVote(manageVoteOp))
            guard let transaction = try? transactionBuilder.buildTransaction() else {
                completion(.failure(Model.VoteError.failedToBuildTransaction))
                return
            }
            
            try? self.transactionSender.sendTransaction(
                transaction,
                walletId: self.userDataProvider.walletId,
                completion: { (result) in
                    switch result {
                        
                    case .failed(let error):
                        completion(.failure(error))
                        
                    case .succeeded:
                        completion(.success)
                    }
            })
            
        }
    }
}

extension Polls.VoteWorker: Polls.VoteWorkerProtocol {
    
    public func addVote(
        pollId: String,
        choice: Int,
        completion: @escaping (PollsWorkerAddVoteResult) -> Void
        ) {
        
        self.networkInfoFetcher.fetchNetworkInfo { (result) in
            switch result {
                
            case .failed(let error):
                completion(.failure(error))
                
            case .succeeded(let networkInfo):
                self.processAddVote(
                    pollId: pollId,
                    choice: choice,
                    networkInfo: networkInfo,
                    completion: completion
                )
            }
        }
    }
    
    public func removeVote(
        pollId: String,
        completion: @escaping (PollsWorkerRemoveVoteResult) -> Void
        ) {
        
        self.networkInfoFetcher.fetchNetworkInfo { (result) in
            switch result {
                
            case .failed(let error):
                completion(.failure(error))
                
            case .succeeded(let networkInfo):
                self.processRemoveVote(
                    pollId: pollId,
                    networkInfo: networkInfo,
                    completion: completion
                )
            }
        }
    }
}
