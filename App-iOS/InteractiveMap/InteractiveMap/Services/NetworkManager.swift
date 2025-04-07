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
                  encoding: JSONEncoding.default, 
                  headers: finalHeaders)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
