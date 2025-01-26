//
//  RestClient.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/28/24.
//

import Foundation
import Network

public enum NetworkPreference {
    case wifiOnly
    case cellularOnly
    case wifiWithFallback
}

public class RestClient {
    // Base URL for the REST API
    private let baseURL: URL

    // Shared URLSession
    private let session: URLSession

    // Network monitor to check for available network paths
    private var monitor: NWPathMonitor
    private var networkPreference: NetworkPreference
    private var isWiFiAvailable: Bool = false

    public init(baseURL: String, networkPreference: NetworkPreference = .wifiWithFallback) {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
        self.session = URLSession.shared
        self.networkPreference = networkPreference

        // Initialize and start the network monitor
        self.monitor = NWPathMonitor()
        self.monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                self.isWiFiAvailable = true
            } else if path.usesInterfaceType(.cellular) {
                self.isWiFiAvailable = false
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        self.monitor.start(queue: queue)
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

    // MARK: - Send Form Data
    public func sendFormData(endpoint: String, formData: [String: String], completion: @escaping (Result<Data, Error>) -> Void) {
        // Convert form data into application/x-www-form-urlencoded format
        let body = formData.map { key, value in
            "\(key)=\(value)"
        }.joined(separator: "&")
        
        // Convert to Data
        guard let bodyData = body.data(using: .utf8) else {
            completion(.failure(NSError(domain: "Form Data Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode form data."])))
            return
        }

        // Set the Content-Type header for form data
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        // Check network availability based on the preference
        if shouldUseWiFi() {
            print("Sending request over Wi-Fi")
            makeRequest(endpoint: endpoint, method: "POST", headers: headers, body: bodyData, completion: completion)
        } else {
            print("Sending request over Cellular (fallback)")
            makeRequest(endpoint: endpoint, method: "POST", headers: headers, body: bodyData, completion: completion)
        }
    }

    // MARK: - Network Preference Logic
    private func shouldUseWiFi() -> Bool {
        switch networkPreference {
        case .wifiOnly:
            return isWiFiAvailable
        case .cellularOnly:
            return false
        case .wifiWithFallback:
            return isWiFiAvailable
        }
    }

    // MARK: - Public Methods
    public func get(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "GET", headers: headers, completion: completion)
    }

    public func post(endpoint: String, headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "POST", headers: headers, body: body, completion: completion)
    }

    public func put(endpoint: String, headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "PUT", headers: headers, body: body, completion: completion)
    }

    public func delete(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "DELETE", headers: headers, completion: completion)
    }
}
