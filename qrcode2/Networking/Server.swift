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
    public var headers: [String: String] = [:]

    public init(baseURL: String, token: String?) {
        self.baseURL = baseURL
        self.token = token
        if token != nil {
            self.headers = [
                "Authorization": token!,
                "Content-Type": "application/json"
            ]
        }
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

    func sendUpdates(body: String) -> (success: Bool, response: [String: Any]?, errorMessage: String?) {
        let result = self.postRequest(endpoint: "/updates", body: body, headers: self.headers)
        return result
    }
    
    func generateStartSessionCommand(session: Models.Session) -> String? {
        let command = [
            "id": session.id,
            "command": "new_session",
            "start_time": formatDateToUTCTime(date: session.starttime)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: command, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
    
    func generateFinishSessionCommand(session: Models.Session) -> String? {
        let command = [
            "id": session.id,
            "command": "end_session",
            "finish_time": formatDateToUTCTime(date: session.finishtime!)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: command, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
    
    
    func generateAddShotCommand(session: Models.Session, shot: Models.Shot) -> String? {
        let command: [String : Any] = [
            "session_id": session.id,
            "command": "add_shot_to_session",
            "timestamp": formatDateToUTCTime(date: shot.time),
            "score": shot.score,
            "all_shots": [],
            "angle": shot.position.angle,
            "distance": shot.position.distance
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: command, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}

func testPost() {
    return
    
    let token = KeychainManager.shared.retrieveToken(forKey: "authToken")
    let server = Server(baseURL: "http://192.168.5.6:5001", token: token)
        
    let session = Models.Session(starttime: Date())
    let new_session_command = server.generateStartSessionCommand(session: session)!
    print(new_session_command)
    let timer = Timer()
    
    timer.start()
    var result = server.sendUpdates(body: new_session_command)
    print("Time: \(timer.stop())")
    print(result)
    
    let shot = Models.Shot(time: Date(), angle: 45.0, distance: 0.5, score: 5)
    session.addShot(shot: shot)
    let add_shot_command = server.generateAddShotCommand(session: session, shot: shot)!
    print(add_shot_command)
    result = server.sendUpdates(body: add_shot_command)
    print(result)
    
    session.finish(finishtime: Date())
    let finish_session_command = server.generateFinishSessionCommand(session: session)!
    print(finish_session_command)
    result = server.sendUpdates(body: finish_session_command)
    print(result)
}
