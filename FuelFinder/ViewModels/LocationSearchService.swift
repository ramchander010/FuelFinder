//
//  LocationSearchService.swift
//  FuelFinder
//
//  Created by Apple on 23/03/26.
//
import MapKit
class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }
 
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
        }
    }
}
