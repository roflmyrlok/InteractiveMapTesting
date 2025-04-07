//
//  ReviewViewModel.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import Foundation

class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let reviewService = ReviewService()
    
    func loadReviews(for locationId: String) {
        isLoading = true
        errorMessage = nil
        
        reviewService.getReviewsForLocation(locationId: locationId) { [weak self] reviews, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let reviews = reviews {
                    self?.reviews = reviews
                }
            }
        }
    }
    
    func addReview(for locationId: String, rating: Int, content: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        reviewService.createReview(locationId: locationId, rating: rating, content: content) { [weak self] review, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else if let review = review {
                    self?.reviews.append(review)
                    completion(true)
                }
            }
        }
    }
}