//
//  DatabaseManager.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/24/25.
//

import Foundation
import SQLite

extension DB {
    
    class DataAccess {
        var databaseFilename = nil as String?
        let id = SQLite.Expression<String>(value: "id")
        let data = SQLite.Expression<String>(value: "data")
        let starttime = SQLite.Expression<Date>("starttime")

        init(_ databaseFilename: String) {
            self.databaseFilename = databaseFilename
        }
            
        func createSession(session: Session) -> Int64? {
            do {
                let db = try Connection(fileName())
                let formatter = ISO8601DateFormatter()            
                let stmt = try db.prepare("INSERT INTO sessions (id, data, starttime) VALUES (?, ?, ?)")
                try stmt.run(session.id, session.data, formatter.string(from: session.starttime))
                return db.lastInsertRowid
            } catch {
                print("ERROR: \(error)")
            }
            return nil
        }
        
        func getSession(id: String) -> Session? {
            do {
                let db = try Connection(fileName())
                let query = "SELECT id, data, starttime FROM sessions WHERE id = \(id)"
                for row in try db.prepare(query) {
                    let dateFormatter = ISO8601DateFormatter()
//                    dateFormatter.timeZone = TimeZone.current
                    
                    let starttimeString = row[2] as? String
                    guard let starttime = dateFormatter.date(from: starttimeString!) else {
                        continue // Skip rows with invalid starttime
                    }
        
                    let session = Session(
                        id: (row[0] as? String)!,
                        data: (row[1] as? String)!,
                        starttime: starttime
                    )
                    return session
                }
            } catch {
                print("ERROR: \(error)")
            }
            return nil
        }
        
        func getAllSessions() -> [Session] {
            var sessions = [Session]()
            
            do {
                let db = try Connection(fileName())
                let dateFormatter = ISO8601DateFormatter()
//                dateFormatter.timeZone = TimeZone.current
                
                for row in try db.prepare("SELECT id, data, starttime FROM sessions ORDER BY starttime DESC") {
                    let starttimeString = row[2] as? String
                    guard let starttime = dateFormatter.date(from: starttimeString!) else {
                        continue // Skip rows with invalid starttime
                    }
                    
                    let session = Session(
                        id: (row[0] as? String)!,
                        data: (row[1] as? String)!,
                        starttime: starttime
                    )
                    sessions.append(session)
                }
            } catch {
                print("ERROR: \(error)")
            }
            
            return sessions
        }
        
        func fileName() -> String {
            // Use FileManager to get the Documents directory path
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentDirectory.appendingPathComponent(databaseFilename!).path
            return dbPath
        }
        
        func initTables() {
            do {
                let db = try Connection(fileName())
                try initSessionsTable(db: db)
            } catch {
                print("ERROR: \(error)")
            }
        }
        
        func dropTables() {
            do {
                let db = try Connection(fileName())
                let sessions = Table("sessions")
                try db.run(sessions.drop(ifExists: true))
            } catch {
                print("ERROR: \(error)")
            }
        }
        
        private func initSessionsTable(db: Connection) throws {
            let sessions = Table("sessions")

            let command = sessions.create { t in
                t.column(id, primaryKey: true)
                t.column(data)
                t.column(starttime)
            }
            try db.run(command)
            
        }
    }

}


func testDB() {
    return

    let dataAccess = DB.DataAccess("db.sqlite3")
    dataAccess.dropTables()
    dataAccess.initTables()
    
    var currentDate = Date() // Current date and time
    for i in 1...5 {
        let startdate = currentDate
        let finishdate = startdate.addingTimeInterval(75)
        
        let msession = Models.Session(starttime: startdate)
        var shotDate = currentDate.addingTimeInterval(1)
        for _ in 0...5 {
            msession.addShot(shot: Models.Shot(time: shotDate, angle: 0.0, distance: 0.5, score: 5))
            shotDate = shotDate.addingTimeInterval(1)
        }
        msession.finish(finishtime: finishdate)
        let rowId = dataAccess.createSession(session: DB.Session(id: "\(i)", data: msession.toJson(), starttime: startdate))
//        print("New session created with ID: \(rowId!)")
        
        currentDate = currentDate.addingTimeInterval(60)
    }
    
    currentDate = currentDate.addingTimeInterval(-24 * 3600)
    let finishdate = currentDate.addingTimeInterval(75)

    var msession = Models.Session(starttime: currentDate)
    msession.addShot(shot: Models.Shot(time: finishdate, angle: 0.0, distance: 0.5, score: 5))
    msession.finish(finishtime: finishdate)
    var rowId = dataAccess.createSession(session: DB.Session(id: "6", data: msession.toJson(), starttime: currentDate))
    
//    print("New session created with ID: \(rowId!)")
//    rowId = dataAccess.createSession(session: DB.Session(id: "1", data: data, starttime: Date()))
//    print("New session created with ID: \(rowId!)")
//    rowId = dataAccess.createSession(session: DB.Session(id: "2'", data: data, starttime: Date()))
//    print("New session created with ID: \(rowId!)")

//    let session = dataAccess.getSession(id: "1")!
//    print("Found session: \(session.id)  - \(session.data) \(session.starttime)")
    
//    print(session.data)
//    let newSession = Models.Session.fromJson(json: session.data)
//    print(newSession!.toJson())
    
    let sessions = dataAccess.getAllSessions()
    for session in sessions {
//        print(session.toString())
        print("Session: \(session.id)  - \(session.starttime)")
    }
    
//    dataAccess.dropTables()
}
