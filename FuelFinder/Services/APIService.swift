import Foundation

final class APIService {

    static let shared = APIService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = ["User-Agent": "FuelFinderApp/1.0 iOS"]
        return URLSession(configuration: config)
    }()

    // MARK: - Free Geocoding via Nominatim
    func geocode(placeName: String) async -> (lat: Double, lon: Double)? {
        
        // ✅ Already coordinates — skip Nominatim call
        let parts = placeName.split(separator: ",")
        if parts.count == 2,
           let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
           let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) {
            print("✅ Already coords, skipping geocode:", lat, lon)
            return (lat: lat, lon: lon)
        }

        // Otherwise geocode as place name via Nominatim
        guard let encoded = placeName
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://nominatim.openstreetmap.org/search?q=\(encoded)&format=json&limit=1")
        else { return nil }

        do {
            let (data, _) = try await session.data(from: url)
            let results = try JSONDecoder().decode([NominatimResult].self, from: data)
            guard let first = results.first,
                  let lat = Double(first.lat ?? ""),
                  let lon = Double(first.lon ?? "") else { return nil }
            return (lat, lon)
        } catch {
            print("Geocode error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Free Real Petrol Pumps via Overpass API (OpenStreetMap)
    func fetchPetrolPumps(
        fromLat: Double, fromLon: Double,
        toLat: Double, toLon: Double
    ) async -> [OverpassElement] {
        
        // ✅ Increase buffer to ensure enough area is covered
        let minLat = min(fromLat, toLat) - 0.5
        let maxLat = max(fromLat, toLat) + 0.5
        let minLon = min(fromLon, toLon) - 0.5
        let maxLon = max(fromLon, toLon) + 0.5

        let query = """
        [out:json][timeout:30];
        (
          node["amenity"="fuel"](\(minLat),\(minLon),\(maxLat),\(maxLon));
          way["amenity"="fuel"](\(minLat),\(minLon),\(maxLat),\(maxLon));
        );
        out center;
        """

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(encoded)")
        else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            
            // ✅ Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("Overpass HTTP status:", httpResponse.statusCode)
                guard httpResponse.statusCode == 200 else {
                    print("❌ Overpass bad status:", httpResponse.statusCode)
                    return []
                }
            }
            
            // ✅ Print raw response to debug
            if let raw = String(data: data, encoding: .utf8) {
                print("Overpass raw (first 200):", raw.prefix(200))
            }
            
            let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
            print("✅ Overpass found:", overpassResponse.elements.count, "stations")
            return overpassResponse.elements
            
        } catch {
            print("❌ Overpass error:", error.localizedDescription)
            return []
        }
    }
}
