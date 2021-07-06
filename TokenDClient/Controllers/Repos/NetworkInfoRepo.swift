import Foundation
import TokenDSDK

public typealias NetworkInfoFetcherResult = Swift.Result<NetworkInfoModel, Swift.Error>

public protocol NetworkInfoFetcher {
    
    func fetchNetworkInfo(_ completion: @escaping (NetworkInfoFetcherResult) -> Void)
}

public protocol PrecisionProvider {

    var precision: Int64? { get }

    func fetchPrecision(_ completion: @escaping (Result<Int64, Swift.Error>) -> Void)
}

public class NetworkInfoRepo {
    
    private typealias LoadNetworkInfoCompletion = (NetworkInfoFetcherResult) -> Void
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.InfoApiV3
    private var completionBlocks: [LoadNetworkInfoCompletion] = []
    
    // MARK: - Public properties
    
    private(set) var networkInfo: NetworkInfoModel?
    
    // MARK: -
    
    public init(
        api: TokenDSDK.InfoApiV3
        ) {
        
        self.api = api
    }
    
    // MARK: - Private
    
    private func loadNetworkInfo(
        _ completion: @escaping (NetworkInfoFetcherResult) -> Void
        ) {
        
        self.completionBlocks.append(completion)
        if self.completionBlocks.count > 1 {
            return
        }
        
        self.api.requestInfo { [weak self] (result) in
            
            switch result {
            
            case .success(let infoModel):
                // TODO: - Uncomment if precision needed
//                let maxFractionDigits = Int(log10(Double(infoModel.precision)))
//                SharedAmountFormatter.maxFractionDigits = maxFractionDigits
//                DecimalFormatter.maxFractionDigits = maxFractionDigits
//                PrecisedFormatter.precision = infoModel.precision
                
                self?.networkInfo = infoModel
                self?.completionBlocks.forEach({ (block) in
                    block(.success(infoModel))
                })
                self?.completionBlocks = []
                
            case .failure(let error):
                self?.networkInfo = nil
                self?.completionBlocks.forEach({ (block) in
                    block(.failure(error))
                })
                self?.completionBlocks = []
            }
        }
    }
}

extension NetworkInfoRepo: NetworkInfoFetcher {
    
    public func fetchNetworkInfo(_ completion: @escaping (NetworkInfoFetcherResult) -> Void) {
        if let info = self.networkInfo {
            completion(.success(info))
        } else {
            self.loadNetworkInfo { (result) in
                switch result {
                    
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let info):
                    completion(.success(info))
                }
            }
        }
    }
}

extension NetworkInfoRepo: PrecisionProvider {

    public var precision: Int64? {
        networkInfo?.precision
    }

    public func fetchPrecision(_ completion: @escaping (Result<Int64, Error>) -> Void) {
        if let info = self.networkInfo {
            completion(.success(info.precision))
        } else {
            self.loadNetworkInfo { (result) in
                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let info):
                    completion(.success(info.precision))
                }
            }
        }
    }
}
