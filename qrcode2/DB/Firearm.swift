//
//  Firearm.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/16/25.
//

import Foundation

extension DB {
    
    struct Firearm: Identifiable, Codable {
        let id: UUID
        let title: String
        let type: String
        let caliber: String
        
        // Custom initializer to provide an ID when needed
        init(id: UUID = UUID(), title: String, type: String, caliber: String) {
            self.id = id
            self.title = title
            self.type = type
            self.caliber = caliber
        }
    }
}
