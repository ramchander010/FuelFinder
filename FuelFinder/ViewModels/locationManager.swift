


import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var isGeocoding = false
    
    @Published var resolvedAddress: String = ""
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?


    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        
        // Request permission
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        print("Requesting location...")
        manager.requestLocation()
    }
    

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location access granted")
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Permission not determined")
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
 
        let locationAge = -location.timestamp.timeIntervalSinceNow
        if locationAge > 5 {
            print("Ignoring old location")
            return
        }
        print("Fresh location:", location.coordinate.latitude, location.coordinate.longitude)
         DispatchQueue.main.async {
            self.userLocation = location
        }
        if !isGeocoding {
            reverseGeocode(location)
        }
    }

    // MARK: - Error Handling
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
    
    // MARK: - Reverse Geocoding
    private func reverseGeocode(_ location: CLLocation) {
        isGeocoding = true
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            self.isGeocoding = false
            
            if let error = error {
                print("Reverse geocode failed:", error.localizedDescription)
                return
            }
            
            guard let place = placemarks?.first else {
                print("No placemark found")
                return
            }
            
            let parts = [
                place.locality,
                place.administrativeArea,
                place.country
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

            let address = parts.joined(separator: ", ")
            
            print("Resolved address:", address)

            DispatchQueue.main.async {
                self.resolvedAddress = address
            }
        }
    }
}
