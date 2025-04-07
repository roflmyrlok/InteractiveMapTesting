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
    @State private var showingProfileMenu = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region, annotationItems: viewModel.locations) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                        Text(location.name)
                            .font(.caption)
                            .padding(4)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(4)
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
                        showingProfileMenu = true
                    }) {
                        Image(systemName: isAuthenticated ? "person.circle.fill" : "person.circle")
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding()
                    .actionSheet(isPresented: $showingProfileMenu) {
                        ActionSheet(
                            title: Text("Profile Options"),
                            message: Text(isAuthenticated ? "You are logged in" : "You are not logged in"),
                            buttons: [
                                .default(Text(isAuthenticated ? "Logout" : "Login")) {
                                    if isAuthenticated {
                                        let authViewModel = AuthViewModel()
                                        authViewModel.logout()
                                        isAuthenticated = false
                                    } else {
                                        isAuthenticated = false
                                    }
                                },
                                .cancel()
                            ]
                        )
                    }
                }
                Spacer()
                
                Button(action: {
                    if let location = locationManager.location {
                        viewModel.loadNearbyLocations(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                        
                        // Update region to current location
                        locationManager.updateRegion(location: location)
                    }
                }) {
                    Text("Find Nearby Locations")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
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
            
            // Error message display
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                    
                    Spacer()
                }
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
