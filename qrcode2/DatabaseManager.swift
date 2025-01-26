//
//  DatabaseManager.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/24/25.
//

import Foundation
import SQLite

class SessionDB {
    var id: Int64?
    var name: String
    var data: String
    var starttime: Date
    
    init(id: Int64?, name: String, data: String, starttime: Date) {
        self.id = id
        self.name = name
        self.data = data
        self.starttime = starttime
    }
    
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let formattedStartTime = dateFormatter.string(from: starttime)
        return "Session: \(name), Start Time: \(formattedStartTime)"
    }
    func print() {
        Swift.print(self.toString())
    }
}

class DataAccess {
    var databaseFilename = nil as String?
    let id = SQLite.Expression<Int64>("id")
    let name = SQLite.Expression<String>(value: "name")
    let data = SQLite.Expression<String>(value: "data")
    let starttime = SQLite.Expression<Date>("starttime")

    init(_ databaseFilename: String) {
        self.databaseFilename = databaseFilename
    }
        
    func createSession(session: SessionDB) -> Int64? {
        do {
            let db = try Connection(fileName())
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone.current
        
            let stmt = try db.prepare("INSERT INTO sessions (name, data, starttime) VALUES (?, ?, ?)")
            try stmt.run(session.name, session.data, formatter.string(from: session.starttime))
            return db.lastInsertRowid
        } catch {
            print("ERROR: \(error)")
        }
        return nil
    }
    
    func getSession(id: Int64) -> SessionDB? {
        do {
            let db = try Connection(fileName())
            let query = "SELECT id, name, data, starttime FROM sessions WHERE id = \(id)"
            for row in try db.prepare(query) {
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.timeZone = TimeZone.current
                
                let starttimeString = row[3] as? String
                guard let starttime = dateFormatter.date(from: starttimeString!) else {
                    continue // Skip rows with invalid starttime
                }
    
                let session = SessionDB(
                    id: row[0] as? Int64,
                    name: (row[1] as? String)!,
                    data: (row[2] as? String)!,
                    starttime: starttime
                )
                return session
            }
        } catch {
            print("ERROR: \(error)")
        }
        return nil
    }
    
    func getAllSessions() -> [SessionDB] {
        var sessions = [SessionDB]()
        
        do {
            let db = try Connection(fileName())
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = TimeZone.current
            
            for row in try db.prepare("SELECT id, name, data, starttime FROM sessions") {
                let starttimeString = row[3] as? String
                guard let starttime = dateFormatter.date(from: starttimeString!) else {
                    continue // Skip rows with invalid starttime
                }
                
                let session = SessionDB(
                    id: row[0] as? Int64,
                    name: (row[1] as? String)!,
                    data: (row[2] as? String)!,
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
            t.column(id, primaryKey: .autoincrement)
            t.column(name)
            t.column(data)
            t.column(starttime)
        }
        try db.run(command)
        
    }
}

func testDB() {
    return
    
    let dataAccess = DataAccess("db.sqlite3")
    
    dataAccess.initTables()
    
    var rowId = dataAccess.createSession(session: SessionDB(id: nil, name: "John Doe", data: "johndoe@example.com", starttime: Date()))
    print("New session created with ID: \(rowId!)")
    rowId = dataAccess.createSession(session: SessionDB(id: nil, name: "Emil", data: "emil@example.com", starttime: Date()))
    print("New session created with ID: \(rowId!)")
    rowId = dataAccess.createSession(session: SessionDB(id: nil, name: "Susan", data: "susan@example.com", starttime: Date()))
    print("New session created with ID: \(rowId!)")

    let session = dataAccess.getSession(id: 2)!
    print("Found session: \(session.id!)  \(session.name) - \(session.data) \(session.starttime)")

    let sessions = dataAccess.getAllSessions()
    for session in sessions {
        print(session.toString())
        print("Session: \(session.id!)  \(session.name) - \(session.data) \(session.starttime)")
    }
    
//    dataAccess.dropTables()
}

//func fileName() -> String {
//    // Use FileManager to get the Documents directory path
//    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//    let dbPath = documentDirectory.appendingPathComponent("db.sqlite3").path
//    return dbPath
//}
//
//func testDB2() {
//    do {
//        let db = try Connection(fileName())
//
//        let users = Table("users")
//        try db.run(users.drop(ifExists: true))
//
//        let id = SQLite.Expression<Int64>("id")
//        let name = Expression<String?>(value: "name")
//        let email = Expression<String>(value: "email")
//
//        try db.run(users.create { t in
//            t.column(id, primaryKey: true)
//            t.column(name)
//            t.column(email, unique: true)
//        })
//        
//        var stmt = try db.prepare("INSERT INTO users (name, email) VALUES (?, ?)")
//        try stmt.run("Alice", "alice@mac.com")
//        print(db.lastInsertRowid)
//        try stmt.run("Emil", "Emil@mac.com")
//        print(db.lastInsertRowid)
//        try stmt.run("John", "John@mac.com")
//        print(db.lastInsertRowid)
//        for row in try db.prepare("SELECT id, name, email FROM users") {
//            print("id: \(row[0]!), name: \(row[1]!)  email: \(row[2]!)")
//        }
//
//        stmt = try db.prepare("UPDATE users SET email = ? WHERE (\"id\" = ?)")
//        try stmt.run("foo@gmail.com", 1)
//        for row in try db.prepare("SELECT id, name, email FROM users") {
//            print("id: \(row[0]!), name: \(row[1]!)  email: \(row[2]!)")
//        }
//        stmt = try db.prepare("DELETE FROM \"users\" WHERE (\"id\" = ?)")
//        try stmt.run(2)
//        for row in try db.prepare("SELECT id, name, email FROM users") {
//            print("id: \(row[0]!), name: \(row[1]!)  email: \(row[2]!)")
//        }
//        
//        let count = try db.scalar(users.count) // 0
//        print(count)
//    } catch {
//        print (error)
//    }
//}
