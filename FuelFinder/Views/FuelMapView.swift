import SwiftUI
import MapKit

struct FuelMapView: UIViewRepresentable {
    @ObservedObject var vm: MainViewModel

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true
        map.showsScale = true
        map.userTrackingMode = .followWithHeading
        map.region = vm.mapRegion
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        
        // ✅ Remove overlays only when NOT navigating
        if !context.coordinator.isNavigating {
            map.removeOverlays(map.overlays)
        }
        
        // ✅ Trigger navigation from list
        if let selected = vm.selectedStation {
            context.coordinator.startNavigation(
                to: selected.coordinate,
                mapView: map
            )
            
            DispatchQueue.main.async {
                vm.selectedStation = nil
            }
        }
        
        // ✅ Remove old annotations
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        
        guard vm.isSuccess, let route = vm.route else { return }
        
        let sourceCoord = CLLocationCoordinate2D(
            latitude: route.fromLat ?? 0.0,
            longitude: route.fromLng ?? 0.0
        )
        
        let destCoord = CLLocationCoordinate2D(
            latitude: route.toLat ?? 0.0,
            longitude: route.toLng ?? 0.0
        )
        
        // ✅ Start pin
        map.addAnnotation(FuelPin(
            coordinate: sourceCoord,
            title: "🟢 Start: \(route.fromName)",
            subtitle: "Departure point",
            type: .start
        ))
        
        // ✅ End pin
        map.addAnnotation(FuelPin(
            coordinate: destCoord,
            title: "🔴 Destination: \(route.toName ?? "")",
            subtitle: "Arrival point",
            type: .end
        ))
        
        // ✅ Pump pins
        for s in vm.stations {
            map.addAnnotation(FuelPin(
                coordinate: s.coordinate,
                title: s.name ?? "",
                subtitle: s.isBestOption ?? false
                ? "⭐ BEST OPTION — ₹\(String(format: "%.2f", s.price ?? 0.0))/L"
                : "₹\(String(format: "%.2f", s.price ?? 0.0))/L • \(s.distanceFromRoute ?? 0.0) km",
                type: s.isBestOption ?? false ? .best : .pump
            ))
        }
        
        
        if !context.coordinator.isNavigating {
            
            let startPoint = MKMapPoint(sourceCoord)
            let endPoint   = MKMapPoint(destCoord)
            
            let rect = MKMapRect(
                x: min(startPoint.x, endPoint.x),
                y: min(startPoint.y, endPoint.y),
                width: abs(startPoint.x - endPoint.x),
                height: abs(startPoint.y - endPoint.y)
            )
            
            map.setVisibleMapRect(
                rect,
                edgePadding: UIEdgeInsets(top: 120, left: 60, bottom: 200, right: 60),
                animated: true
            )
        }
        
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {

        var isNavigating = false
        var selectedDestination: CLLocationCoordinate2D?
        var lastUpdateTime: TimeInterval = 0

        // ✅ Tap on pin
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let pin = view.annotation as? FuelPin else { return }

            if pin.type == .pump || pin.type == .best {
                startNavigation(to: pin.coordinate, mapView: mapView)
            }
        }

        // ✅ Draw route line
        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer() }

            let renderer = MKPolylineRenderer(polyline: poly)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 6
            return renderer
        }

        // ✅ Main navigation logic (ONLY PLACE ROUTE IS CREATED)
        func startNavigation(to coordinate: CLLocationCoordinate2D, mapView: MKMapView) {

            // ❌ Prevent duplicate navigation
            if let current = selectedDestination,
               current.latitude == coordinate.latitude &&
               current.longitude == coordinate.longitude {
                return
            }

            isNavigating = true
            selectedDestination = coordinate

            guard let userLocation = mapView.userLocation.location else { return }

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            request.transportType = .automobile

            MKDirections(request: request).calculate { response, _ in
                guard let route = response?.routes.first else { return }

                DispatchQueue.main.async {

                    // ✅ Remove old route
                    mapView.removeOverlays(mapView.overlays)

                    // ✅ Add new route
                    mapView.addOverlay(route.polyline)

                    // ✅ Follow user
                    mapView.setUserTrackingMode(.followWithHeading, animated: true)

                    // ✅ Zoom properly
                    mapView.setVisibleMapRect(
                        route.polyline.boundingMapRect,
                        edgePadding: UIEdgeInsets(top: 120, left: 40, bottom: 200, right: 40),
                        animated: true
                    )
                }

                // ✅ Send ETA / distance
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .navigationUpdated,
                        object: route
                    )
                }
            }
        }

        // ✅ Live route update (every few sec)
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {

            guard isNavigating,
                  let destination = selectedDestination else { return }

            let now = Date().timeIntervalSince1970
            if now - lastUpdateTime < 8 { return }

            lastUpdateTime = now

            startNavigation(to: destination, mapView: mapView)
        }

        // ✅ Pin UI
        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pin = annotation as? FuelPin else { return nil }

            let id = "FuelPin"
            let view = (map.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)

            view.annotation = annotation
            view.canShowCallout = true

            switch pin.type {
            case .start:
                view.markerTintColor = .systemGreen
                view.glyphText = "🟢"
            case .end:
                view.markerTintColor = .systemRed
                view.glyphText = "🔴"
            case .best:
                view.markerTintColor = .systemGreen
                view.glyphText = "⭐"
            case .pump:
                view.markerTintColor = .orange
                view.glyphText = "⛽"
            }

            return view
        }
    }
}


final class FuelPin: NSObject, MKAnnotation {
        enum PinType {
        case start
        case end
        case pump
        case best
    }
        var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    let type: PinType

    init(coordinate: CLLocationCoordinate2D,
         title: String,
         subtitle: String,
         type: PinType) {
        
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
}
