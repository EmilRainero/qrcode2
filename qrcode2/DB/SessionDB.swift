//
//  SessionDB.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/26/25.
//
import Foundation


extension DB {
    
    class Session {
        var id: Int64?
        var data: String
        var starttime: Date
        
        init(id: Int64?, data: String, starttime: Date) {
            self.id = id
            self.data = data
            self.starttime = starttime
        }
        
        func toString() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let formattedStartTime = dateFormatter.string(from: starttime)
            return "Session:  Start Time: \(formattedStartTime)"
        }
        func print() {
            Swift.print(self.toString())
        }
        
        func toSession() -> Models.Session {
            let session = Models.Session(
                starttime: self.starttime
            )
            
            return session
        }
        
//        class fromModelSession(session: Models.Session) -> DB.Session {
//
//        }
    }
}
