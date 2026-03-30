//
//  FilterViewModel.swift
//  FuelFinder
//
//  Created by Apple on 23/03/26.
//
import MapKit
import Combine
class LocationSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []
    private let searchService = LocationSearchService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bindSearch()
    }
    
    private func bindSearch() {
        searchService.$suggestions
            .assign(to: &$suggestions)
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.searchService.updateQuery(text)
            }
            .store(in: &cancellables)
    }
}
