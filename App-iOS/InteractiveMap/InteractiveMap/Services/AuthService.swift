//
//  AuthService.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation
import Alamofire

class AuthService {
    func login(username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let parameters: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        NetworkManager.shared.request(
            APIConstants.authServiceURL + "/login",
            method: .post,
            parameters: parameters
        ) { (result: Result<LoginResponse, Error>) in
            switch result {
            case .success(let response):
                TokenManager.shared.saveToken(response.token)
                completion(true, nil)
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }
    
    func register(username: String, email: String, password: String, firstName: String, lastName: String, completion: @escaping (Bool, String?) -> Void) {
        let parameters: [String: Any] = [
            "username": username,
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName,
            "role": 0 // Regular user
        ]
        
        NetworkManager.shared.request(
            APIConstants.userServiceURL,
            method: .post,
            parameters: parameters
        ) { (result: Result<RegisterResponse, Error>) in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }
    
    func logout() {
        TokenManager.shared.clearToken()
    }
}
