//
//  UserService.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation
import Alamofire

class UserService {
    func getCurrentUser(completion: @escaping (User?, Error?) -> Void) {
        guard TokenManager.shared.isAuthenticated else {
            let authError = NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token"])
            completion(nil, authError)
            return
        }
        
        NetworkManager.shared.request(
            APIConstants.userServiceURL + "/me",
            method: .get,
            authenticated: true
        ) { (result: Result<User, Error>) in
            switch result {
            case .success(let user):
                completion(user, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func changePassword(request: ChangePasswordRequest, completion: @escaping (Bool, String?) -> Void) {
        let parameters: [String: Any] = [
            "currentPassword": request.currentPassword,
            "newPassword": request.newPassword,
            "confirmNewPassword": request.confirmNewPassword
        ]
        
        guard TokenManager.shared.isAuthenticated else {
            completion(false, "No authentication token")
            return
        }
        
        NetworkManager.shared.request(
            APIConstants.userServiceURL + "/change-password",
            method: .put,
            parameters: parameters,
            authenticated: true
        ) { (result: Result<PasswordChangeResponse, Error>) in
            switch result {
            case .success(let response):
                completion(true, response.message)
            case .failure(let error):
                let errorMessage = self.extractErrorMessage(from: error)
                completion(false, errorMessage)
            }
        }
    }
    
    func deleteAccount(request: DeleteAccountRequest, completion: @escaping (Bool, String?) -> Void) {
        let parameters: [String: Any] = [
            "currentPassword": request.currentPassword
        ]
        
        guard TokenManager.shared.isAuthenticated else {
            completion(false, "No authentication token")
            return
        }
        
        NetworkManager.shared.request(
            APIConstants.userServiceURL + "/delete-account",
            method: .delete,
            parameters: parameters,
            authenticated: true
        ) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success(_):
                TokenManager.shared.clearToken()
                completion(true, "Account deleted successfully")
            case .failure(let error):
                let errorMessage = self.extractErrorMessage(from: error)
                completion(false, errorMessage)
            }
        }
    }
}

// MARK: - Private Helper Methods
extension UserService {
    private func extractErrorMessage(from error: Error) -> String {
        if let afError = error as? AFError {
            switch afError {
            case .responseValidationFailed(let reason):
                switch reason {
                case .unacceptableStatusCode(let code):
                    switch code {
                    case 400:
                        return "Invalid request. Please check your input."
                    case 401:
                        return "Authentication failed. Please log in again."
                    case 403:
                        return "You don't have permission to perform this action."
                    case 404:
                        return "User not found."
                    case 500:
                        return "Server error. Please try again later."
                    default:
                        return "Request failed with status code \(code)."
                    }
                default:
                    break
                }
            case .sessionTaskFailed(let error):
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    return "No internet connection. Please check your network."
                } else if (error as NSError).code == NSURLErrorTimedOut {
                    return "Request timed out. Please try again."
                }
            default:
                break
            }
        }
        
        return error.localizedDescription
    }
}
