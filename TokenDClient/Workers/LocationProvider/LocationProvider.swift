import CoreLocation

final class LocationProvider: NSObject {
    
    public typealias OnRequestLocation = (Result<Location, Swift.Error>) -> Void
    
    // MARK: Private properties
    
    private let locationManager: CLLocationManager = .init()
    
    private var requestLocation: OnRequestLocation?
    private var currentLocation: Location?
    private var error: Error?
    
    override init() {
        super.init()
        
        setup()
    }
    
    deinit {
        locationManager.stopUpdatingLocation()
    }
    
    func setup() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationProvider: CLLocationManagerDelegate {

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        
        guard let userLocation: CLLocation = locations.first
        else {
            return
        }
        
        let latitude: Double = userLocation.coordinate.latitude
        let longitude: Double = userLocation.coordinate.longitude
        
        let location: Location = .init(
            latitude: latitude,
            longitude: longitude
        )
        self.currentLocation = location
        self.error = nil
        
        self.requestLocation?(.success(location))
        self.requestLocation = nil
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        
        self.currentLocation = nil
        self.error = error
        
        self.requestLocation?(.failure(error))
        self.requestLocation = nil
    }
}

// MARK: - LocationWorkerProtocol

extension LocationProvider: LocationProviderProtocol {
    
    func requestLocation(
        completion: @escaping OnRequestLocation
    ) {
        
        if let error = self.error {
            completion(.failure(error))
        } else if let location = self.currentLocation {
            completion(.success(location))
        } else {
            self.requestLocation = completion
        }
    }
}
