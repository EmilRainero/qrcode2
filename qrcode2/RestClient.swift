import Foundation

class RestClient {
    // Base URL for the REST API
    private let baseURL: URL

    // Shared URLSession
    private let session: URLSession

    init(baseURL: String) {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
        self.session = URLSession.shared
    }

    // MARK: - Generic REST Call
    private func makeRequest(endpoint: String, method: String, headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = body

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let error = NSError(domain: "HTTP Error", code: statusCode, userInfo: nil)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NSError(domain: "No Data", code: -1, userInfo: nil)
                completion(.failure(error))
                return
            }

            completion(.success(data))
        }.resume()
    }

    // MARK: - Public Methods

    /// GET request
    func get(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "GET", headers: headers, completion: completion)
    }

    /// POST request
    func post(endpoint: String, headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "POST", headers: headers, body: body, completion: completion)
    }

    /// PUT request
    func put(endpoint: String, headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "PUT", headers: headers, body: body, completion: completion)
    }

    /// DELETE request
    func delete(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "DELETE", headers: headers, completion: completion)
    }
}