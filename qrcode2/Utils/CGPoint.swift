//
//  CGPoint.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/26/25.
//

import UIKit


extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}
