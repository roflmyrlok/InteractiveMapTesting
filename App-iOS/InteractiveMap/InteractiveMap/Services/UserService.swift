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
        // Explicit error object to avoid 'nil' contextual type error
        let authError = NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token"])
        
        guard let token = TokenManager.shared.getToken() else {
            completion(nil, authError)
            return
        }
        
        // Explicit type parameters to avoid T inference issues
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
}
