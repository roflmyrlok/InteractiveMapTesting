//
//  ExploreMapView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI
import MapKit

struct ExploreMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = MapViewModel()
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var selectedTab = 0
    
    // Default to Kyiv coordinates if user location is not available
    private let kyivCoordinates = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search locations", text: $searchText)
                            .foregroundColor(.primary)
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
                    
                    Button(action: {
                        // Center map on user's location
                        if let location = locationManager.location {
                            locationManager.updateRegion(location: location)
                        } else {
                            // Center on Kyiv if user location unavailable
                            locationManager.region = MKCoordinateRegion(
                                center: kyivCoordinates,
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
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
                .padding(.top, 10)
                
                // Main content
                if UIDevice.current.userInterfaceIdiom == .pad && geometry.size.width > 768 {
                    // iPad layout - side by side
                    HStack(spacing: 0) {
                        // Map view
                        mapView
                            .frame(width: geometry.size.width * 0.6)
                        
                        // List view
                        locationListView
                            .frame(width: geometry.size.width * 0.4)
                    }
                } else {
                    // iPhone layout - tabbed
                    TabView(selection: $selectedTab) {
                        mapView
                            .tag(0)
                        
                        locationListView
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Custom tab indicator
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
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            // Error message display
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
            if let location = locationManager.location {
                viewModel.loadNearbyLocations(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            } else {
                // If user location is not available, load locations near Kyiv
                viewModel.loadNearbyLocations(
                    latitude: kyivCoordinates.latitude,
                    longitude: kyivCoordinates.longitude
                )
                
                // Set region to Kyiv
                locationManager.region = MKCoordinateRegion(
                    center: kyivCoordinates,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        }
    }
    
    // Map View
    private var mapView: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: viewModel.locations) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                    LocationMarkerView(location: location)
                        .onTapGesture {
                            viewModel.selectedLocation = location
                        }
                }
            }
            .ignoresSafeArea(edges: UIDevice.current.userInterfaceIdiom == .pad ? [] : .bottom)
            
            // iPad-specific "Find Nearby" button
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
    
    // List View
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
}

// Tab Button Component
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

// Location Row Component
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

struct ExploreMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExploreMapView()
        }
    }
}
