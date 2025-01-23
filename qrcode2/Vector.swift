//
//  Vector.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/23/25.
//


import Foundation

struct Vector: Codable {
    var angle: Double // Angle in radians
    var distance: Double // Distance (magnitude)

    // Convert to Cartesian coordinates
    func toCartesian() -> (x: Double, y: Double) {
        let x = distance * cos(angle)
        let y = distance * sin(angle)
        return (x, y)
    }
    
    func vectorDifference(other: Vector) -> Vector {
        // Convert both vectors to Cartesian coordinates
        let cartesian1 = self.toCartesian()
        let cartesian2 = other.toCartesian()

        // Compute the difference in Cartesian coordinates
        let diffX = cartesian1.x - cartesian2.x
        let diffY = cartesian1.y - cartesian2.y

        // Convert the result back to polar coordinates
        let angle = atan2(diffY, diffX)
        let distance = sqrt(diffX * diffX + diffY * diffY)

        return Vector(angle: angle, distance: distance)
    }
}

// Function to compute the difference between two vectors
func vectorDifference(_ v1: Vector, _ v2: Vector) -> Vector {
    // Convert both vectors to Cartesian coordinates
    let cartesian1 = v1.toCartesian()
    let cartesian2 = v2.toCartesian()

    // Compute the difference in Cartesian coordinates
    let diffX = cartesian1.x - cartesian2.x
    let diffY = cartesian1.y - cartesian2.y

    // Convert the result back to polar coordinates
    let angle = atan2(diffY, diffX)
    let distance = sqrt(diffX * diffX + diffY * diffY)

    return Vector(angle: angle, distance: distance)
}

func testVector() {
    let vector1 = Vector(angle: Double.pi / 4, distance: 5.0) // 45 degrees, distance 5
    let vector2 = Vector(angle: Double.pi / 3, distance: 3.0) // 60 degrees, distance 3

    let result = vectorDifference(vector1, vector2)
    print("Resultant Vector -> Angle: \(result.angle) radians, Distance: \(result.distance)")
}
