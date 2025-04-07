//
//  MapView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = MapViewModel()
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region, annotationItems: viewModel.locations) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                        Text(location.name)
                            .font(.caption)
                            .fixedSize()
                    }
                    .onTapGesture {
                        viewModel.selectedLocation = location
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        if isAuthenticated {
                            // Show profile or logout
                            let authViewModel = AuthViewModel()
                            authViewModel.logout()
                            isAuthenticated = false
                        } else {
                            // Navigate to login
                        }
                    }) {
                        Image(systemName: isAuthenticated ? "person.circle.fill" : "person.circle")
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
                
                Button(action: {
                    if let location = locationManager.location {
                        viewModel.loadNearbyLocations(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                    }
                }) {
                    Text("Find Nearby Locations")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .sheet(item: $viewModel.selectedLocation) { location in
            LocationDetailView(location: location, isAuthenticated: isAuthenticated)
        }
        .onAppear {
            if let location = locationManager.location {
                viewModel.loadNearbyLocations(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }
}