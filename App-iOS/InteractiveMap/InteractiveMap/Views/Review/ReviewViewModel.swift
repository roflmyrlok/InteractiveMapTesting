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
    @Published var isOfflineMode = false
    
    private let reviewService = ReviewService()
    private let cacheManager = CacheManager.shared
    
    func loadReviews(for locationId: String) {
        isLoading = true
        errorMessage = nil
        isOfflineMode = false
        
        reviewService.getReviewsForLocation(locationId: locationId) { [weak self] reviews, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    // Check if we have cached reviews to fall back on
                    let cachedReviews = self?.cacheManager.getCachedReviews(for: locationId) ?? []
                    if !cachedReviews.isEmpty {
                        self?.reviews = cachedReviews
                        self?.isOfflineMode = true
                        self?.errorMessage = nil
                        print("Using cached reviews due to network error: \(error.localizedDescription)")
                    } else {
                        self?.errorMessage = error.localizedDescription
                        self?.isOfflineMode = false
                    }
                } else if let reviews = reviews {
                    self?.reviews = reviews
                    self?.isOfflineMode = false
                }
            }
        }
    }
    
    func forceRefreshReviews(for locationId: String) {
        isLoading = true
        errorMessage = nil
        isOfflineMode = false
        
        // Force network fetch by directly calling the private method
        let url = "\(APIConstants.reviewServiceURL)/by-location/\(locationId)"
        
        NetworkManager.shared.request(
            url,
            method: .get
        ) { (result: Result<[Review], Error>) in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                
                switch result {
                case .success(let reviews):
                    self?.reviews = reviews
                    self?.isOfflineMode = false
                    self?.errorMessage = nil
                    
                    // Update cache with fresh data
                    self?.cacheManager.cacheReviews(reviews, for: locationId)
                    
                case .failure(let error):
                    // Fall back to cached reviews if available
                    let cachedReviews = self?.cacheManager.getCachedReviews(for: locationId) ?? []
                    if !cachedReviews.isEmpty {
                        self?.reviews = cachedReviews
                        self?.isOfflineMode = true
                        self?.errorMessage = nil
                    } else {
                        self?.errorMessage = error.localizedDescription
                        self?.isOfflineMode = false
                    }
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
                    // Insert the new review at the beginning
                    self?.reviews.insert(review, at: 0)
                    self?.isOfflineMode = false
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
                    // Insert the new review at the beginning
                    self?.reviews.insert(review, at: 0)
                    self?.isOfflineMode = false
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Cache Management
    
    func getCachedReviews(for locationId: String) -> [Review] {
        return cacheManager.getCachedReviews(for: locationId)
    }
    
    func areReviewsCached(for locationId: String) -> Bool {
        return cacheManager.areReviewsCached(for: locationId)
    }
}
