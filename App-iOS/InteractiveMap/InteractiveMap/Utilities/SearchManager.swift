// App-iOS/InteractiveMap/InteractiveMap/Utilities/SearchManager.swift

import Foundation
import MapKit
import Combine

class SearchManager: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchText = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    @Published var locationSearchResults: [LocationSearchResult] = []
    @Published var isOfflineMode = false
    
    private var cancellables = Set<AnyCancellable>()
    private let searchCompleter = MKLocalSearchCompleter()
    private let locationService = LocationService()
    private let cacheManager = CacheManager.shared
    
    override init() {
        super.init()
        setupSearchCompleter()
        setupSearchDebounce()
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.filterType = .locationsOnly
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.handleSearchTextChange(text)
            }
            .store(in: &cancellables)
    }
    
    private func handleSearchTextChange(_ text: String) {
        if text.isEmpty {
            searchResults = []
            locationSearchResults = []
            isSearching = false
            isOfflineMode = false
            return
        }
        
        if text.count > 2 {
            isSearching = true
            isOfflineMode = false
            
            // Always search cached locations first for instant results
            searchCachedLocations(query: text)
            
            // Then try network search for map places
            searchCompleter.queryFragment = text
            
            // And search our live locations if online
            searchOurLocations(query: text)
        } else {
            searchResults = []
            locationSearchResults = []
            isSearching = false
            isOfflineMode = false
        }
    }
    
    private func searchCachedLocations(query: String) {
        let cachedLocations = cacheManager.getCachedLocations()
        let filteredLocations = cachedLocations.filter { location in
            let searchQuery = query.lowercased()
            
            let addressMatch = location.address.lowercased().contains(searchQuery)
            
            let detailsMatch = location.details.contains { detail in
                detail.propertyValue.lowercased().contains(searchQuery) ||
                detail.propertyName.lowercased().contains(searchQuery)
            }
            
            return addressMatch || detailsMatch
        }
        
        // Update UI immediately with cached results
        DispatchQueue.main.async { [weak self] in
            self?.locationSearchResults = filteredLocations.prefix(5).map { location in
                LocationSearchResult(
                    location: location,
                    title: self?.getLocationDisplayName(location) ?? location.address,
                    subtitle: location.address,
                    isCached: true
                )
            }
            
            // If we only have cached results, we're in offline mode for location search
            if !filteredLocations.isEmpty {
                self?.isOfflineMode = true
            }
        }
    }
    
    private func searchOurLocations(query: String) {
        locationService.getLocations { [weak self] locations, error in
            DispatchQueue.main.async {
                if let locations = locations {
                    let filteredLocations = locations.filter { location in
                        let searchQuery = query.lowercased()
                        
                        let addressMatch = location.address.lowercased().contains(searchQuery)
                        
                        let detailsMatch = location.details.contains { detail in
                            detail.propertyValue.lowercased().contains(searchQuery) ||
                            detail.propertyName.lowercased().contains(searchQuery)
                        }
                        
                        return addressMatch || detailsMatch
                    }
                    
                    // Merge with cached results, prioritizing fresh network results
                    let networkResults = filteredLocations.prefix(5).map { location in
                        LocationSearchResult(
                            location: location,
                            title: self?.getLocationDisplayName(location) ?? location.address,
                            subtitle: location.address,
                            isCached: false
                        )
                    }
                    
                    // If we got network results, replace cached results
                    if !networkResults.isEmpty {
                        self?.locationSearchResults = Array(networkResults)
                        self?.isOfflineMode = false
                    }
                    // If network results are empty but we had cached results, keep cached
                    else if self?.locationSearchResults.isEmpty ?? true {
                        self?.locationSearchResults = []
                        self?.isOfflineMode = false
                    }
                } else {
                    // Network failed - keep cached results if any, mark as offline
                    if !(self?.locationSearchResults.isEmpty ?? true) {
                        self?.isOfflineMode = true
                    }
                }
            }
        }
    }
    
    private func getLocationDisplayName(_ location: Location) -> String {
        if let typeDetail = location.details.first(where: {
            $0.propertyName.lowercased() == "sheltertype" ||
            $0.propertyName.lowercased() == "type"
        }) {
            return typeDetail.propertyValue
        }
        return location.address
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let mapResults = completer.results.prefix(5)
        self.searchResults = Array(mapResults)
        self.isSearching = false
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Map search failed with error: \(error.localizedDescription)")
        // Don't clear location search results - those might be from cache
        self.searchResults = []
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
    
    func selectLocationResult(_ result: LocationSearchResult, completionHandler: @escaping (CLLocationCoordinate2D?) -> Void) {
        let coordinate = CLLocationCoordinate2D(
            latitude: result.location.latitude,
            longitude: result.location.longitude
        )
        completionHandler(coordinate)
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        locationSearchResults = []
        isSearching = false
        isOfflineMode = false
    }
    
    // MARK: - Offline Search Only
    
    func searchOfflineOnly(query: String) -> [LocationSearchResult] {
        let cachedLocations = cacheManager.getCachedLocations()
        let filteredLocations = cachedLocations.filter { location in
            let searchQuery = query.lowercased()
            
            let addressMatch = location.address.lowercased().contains(searchQuery)
            
            let detailsMatch = location.details.contains { detail in
                detail.propertyValue.lowercased().contains(searchQuery) ||
                detail.propertyName.lowercased().contains(searchQuery)
            }
            
            return addressMatch || detailsMatch
        }
        
        return filteredLocations.map { location in
            LocationSearchResult(
                location: location,
                title: getLocationDisplayName(location),
                subtitle: location.address,
                isCached: true
            )
        }
    }
}

struct LocationSearchResult: Identifiable, Hashable {
    let id = UUID()
    let location: Location
    let title: String
    let subtitle: String
    let isCached: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}
