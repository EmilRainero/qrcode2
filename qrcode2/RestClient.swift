//
//  RestClient.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/28/24.
//

import Foundation
import Network

public class RestClient {
    // Base URL for the REST API
    private let baseURL: URL

    // Shared URLSession
    private let session: URLSession

    // Network monitor for checking the interface type
    private let monitor = NWPathMonitor()

    // Network preference (default: Wi-Fi only)
    public enum NetworkPreference {
        case wifiOnly
        case cellularOnly
        case any
    }
    private let networkPreference: NetworkPreference

    // Variable to store the current path status
    private var currentPath: NWPath?

    public init(baseURL: String, networkPreference: NetworkPreference = .wifiOnly) {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
        self.session = URLSession.shared
        self.networkPreference = networkPreference

        // Start monitoring the network path
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
            print("Current Path Updated: \(path)")
        }

        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    // MARK: - Generic REST Call
    private func makeRequest(
        endpoint: String,
        method: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // Wait for the network path to be updated before proceeding
        waitForNetworkPathUpdate()

        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        // Validate network preference before making the request
        guard isValidNetworkConnection() else {
            let error = NSError(domain: "Network Preference", code: -2, userInfo: [NSLocalizedDescriptionKey: "Request blocked due to network preference settings"])
            completion(.failure(error))
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

    // MARK: - Network Validation
    private func isValidNetworkConnection() -> Bool {
        // Ensure we have a valid currentPath
        guard let path = currentPath else {
            print("Network path is unavailable or hasn't been detected yet.")
            return false
        }

        print("Current Path: \(path)")
        print("Network Preference: \(networkPreference)")
        
        switch networkPreference {
        case .wifiOnly:
            return path.usesInterfaceType(.wifi)
        case .cellularOnly:
            return path.usesInterfaceType(.cellular)
        case .any:
            return path.status == .satisfied
        }
    }

    // MARK: - Wait for Network Path Update
    private func waitForNetworkPathUpdate() {
        let semaphore = DispatchSemaphore(value: 0)

        // Set pathUpdateHandler to signal semaphore when path is updated
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
            print("Current Path Updated: \(path)")
            semaphore.signal()  // Signal the semaphore when the path is updated
        }

        // Wait for the network path to be updated
        let timeout = DispatchTime.now() + .seconds(5) // Wait up to 5 seconds
        if semaphore.wait(timeout: timeout) == .timedOut {
            print("Timed out waiting for network path update.")
        }
    }

    // MARK: - Public Methods

    /// GET request
    public func get(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "GET", headers: headers, completion: completion)
    }

    /// POST request
    public func post(endpoint: String, headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "POST", headers: headers, body: body, completion: completion)
    }

    /// PUT request
    public func put(endpoint: String, headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "PUT", headers: headers, body: body, completion: completion)
    }

    /// DELETE request
    public func delete(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        makeRequest(endpoint: endpoint, method: "DELETE", headers: headers, completion: completion)
    }
}
