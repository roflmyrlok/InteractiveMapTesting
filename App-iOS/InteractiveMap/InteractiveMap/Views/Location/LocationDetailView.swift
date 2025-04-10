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
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Map header
                    ZStack(alignment: .bottomLeading) {

                        Map {
                            Marker("", coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                                .tint(.red)
                        }
                        .frame(height: min(200, geometry.size.height * 0.3))
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
                    
                    // iPad-specific layout
                    if UIDevice.current.userInterfaceIdiom == .pad && geometry.size.width > 768 {
                        HStack(alignment: .top, spacing: 0) {
                            // Location details column
                            detailsSection
                                .frame(width: geometry.size.width * 0.4)
                                .padding()
                            
                            Divider()
                            
                            // Reviews column
                            reviewsSection
                                .frame(width: geometry.size.width * 0.6)
                                .padding()
                        }
                    } else {
                        // iPhone layout - vertical
                        VStack(alignment: .leading, spacing: 16) {
                            detailsSection
                                .padding(.horizontal)
                            
                            Divider()
                                .padding(.horizontal)
                            
                            reviewsSection
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAddReview) {
            NavigationView {
                AddReviewView(locationId: location.id, viewModel: reviewViewModel)
            }
        }
        .sheet(isPresented: $isLoginViewPresented) {
            NavigationView {
                AuthView()
                    .environmentObject(AuthViewModel())
                    .onDisappear {
                        // Check if the user is now authenticated
                        if TokenManager.shared.isAuthenticated {
                            isAuthenticated = true
                        }
                    }
            }
        }
        .onAppear {
            reviewViewModel.loadReviews(for: location.id)
        }
    }
    
    // Details Section
    private var detailsSection: some View {
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
            }
        }
    }
    
    // Reviews Section
    private var reviewsSection: some View {
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
            } else if let errorMessage = reviewViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if reviewViewModel.reviews.isEmpty {
                Text("No reviews yet. Be the first to review!")
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
        .alert(isPresented: $showingLoginPrompt) {
            Alert(
                title: Text("Login Required"),
                message: Text("You need to be logged in to add reviews."),
                primaryButton: .default(Text("Login")) {
                    // Navigate to the login view
                    isLoginViewPresented = true
                },
                secondaryButton: .cancel()
            )
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
