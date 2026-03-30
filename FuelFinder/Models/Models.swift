import Foundation
import CoreLocation

// MARK: - App Models
struct FuelStation: Identifiable, Equatable {
    let id: Int?
    let name: String?
    let brand: String?
    let lat: Double?
    let lng: Double?
    var price: Double?
    var distanceFromRoute: Double?
    var isBestOption: Bool?
    var address: String?
    var isOpen24Hours: Bool?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat ?? 0.0, longitude: lng ?? 0.0)
    }
}

struct RouteInfo {
    let fromName: String?
    let toName: String?
    let fromLat: Double?
    let fromLng: Double?
    let toLat: Double?
    let toLng: Double?
    let totalDistanceKm: Double?
}

// MARK: - Nominatim API Response
struct NominatimResult: Codable {
    let place_id: Int?
    let display_name: String?
    let lat: String?
    let lon: String?
}

// MARK: - Overpass API Response
struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let id: Int?
    let type: String?
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

struct OverpassCenter: Codable {
    let lat: Double?
    let lon: Double?
}
