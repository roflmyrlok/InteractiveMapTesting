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
            print("Using token for authenticated request: \(token.prefix(10))...")
        } else if authenticated {
            print("No token available for authenticated request!")
        }
        
        print("Making request to: \(url)")
        print("Method: \(method.rawValue)")
        
        if let params = parameters {
            print("Parameters: \(params)")
        }
        
        AF.request(url,
                  method: method,
                  parameters: parameters,
                  encoding: method == .get ? URLEncoding.default : JSONEncoding.default,
                  headers: finalHeaders)
            .validate()
            .responseData { response in
                print("Response status code: \(String(describing: response.response?.statusCode))")
                
                // Log raw response data for debugging
                if let data = response.data {
                    print("Raw response data size: \(data.count) bytes")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON response: \(jsonString.prefix(500))...")
                    }
                }
                
                switch response.result {
                case .success(let data):
                    print("Request successful: \(url)")
                    
                    // Attempt to decode the data
                    do {
                        let decoder = JSONDecoder()
                        
                        // Configure date decoding strategy for ISO8601 dates
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                        formatter.timeZone = TimeZone(abbreviation: "UTC")
                        decoder.dateDecodingStrategy = .formatted(formatter)
                        
                        // Alternative: Use ISO8601 decoder for simpler dates
                        // decoder.dateDecodingStrategy = .iso8601
                        
                        let decodedResult = try decoder.decode(T.self, from: data)
                        completion(.success(decodedResult))
                    } catch {
                        print("Decoding error: \(error)")
                        if let decodingError = error as? DecodingError {
                            print("Detailed decoding error: \(decodingError)")
                            switch decodingError {
                            case .dataCorrupted(let context):
                                print("Data corrupted: \(context)")
                            case .keyNotFound(let key, let context):
                                print("Key '\(key)' not found: \(context)")
                            case .typeMismatch(let type, let context):
                                print("Type '\(type)' mismatch: \(context)")
                            case .valueNotFound(let value, let context):
                                print("Value '\(value)' not found: \(context)")
                            @unknown default:
                                print("Unknown decoding error")
                            }
                        }
                        completion(.failure(error))
                    }
                    
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
