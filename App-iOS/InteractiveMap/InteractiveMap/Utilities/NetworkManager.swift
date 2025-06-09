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
                        
                        // Configure custom date decoding strategy to handle multiple formats
                        decoder.dateDecodingStrategy = .custom { decoder in
                            let container = try decoder.singleValueContainer()
                            let dateString = try container.decode(String.self)
                            
                            // Try multiple date formats
                            let formatters: [DateFormatter] = [
                                {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                                    return formatter
                                }(),
                                {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                                    return formatter
                                }(),
                                {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                                    return formatter
                                }()
                            ]
                            
                            for formatter in formatters {
                                if let date = formatter.date(from: dateString) {
                                    return date
                                }
                            }
                            
                            // Fallback to ISO8601DateFormatter
                            let iso8601Formatter = ISO8601DateFormatter()
                            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            if let date = iso8601Formatter.date(from: dateString) {
                                return date
                            }
                            
                            // If all else fails, throw an error
                            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode date from string: \(dateString)")
                        }
                        
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
                        
                        if response.response?.statusCode == 500 {
                            // Custom server error
                            let serverError = NSError(domain: "NetworkManager",
                                                    code: 2,
                                                    userInfo: [NSLocalizedDescriptionKey: "Server error occurred. Please try again later."])
                            completion(.failure(serverError))
                            return
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
}
