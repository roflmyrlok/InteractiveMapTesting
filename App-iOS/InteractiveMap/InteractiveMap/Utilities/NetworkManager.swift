//
//  NetworkManager.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation
import Alamofire

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {
        // Set up any session configuration here
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        
        // Allow HTTP connections explicitly (this works with our Info.plist changes)
        configuration.waitsForConnectivity = true
    }
    
    func request<T: Decodable>(_ url: URLConvertible,
                               method: HTTPMethod = .get,
                               parameters: Parameters? = nil,
                               headers: HTTPHeaders? = nil,
                               authenticated: Bool = false,
                               completion: @escaping (Result<T, Error>) -> Void) {
        
        var finalHeaders = headers ?? HTTPHeaders()
        
        if authenticated, let token = TokenManager.shared.getToken() {
            finalHeaders.add(HTTPHeader(name: "Authorization", value: "Bearer \(token)"))
        }
        
        print("📱 Making request to: \(url)")
        
        AF.request(url,
                  method: method,
                  parameters: parameters,
                  encoding: method == .get ? URLEncoding.default : JSONEncoding.default,
                  headers: finalHeaders)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    print("Request successful: \(url)")
                    completion(.success(value))
                case .failure(let error):
                    print("Request failed: \(url)")
                    print("Error: \(error.localizedDescription)")
                    
                    // Enhanced error logging
                    if let data = response.data, let json = String(data: data, encoding: .utf8) {
                        print("Error response JSON: \(json)")
                    }
                    
                    if let urlError = error.underlyingError as? URLError {
                        if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                            // Custom network error
                            let networkError = NSError(domain: "NetworkManager",
                                                     code: 0,
                                                     userInfo: [NSLocalizedDescriptionKey: "No internet connection. Please check your connection and try again."])
                            completion(.failure(networkError))
                            return
                        }
                        
                        if urlError.code == .timedOut {
                            // Custom timeout error
                            let timeoutError = NSError(domain: "NetworkManager",
                                                     code: 1,
                                                     userInfo: [NSLocalizedDescriptionKey: "Request timed out. The server is taking too long to respond."])
                            completion(.failure(timeoutError))
                            return
                        }
                    }
                    
                    // Handle specific HTTP status codes
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 {
                            let authError = NSError(domain: "NetworkManager",
                                                   code: 401,
                                                   userInfo: [NSLocalizedDescriptionKey: "Authentication required. Please log in again."])
                            // Clear token if authentication failed
                            TokenManager.shared.clearToken()
                            completion(.failure(authError))
                            return
                        }
                        
                        if statusCode >= 500 {
                            let serverError = NSError(domain: "NetworkManager",
                                                    code: statusCode,
                                                    userInfo: [NSLocalizedDescriptionKey: "Server error occurred. Please try again later."])
                            completion(.failure(serverError))
                            return
                        }
                    }
                    
                    completion(.failure(error))
                }
            }
    }
}
