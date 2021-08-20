import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

public class AssetsRepo {

    typealias AssetIdentifier = String
    
    public enum LoadingStatus {
        case loading
        case loaded
    }
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.AssetsApiV3

    private let loadAllAssetsController: LoadAllResourcesController<Horizon.AssetResource> = .init(
        requestPagination: .init(
            .indexedStrategy(.init(
                index: nil,
                limit: 20,
                order: .descending
                )
            )
        )
    )

    private let assetsBehaviorRelay: BehaviorRelay<[Asset]> = BehaviorRelay(value: [])
    private let loadingStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatusPublishRelay: PublishRelay<Swift.Error> = PublishRelay()
    
    private let disposeBag = DisposeBag()
    
    private var shouldInitiateLoad: Bool = true
    
    // MARK: - Public properties
    
    public var assets: [Asset] {
        return assetsBehaviorRelay.value
    }
    
    public var loadingStatus: LoadingStatus {
        return loadingStatusBehaviorRelay.value
    }
    
    // MARK: -
    
    public init(
        api: TokenDSDK.AssetsApiV3
    ) {
        
        self.api = api
        self.observeRepoErrorStatus()
    }
    
    // MARK: - Private
    
    private func observeRepoErrorStatus() {
        errorStatusPublishRelay
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.shouldInitiateLoad = true
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public
    
    public func observeAssets() -> Observable<[Asset]> {
        if shouldInitiateLoad {
            shouldInitiateLoad = false
            reloadAssets()
        }
        return assetsBehaviorRelay.asObservable()
    }
    
    public func observeAsset(asset: String) -> Observable<Asset?> {
        if shouldInitiateLoad {
            shouldInitiateLoad = false
            reloadAssets()
        }
        return assetsBehaviorRelay.map { $0.first { $0.asset == asset } }.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return errorStatusPublishRelay.asObservable()
    }

    enum ReloadAssetsError: Swift.Error {

        case cannotMap
    }
    public func reloadAssets() {
        guard loadingStatus != .loading else { return }
        loadingStatusBehaviorRelay.accept(.loading)

        loadAllAssetsController.loadResources(
            loadPage: { [weak self] (pagination, completion) in
                self?.api.requestAssets(
                    pagination: pagination,
                    completion: { (result) in

                        switch result {

                        case .failure(let error):
                            completion(.failed(error))

                        case .success(let document):
                            let data = document.data ?? []
                            pagination.adjustPagination(
                                resultsCount: data.count,
                                links: document.links
                            )
                            completion(.succeeded(data))
                        }
                })
            },
            completion: { [weak self] (result, data) in
                self?.loadingStatusBehaviorRelay.accept(.loaded)

                switch result {

                case .failed(let error):
                    self?.errorStatusPublishRelay.accept(error)

                case .succeded:
                    break
                }

                guard let assets = try? data.mapToAssets()
                    else {
                        self?.errorStatusPublishRelay.accept(ReloadAssetsError.cannotMap)
                        return
                }
                self?.assetsBehaviorRelay.accept(assets)
        })
    }
}

// MARK: - Asset -

public extension AssetsRepo {

    struct Asset {

        let id: AssetIdentifier
        let asset: String
        let trailingDigits: NewAmountFormatter.TrailingDigits
        let details: Details
        let ownerAccountId: String
    }
}

public extension AssetsRepo.Asset {

    struct Details: Decodable {

        let name: String?
        let description: String?
        let logo: Logo?
    }
}

extension AssetsRepo.Asset.Details {

    public struct Logo: Decodable {
        
        // FIXME: - make mimeType non optional
        public let key: String
        public let mimeType: String?
    }
}

// MARK: - Mappers -

private extension Array where Element == Horizon.AssetResource {

    func mapToAssets() throws -> [AssetsRepo.Asset] {

        compactMap { (asset) in
            try? asset.mapToAsset()
        }
    }
}

private enum AssetMapperError: Error {

    case notEnoughData
}

private extension Horizon.AssetResource {

    func mapToAsset() throws -> AssetsRepo.Asset {

        guard let id = self.id,
            let details = try? AssetsRepo.Asset.Details.decode(
                from: self.details,
                decoder: JSONCoders.camelCaseDecoder
            )
            else {
                throw AssetMapperError.notEnoughData
        }

        guard let ownerAccountId = owner?.id
            else {
                throw AssetMapperError.notEnoughData
        }

        return .init(
            id: id,
            asset: id,
            trailingDigits: NewAmountFormatter.TrailingDigits(trailingDigits),
            details: details,
            ownerAccountId: ownerAccountId
        )
    }
}
