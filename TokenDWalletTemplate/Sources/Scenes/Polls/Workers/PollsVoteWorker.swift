import Foundation
import TokenDSDK

public enum PollsWorkerAddVoteResult {
    case failure(Error)
    case success
}
public enum PollsWorkerRemoveVoteResult {
    case failure(Error)
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
        
        // MARK: -
        
        init(transactionSender: TransactionSender) {
            self.transactionSender = transactionSender
        }
        
        // MARK: - Private
        
        private func processAddVote(
            pollId: String,
            choice: Int,
            completion: @escaping(PollsWorkerAddVoteResult) -> Void
            ) {
              
        }
        
        private func processRemoveVote(
            pollId: String,
            completion: @escaping(PollsWorkerRemoveVoteResult) -> Void
            ) {
            
        }
    }
}

extension Polls.VoteWorker: Polls.VoteWorkerProtocol {
    
    public func addVote(pollId: String, choice: Int, completion: @escaping (PollsWorkerAddVoteResult) -> Void) {
        self.processAddVote(pollId: pollId, choice: choice, completion: completion)
    }
    
    public func removeVote(pollId: String, completion: @escaping (PollsWorkerRemoveVoteResult) -> Void) {
        self.processRemoveVote(pollId: pollId, completion: completion)
    }
}
