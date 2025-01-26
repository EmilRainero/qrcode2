//
//  Session.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/18/25.
//

import SwiftUI

extension Models {
    
    class Session: Codable {
        var id: String
        var starttime: Date
        var finishtime: Date? = nil
        var shots: [Shot]
        var score: Int32
        
        init(starttime: Date) {
            self.id = UUID().uuidString
            self.starttime = starttime
            self.shots = []
            self.score = 0
        }
        
        func addShot(shot: Shot) {
            self.shots.append(shot)
            self.score += shot.score
        }
        
        func description() -> String {
            return "Session - Starttime: \(self.starttime)  # Shots: \(self.shots.count)"
        }
        
        func finish(finishtime: Date) {
            self.finishtime = finishtime
        }
        
        func toJson() -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .custom { (date, encoder) in
                let formatter = DateFormatter()
                formatter.dateFormat = TIME_FORMAT
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let dateString = formatter.string(from: date)
                var container = encoder.singleValueContainer()
                try container.encode(dateString)
            }
            
            do {
                let data = try encoder.encode(self)
                return String(data: data, encoding: .utf8) ?? ""
            } catch {
                LoggerManager.log.error("Error encoding to JSON: \(error)")
                return ""
            }
        }
        
    }
     
}
