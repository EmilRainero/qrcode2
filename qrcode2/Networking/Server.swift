//
//  Server.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/7/25.
//
import UIKit


class Server {
    private let baseURL: String
    public var token: String? = nil
    public var errorMessage: String = ""

    public init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func getLoginToken(username: String, password: String) -> Bool {
        let client = RestClient(baseURL: self.baseURL, networkPreference: .wifiWithFallback)

        // Define the login credentials
        let credentials = [
            "username": username,
            "password": password
        ]

        // Convert the credentials into application/x-www-form-urlencoded format
        let body = credentials.map { key, value in
            "\(key)=\(value)"
        }.joined(separator: "&")

        // Convert to Data
        guard let bodyData = body.data(using: .utf8) else {
            print("Failed to encode form data")
            return false
        }

        // Set the Content-Type header for form data
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        // Semaphore to wait for the asynchronous operation
        let semaphore = DispatchSemaphore(value: 0)
        var isSuccess = false
        self.errorMessage = ""

        // Make the POST request to the login endpoint
        client.post(endpoint: "/api/login", headers: headers, body: bodyData) { result in
            switch result {
            case .success(let data):
                // Parse the response data
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = jsonResponse["token"] as? String {
                    self.token = "Bearer " + token
//                    print("Login successful - token: \(self.token!)")
                    isSuccess = true
                } else {
                    self.errorMessage = "Failed to parse response"
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
            
            // Signal the semaphore to unblock the waiting thread
            semaphore.signal()
        }

        // Wait for the request to complete
        semaphore.wait()
        return isSuccess
    }

}
