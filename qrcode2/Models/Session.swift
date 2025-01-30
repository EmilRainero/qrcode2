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
        
        func createTargetImageWithShots(size: CGSize) -> UIImage? {
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                let strokeColor = UIColor.black
                let lineWidth = 4.0

                let cgContext = context.cgContext
                cgContext.setLineWidth(lineWidth)
                cgContext.setLineJoin(.miter)
                cgContext.setLineCap(.square)
                
                let maxRadius = size.width / 2.0 - 10.0
                let center = CGPoint(x: CGFloat(size.width/2), y: CGFloat(size.height/2))
                
                cgContext.setFillColor(strokeColor.cgColor)
                cgContext.setStrokeColor(strokeColor.cgColor)

                // draw target
                for i in 1...10 {
                    let radius = maxRadius * CGFloat(i) / 10.0
                    let circleRect = CGRect(x: center.x-radius, y: center.y-radius, width: radius * 2, height: radius * 2)
                    cgContext.addEllipse(in: circleRect)
                    if i == 1 {
                        cgContext.fillPath()
                    } else {
                        cgContext.strokePath()
                    }
                }
                
                // draw shots
                for (index, shot) in self.shots.enumerated() {
                    let position = shot.position
                    let angle = position.angle
                    let distance = position.distance
                    
//                    print("\(angle), \(distance)")
                    
                    var point = polarToCartesian(angle: angle - 90.0, distance: distance)
                    point = CGPoint(x: point.x * maxRadius + center.x, y: point.y * maxRadius + center.y)
                    
//                    print("\(angle), \(distance)  \(point)")

                    let shotRadius = 15.0
                    let circleRect = CGRect(x: point.x - shotRadius, y: point.y - shotRadius, width: shotRadius * 2, height: shotRadius * 2)
                    
                    // Draw shot circle
                    cgContext.addEllipse(in: circleRect)
                    cgContext.setFillColor(UIColor.red.cgColor)

                    cgContext.fillPath()
                    
                    // Draw text (shot number)
                    let shotNumber = "\((index + 1))"  // Convert index to string (1-based index)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 18),
                        .foregroundColor: UIColor.white
                    ]
                    
                    let textSize = shotNumber.size(withAttributes: attributes)
                    let textPoint = CGPoint(x: point.x - textSize.width / 2, y: point.y - textSize.height / 2)
                    
                    shotNumber.draw(at: textPoint, withAttributes: attributes)
                }
                
            }
        }
    }
     
}

func polarToCartesian(angle: CGFloat, distance: CGFloat) -> CGPoint {
    let radians = angle * .pi / 180  // Convert degrees to radians
    let x = distance * cos(radians)
    let y = distance * sin(radians)
    return CGPoint(x: x, y: y)
}
