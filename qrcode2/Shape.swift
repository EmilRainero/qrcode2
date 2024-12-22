//
//  Shape.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/20/24.
//

import Foundation


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

// Ellipse subclass
class Ellipse: Codable {
    var centerx: Double
    var centery: Double
    var majorAxis: Double
    var minorAxis: Double

    init(centerx: Double, centery: Double, majorAxis: Double, minorAxis: Double) {
        self.centerx = centerx
        self.centery = centery
        self.majorAxis = majorAxis
        self.minorAxis = minorAxis
    }

    func area() -> Double {
        return Double.pi * majorAxis * minorAxis
    }
    
    func toJson() -> String? {
        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted // Makes JSON output readable
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to encode Ellipse to JSON: \(error)")
            return nil
        }
    }
    
    func getCGPoint() -> CGPoint {
        return CGPoint(x: self.centerx - self.majorAxis/2, y: self.centery - self.minorAxis/2)
    }
    
    func getCGSize() -> CGSize {
        return CGSize(width: self.majorAxis, height: self.minorAxis)
    }
}

func isCircleOverlappingEllipse(circle: Circle, ellipse: Ellipse) -> Bool {
    let a = ellipse.majorAxis / 2
    let b = ellipse.minorAxis / 2

    // Check if the circle's center is inside the ellipse
    let ellipseEquation = pow(circle.x - ellipse.centerx, 2) / pow(a, 2) + pow(circle.y - ellipse.centery, 2) / pow(b, 2)
    if ellipseEquation <= 1 {
        return true
    }

    // Find the closest point on the ellipse's bounding box to the circle's center
    let closestX = max(ellipse.centerx - a, min(circle.x, ellipse.centerx + a))
    let closestY = max(ellipse.centery - b, min(circle.y, ellipse.centery + b))

    // Calculate the distance between the circle's center and the closest point
    let distance = sqrt(pow(closestX - circle.x, 2) + pow(closestY - circle.y, 2))

    // Check if the distance is less than or equal to the circle's radius
    return distance <= circle.radius
}
