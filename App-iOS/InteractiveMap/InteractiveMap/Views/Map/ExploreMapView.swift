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
    
    private let kyivCoordinates = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            // App-iOS/InteractiveMap/InteractiveMap/Views/Map/ExploreMapView.swift
                            // Update the TextField and search results styling

                            TextField("Search locations", text: $searchManager.searchText, onCommit: {
                                if !searchManager.searchText.isEmpty {
                                    showSearchResults = true
                                }
                            })
                            .foregroundColor(.black) // Changed from .primary to .black

                            
                            if !searchManager.searchText.isEmpty {
                                Button(action: {
                                    searchManager.searchText = ""
                                    showSearchResults = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                        .overlay(
                            VStack {
                                if showSearchResults && !searchManager.searchResults.isEmpty {
                                    ScrollView {
                                        VStack(spacing: 0) {
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
                                                    VStack(alignment: .leading) {
                                                        Text(result.title)
                                                            .foregroundColor(.primary)
                                                        Text(result.subtitle)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        // Then in the search results section:
                                                        Text(result.title)
                                                            .foregroundColor(.black) // Changed from .primary to .black
                                                        Text(result.subtitle)
                                                            .font(.caption)
                                                            .foregroundColor(.black) // Changed from .secondary to .black
                                                        
                                                    }
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                Divider()
                                            }
                                        }
                                        .background(Color.gray)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                                    }
                                    .frame(height: min(300, CGFloat(searchManager.searchResults.count * 60)))
                                }
                            }
                            .offset(y: 50)
                            .zIndex(1)
                        , alignment: .top)
                        
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
        .sheet(item: $viewModel.selectedLocation) { location in
            LocationDetailView(location: location, isAuthenticated: true)
        }
        .onAppear {
            // Initialize camera position from the region
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
    
    private var mapView: some View {
        ZStack {

            Map(position: $cameraPosition) {
                UserAnnotation()
                
                ForEach(viewModel.locations) { location in
                    Annotation(
                        "", // Remove the name string to not show text
                        coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        anchor: .bottom
                    ) {
                        LocationMarkerView(location: location)
                            .onTapGesture {
                                viewModel.selectedLocation = location
                            }
                    }
                }
            }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: UIDevice.current.userInterfaceIdiom == .pad ? [] : .bottom)
            // Use this onChange handler to update the region when the user interacts with the map
            .onChange(of: cameraPosition) { oldPosition, newPosition in
                // We'd need a way to extract the region from the camera position
                // This is challenging due to Swift/MapKit limitations
                // For now, we won't sync back to locationManager.region
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
        List {
            if viewModel.locations.isEmpty && !viewModel.isLoading {
                Text("No locations found")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .padding(.top, 40)
            } else {
                ForEach(viewModel.locations) { location in
                    LocationRow(location: location)
                        .onTapGesture {
                            viewModel.selectedLocation = location
                        }
                }
            }
        }
        .listStyle(PlainListStyle())
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(location.city), \(location.state)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
