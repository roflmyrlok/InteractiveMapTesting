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
        
        if authenticated {
            if let token = TokenManager.shared.getToken() {
                finalHeaders.add(HTTPHeader(name: "Authorization", value: "Bearer \(token)"))
                print("DEBUG: Using token for authenticated request: \(token.prefix(20))...")
                
                // Debug: Check token expiry
                if let decodedToken = decodeJWT(token: token) {
                    print("DEBUG: Token expires at: \(decodedToken.exp)")
                    let now = Date().timeIntervalSince1970
                    if decodedToken.exp < now {
                        print("WARNING: Token appears to be expired!")
                    } else {
                        print("DEBUG: Token is still valid for \(Int(decodedToken.exp - now)) seconds")
                    }
                } else {
                    print("WARNING: Could not decode token!")
                }
            } else {
                print("ERROR: No token available for authenticated request!")
                let authError = NSError(domain: "NetworkManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
                completion(.failure(authError))
                return
            }
        }
        
        print("DEBUG: Making request to: \(url)")
        print("DEBUG: Method: \(method.rawValue)")
        print("DEBUG: Headers: \(finalHeaders)")
        
        if let params = parameters {
            print("DEBUG: Parameters: \(params)")
        }
        
        AF.request(url,
                  method: method,
                  parameters: parameters,
                  encoding: method == .get ? URLEncoding.default : JSONEncoding.default,
                  headers: finalHeaders)
            .validate()
            .responseData { response in
                print("DEBUG: Response status code: \(String(describing: response.response?.statusCode))")
                print("DEBUG: Response headers: \(String(describing: response.response?.allHeaderFields))")
                
                // Log raw response data for debugging
                if let data = response.data {
                    print("DEBUG: Raw response data size: \(data.count) bytes")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("DEBUG: Raw JSON response: \(jsonString.prefix(500))...")
                    }
                }
                
                // Check for specific authentication failures
                if let httpResponse = response.response {
                    if httpResponse.statusCode == 401 {
                        print("ERROR: Authentication failed (401) - clearing token")
                        TokenManager.shared.clearToken()
                        // Notify the app that authentication failed
                        NotificationCenter.default.post(name: NSNotification.Name("AuthenticationFailed"), object: nil)
                    }
                }
                
                switch response.result {
                case .success(let data):
                    print("DEBUG: Request successful: \(url)")
                    
                    // Special handling for empty responses (204 No Content)
                    if let httpResponse = response.response, httpResponse.statusCode == 204 {
                        if T.self == EmptyResponse.self {
                            completion(.success(EmptyResponse() as! T))
                        } else {
                            let emptyError = NSError(domain: "NetworkManager", code: 204, userInfo: [NSLocalizedDescriptionKey: "Empty response received"])
                            completion(.failure(emptyError))
                        }
                        return
                    }
                    
                    // Attempt to decode the data
                    do {
                        let decoder = JSONDecoder()
                        
                        // Configure custom date decoding strategy to handle multiple formats
                        decoder.dateDecodingStrategy = .custom { decoder in
                            let container = try decoder.singleValueContainer()
                            let dateString = try container.decode(String.self)
                            
                            // Try multiple date formats
                            let formatters = [
                                // ISO 8601 with fractional seconds
                                {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                                    return formatter
                                }(),
                                // ISO 8601 without fractional seconds
                                {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                                    return formatter
                                }(),
                                // ISO 8601 with 'Z' timezone
                                {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                                    return formatter
                                }()
                            ]
                            
                            for formatter in formatters {
                                if let date = formatter.date(from: dateString) {
                                    return date
                                }
                            }
                            
                            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                        }
                        
                        let decodedObject = try decoder.decode(T.self, from: data)
                        completion(.success(decodedObject))
                    } catch {
                        print("DEBUG: JSON decoding failed: \(error)")
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    print("DEBUG: Request failed: \(url) with error: \(error)")
                    
                    // Handle specific network errors with user-friendly messages
                    if let afError = error as? AFError {
                        switch afError {
                        case .sessionTaskFailed(let urlError as URLError):
                            if urlError.code == .notConnectedToInternet {
                                let networkError = NSError(domain: "NetworkManager",
                                                          code: 0,
                                                          userInfo: [NSLocalizedDescriptionKey: "No internet connection. Please check your network settings."])
                                completion(.failure(networkError))
                                return
                            }
                            
                            if urlError.code == .timedOut {
                                let timeoutError = NSError(domain: "NetworkManager",
                                                         code: 1,
                                                         userInfo: [NSLocalizedDescriptionKey: "Request timed out. The server is taking too long to respond."])
                                completion(.failure(timeoutError))
                                return
                            }
                            
                            if response.response?.statusCode == 500 {
                                let serverError = NSError(domain: "NetworkManager",
                                                        code: 2,
                                                        userInfo: [NSLocalizedDescriptionKey: "Server error occurred. Please try again later."])
                                completion(.failure(serverError))
                                return
                            }
                        default:
                            break
                        }
                    }
                    
                    completion(.failure(error))
                }
            }
    }
    
    func downloadImage(from url: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Handle both internal API URLs and direct URLs
        let imageUrl: String
        if url.hasPrefix("/api/reviews/images/") {
            // Convert internal API URL to full URL
            imageUrl = "\(APIConstants.baseURL)\(url)"
        } else if url.hasPrefix("http://") || url.hasPrefix("https://") {
            // Already a full URL
            imageUrl = url
        } else {
            // Assume it's a relative path and prepend base URL
            imageUrl = "\(APIConstants.baseURL)/\(url)"
        }
        
        print("Downloading image from URL: \(imageUrl)")
        
        var headers = HTTPHeaders()
        if let token = TokenManager.shared.getToken() {
            headers.add(HTTPHeader(name: "Authorization", value: "Bearer \(token)"))
            print("Using token for image download")
        }
        
        AF.request(imageUrl, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    print("Successfully downloaded image: \(data.count) bytes from \(imageUrl)")
                    completion(.success(data))
                case .failure(let error):
                    print("Image download failed for URL: \(imageUrl)")
                    print("Error: \(error)")
                    completion(.failure(error))
                }
            }
    }
    
    // Helper function to decode JWT token for debugging
    private func decodeJWT(token: String) -> JWTPayload? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        
        let payload = parts[1]
        var base64 = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return nil
        }
        
        return JWTPayload(exp: exp, sub: nil)
    }
}

// Helper struct for JWT payload
struct JWTPayload {
    let exp: TimeInterval
    let sub: String?
}
