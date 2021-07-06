import Foundation

public protocol LocationProviderProtocol {
    typealias OnRequestLocation = (Result<Location, Swift.Error>) -> Void
    
    func requestLocation(completion: @escaping OnRequestLocation)
}

public struct Location {
    let latitude: Double
    let longitude: Double
}
