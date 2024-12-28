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
    
    @Test func compareQRCodes() {
        let code1 = DetectedQRCode(
            message: "message",
            topLeft: CGPoint(x: 0, y: 10),
            topRight: CGPoint(x: 10, y: 10),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 10, y: 0),
            width: 10,
            height: 10
        )
        let code2 = DetectedQRCode(
            message: "message",
            topLeft: CGPoint(x: 0, y: 10),
            topRight: CGPoint(x: 10, y: 12),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 12, y: 0),
            width: 10,
            height: 10
        )
        
        #expect(code1.QRCodeApproxEqual(qrcode: code2))
    }

}
