//
//  LocationDetailView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct LocationDetailView: View {
    let location: Location
    let isAuthenticated: Bool
    @StateObject private var reviewViewModel = ReviewViewModel()
    @State private var showingAddReview = false
    @State private var rating = 3
    @State private var reviewContent = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(location.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Divider()
                
                Group {
                    Text("Address:")
                        .font(.headline)
                    Text("\(location.address), \(location.city), \(location.state)")
                    Text("\(location.country), \(location.postalCode)")
                }
                
                if !location.details.isEmpty {
                    Divider()
                    
                    Text("Details:")
                        .font(.headline)
                    
                    ForEach(location.details) { detail in
                        HStack {
                            Text(detail.propertyName)
                                .fontWeight(.medium)
                            Spacer()
                            Text(detail.propertyValue)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Reviews")
                        .font(.headline)
                    
                    Spacer()
                    
                    if isAuthenticated {
                        Button(action: {
                            showingAddReview = true
                        }) {
                            Text("Add Review")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if reviewViewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if reviewViewModel.reviews.isEmpty {
                    Text("No reviews yet")
                        .italic()
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(reviewViewModel.reviews) { review in
                        VStack(alignment: .leading) {
                            HStack {
                                RatingView(rating: review.rating)
                                Spacer()
                                Text(formatDate(review.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text(review.content)
                                .padding(.top, 4)
                            
                            Divider()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddReview) {
            AddReviewView(locationId: location.id, viewModel: reviewViewModel)
        }
        .onAppear {
            reviewViewModel.loadReviews(for: location.id)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}