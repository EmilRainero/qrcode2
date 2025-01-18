//
//  Session.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/18/25.
//

import SwiftUI


class Session {
    var id: String
    var starttime: Date
    var shots: [Shot]
    
    init(starttime: Date) {
        self.id = UUID().uuidString
        self.starttime = starttime
        self.shots = []
    }
    
    func addShot(shot: Shot) {
        self.shots.append(shot)
    }
    
    func description() -> String {
        return "Session - Starttime: \(self.starttime)  # Shots: \(self.shots.count)"
    }
}
