// App-iOS/InteractiveMap/InteractiveMap/Views/Map/ExploreMapView.swift

import SwiftUI
import MapKit

struct ExploreMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var searchManager = SearchManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedTab = 0
    @State private var showSearchResults = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingLocationDetail = false
    @State private var locationToShow: Location?
    @State private var selectedLocation: Location?
    @State private var navigationPath = NavigationPath()
    @State private var showingOfflineSearch = false
    @State private var searchTextFocused = false
    @State private var keepSearchResultsVisible = false
    @State private var displayedLocations: [Location] = []
    
    private let kyivCoordinates = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    VStack {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Search locations or shelters", text: $searchManager.searchText)
                                    .foregroundColor(.black)
                                    .onTapGesture {
                                        searchTextFocused = true
                                        showSearchResults = true
                                        keepSearchResultsVisible = true
                                    }
                                    .onSubmit {
                                        searchTextFocused = false
                                    }
                                
                                if !searchManager.searchText.isEmpty {
                                    Button(action: {
                                        searchManager.clearSearch()
                                        searchTextFocused = false
                                        showSearchResults = false
                                        keepSearchResultsVisible = false
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                if searchManager.isSearching {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.2), radius: 5)
                            .overlay(
                                searchResultsOverlay,
                                alignment: .top
                            )
                            
                            // Search results toggle button - moved from navigation bar
                            if !searchManager.searchText.isEmpty || !networkMonitor.isConnected {
                                Button(action: {
                                    showSearchResults.toggle()
                                    keepSearchResultsVisible = showSearchResults
                                }) {
                                    Image(systemName: showSearchResults ? "list.bullet.circle.fill" : "list.bullet.circle")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .padding(10)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                                }
                                .padding(.trailing)
                            } else {
                                Button(action: {
                                    searchTextFocused = true
                                    showSearchResults = true
                                    keepSearchResultsVisible = true
                                }) {
                                    Image(systemName: "list.bullet.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .padding(10)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                                }
                                .padding(.trailing)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .zIndex(2)
                    
                    if UIDevice.current.userInterfaceIdiom == .pad && geometry.size.width > 768 {
                        HStack(spacing: 0) {
                            mapView
                                .frame(width: geometry.size.width * 0.6)
                            
                            locationListView
                                .frame(width: geometry.size.width * 0.4)
                        }
                    } else {
                        TabView(selection: $selectedTab) {
                            mapView
                                .tag(0)
                            
                            locationListView
                                .tag(1)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        
                        HStack(spacing: 20) {
                            TabButton(isSelected: selectedTab == 0, title: "Map", systemImage: "map") {
                                selectedTab = 0
                            }
                            
                            TabButton(isSelected: selectedTab == 1, title: "List", systemImage: "list.bullet") {
                                selectedTab = 1
                            }
                            
                            Button(action: {
                                findNearbyLocations()
                            }) {
                                Text("Find Nearby")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: -2)
                    }
                }
                .onTapGesture {
                    // Only dismiss search results if user taps outside and search is not focused
                    if !searchTextFocused && !keepSearchResultsVisible {
                        showSearchResults = false
                    }
                    selectedLocation = nil
                }
                
                if viewModel.isLoading {
                    LoadingView()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    ErrorBannerView(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button(action: {
                    showingOfflineSearch = true
                }) {
                    HStack {
                        // FIXED: Changed icon and color based on connection status
                        Image(systemName: networkMonitor.isConnected ? "wifi" : "externaldrive")
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        // FIXED: Changed text based on connection status
                        Text(networkMonitor.isConnected ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                    }
                }
            )
            .sheet(isPresented: $showingOfflineSearch) {
                OfflineSearchView()
            }
            .navigationDestination(for: Location.self) { location in
                LocationDetailView(location: location, isAuthenticated: TokenManager.shared.isAuthenticated)
            }
            .onChange(of: searchManager.searchText) { newValue in
                if !newValue.isEmpty || !networkMonitor.isConnected {
                    showSearchResults = true
                    keepSearchResultsVisible = true
                } else {
                    keepSearchResultsVisible = false
                }
            }
            .onChange(of: searchManager.isOfflineMode) { isOffline in
                if isOffline {
                    showSearchResults = true
                    keepSearchResultsVisible = true
                }
            }
            .onChange(of: networkMonitor.isConnected) { isConnected in
                if !isConnected {
                    // FIXED: Load all cached locations when going offline
                    loadAllCachedLocations()
                    searchManager.refreshCachedLocations()
                    showSearchResults = true
                    keepSearchResultsVisible = true
                } else {
                    // When coming back online, refresh nearby locations
                    findNearbyLocations()
                }
            }
            .onChange(of: navigationPath) { path in
                // When returning from location detail, restore search results if there was an active search
                if path.isEmpty && (!searchManager.searchText.isEmpty || !networkMonitor.isConnected) {
                    showSearchResults = keepSearchResultsVisible
                }
            }
            .onChange(of: viewModel.locations) { newLocations in
                // Persist displayed locations - don't clear them when navigating
                if !newLocations.isEmpty {
                    displayedLocations = newLocations
                }
            }
            .onAppear {
                cameraPosition = .region(locationManager.region)
                searchManager.refreshCachedLocations()
                
                // FIXED: Check connection status on appear
                if networkMonitor.isConnected {
                    findNearbyLocations()
                } else {
                    loadAllCachedLocations()
                }
                
                // Show cached locations if offline
                if !networkMonitor.isConnected {
                    showSearchResults = true
                    keepSearchResultsVisible = true
                }
            }
        }
    }
    
    private func findNearbyLocations() {
        let coordinates: CLLocationCoordinate2D
        
        // Try to use user's location first, then fall back to Kyiv
        if let location = locationManager.location {
            coordinates = location.coordinate
            // Update map to user's location
            locationManager.updateRegion(location: location)
            cameraPosition = .region(locationManager.region)
        } else {
            coordinates = kyivCoordinates
            // Update map to Kyiv
            let kyivRegion = MKCoordinateRegion(
                center: kyivCoordinates,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            locationManager.region = kyivRegion
            cameraPosition = .region(kyivRegion)
        }
        
        // Load nearby locations
        viewModel.loadNearbyLocations(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )
    }
    
    // FIXED: New function to load all cached locations for offline mode
    private func loadAllCachedLocations() {
        let cachedLocations = CacheManager.shared.getCachedLocations()
        displayedLocations = cachedLocations
        viewModel.locations = cachedLocations
        
        print("Loaded \(cachedLocations.count) cached locations for offline mode")
    }
    
    private var searchResultsOverlay: some View {
        VStack {
            let hasResults = !searchManager.locationSearchResults.isEmpty || !searchManager.searchResults.isEmpty
            let shouldShow = showSearchResults && (hasResults || searchManager.isSearching || !networkMonitor.isConnected)
            
            if shouldShow {
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        if searchManager.isSearching {
                            HStack {
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        } else if hasResults {
                            Text("Search Results")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showSearchResults = false
                            keepSearchResultsVisible = false
                            searchTextFocused = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    
                    // Offline indicator
                    if !networkMonitor.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("Offline - Showing cached locations only")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                    }
                    
                    if !searchManager.locationSearchResults.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Shelters")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                if searchManager.isOfflineMode {
                                    Image(systemName: "wifi.slash")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                    Text("Cached")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                
                                Spacer()
                                
                                Text("\(searchManager.locationSearchResults.count)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(searchManager.locationSearchResults) { result in
                                        Button(action: {
                                            searchManager.selectLocationResult(result) { coordinate in
                                                if let coordinate = coordinate {
                                                    // Update map position
                                                    let newRegion = MKCoordinateRegion(
                                                        center: coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                    )
                                                    locationManager.region = newRegion
                                                    cameraPosition = .region(newRegion)
                                                    
                                                    // Load nearby locations but keep the selected one visible
                                                    if networkMonitor.isConnected {
                                                        viewModel.loadNearbyLocations(
                                                            latitude: coordinate.latitude,
                                                            longitude: coordinate.longitude
                                                        )
                                                    }
                                                    
                                                    // Navigate to location detail without dismissing search
                                                    navigationPath.append(result.location)
                                                    searchTextFocused = false
                                                    // DON'T dismiss search results - keep them visible
                                                }
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: result.isCached ? "externaldrive" : "building.2.fill")
                                                    .foregroundColor(result.isCached ? .red : .blue)
                                                    .frame(width: 20)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    HStack {
                                                        Text(result.title)
                                                            .font(.body)
                                                            .foregroundColor(.black)
                                                            .multilineTextAlignment(.leading)
                                                        
                                                        if result.isCached {
                                                            Image(systemName: "wifi.slash")
                                                                .font(.caption2)
                                                                .foregroundColor(.red)
                                                        }
                                                    }
                                                    Text(result.subtitle)
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                        .multilineTextAlignment(.leading)
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .background(result.isCached ? Color.red.opacity(0.05) : Color.blue.opacity(0.05))
                                        
                                        if result != searchManager.locationSearchResults.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 300)
                        }
                    }
                    
                    if !searchManager.searchResults.isEmpty && networkMonitor.isConnected {
                        if !searchManager.locationSearchResults.isEmpty {
                            Divider()
                                .background(Color.gray)
                                .padding(.vertical, 4)
                        }
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Places")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            
                            ForEach(searchManager.searchResults, id: \.self) { result in
                                Button(action: {
                                    searchManager.searchLocation(for: result) { coordinate in
                                        if let coordinate = coordinate {
                                            searchManager.searchText = result.title
                                            
                                            let newRegion = MKCoordinateRegion(
                                                center: coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            )
                                            locationManager.region = newRegion
                                            cameraPosition = .region(newRegion)
                                            
                                            if networkMonitor.isConnected {
                                                viewModel.loadNearbyLocations(
                                                    latitude: coordinate.latitude,
                                                    longitude: coordinate.longitude
                                                )
                                            }
                                            
                                            searchTextFocused = false
                                            // DON'T dismiss search results - this is a map location search
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.green)
                                            .frame(width: 20)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.title)
                                                .font(.body)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                if result != searchManager.searchResults.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5)
                .padding(.horizontal)
                .frame(maxHeight: 500)
            }
        }
        .offset(y: 50)
        .zIndex(1)
    }
    
    private func showLocationDetail(for location: Location) {
        print("Showing location detail for: \(location.id) - \(location.address)")
        navigationPath.append(location)
        // Don't dismiss search results when navigating to details
    }
    
    private var mapView: some View {
        ZStack {
            Map(position: $cameraPosition, selection: $selectedLocation) {
                UserAnnotation()
                
                // Use displayedLocations to persist pins
                ForEach(displayedLocations) { location in
                    Annotation(
                        location.address,
                        coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        anchor: .bottom
                    ) {
                        LocationMarkerView(location: location)
                            .onTapGesture {
                                print("Map pin tapped for location: \(location.id) - \(location.address)")
                                showLocationDetail(for: location)
                            }
                            .onAppear {
                                // Cache location when marker appears on map
                                CacheManager.shared.cacheLocation(location)
                            }
                    }
                    .tag(location)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: UIDevice.current.userInterfaceIdiom == .pad ? [] : .bottom)
            .onChange(of: selectedLocation) { newLocation in
                if let location = newLocation {
                    showLocationDetail(for: location)
                }
            }
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        if networkMonitor.isConnected {
                            findNearbyLocations()
                        } else {
                            loadAllCachedLocations()
                        }
                    }) {
                        Text(networkMonitor.isConnected ? "Find Nearby" : "Show All Cached")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(networkMonitor.isConnected ? Color.blue : Color.red)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.2), radius: 5)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private var locationListView: some View {
        VStack {
            if displayedLocations.isEmpty && !viewModel.isLoading {
                VStack(spacing: 16) {
                    Text(networkMonitor.isConnected ? "No locations found" : "No cached locations available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    
                    Text(networkMonitor.isConnected ?
                         "Try searching for a different area or use 'Find Nearby' to discover locations around you." :
                         "Visit locations while online to cache them for offline viewing.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            } else {
                VStack {
                    if !networkMonitor.isConnected {
                        Text("Showing all \(displayedLocations.count) cached locations")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    } else if displayedLocations.count == 10 {
                        Text("Showing top 10 locations")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    
                    List {
                        ForEach(displayedLocations) { location in
                            LocationRow(
                                location: location,
                                isSelected: selectedLocation?.id == location.id
                            )
                            .onTapGesture {
                                print("List row tapped for location: \(location.id) - \(location.address)")
                                showLocationDetail(for: location)
                            }
                            .listRowBackground(
                                selectedLocation?.id == location.id ?
                                Color.blue.opacity(0.1) : Color.clear
                            )
                            .onAppear {
                                // Cache location when it appears on screen
                                CacheManager.shared.cacheLocationAsViewed(location)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
    }
}

struct TabButton: View {
    let isSelected: Bool
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

struct LocationRow: View {
    let location: Location
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            LocationMarkerView(location: location)
                .scaleEffect(0.8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getLocationDisplayName(location))
                    .font(.headline)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let district = getLocationDistrict(location) {
                    Text(district)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func getLocationDisplayName(_ location: Location) -> String {
        if let typeDetail = location.details.first(where: { $0.propertyName.lowercased() == "sheltertype" || $0.propertyName.lowercased() == "type" }) {
            return typeDetail.propertyValue
        }
        return location.address
    }
    
    private func getLocationDistrict(_ location: Location) -> String? {
        return location.details.first(where: { $0.propertyName.lowercased() == "district" })?.propertyValue
    }
}
