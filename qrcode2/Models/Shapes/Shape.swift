//
//  Shape.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/20/24.
//

import Foundation

extension Models {
    
    class func isCircleOverlappingEllipse(circle: Circle, ellipse: Ellipse) -> Bool {
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
    
}
