//
//  Ellipse.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/26/25.
//
import Foundation


extension Models {
    
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
        
        // create a function to compute the closest distance from x,y to the edge of the ellipse
        func distanceFromEdge(x: Double, y: Double) -> Double {
            let a = self.majorAxis / 2
            let b = self.minorAxis / 2
            let dx = x - self.centerx
            let dy = y - self.centery
            let ellipseEquation = pow(dx, 2) / pow(a, 2) + pow(dy, 2) / pow(b, 2)
            if ellipseEquation <= 1 {
                // if inside compute to edge of ellipse
                let distance = min(abs(dx) - a, abs(dy) - b)
                return distance
            }
            let closestX = max(self.centerx - a, min(x, self.centerx + a))
            let closestY = max(self.centery - b, min(y, self.centery + b))
            let distance = sqrt(pow(closestX - x, 2) + pow(closestY - y, 2))
            return distance
        }
        
        func distanceFromPoint(x: Double, y: Double) -> Double {
            let dx = x - centerx
            let dy = y - centery
            let a = majorAxis / 2.0
            let b = minorAxis / 2.0
            
            // Check if the point is inside or outside the ellipse
            let value = (dx * dx) / (a * a) + (dy * dy) / (b * b)
            
            if value < 1 {
                // Inside: Find the farthest distance to the edge
                return farthestDistanceToEdge(dx: dx, dy: dy, a: a, b: b)
            } else {
                // Outside: Find the closest distance to the edge
                return closestDistanceToEdge(dx: dx, dy: dy, a: a, b: b)
            }
        }
        
        private func closestDistanceToEdge(dx: Double, dy: Double, a: Double, b: Double) -> Double {
            let theta = atan2(dy, dx)
            let edgeX = a * cos(theta)
            let edgeY = b * sin(theta)
            let edgeDistance = sqrt(pow(edgeX - dx, 2) + pow(edgeY - dy, 2))
            return edgeDistance
        }
        
        private func farthestDistanceToEdge(dx: Double, dy: Double, a: Double, b: Double) -> Double {
            let theta = atan2(dy, dx)
            let edgeX = a * cos(theta)
            let edgeY = b * sin(theta)
            let edgeDistance = sqrt(pow(edgeX + dx, 2) + pow(edgeY + dy, 2))
            return edgeDistance
        }
        
        // angle is in degrees
        func distanceToEdge(angle angle: Double) -> Double {
            let a = majorAxis / 2.0 // Semi-major axis
            let b = minorAxis / 2.0 // Semi-minor axis
            
            let angleRadians = angle * (.pi / 180.0)
            // Compute the distance using the formula
            let numerator = a * b
            let denominator = sqrt(pow(b * cos(angleRadians), 2) + pow(a * sin(angleRadians), 2))
            return numerator / denominator
        }
    }
    
}
