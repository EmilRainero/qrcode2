//
//  Shot.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/20/24.
//

import SwiftUI
import Foundation

class Shot {
    var time: Double
    var position: CGPoint
    var allShots: [Shot] = []

    init(time: Double, position: CGPoint) {
        self.time = time
        self.position = position
        self.addAdditionalShots(time: time, position: position)
    }

    func description() -> String {
        return "Shot - \(time)  position: \(position)"
    }
    
    func addAdditionalShots(time: Double, position: CGPoint) {
        let shot = Shot(time: time, position: position)
        self.allShots.append(shot)
    }
    
    func driftAngle() -> Double? {
        guard self.allShots.count >= 2 else {
            return nil // Not enough points to calculate drift angle
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
        
        return angleDegrees
    }
}

