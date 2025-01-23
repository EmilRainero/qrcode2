//
//  DetectedQRCode.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/23/25.
//

import SwiftUI
import UIKit

// Struct to store QR code data and corners
public struct DetectedQRCode {
    let message: String
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    let width: CGFloat
    let height: CGFloat
    var frame: Int32?
    
    public init(message: String, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint, width: CGFloat, height: CGFloat) {
        self.message = message
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.width = width
        self.height = height
    }
    
    public func QRCodeApproxEqual(qrcode: DetectedQRCode) -> Bool {
        return CGPointApproxEqual(pt1: self.bottomLeft, pt2: qrcode.bottomLeft) &&
            CGPointApproxEqual(pt1: self.bottomRight, pt2: qrcode.bottomRight) &&
            CGPointApproxEqual(pt1: self.topLeft, pt2: qrcode.topLeft) &&
            CGPointApproxEqual(pt1: self.topRight, pt2: qrcode.topRight)
    }
    
    func CGPointApproxEqual(pt1: CGPoint, pt2: CGPoint) -> Bool {
        return abs(pt1.x - pt2.x) < 3 && abs(pt1.y - pt2.y) < 3
    }
}

func QRCodeApproxEqual(q1: DetectedQRCode, q2: DetectedQRCode) -> Bool {
    return false
}

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}
