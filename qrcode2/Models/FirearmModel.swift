//
//  FirearmModel.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/16/25.
//

import SwiftUI

extension Models {
    
    struct Firearm: Identifiable, Codable {
        let id: UUID  // Now allows a custom ID
        let title: String
        let type: String
        let caliber: String
        let diameter_mm: Double
        
        // Custom initializer to provide an ID when needed
        init(id: UUID = UUID(), title: String, type: String, caliber: String) {
            self.id = id
            self.title = title
            self.type = type
            self.caliber = caliber
            self.diameter_mm = getCaliberDiameter(type: type, caliber: caliber) ?? 0.0
        }
    }
    
    class func getCaliberDiameter(type: String, caliber: String) -> Double? {
        let caliberDiameters: [String: Double] = [
            // Handgun calibers
            "9mm": 9.0,
            ".380 ACP": 9.0,
            ".40 S&W": 10.2,
            ".45 ACP Auto": 11.43,
            "10mm Auto": 10.0,
            "357 Magnum": 9.07,
            "357 SIG": 9.02,
            "38 Special": 9.07,
            "44 Remington Magnum": 10.9,
            "45 Colt": 11.48,

            // Rifle calibers
            "223 Remington": 5.7,
            "5.56 NATO": 5.7,
            "5.7X28mm Rifle": 5.7,
            "6.8x51mm": 6.8,
            "7.62x51mm NATO": 7.62,
            "308 Winchester": 7.82,
            ".30-06": 7.82,
            ".50 BMG": 12.7,

            // Shotgun calibers (Gauge to mm conversion)
            "410 Gauge": 10.4,
            "12 Gauge": 18.5,
            "16 Gauge": 17.0,
            "20 Gauge": 15.6,
            "24 Gauge": 14.7,
            "10 Gauge": 19.7,
            "28 Gauge": 13.9
        ]
        
        return caliberDiameters[caliber]
    }

}
