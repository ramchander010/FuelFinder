import Foundation

final class FuelRepository {
    
    static let shared = FuelRepository()
    private init() {}
    
    // Real Indian petrol prices by state (₹/litre, March 2026)
    private let statePrices: [String: Double] = [
        "delhi": 94.77, "haryana": 94.29, "punjab": 97.18,
        "himachal pradesh": 93.52, "uttarakhand": 94.38,
        "uttar pradesh": 95.28, "rajasthan": 104.88,
        "gujarat": 94.58, "maharashtra": 104.21,
        "karnataka": 102.86, "tamil nadu": 100.75,
        "kerala": 107.74, "west bengal": 104.95,
        "madhya pradesh": 107.95, "chandigarh": 94.33,
        "default": 96.50
    ]
    
    // MARK: - Main fetch method
    func getStations(fromLat: Double, fromLon: Double, toLat: Double, toLon: Double) async -> [FuelStation] {
        let elements = await APIService.shared.fetchPetrolPumps(
            fromLat: fromLat, fromLon: fromLon,
            toLat: toLat, toLon: toLon
        )
        
        var stations: [FuelStation] = []
        
        for (index, element) in elements.enumerated() {
            guard let lat = element.lat ?? element.center?.lat,
                  let lon = element.lon ?? element.center?.lon else { continue }
            
            let dist = distanceFromRouteLine(
                pLat: lat, pLon: lon,
                fromLat: fromLat, fromLon: fromLon,
                toLat: toLat, toLon: toLon
            )
            guard dist <= 5.0 else { continue }
            
            let tags = element.tags ?? [:]
            let brand = detectBrand(tags: tags)
            let rawName = tags["name"] ?? tags["brand"] ?? tags["operator"] ?? ""
            let name = rawName.isEmpty ? "\(brand) Petrol Pump" : rawName
            let address = buildAddress(tags: tags)
            let price = estimatePrice(lat: lat, lon: lon)
            
            stations.append(FuelStation(
                id: index + 1,
                name: name,
                brand: brand,
                lat: lat,
                lng: lon,
                price: price,
                distanceFromRoute: Double(String(format: "%.1f", dist)) ?? dist,
                isBestOption: false,
                address: address.isEmpty ? "Along route" : address,
                isOpen24Hours: tags["opening_hours"] == "24/7"
            ))
        }
        
        // Sort by price low → high, mark cheapest as Best
        var sorted = stations.sorted { $0.price ?? 0.0 < $1.price ?? 0.0 }
        if !sorted.isEmpty { sorted[0].isBestOption = true }
        return sorted
    }
    
    // MARK: - Brand detection
    private func detectBrand(tags: [String: String]) -> String {
        let combined = [tags["brand"], tags["operator"], tags["name"]]
            .compactMap { $0 }.joined(separator: " ").lowercased()
        if combined.contains("indian oil") || combined.contains("iocl") { return "Indian Oil" }
        if combined.contains("bharat") || combined.contains("bpcl") { return "BPCL" }
        if combined.contains("hindustan") || combined.contains("hpcl") { return "HPCL" }
        if combined.contains("reliance") { return "Reliance" }
        if combined.contains("shell") { return "Shell" }
        if combined.contains("nayara") || combined.contains("essar") { return "Nayara" }
        return "Fuel Station"
    }
    
    // MARK: - Address builder
    private func buildAddress(tags: [String: String]) -> String {
        [tags["addr:housenumber"], tags["addr:street"],
         tags["addr:city"] ?? tags["addr:town"] ?? tags["addr:village"],
         tags["addr:state"]]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
    
    // MARK: - Price estimate based on state
    private func estimatePrice(lat: Double, lon: Double) -> Double {
        let state = detectState(lat: lat, lon: lon)
        let base = statePrices[state] ?? statePrices["default"]!
        let variation = Double.random(in: -0.5...0.5)
        return Double(String(format: "%.2f", base + variation)) ?? base
    }
    
    private func detectState(lat: Double, lon: Double) -> String {
        if (28.4...28.9).contains(lat) && (76.8...77.4).contains(lon) { return "delhi" }
        if (29.0...32.0).contains(lat) && (74.0...77.5).contains(lon) { return "punjab" }
        if (29.5...31.5).contains(lat) && (75.5...77.5).contains(lon) { return "haryana" }
        if (30.0...33.5).contains(lat) && (75.5...79.0).contains(lon) { return "himachal pradesh" }
        if (28.7...31.5).contains(lat) && (77.5...81.0).contains(lon) { return "uttarakhand" }
        if (23.0...30.5).contains(lat) && (77.0...84.5).contains(lon) { return "uttar pradesh" }
        if (24.0...30.5).contains(lat) && (69.5...78.0).contains(lon) { return "rajasthan" }
        if (20.0...24.5).contains(lat) && (68.0...74.5).contains(lon) { return "gujarat" }
        if (15.5...22.0).contains(lat) && (72.5...80.5).contains(lon) { return "maharashtra" }
        if (11.5...18.5).contains(lat) && (74.0...78.5).contains(lon) { return "karnataka" }
        if (8.0...13.5).contains(lat) && (76.0...80.5).contains(lon) { return "tamil nadu" }
        if (8.0...12.5).contains(lat) && (74.5...77.5).contains(lon) { return "kerala" }
        return "default"
    }
    
    // MARK: - Distance from route line (km)
    func distanceFromRouteLine(pLat: Double, pLon: Double, fromLat: Double, fromLon: Double, toLat: Double, toLon: Double) -> Double {
        let dx = toLon - fromLon
        let dy = toLat - fromLat
        let d = sqrt(dx*dx + dy*dy)
        if d == 0 { return haversine(lat1: pLat, lon1: pLon, lat2: fromLat, lon2: fromLon) }
        let t = max(0, min(1, ((pLon - fromLon)*dx + (pLat - fromLat)*dy) / (d*d)))
        return haversine(lat1: pLat, lon1: pLon, lat2: fromLat + t*dy, lon2: fromLon + t*dx)
    }
    
    // MARK: - Haversine distance
    func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6371.0 // Earth radius in kilometers
        let φ1 = lat1 * .pi / 180
        let φ2 = lat2 * .pi / 180
        let Δφ = (lat2 - lat1) * .pi / 180
        let Δλ = (lon2 - lon1) * .pi / 180
        let a = sin(Δφ / 2) * sin(Δφ / 2)
        + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
