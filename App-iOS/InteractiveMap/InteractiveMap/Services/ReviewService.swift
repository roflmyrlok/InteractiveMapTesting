//
//  ReviewService.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


// App-iOS/InteractiveMap/InteractiveMap/Services/ReviewService.swift
import Foundation
import Alamofire

class ReviewService {
    func getReviewsForLocation(locationId: String, completion: @escaping ([Review]?, Error?) -> Void) {
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
        
        // Check if token exists before making request
        if TokenManager.shared.isAuthenticated {
            NetworkManager.shared.request(
                APIConstants.reviewServiceURL,
                method: .post,
                parameters: parameters,
                authenticated: true  // Explicitly set authenticated to true
            ) { (result: Result<Review, Error>) in
                switch result {
                case .success(let review):
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
}
