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
    @Published var allCachedLocations: [LocationSearchResult] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let searchCompleter = MKLocalSearchCompleter()
    private let locationService = LocationService()
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    
    override init() {
        super.init()
        setupSearchCompleter()
        setupSearchDebounce()
        setupNetworkMonitoring()
        loadAllCachedLocations()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOfflineMode = !isConnected
                if !isConnected {
                    self?.showAllCachedLocationsWhenOffline()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadAllCachedLocations() {
        let cachedLocations = cacheManager.getCachedLocations()
        allCachedLocations = cachedLocations.map { location in
            LocationSearchResult(
                location: location,
                title: getLocationDisplayName(location),
                subtitle: location.address,
                isCached: true
            )
        }
    }
    
    private func showAllCachedLocationsWhenOffline() {
        if !networkMonitor.isConnected {
            locationSearchResults = allCachedLocations
            searchResults = []
            isOfflineMode = true
        }
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
            .debounce(for: .milliseconds(800), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.handleSearchTextChange(text)
            }
            .store(in: &cancellables)
    }
    
    private func handleSearchTextChange(_ text: String) {
        // Update offline mode based on network status
        isOfflineMode = !networkMonitor.isConnected
        
        // If offline, always show cached locations
        if !networkMonitor.isConnected {
            if text.isEmpty {
                locationSearchResults = allCachedLocations
            } else {
                searchCachedLocations(query: text)
            }
            searchResults = []
            isSearching = false
            return
        }
        
        // Online behavior
        if text.isEmpty {
            searchResults = []
            locationSearchResults = []
            isSearching = false
            return
        }
        
        if text.count > 2 {
            isSearching = true
            
            // Always search cached locations first for instant results
            searchCachedLocations(query: text)
            
            // Then try network search for map places
            searchCompleter.queryFragment = text
            
            // And search our live locations
            searchOurLocations(query: text)
        } else {
            searchResults = []
            locationSearchResults = []
            isSearching = false
        }
    }
    
    private func searchCachedLocations(query: String) {
        let filteredLocations = allCachedLocations.filter { result in
            let searchQuery = query.lowercased()
            
            let titleMatch = result.title.lowercased().contains(searchQuery)
            let addressMatch = result.subtitle.lowercased().contains(searchQuery)
            
            let detailsMatch = result.location.details.contains { detail in
                detail.propertyValue.lowercased().contains(searchQuery) ||
                detail.propertyName.lowercased().contains(searchQuery)
            }
            
            return titleMatch || addressMatch || detailsMatch
        }
        
        // Update UI immediately with cached results
        DispatchQueue.main.async { [weak self] in
            self?.locationSearchResults = Array(filteredLocations.prefix(20))
        }
    }
    
    private func searchOurLocations(query: String) {
        // Only search network if we're online
        guard networkMonitor.isConnected else {
            isOfflineMode = true
            isSearching = false
            return
        }
        
        locationService.getLocations { [weak self] locations, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
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
                    let networkResults = filteredLocations.prefix(10).map { location in
                        LocationSearchResult(
                            location: location,
                            title: self?.getLocationDisplayName(location) ?? location.address,
                            subtitle: location.address,
                            isCached: false
                        )
                    }
                    
                    // Combine network results with cached results, removing duplicates
                    let cachedResults = self?.locationSearchResults.filter { $0.isCached } ?? []
                    let uniqueCachedResults = cachedResults.filter { cachedResult in
                        !networkResults.contains { networkResult in
                            networkResult.location.id == cachedResult.location.id
                        }
                    }
                    
                    let combinedResults = Array(networkResults) + uniqueCachedResults
                    self?.locationSearchResults = Array(combinedResults.prefix(20))
                    self?.isOfflineMode = false
                } else {
                    // Network failed - keep cached results and mark as offline
                    self?.isOfflineMode = true
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
        // Only update if we're online
        guard networkMonitor.isConnected else { return }
        
        let mapResults = completer.results.prefix(5)
        self.searchResults = Array(mapResults)
        self.isSearching = false
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Map search failed with error: \(error.localizedDescription)")
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
        
        // Don't clear everything if we're offline
        if !networkMonitor.isConnected {
            locationSearchResults = allCachedLocations
            isOfflineMode = true
        } else {
            locationSearchResults = []
            isOfflineMode = false
        }
        
        searchResults = []
        isSearching = false
    }
    
    // MARK: - Offline Search Only
    
    func searchOfflineOnly(query: String) -> [LocationSearchResult] {
        if query.isEmpty {
            return allCachedLocations
        }
        
        return allCachedLocations.filter { result in
            let searchQuery = query.lowercased()
            
            let titleMatch = result.title.lowercased().contains(searchQuery)
            let addressMatch = result.subtitle.lowercased().contains(searchQuery)
            
            let detailsMatch = result.location.details.contains { detail in
                detail.propertyValue.lowercased().contains(searchQuery) ||
                detail.propertyName.lowercased().contains(searchQuery)
            }
            
            return titleMatch || addressMatch || detailsMatch
        }
    }
    
    // MARK: - Public Methods
    
    func refreshCachedLocations() {
        loadAllCachedLocations()
        
        // If we're offline or searching, update the results
        if !networkMonitor.isConnected || searchText.isEmpty {
            if searchText.isEmpty {
                locationSearchResults = allCachedLocations
            } else {
                searchCachedLocations(query: searchText)
            }
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
