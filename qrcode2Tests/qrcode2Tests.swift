//
//  qrcode2Tests.swift
//  qrcode2Tests
//
//  Created by Emil V Rainero on 12/1/24.
//

import Testing
import qrcode2


struct qrcode2Tests {

    @Test func example() async throws {
        // Example asynchronous test
        let result = await performAsyncOperation()
        
        // Expect the result to match the expected value (example: "success")
        #expect(result == "success")
        testFrames()
    }
    
    // Example async function that we are testing
    func performAsyncOperation() async -> String {
        // Simulating an async operation (e.g., network call)
        return "success"
    }

}
