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
        print("Request Body Data: \(String(data: bodyData, encoding: .utf8) ?? "Invalid Data")")

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
    
    func postRequest(endpoint: String, body: String, headers: [String: String] = ["Content-Type": "application/json"]) -> (success: Bool, response: [String: Any]?, errorMessage: String?) {
            let client = RestClient(baseURL: self.baseURL, networkPreference: .wifiWithFallback)
            
            // Convert to Data
            guard let bodyData = body.data(using: .utf8) else {
                return (false, nil, "Failed to encode JSON data")
            }
            
            // Semaphore for synchronous behavior
            let semaphore = DispatchSemaphore(value: 0)
            var responseDict: [String: Any]? = nil
            var isSuccess = false
            var errorMessage: String? = nil
            
            client.post(endpoint: endpoint, headers: headers, body: bodyData) { result in
                switch result {
                case .success(let data):
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        responseDict = jsonResponse
                        isSuccess = true
                    } else {
                        errorMessage = "Failed to parse response"
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
                semaphore.signal()
            }
            
            // Wait for the request to complete
            semaphore.wait()
            return (isSuccess, responseDict, errorMessage)
        }

}

func testPost() {
    let token = KeychainManager.shared.retrieveToken(forKey: "authToken")
//    print(token!)
    let server = Server(baseURL: "http://192.168.5.6:5001")
    
//    let x = server.getLoginToken(username: "emil.rainero@gmail.com", password: "a")
//    print(x)
    
    let headers = [
        "Authorization": token!,
        "Content-Type": "application/json"
    ]
    let command = [
        "id": UUID().uuidString,
        "command": "new_session",
        "start_time": "2021-01-01T12:00:00.000000Z"
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: command, options: []),
       let jsonString = String(data: jsonData, encoding: .utf8) {
//        print(jsonString) // Prints the JSON string
        
        let beforeTime = CFAbsoluteTimeGetCurrent()
        let result = server.postRequest(endpoint: "/updates", body: jsonString, headers: headers)
        let afterTime = CFAbsoluteTimeGetCurrent()
        print("Time: \(afterTime - beforeTime)")
        print(result)
    }
    
    
}
