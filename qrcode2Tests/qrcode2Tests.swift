//
//  qrcode2Tests.swift
//  qrcode2Tests
//
//  Created by Emil V Rainero on 12/1/24.
//

import Testing
import qrcode2
import SwiftUI
import UIKit
import XCTest

struct qrcode2Tests {
    
    //    @Test func example() async throws {
    //        // Example asynchronous test
    //        let result = await performAsyncOperation()
    //
    //        // Expect the result to match the expected value (example: "success")
    //        #expect(result == "success")
    //        testFrames()
    //    }
    //
    //    // Example async function that we are testing
    //    func performAsyncOperation() async -> String {
    //        // Simulating an async operation (e.g., network call)
    //        return "success"
    //    }
    
    //    @Test func compareQRCodes() {
    //        let code1 = DetectedQRCode(
    //            message: "message",
    //            topLeft: CGPoint(x: 0, y: 10),
    //            topRight: CGPoint(x: 10, y: 10),
    //            bottomLeft: CGPoint(x: 0, y: 0),
    //            bottomRight: CGPoint(x: 10, y: 0),
    //            width: 10,
    //            height: 10
    //        )
    //        let code2 = DetectedQRCode(
    //            message: "message",
    //            topLeft: CGPoint(x: 0, y: 10),
    //            topRight: CGPoint(x: 10, y: 12),
    //            bottomLeft: CGPoint(x: 0, y: 0),
    //            bottomRight: CGPoint(x: 12, y: 0),
    //            width: 10,
    //            height: 10
    //        )
    //
    //        #expect(code1.QRCodeApproxEqual(qrcode: code2))
    //    }
}

class RestClientTests: XCTestCase {
    func testGetRequest() {
        let apiClient = RestClient(baseURL: "http://192.168.5.3:5001", networkPreference: .wifiWithFallback)
        
        let expectation = self.expectation(description: "Login request completes")

        // Example: GET Request
        apiClient.get(endpoint: "/") { result in
            switch result {
            case .success(let data):
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response: \(jsonString)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
            expectation.fulfill()
        }
        // Wait for the expectation to be fulfilled, with a timeout
        waitForExpectations(timeout: 10) // Adjust timeout as needed
    }
    
    func testLogin() {
        let client = RestClient(baseURL: "http://192.168.5.3:5001", networkPreference: .wifiWithFallback)

        // Define the login credentials
        let credentials = [
            "username": "a",
            "password": "a"
        ]

        // Convert the credentials into application/x-www-form-urlencoded format
        let body = credentials.map { key, value in
            "\(key)=\(value)"
        }.joined(separator: "&")

        // Convert to Data
        guard let bodyData = body.data(using: .utf8) else {
            print("Failed to encode form data")
            return
        }

        // Set the Content-Type header for form data
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        // Create an expectation
        let expectation = self.expectation(description: "Login request completes")

        print("Making POST request...")
        // Make the POST request to the login endpoint
        client.post(endpoint: "/login", headers: headers, body: bodyData) { result in
            switch result {
            case .success(let data):
                // Parse the response data
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Login successful: \(jsonResponse)")
                } else {
                    print("Failed to parse response")
                }
            case .failure(let error):
                print("Login failed: \(error.localizedDescription)")
            }
            
            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled, with a timeout
        waitForExpectations(timeout: 10) // Adjust timeout as needed
    }
}
