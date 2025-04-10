// App-iOS/InteractiveMap/InteractiveMap/Utilities/SearchManager.swift

import Foundation
import MapKit
import Combine

class SearchManager: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchText = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var isSearching = false
    
    private var cancellables = Set<AnyCancellable>()
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.region = MKCoordinateRegion(.world)
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                if !text.isEmpty && text.count > 2 {
                    self?.searchCompleter.queryFragment = text
                    self?.isSearching = true
                } else {
                    self?.searchResults = []
                    self?.isSearching = false
                }
            }
            .store(in: &cancellables)
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
        self.isSearching = false
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search failed with error: \(error.localizedDescription)")
        self.isSearching = false
    }
    
    func searchLocation(for completion: MKLocalSearchCompletion, completionHandler: @escaping (CLLocationCoordinate2D?) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = completion.title + ", " + completion.subtitle
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                completionHandler(nil)
                return
            }
            
            let coordinate = item.placemark.coordinate
            completionHandler(coordinate)
        }
    }
}
