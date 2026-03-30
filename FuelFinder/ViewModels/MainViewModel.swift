import Foundation
import SwiftUI
import MapKit

enum AppState {
    case idle
    case loading(String)
    case success
    case error(String)
}
  @MainActor
final class MainViewModel: ObservableObject {
    @Published var selectedStation: FuelStation? = nil
        @Published var navigationRoute: MKRoute? = nil
    @Published var navigatingToStation: FuelStation? = nil
   @Published var appState: AppState = .idle
    @Published var stations: [FuelStation] = []
    @Published var route: RouteInfo? = nil
    @Published var showStationList = false
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
    )
    @Published var fromCoord: CLLocationCoordinate2D? = nil
    @Published var toCoord: CLLocationCoordinate2D? = nil
    private let repo = FuelRepository.shared

    // MARK: - Search
    func search(from: String, to: String, fromDisplayName: String? = nil) {
        let from = from.trimmingCharacters(in: .whitespaces)
        let to   = to.trimmingCharacters(in: .whitespaces)
        guard !from.isEmpty, !to.isEmpty else {
            appState = .error("Please enter both start and destination")
            return
        }
        Task {
            appState = .loading("Finding \(from)...")
            guard let fc = await APIService.shared.geocode(placeName: from) else {
                appState = .error("Could not find: \(from)\nTry full city name e.g. Delhi, India")
                return
            }
                        appState = .loading("Finding \(to)...")
            guard let tc = await APIService.shared.geocode(placeName: to) else {
                appState = .error("Could not find: \(to)\nTry full city name e.g. Chandigarh, India")
                return
            }
                        appState = .loading("Fetching petrol pumps from OpenStreetMap...")
            let fetched = await repo.getStations(
                fromLat: fc.lat, fromLon: fc.lon,
                toLat: tc.lat, toLon: tc.lon
            )
            let dist = repo.haversine(lat1: fc.lat, lon1: fc.lon, lat2: tc.lat, lon2: tc.lon)
                    self.fromCoord = CLLocationCoordinate2D(latitude: fc.lat, longitude: fc.lon)
            self.toCoord   = CLLocationCoordinate2D(latitude: tc.lat, longitude: tc.lon)
            self.route = RouteInfo(
                fromName: from, toName: to,
                fromLat: fc.lat, fromLng: fc.lon,
                toLat: tc.lat, toLng: tc.lon,
                totalDistanceKm: dist
            )
            self.stations = fetched
            if fetched.isEmpty {
                appState = .error("No petrol pumps found on this route.\nTry a longer route or different cities.")
            } else {
                appState = .success
                zoomMapToRoute(fc: fc, tc: tc)
            }
            self.route = RouteInfo(
                    fromName: fromDisplayName ?? from,
                    toName: to,
                    fromLat: fc.lat, fromLng: fc.lon,
                    toLat: tc.lat, toLng: tc.lon,
                    totalDistanceKm: dist
                )
       }
    }

    
    func navigateToStation(_ station: FuelStation) {
        selectedStation = station
    }
    
    func navigateToStation(_ station: FuelStation, userLocation: CLLocationCoordinate2D?) {
        guard let userCoord = userLocation else {
            print("❌ No user location")
            return
        }
        print("✅ Starting navigation to:", station.name)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: station.coordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self, let route = response?.routes.first else {
                print("❌ Route error:", error?.localizedDescription ?? "unknown")
                return
            }
            print("✅ Route calculated:", route.distance / 1000, "km")
            DispatchQueue.main.async {
                self.navigationRoute = route
                self.navigatingToStation = station
                self.showStationList = false
            }
        }
    }

    func stopNavigation() {
        navigationRoute = nil
        navigatingToStation = nil
    }
  private func zoomMapToRoute(fc: (lat: Double, lon: Double), tc: (lat: Double, lon: Double)) {
        let midLat = (fc.lat + tc.lat) / 2
        let midLon = (fc.lon + tc.lon) / 2
        let latDelta = max(abs(fc.lat - tc.lat) * 1.6, 0.5)
        let lonDelta = max(abs(fc.lon - tc.lon) * 1.6, 0.5)
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    // MARK: - Fly to station
    func flyToStation(_ station: FuelStation) {
        mapRegion = MKCoordinateRegion(
            center: station.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
        showStationList = false
    }

    // MARK: - Reset
    func reset() {
        appState = .idle
        stations = []
        route = nil
        fromCoord = nil
        toCoord = nil
        showStationList = false
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        )
    }

    var isLoading: Bool { if case .loading = appState { return true }; return false }
    var loadingMessage: String { if case .loading(let m) = appState { return m }; return "" }
    var errorMessage: String? { if case .error(let m) = appState { return m }; return nil }
    var isSuccess: Bool { if case .success = appState { return true }; return false }
}


