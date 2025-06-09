//
//  ReviewService.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation
import Alamofire

class ReviewService {
    private let cacheManager = CacheManager.shared
    
    func getReviewsForLocation(locationId: String, completion: @escaping ([Review]?, Error?) -> Void) {
        // Try cache first
        let cachedReviews = cacheManager.getCachedReviews(for: locationId)
        if !cachedReviews.isEmpty {
            print("Returning \(cachedReviews.count) reviews from cache for location \(locationId)")
            completion(cachedReviews, nil)
            
            // Still fetch from network in background to update cache
            fetchReviewsFromNetwork(locationId: locationId) { [weak self] reviews, error in
                if let reviews = reviews {
                    self?.cacheManager.cacheReviews(reviews, for: locationId)
                }
            }
            return
        }
        
        // Fetch from network
        fetchReviewsFromNetwork(locationId: locationId) { [weak self] reviews, error in
            if let reviews = reviews {
                print("Successfully fetched \(reviews.count) reviews from network for location \(locationId)")
                self?.cacheManager.cacheReviews(reviews, for: locationId)
                completion(reviews, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    private func fetchReviewsFromNetwork(locationId: String, completion: @escaping ([Review]?, Error?) -> Void) {
        let url = "\(APIConstants.reviewServiceURL)/by-location/\(locationId)"
        
        NetworkManager.shared.request(
            url,
            method: .get
        ) { (result: Result<[Review], Error>) in
            switch result {
            case .success(let reviews):
                completion(reviews, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    func createReview(locationId: String, rating: Int, content: String, completion: @escaping (Review?, Error?) -> Void) {
        let parameters: [String: Any] = [
            "locationId": locationId,
            "rating": rating,
            "content": content
        ]
        
        if TokenManager.shared.isAuthenticated {
            NetworkManager.shared.request(
                APIConstants.reviewServiceURL + "/json",
                method: .post,
                parameters: parameters,
                authenticated: true
            ) { (result: Result<Review, Error>) in
                switch result {
                case .success(let review):
                    // Update cache with new review
                    var cachedReviews = CacheManager.shared.getCachedReviews(for: locationId)
                    cachedReviews.insert(review, at: 0) // Add to beginning
                    CacheManager.shared.cacheReviews(cachedReviews, for: locationId)
                    
                    completion(review, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        } else {
            let authError = NSError(
                domain: "ReviewService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "You must be logged in to create a review."]
            )
            completion(nil, authError)
        }
    }
    
    func createReviewWithImages(request: CreateReviewWithImagesRequest, completion: @escaping (Review?, Error?) -> Void) {
        guard TokenManager.shared.isAuthenticated else {
            let authError = NSError(
                domain: "ReviewService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "You must be logged in to create a review."]
            )
            completion(nil, authError)
            return
        }
        
        guard let token = TokenManager.shared.getToken() else {
            let authError = NSError(
                domain: "ReviewService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Authentication token not found."]
            )
            completion(nil, authError)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        AF.upload(
            multipartFormData: { multipartFormData in
                // Add text fields
                multipartFormData.append(request.locationId.data(using: .utf8)!, withName: "locationId")
                multipartFormData.append("\(request.rating)".data(using: .utf8)!, withName: "rating")
                multipartFormData.append(request.content.data(using: .utf8)!, withName: "content")
                
                // Add image files
                for (index, imageData) in request.images.enumerated() {
                    let fileName = index < request.imageNames.count ? request.imageNames[index] : "image_\(index).jpg"
                    let mimeType = self.getMimeType(for: fileName)
                    multipartFormData.append(imageData, withName: "images", fileName: fileName, mimeType: mimeType)
                }
            },
            to: APIConstants.reviewServiceURL,
            headers: headers
        )
        .validate()
        .responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    decoder.dateDecodingStrategy = .formatted(formatter)
                    
                    let review = try decoder.decode(Review.self, from: data)
                    
                    // Update cache with new review
                    var cachedReviews = CacheManager.shared.getCachedReviews(for: request.locationId)
                    cachedReviews.insert(review, at: 0) // Add to beginning
                    CacheManager.shared.cacheReviews(cachedReviews, for: request.locationId)
                    
                    completion(review, nil)
                } catch {
                    print("Decoding error: \(error)")
                    completion(nil, error)
                }
            case .failure(let error):
                print("Upload error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    private func getMimeType(for fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        default:
            return "image/jpeg"
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
