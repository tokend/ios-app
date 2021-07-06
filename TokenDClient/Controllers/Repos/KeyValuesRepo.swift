import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

class KeyValuesRepo {

    typealias Key = String
    typealias Value = Horizon.KeyValueEntryValue

    // MARK: - Private properties

    private let keyValuesApi: KeyValuesApiV3

    private let keyValuesBehaviorRelay: BehaviorRelay<[Key: Value]>
    private var keyValues: [Key: Value] { keyValuesBehaviorRelay.value }

    // MARK: - Public properties

    // MARK: -

    init(
        keyValuesApi: KeyValuesApiV3
    ) {

        self.keyValuesApi = keyValuesApi

        self.keyValuesBehaviorRelay = .init(value: [:])
    }
}

// MARK: - Private methods

private extension KeyValuesRepo {

    enum LoadValueResult {

        enum Error: Swift.Error {

            case emptyData
            case other(Swift.Error)
        }

        case success(Value)
        case failure(Error)
    }
    func loadValue(
        for key: Key,
        completion: ((LoadValueResult) -> Void)?
    ) {

        if let value = keyValues[key] {
            completion?(.success(value))
            return
        }

        keyValuesApi.requestKeyValue(
            key: key,
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion?(.failure(.other(error)))

                case .success(let document):
                    guard let value = document.data?.value
                        else {
                            completion?(.failure(.emptyData))
                            return
                    }

                    if let self = self {
                        var newKeyValues = self.keyValues
                        newKeyValues[key] = value
                        self.keyValuesBehaviorRelay.accept(newKeyValues)
                    }
                    completion?(.success(value))
                }
        })
    }

    enum LoadValuesResult {

        enum Error: Swift.Error {

            case loadValueError(LoadValueResult.Error)
        }

        case failure(Error)
        case success([Key: Value])
    }
    func loadValues(
        _ keys: [Key],
        completion: ((LoadValuesResult) -> Void)?
    ) {

        var keyValues: [Key: Value] = [:]
        var error: LoadValueResult.Error?

        let group: DispatchGroup = .init()
        group.notify(
            queue: .main,
            execute: {

                if let error = error {
                    completion?(.failure(.loadValueError(error)))
                } else {
                    completion?(.success(keyValues))
                }
        })

        group.enter()
        for key in keys {
            group.enter()
            loadValue(
                for: key,
                completion: { (result) in

                    switch result {

                    case .success(let value):
                        keyValues[key] = value

                    case .failure(let internalError):
                        error = internalError
                    }

                    group.leave()
            })
        }
        group.leave()
    }
}

// MARK: - Public methods

extension KeyValuesRepo {

    enum LoadValues {
        case success([Key: Value])
        case failure
    }
    func loadValues(
        for keys: [Key],
        completion: ((LoadValues) -> Void)?
    ) {

        loadValues(
            keys,
            completion: { (result) in

                switch result {

                case .failure:
                    completion?(.failure)

                case .success(let keyValues):
                    completion?(.success(keyValues))
                }
        })
    }
}
