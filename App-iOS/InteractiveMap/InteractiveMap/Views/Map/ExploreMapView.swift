// App-iOS/InteractiveMap/InteractiveMap/Views/Map/ExploreMapView.swift

import SwiftUI
import MapKit

struct ExploreMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var searchManager = SearchManager()
    @State private var selectedTab = 0
    @State private var showSearchResults = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingLocationDetail = false
    @State private var locationToShow: Location?
    @State private var selectedLocation: Location?
    @State private var navigationPath = NavigationPath()
    @State private var showingOfflineSearch = false
    
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
                                        if !searchManager.searchText.isEmpty {
                                            showSearchResults = true
                                        }
                                    }
                                
                                if !searchManager.searchText.isEmpty {
                                    Button(action: {
                                        searchManager.clearSearch()
                                        showSearchResults = false
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
                            
                            Button(action: {
                                if let location = locationManager.location {
                                    locationManager.updateRegion(location: location)
                                    cameraPosition = .region(locationManager.region)
                                } else {
                                    let kyivRegion = MKCoordinateRegion(
                                        center: kyivCoordinates,
                                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                    )
                                    locationManager.region = kyivRegion
                                    cameraPosition = .region(kyivRegion)
                                }
                            }) {
                                Image(systemName: "location.circle.fill")
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
                                let coordinates: CLLocationCoordinate2D
                                
                                if let location = locationManager.location {
                                    coordinates = location.coordinate
                                } else {
                                    coordinates = kyivCoordinates
                                }
                                
                                viewModel.loadNearbyLocations(
                                    latitude: coordinates.latitude,
                                    longitude: coordinates.longitude
                                )
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
                    showSearchResults = false
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
                    Image(systemName: "externaldrive")
                        .foregroundColor(.red)
                }
            )
            .sheet(isPresented: $showingOfflineSearch) {
                OfflineSearchView()
            }
            .navigationDestination(for: Location.self) { location in
                LocationDetailView(location: location, isAuthenticated: TokenManager.shared.isAuthenticated)
            }
            .onChange(of: searchManager.searchText) { newValue in
                showSearchResults = !newValue.isEmpty
            }
            .onAppear {
                cameraPosition = .region(locationManager.region)
                
                if let location = locationManager.location {
                    viewModel.loadNearbyLocations(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                } else {
                    viewModel.loadNearbyLocations(
                        latitude: kyivCoordinates.latitude,
                        longitude: kyivCoordinates.longitude
                    )
                    
                    locationManager.region = MKCoordinateRegion(
                        center: kyivCoordinates,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
            }
        }
    }
    
    private var searchResultsOverlay: some View {
        VStack {
            if showSearchResults && (!searchManager.searchResults.isEmpty || !searchManager.locationSearchResults.isEmpty || searchManager.isSearching) {
                VStack(spacing: 0) {
                    if searchManager.isSearching {
                        HStack {
                            Text("Searching...")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
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
                                    Text("Offline")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            
                            ForEach(searchManager.locationSearchResults) { result in
                                Button(action: {
                                    searchManager.selectLocationResult(result) { coordinate in
                                        if let coordinate = coordinate {
                                            searchManager.searchText = result.title
                                            
                                            let newRegion = MKCoordinateRegion(
                                                center: coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            )
                                            locationManager.region = newRegion
                                            cameraPosition = .region(newRegion)
                                            
                                            viewModel.loadNearbyLocations(
                                                latitude: coordinate.latitude,
                                                longitude: coordinate.longitude
                                            )
                                            
                                            showSearchResults = false
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
                    
                    if !searchManager.searchResults.isEmpty {
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
                                            
                                            viewModel.loadNearbyLocations(
                                                latitude: coordinate.latitude,
                                                longitude: coordinate.longitude
                                            )
                                            
                                            showSearchResults = false
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
                .frame(maxHeight: 400)
            }
        }
        .offset(y: 50)
        .zIndex(1)
    }
    
    private func showLocationDetail(for location: Location) {
        print("Showing location detail for: \(location.id) - \(location.address)")
        navigationPath.append(location)
    }
    
    private var mapView: some View {
        ZStack {
            Map(position: $cameraPosition, selection: $selectedLocation) {
                UserAnnotation()
                
                ForEach(viewModel.locations) { location in
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
                        let coordinates: CLLocationCoordinate2D
                        
                        if let location = locationManager.location {
                            coordinates = location.coordinate
                        } else {
                            coordinates = kyivCoordinates
                        }
                        
                        viewModel.loadNearbyLocations(
                            latitude: coordinates.latitude,
                            longitude: coordinates.longitude
                        )
                    }) {
                        Text("Find Nearby")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.blue)
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
            if viewModel.locations.isEmpty && !viewModel.isLoading {
                VStack(spacing: 16) {
                    Text("No locations found")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    
                    Text("Try searching for a different area or use 'Find Nearby' to discover locations around you.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            } else {
                VStack {
                    if viewModel.locations.count == 10 {
                        Text("Showing top 10 locations")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    
                    List {
                        ForEach(viewModel.locations) { location in
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
