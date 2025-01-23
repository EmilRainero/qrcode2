//
//  Shot.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/20/24.
//

import SwiftUI
import Foundation

struct TimeVector: Codable {
    var time: Date
    var position: Vector
//    var angle: Double
//    var distance: Double

    init(time: Date, angle: Double, distance: Double) {
        self.time = time
//        self.angle = angle
//        self.distance = distance
        self.position = Vector(angle: angle, distance: distance)
    }

    // Custom JSON encoding with microsecond precision
    func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .custom { (date, encoder) in
            let formatter = DateFormatter()
            formatter.dateFormat = TIME_FORMAT
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
    var allShots: [TimeVector] = []
//    var angle: Double
//    var distance: Double
    var position: Vector
    var score: Int32

    init(time: Date, angle: Double, distance: Double, score: Int32) {
        self.time = time
        self.allShots = []
        self.position = Vector(angle: angle, distance: distance)
//        self.angle = angle
//        self.distance = distance
        self.score = score
        self.addAdditionalShots(time: time, angle: angle, distance: distance)
    }

    func description() -> String {
        return "Shot - \(self.time)  angle: \(self.position.angle)  distance: \(self.position.distance)"
    }
    
    func addAdditionalShots(time: Date, angle: Double, distance: Double) {
        let tv = TimeVector(time: time, angle: angle, distance: distance)
        self.allShots.append(tv)
    }
    
    func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .custom { (date, encoder) in
            let formatter = DateFormatter()
            formatter.dateFormat = TIME_FORMAT
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let dateString = formatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        }
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
