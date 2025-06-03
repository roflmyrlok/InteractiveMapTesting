// App-iOS/InteractiveMap/InteractiveMap/Views/Location/LocationDetailView.swift

import SwiftUI
import MapKit

struct LocationDetailView: View {
    let location: Location
    @State var isAuthenticated: Bool
    @StateObject private var reviewViewModel = ReviewViewModel()
    @State private var showingAddReview = false
    @State private var showingLoginPrompt = false
    @State private var isLoginViewPresented = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Map header
                ZStack(alignment: .bottomLeading) {
                    Map {
                        Marker("", coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                            .tint(.red)
                    }
                    .frame(height: 200)
                    .disabled(true)
                    .cornerRadius(12)
                    
                    // Location name overlay
                    Text(getLocationDisplayName(location))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                        .padding(.leading, 16)
                }
                .padding(.horizontal)
                
                // Location details section
                VStack(alignment: .leading, spacing: 16) {
                    // Address section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            Text("Address")
                                .font(.headline)
                        }
                        
                        Text(location.address)
                            .padding(.leading, 4)
                    }
                    
                    // Details section
                    if !location.details.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                Text("Details")
                                    .font(.headline)
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(location.details) { detail in
                                    HStack {
                                        Text(formatPropertyName(detail.propertyName))
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(detail.propertyValue)
                                            .multilineTextAlignment(.trailing)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.leading, 4)
                        }
                    }
                    
                    Divider()
                    
                    // Reviews section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                Text("Reviews")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if isAuthenticated {
                                    showingAddReview = true
                                } else {
                                    showingLoginPrompt = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Review")
                                }
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
                                    .scaleEffect(1.2)
                                Spacer()
                            }
                            .padding()
                        } else if let errorMessage = reviewViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        } else if reviewViewModel.reviews.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No reviews yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Be the first to review this location!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            // Reviews list
                            LazyVStack(spacing: 16) {
                                ForEach(reviewViewModel.reviews) { review in
                                    ReviewCardView(review: review)
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Bottom padding
                Color.clear.frame(height: 20)
            }
        }
        .navigationTitle(getLocationDisplayName(location))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddReview) {
            AddReviewView(locationId: location.id, viewModel: reviewViewModel)
        }
        .sheet(isPresented: $isLoginViewPresented) {
            AuthView()
                .environmentObject(AuthViewModel())
                .onDisappear {
                    // Check if the user is now authenticated
                    if TokenManager.shared.isAuthenticated {
                        isAuthenticated = true
                    }
                }
        }
        .onAppear {
            reviewViewModel.loadReviews(for: location.id)
            isAuthenticated = TokenManager.shared.isAuthenticated
        }
        .alert(isPresented: $showingLoginPrompt) {
            Alert(
                title: Text("Login Required"),
                message: Text("You need to be logged in to add reviews."),
                primaryButton: .default(Text("Login")) {
                    isLoginViewPresented = true
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func getLocationDisplayName(_ location: Location) -> String {
        // Try to get a meaningful name from location details
        if let typeDetail = location.details.first(where: { $0.propertyName.lowercased() == "sheltertype" || $0.propertyName.lowercased() == "type" }) {
            return typeDetail.propertyValue
        }
        
        // Fallback to address if no type is found
        return location.address
    }
    
    private func formatPropertyName(_ propertyName: String) -> String {
        // Convert camelCase and other formats to readable text
        let formatted = propertyName
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
        
        return formatted
    }
}
