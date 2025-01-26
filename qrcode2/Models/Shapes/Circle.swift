//
//  Circle.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/26/25.
//


import Foundation

extension Models {
    
    // Circle subclass
    class Circle: Codable {
        var x, y, radius: Double
        
        init(x: Double, y: Double, radius: Double) {
            self.x = x
            self.y = y
            self.radius = radius
        }
        
        func area() -> Double {
            return Double.pi * radius * radius
        }
        
        func toJson() -> String? {
            let encoder = JSONEncoder()
            //        encoder.outputFormatting = .prettyPrinted // Makes JSON output readable
            do {
                let jsonData = try encoder.encode(self)
                return String(data: jsonData, encoding: .utf8)
            } catch {
                print("Failed to encode Circle to JSON: \(error)")
                return nil
            }
        }
    }
    
}
