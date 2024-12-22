//
//  Target.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/22/24.
//

import Foundation

class TargetRing: Codable {
    var score: Int
    var ellipse: Ellipse
    
    init(score: Int, ellipse: Ellipse) {
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

class Target {
    var name: String
    var rings: [TargetRing]
    
    init(name: String) {
        self.name = name
        self.rings = []
    }
    
    func addRing(ring: TargetRing) {
        self.rings.append(ring)
    }
    
    func sortRings() {
        self.rings.sort { $0.score > $1.score }
    }
    
    func assignScores() {
        self.rings.sort { $0.ellipse.area() < $1.ellipse.area() }

        for i in 0..<self.rings.count {
            self.rings[i].score = 10 - i
        }
    }
    
    func printdetails() {
        print("Name: \(self.name)")
        for i in 0..<self.rings.count {
            print("    \(i) \(self.rings[i].toJson()!)")
        }
    }
    
    func getScore(x: Double, y: Double, radius: Double) -> Int {
        let circle = Circle(x: x, y: y, radius: radius)
        for i in 0..<self.rings.count {
            if isCircleOverlappingEllipse(circle: circle, ellipse: self.rings[i].ellipse) {
                print("getScore \(i) \(self.rings[i].score)")
                print("circle: \(circle.toJson()!) ellipse: \(self.rings[i].ellipse.toJson()!)")
                return self.rings[i].score
            }
        }
        print("getScore failed")
        return 0
    }
}
