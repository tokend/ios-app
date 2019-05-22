import Foundation
import TokenDSDK

public enum NetworkInfoFetcherResult {
    
    public typealias FetchError = GeneralApi.RequestNetworkInfoResult.RequestError
    
    case failed(FetchError)
    case succeeded(NetworkInfoModel)
}

public protocol NetworkInfoFetcher {
    
    func fetchNetworkInfo(_ completion: @escaping (NetworkInfoFetcherResult) -> Void)
}

public class NetworkInfoRepo {
    
    private typealias LoadNetworkInfoCompletion = (LoadNetworkInfoResult) -> Void
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.GeneralApi
    private var completionBlocks: [LoadNetworkInfoCompletion] = []
    
    // MARK: - Public properties
    
    private(set) var networkInfo: NetworkInfoModel?
    
    // MARK: -
    
    public init(
        api: TokenDSDK.GeneralApi
        ) {
        
        self.api = api
    }
    
    // MARK: - Private
    
    enum LoadNetworkInfoResult {
        case succeeded(NetworkInfoModel)
        case failed(NetworkInfoFetcherResult.FetchError)
    }
    private func loadNetworkInfo(
        _ completion: @escaping LoadNetworkInfoCompletion
        ) {
        
        self.completionBlocks.append(completion)
        if self.completionBlocks.count > 1 {
            return
        }
        
        self.api.requestNetworkInfo { [weak self] (result) in
            switch result {
            case .succeeded(let infoModel):
                let maxFractionDigits = Int(log10(Double(infoModel.precision)))
                SharedAmountFormatter.maxFractionDigits = maxFractionDigits
                DecimalFormatter.maxFractionDigits = maxFractionDigits
                PrecisedFormatter.precision = infoModel.precision
                
                self?.networkInfo = infoModel
                self?.completionBlocks.forEach({ (block) in
                    block(.succeeded(infoModel))
                })
                self?.completionBlocks = []
            case .failed(let error):
                self?.networkInfo = nil
                self?.completionBlocks.forEach({ (block) in
                    block(.failed(error))
                })
                self?.completionBlocks = []
            }
        }
    }
}

extension NetworkInfoRepo: NetworkInfoFetcher {
    
    public func fetchNetworkInfo(_ completion: @escaping (NetworkInfoFetcherResult) -> Void) {
        if let info = self.networkInfo {
            completion(.succeeded(info))
        } else {
            self.loadNetworkInfo { (result) in
                switch result {
                    
                case .failed(let error):
                    completion(.failed(error))
                    
                case .succeeded(let info):
                    completion(.succeeded(info))
                }
            }
        }
    }
}
