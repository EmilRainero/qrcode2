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
        
        func shotAverage() -> Double {
            guard !shots.isEmpty else { return 0.0 }
            
            let average = Double(self.score) / Double(self.shots.count)
            return average
        }
        
        func toJson() -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .custom { (date, encoder) in
                let formatter = DateFormatter()
                formatter.dateFormat = TIME_FORMAT
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(abbreviation: "UTC") // Ensures UTC time zone

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
        
        class func fromJson(json: String) -> Session? {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder -> Date in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = TIME_FORMAT // Ensure TIME_FORMAT matches the encoder
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(abbreviation: "UTC") // Ensures UTC time zone
                    
                    if let date = formatter.date(from: dateString) {
                        return date
                    } else {
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Cannot decode date string \(dateString)"
                        )
                    }
                }
                
                let decodedSession = try decoder.decode(Session.self, from: json.data(using: .utf8)!)
                return decodedSession
            } catch {
                print("Error decoding JSON: \(error)")
            }
            return nil
        }
    }
     
}
