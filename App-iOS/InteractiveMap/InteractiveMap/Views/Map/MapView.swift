// App-iOS/InteractiveMap/InteractiveMap/Views/Map/MapView.swift

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = MapViewModel()
    @Binding var isAuthenticated: Bool
    @State private var showingProfileMenu = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation()
                
                ForEach(viewModel.locations) { location in
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        anchor: .bottom
                    ) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .onTapGesture {
                            viewModel.selectedLocation = location
                        }
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .onAppear {
                cameraPosition = .region(locationManager.region)
            }
            
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
                        cameraPosition = .region(locationManager.region)
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
