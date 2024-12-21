//
//  Shot.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/20/24.
//

import SwiftUI


class Shot {
    var time: Double
    var position: CGPoint

    init(time: Double, position: CGPoint) {
        self.time = time
        self.position = position
    }

    func description() -> String {
        return "Shot - \(time)  position: \(position)"
    }
}

class Session {
    var starttime: Date
    var shots: [Shot]
    
    init(starttime: Date) {
        self.starttime = starttime
        self.shots = []
    }
    
    func addShot(shot: Shot) {
        self.shots.append(shot)
    }
    
    func description() -> String {
        return "Session - Starttime: \(time)  # Shots: \(shots.count)"
    }
}
