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
    var email: String
    
    init(id: Int64?, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

class DataAccess {
    var databaseFilename = nil as String?
    let id = SQLite.Expression<Int64>("id")
    let name = SQLite.Expression<String>(value: "name")
    let email = SQLite.Expression<String>(value: "email")
    
    init(_ databaseFilename: String) {
        self.databaseFilename = databaseFilename
    }
        
    func createSession(session: SessionDB) -> Int64? {
        do {
            let db = try Connection(fileName())
            let stmt = try db.prepare("INSERT INTO sessions (name, email) VALUES (?, ?)")
            try stmt.run(session.name, session.email)
            return db.lastInsertRowid
        } catch {
            print("ERROR: \(error)")
        }
        return nil
    }
    
    func getSession(id: Int64) -> SessionDB? {
        do {
            let db = try Connection(fileName())
            let query = "SELECT id, name, email FROM sessions WHERE id = \(id)"
            for row in try db.prepare(query) {
                let session = SessionDB(
                    id: row[0] as? Int64,
                    name: (row[1] as? String)!,
                    email: (row[2] as? String)!
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
            
            for row in try db.prepare("SELECT id, name, email FROM sessions") {
                let session = SessionDB(
                    id: row[0] as? Int64,
                    name: (row[1] as? String)!,
                    email: (row[2] as? String)!
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
            t.column(email)
        }
        try db.run(command)
        
    }
}

func testDB() {
    let dataAccess = DataAccess("db.sqlite3")
    dataAccess.dropTables()

    dataAccess.initTables()
    
    var rowId = dataAccess.createSession(session: SessionDB(id: nil, name: "John Doe", email: "johndoe@example.com"))
    print("New session created with ID: \(rowId!)")
    rowId = dataAccess.createSession(session: SessionDB(id: nil, name: "Emil", email: "emil@example.com"))
    print("New session created with ID: \(rowId!)")
    rowId = dataAccess.createSession(session: SessionDB(id: nil, name: "Susan", email: "susan@example.com"))
    print("New session created with ID: \(rowId!)")

    let session = dataAccess.getSession(id: 2)!
    print("Found session: \(session.id!)  \(session.name) - \(session.email)")

    let sessions = dataAccess.getAllSessions()
    for session in sessions {
        print("Session: \(session.id!)  \(session.name) - \(session.email)")
    }
    dataAccess.dropTables()
}

func fileName() -> String {
    // Use FileManager to get the Documents directory path
    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dbPath = documentDirectory.appendingPathComponent("db.sqlite3").path
    return dbPath
}

func testDB2() {
    do {
        let db = try Connection(fileName())

        let users = Table("users")
        try db.run(users.drop(ifExists: true))

        let id = SQLite.Expression<Int64>("id")
        let name = Expression<String?>(value: "name")
        let email = Expression<String>(value: "email")

        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(email, unique: true)
        })
        
        var stmt = try db.prepare("INSERT INTO users (name, email) VALUES (?, ?)")
        try stmt.run("Alice", "alice@mac.com")
        print(db.lastInsertRowid)
        try stmt.run("Emil", "Emil@mac.com")
        print(db.lastInsertRowid)
        try stmt.run("John", "John@mac.com")
        print(db.lastInsertRowid)
        for row in try db.prepare("SELECT id, name, email FROM users") {
            print("id: \(row[0]!), name: \(row[1]!)  email: \(row[2]!)")
        }

//        let alice = users.filter(id == 1)
//        let update = alice.update(email <- "new@gmail.com")
        stmt = try db.prepare("UPDATE users SET email = ? WHERE (\"id\" = ?)")
//        print(update)
        try stmt.run("foo@gmail.com", 1)
        for row in try db.prepare("SELECT id, name, email FROM users") {
            print("id: \(row[0]!), name: \(row[1]!)  email: \(row[2]!)")
        }
        stmt = try db.prepare("DELETE FROM \"users\" WHERE (\"id\" = ?)")
        try stmt.run(2)
        for row in try db.prepare("SELECT id, name, email FROM users") {
            print("id: \(row[0]!), name: \(row[1]!)  email: \(row[2]!)")
        }
        
//        try db.run(alice.delete())
        // DELETE FROM "users" WHERE ("id" = 1)
        
        let count = try db.scalar(users.count) // 0
        print(count)
        // SELECT count(*) FROM "users"
    } catch {
        print (error)
    }
}
