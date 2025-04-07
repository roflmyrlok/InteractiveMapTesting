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
        
        AF.request(url,
                  method: method,
                  parameters: parameters,
                  encoding: method == .get ? URLEncoding.default : JSONEncoding.default,
                  headers: finalHeaders)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    // Print additional debug info
                    if let data = response.data, let json = String(data: data, encoding: .utf8) {
                        print("Error response JSON: \(json)")
                    }
                    completion(.failure(error))
                }
            }
    }
}
