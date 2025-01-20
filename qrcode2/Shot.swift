//
//  Shot.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/20/24.
//

import SwiftUI
import Foundation

struct TimePosition: Codable {
    var time: Date
    var position: CGPoint

    init(time: Date, position: CGPoint) {
        self.time = time
        self.position = position
    }

    // Custom JSON encoding with microsecond precision
    func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .custom { (date, encoder) in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let dateString = formatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        }
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? ""
    }
}

class Shot: Codable {
    var time: Date
    var position: CGPoint
    var allShots: [TimePosition] = []
    var angle: Double?
    var distance: Double?

    init(time: Date, position: CGPoint) {
        self.time = time
        self.position = position
        self.allShots = []
        self.addAdditionalShots(time: time, position: position)
    }

    func description() -> String {
        return "Shot - \(time)  position: \(position)"
    }
    
    func addAdditionalShots(time: Date, position: CGPoint) {
        let tp = TimePosition(time: time, position: position)
        self.allShots.append(tp)
        let result = self.driftAngleAndDistance()
        if let angle = result.0, let distance = result.1 {
            self.angle = angle
            self.distance = distance
//            LoggerManager.log.info("addAddtionalShots: angle: \(angle)  distance: \(distance)")
        }
    }
    
    func driftAngleAndDistance() -> (Double?, Double?) {
        guard self.allShots.count >= 2 else {
            return (nil, nil) // Not enough points to calculate
        }
        
        let firstPoint = self.allShots.first!.position
        let lastPoint = self.allShots.last!.position
        
        // Calculate the differences in x and y
        let deltaX = lastPoint.x - firstPoint.x
        let deltaY = lastPoint.y - firstPoint.y
        
        // Calculate the angle in radians
        let angleRadians = atan2(deltaY, deltaX)
        
        // Convert to degrees
        let angleDegrees = angleRadians * 180 / .pi
        
        // Calculate distance using Pythagorean theorem
        let distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2))
        
        return (angleDegrees, distance)
    }
    
    func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .custom { (date, encoder) in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let dateString = formatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        }
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
