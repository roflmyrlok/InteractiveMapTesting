//
//  InstantFeedbackService.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 10.06.2025.
//

import Foundation
import Alamofire

class InstantFeedbackService {
    
    func submitInstantFeedback(
        locationId: String,
        feedbackType: InstantFeedbackType,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard TokenManager.shared.isAuthenticated else {
            completion(false, "You must be logged in to submit feedback")
            return
        }
        
        let request = SubmitInstantFeedbackRequest(
            locationId: locationId,
            feedbackType: feedbackType
        )
        
        let parameters: [String: Any] = [
            "locationId": request.locationId,
            "feedbackType": request.feedbackType.rawValue
        ]
        
        print("Submitting instant feedback for location \(locationId) with type \(feedbackType.title)")
        
        NetworkManager.shared.request(
            "\(APIConstants.reviewServiceURL)/LocationInstantFeedback/submit",
            method: .post,
            parameters: parameters,
            authenticated: true
        ) { (result: Result<InstantFeedbackResponse, Error>) in
            switch result {
            case .success(let response):
                print("Successfully submitted instant feedback: \(response.message)")
                completion(true, response.message)
            case .failure(let error):
                print("Failed to submit instant feedback: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            }
        }
    }
    
    func getLocationInstantStatus(
        locationId: String,
        completion: @escaping (LocationInstantStatus?, Error?) -> Void
    ) {
        let url = "\(APIConstants.reviewServiceURL)/LocationInstantFeedback/status/\(locationId)"
        
        NetworkManager.shared.request(
            url,
            method: .get,
            authenticated: true
        ) { (result: Result<LocationInstantStatus, Error>) in
            switch result {
            case .success(let status):
                completion(status, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func getLocationInstantStatuses(
        locationIds: [String],
        completion: @escaping ([LocationInstantStatusSummary]?, Error?) -> Void
    ) {
        let request = GetLocationInstantStatusesRequest(locationIds: locationIds)
        
        let parameters: [String: Any] = [
            "locationIds": request.locationIds
        ]
        
        NetworkManager.shared.request(
            "\(APIConstants.reviewServiceURL)/LocationInstantFeedback/statuses",
            method: .post,
            parameters: parameters,
            authenticated: true
        ) { (result: Result<[LocationInstantStatusSummary], Error>) in
            switch result {
            case .success(let statuses):
                completion(statuses, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
