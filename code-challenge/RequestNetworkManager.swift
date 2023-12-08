import Foundation

/**
 A generic network fetching protocol for `Codable` objects.
 Simply provide a session, and your implementation can define the type `T` to fetch.
 */
public protocol NetworkRequestProvider {
    
    typealias ResponseObject = (data: Data, response: URLResponse)
    
    ///The `URLSession` that should be used for this request
    var session: URLSession { get }
    
    func fetch(from url: URL, completion: @escaping(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)
    
    func fetch<T>(_ type: T.Type, from url: URL, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable, T: Encodable
    
    // MARK: - Async/Await methods
    func fetch<T>(_ type: T.Type, from url: URL) async throws -> T where T : Decodable, T : Encodable
    
    func fetch<T>(_ type: T.Type, withRequest urlRequest: URLRequest) async throws -> T where T : Decodable, T : Encodable
    
    func fetch(from url: URL) async throws -> ResponseObject
    
    func fetch(withRequest urlRequest: URLRequest) async throws -> ResponseObject
    
}

public extension NetworkRequestProvider {
    
    func fetch<T>(_ type: T.Type, from url: URL) async throws -> T where T : Decodable, T : Encodable {
        let urlRequest = URLRequest(url: url)
        return try await fetch(type, withRequest: urlRequest)
    }
    
    func fetch(from url: URL) async throws -> ResponseObject {
        let urlRequest = URLRequest(url: url)
        return try await fetch(withRequest: urlRequest)
    }
}

/**
 A generic network fetching class for `Codable` objects.
 */
public class NetworkRequestManager: NetworkRequestProvider {
    public var session: URLSession
    
    public init(_ session: URLSession = URLSession(configuration: .default)) {
        self.session = session
    }
    
    public func fetch(from url: URL, completion: @escaping(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let urlRequest = URLRequest(url: url)
        session.dataTask(with: urlRequest) { (data, response, error) in
            guard let responseData = data, error == nil else {
                let newError = error ?? NetworkRequestManagerError.apiError(NSError(domain: "error", code: -123))
                DispatchQueue.main.async {
                    completion(data, response, newError)
                }
                return
            }
            
            var apiError: Error? = nil
            if let response = response as? HTTPURLResponse, 400...599 ~= response.statusCode {
                let message = String(data: responseData, encoding: .utf8) ?? "No Body"
                apiError = NetworkRequestManagerError.apiError(NSError(domain: urlRequest.url?.absoluteString ?? "", code: response.statusCode))
            }
            
            DispatchQueue.main.async {
                completion(responseData, response, apiError)
            }
        }.resume()
    }
    
    public func fetch<T>(_ type: T.Type, from url: URL, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable, T: Encodable {
        self.fetch(from: url) { (data, response, error) in
            guard let data = data, error == nil else {
                let newError = error ??  NetworkRequestManagerError.apiError(NSError(domain: "error", code: -123))
                completion(Result.failure(newError))
                return
            }
            do {
                let codableResonse = try JSONDecoder().decode(T.self, from: data)
                completion(Result.success(codableResonse))
            } catch {
                completion(Result.failure(error))
            }
        }
    }
}

// MARK: - Async/Await implementations
extension NetworkRequestManager {
    public func fetch<T>(_ type: T.Type, withRequest urlRequest: URLRequest) async throws -> T where T : Decodable, T : Encodable {
        let (data, _) = try await fetch(withRequest: urlRequest)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func fetch(withRequest urlRequest: URLRequest) async throws -> ResponseObject {
        let (data, response) = try await session.data(for: urlRequest)
        if let response = response as? HTTPURLResponse, 400...599 ~= response.statusCode {
            let message = String(data: data, encoding: .utf8) ?? "No Body"
            throw NetworkRequestManagerError.apiError(NSError(domain: urlRequest.url?.absoluteString ?? "", code: response.statusCode))
        }
        return (data: data, response: response)
    }
}

enum NetworkRequestManagerError: Error {
    case apiError(NSError)
}
