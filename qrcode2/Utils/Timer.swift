//
//  Timer.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/3/25.
//

import CoreFoundation

class Timer {
    private var before: Double = 0
    
    func start() {
        self.before = CFAbsoluteTimeGetCurrent()
    }
    
    func stop() -> Double {
        return CFAbsoluteTimeGetCurrent() - self.before
    }
}
