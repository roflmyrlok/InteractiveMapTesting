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
    
    // Default to Kyiv coordinates if user location is not available
    private let kyivCoordinates = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: viewModel.locations) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                    LocationMarkerView(location: location)
                        .onTapGesture {
                            viewModel.selectedLocation = location
                        }
                }
            }
            .ignoresSafeArea()
            
            VStack {
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
                
                Spacer()
                
                // Bottom panel with nearby button
                HStack {
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
                }
                .padding(.bottom, 30)
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
}

struct ExploreMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExploreMapView()
        }
    }
}