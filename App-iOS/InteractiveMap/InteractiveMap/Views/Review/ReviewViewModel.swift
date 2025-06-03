//
//  ReviewViewModel.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation
import UIKit

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
    
    func addReviewWithImages(for locationId: String, rating: Int, content: String, images: [UIImage], completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Convert UIImages to Data
        var imageDataArray: [Data] = []
        var imageNames: [String] = []
        
        for (index, image) in images.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                imageDataArray.append(imageData)
                imageNames.append("image_\(index).jpg")
            }
        }
        
        let request = CreateReviewWithImagesRequest(
            locationId: locationId,
            rating: rating,
            content: content,
            images: imageDataArray,
            imageNames: imageNames
        )
        
        reviewService.createReviewWithImages(request: request) { [weak self] review, error in
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
