//
//  TargetRing.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/26/25.
//


import Foundation
import SwiftUI
import opencv2

extension Models {
    
    class TargetRing: Codable {
        var score: Int
        var ellipse: Models.Ellipse
        
        init(score: Int, ellipse: Models.Ellipse) {
            self.score = score
            self.ellipse = ellipse
        }
        
        func toJson() -> String? {
            let encoder = JSONEncoder()
            //        encoder.outputFormatting = .prettyPrinted // Makes JSON output readable
            do {
                let jsonData = try encoder.encode(self)
                return String(data: jsonData, encoding: .utf8)
            } catch {
                print("Failed to encode TargetRing to JSON: \(error)")
                return nil
            }
        }
    }
    
}
