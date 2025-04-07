//
//  LocationDetailView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI
import MapKit

struct LocationDetailView: View {
    let location: Location
    let isAuthenticated: Bool
    @StateObject private var reviewViewModel = ReviewViewModel()
    @State private var showingAddReview = false
    @State private var showingLoginPrompt = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Map header
                ZStack(alignment: .bottomLeading) {
                    // Static map image
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [location]) { location in
                        MapPin(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                    }
                    .frame(height: 200)
                    .disabled(true)
                    
                    // Location name overlay
                    Text(location.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8, corners: [.topRight])
                        .padding(.bottom, 16)
                }
                
                // Location details
                VStack(alignment: .leading, spacing: 16) {
                    // Address section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text("Address")
                                .font(.headline)
                        }
                        
                        Text("\(location.address)")
                        Text("\(location.city), \(location.state) \(location.postalCode)")
                        Text("\(location.country)")
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Details section
                    if !location.details.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location Details")
                                .font(.headline)
                            
                            ForEach(location.details) { detail in
                                HStack {
                                    Text(detail.propertyName)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(detail.propertyValue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                    }
                    
                    // Reviews section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Reviews")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                if isAuthenticated {
                                    showingAddReview = true
                                } else {
                                    showingLoginPrompt = true
                                }
                            }) {
                                Label("Add Review", systemImage: "square.and.pencil")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                            }
                        }
                        
                        if reviewViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if reviewViewModel.reviews.isEmpty {
                            Text("No reviews yet")
                                .italic()
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            // Reviews list
                            ForEach(reviewViewModel.reviews) { review in
                                ReviewCardView(review: review)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddReview) {
            NavigationView {
                AddReviewView(locationId: location.id, viewModel: reviewViewModel)
            }
        }
        .alert(isPresented: $showingLoginPrompt) {
            Alert(
                title: Text("Login Required"),
                message: Text("You need to be logged in to add reviews."),
                primaryButton: .default(Text("Login"), action: {
                    // Handle navigation to login screen
                }),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            reviewViewModel.loadReviews(for: location.id)
        }
    }
}

// Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
