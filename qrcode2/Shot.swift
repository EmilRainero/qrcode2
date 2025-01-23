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
    var angle: Double
    var distance: Double

    init(time: Date, angle: Double, distance: Double) {
        self.time = time
        self.angle = angle
        self.distance = distance
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
    var allShots: [TimePosition] = []
    var angle: Double
    var distance: Double
    var score: Int32

    init(time: Date, angle: Double, distance: Double, score: Int32) {
        self.time = time
        self.allShots = []
        self.angle = angle
        self.distance = distance
        self.score = score
        self.addAdditionalShots(time: time, angle: angle, distance: distance)
    }

    func description() -> String {
        return "Shot - \(self.time)  angle: \(self.angle)  distance: \(self.distance)"
    }
    
    func addAdditionalShots(time: Date, angle: Double, distance: Double) {
        let tp = TimePosition(time: time, angle: angle, distance: distance)
        self.allShots.append(tp)
//        let result = self.driftAngleAndDistance()
//        if let angle = result.0, let distance = result.1 {
//            self.angle = angle
//            self.distance = distance
////            LoggerManager.log.info("addAddtionalShots: angle: \(angle)  distance: \(distance)")
//        }
    }
    
//    func driftAngleAndDistance() -> (Double?, Double?) {
//        guard self.allShots.count >= 2 else {
//            return (nil, nil) // Not enough points to calculate
//        }
//        
//        let firstPoint = self.allShots.first!.position
//        let lastPoint = self.allShots.last!.position
//        
//        // Calculate the differences in x and y
//        let deltaX = lastPoint.x - firstPoint.x
//        let deltaY = lastPoint.y - firstPoint.y
//        
//        // Calculate the angle in radians
//        let angleRadians = atan2(deltaY, deltaX)
//        
//        // Convert to degrees
//        let angleDegrees = angleRadians * 180 / .pi
//        
//        // Calculate distance using Pythagorean theorem
//        let distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2))
//        
//        return (angleDegrees, distance)
//    }
    
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
