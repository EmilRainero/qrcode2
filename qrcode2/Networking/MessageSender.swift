//
//  MessageSender.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/30/25.
//

import Foundation
import SQLite

class MessageSender {

    private let messageQueue: DispatchQueue
    private let dbPath: String
    private var db: Connection?
    private let dbQueue: DispatchQueue

    init(dbPath: String) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentDirectory.appendingPathComponent(dbPath).path
        
        self.dbPath = fullPath
        self.messageQueue = DispatchQueue(label: "com.example.messageQueue", qos: .userInitiated)
        self.dbQueue = DispatchQueue(label: "com.example.dbQueue")

        dbQueue.sync {
            do {
                self.db = try Connection(self.dbPath)

                let messages = Table("messages")

                let command = messages.create { t in
                    t.column(id, primaryKey: .autoincrement)
                    t.column(message)
                    t.column(timestamp)
                    t.column(sent)
                }
                do {
                    try db!.run(command)
                } catch let error as SQLite.Result {
//                    print("Table 'messages' already exists. \(error)")
                } catch {
                    fatalError("Error creating table: \(error)")
                }
                self.deleteAllMessages()
//                try self.db?.run("""
//                    CREATE TABLE IF NOT EXISTS messages (
//                        id INTEGER PRIMARY KEY AUTOINCREMENT,
//                        message TEXT NOT NULL,
//                        timestamp REAL NOT NULL,
//                        sent INTEGER NOT NULL DEFAULT 0
//                    )
//                """)
            } catch {
                fatalError("Failed to open database: \(error)")
            }
        }
    }

    deinit {
        dbQueue.sync {
            self.db = nil
        }
    }

    func sendMessage(message: String) {
        print("sendMessage \(message)")
        
        weak var weakSelf = self
        dbQueue.async { [weak weakSelf] in
            guard let self = weakSelf, let db = self.db else {
                print("MessageSender or database deallocated")
                return
            }

            do {
                let formatter = ISO8601DateFormatter()
                let stmt = try db.prepare("INSERT INTO messages (message, timestamp, sent) VALUES (?, ?, ?)")
                try stmt.run(message, formatter.string(from: Date()), 0)
//                let rowid =  db.lastInsertRowid
                
//                print("Message inserted successfully with ID: \(rowid), Message: \(message)")
//                self.printTableContents()

            } catch {
                print("Error inserting message: \(error)")
            }
        }

        weak var weakSelfForMessageQueue = self
        messageQueue.async { [weak weakSelfForMessageQueue] in
            weakSelfForMessageQueue?.processQueue()
        }
    }

    private var messages: Table {
        return Table("messages")
    }

    private var id = SQLite.Expression<Int64>("id")
    private var message = SQLite.Expression<String>(value: "message")
    private var timestamp = SQLite.Expression<Date>("timestamp")
    private var sent = SQLite.Expression<Int64>("sent")

    private var isProcessing = false // Flag to track processing state

    private func processQueue() {
        guard !isProcessing else { return } // Already processing, do nothing

        isProcessing = true // Set flag to true

        messageQueue.async { [weak self] in
            guard let self = self else { return }

            let messageData = self.getNextMessage()

            if let (id, message) = messageData {
//                print("\(Date()) \(message)")
                self.sendRESTRequest(message: message) { [weak self] success in
                    guard let self = self else { return }

                    if success {
                        self.markMessageAsSent(id: id)
                        self.deleteMessage(id: id)
                        self.isProcessing = false // Reset flag *after* successful processing
                        self.processQueue() // Process the next message immediately
                    } else {
                        let retryDelay = 1  // Int.random(in: 5...10)
//                        print("\tRETRYING in \(retryDelay) seconds...")

                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryDelay)) { [weak self] in
                            guard let self = self else { return }
                            self.isProcessing = false // Reset flag *before* retrying
                            self.processQueue() // Retry after delay
                        }
                    }
                }
            } else {
                // No messages to process currently. Check again later.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    guard let self = self else { return }
                    self.isProcessing = false // Reset flag *before* checking again
                    self.processQueue()
                }
            }
        }
    }
    
    private func getMessagesToProcess() -> [(id: Int, message: String)] {
        var messages: [(id: Int, message: String)] = []
        while let messageData = self.getNextMessage() {
            messages.append(messageData)
        }
        return messages
    }
    
    private func getNextMessage() -> (id: Int, message: String)? {
        var result: (id: Int, message: String)? = nil

        dbQueue.sync { [weak self] in
            guard let self = self, let db = self.db else { return }

            do {
                let query = "SELECT id, message FROM messages WHERE sent = 0 ORDER BY timestamp LIMIT 1"
                for row in try db.prepare(query) {
                    result = (id: Int((row[0] as? Int64)!), message: (row[1] as? String)!)
                }
//                for row in try db.prepare(self.messages.filter(self.sent == 0).order(self.timestamp).limit(1)) {
//                    let idValue = try row.get(self.id)
//                    let messageValue = try row.get(self.message)
//                    result = (id: Int(idValue), message: messageValue)
//                }
            } catch {
                print("Error getting next message: \(error)")
            }
        }
        return result
    }

    private func sendRESTRequest(message: String, completion: @escaping (Bool) -> Void) {
//        let urlString = "YOUR_REST_API_ENDPOINT" // Replace with your endpoint
//        guard let url = URL(string: urlString) else {
//            print("Invalid URL")
//            completion(false)
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let parameters = ["message": message]
//        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters) else {
//            print("Error serializing JSON")
//            completion(false)
//            return
//        }
//        request.httpBody = httpBody
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error sending request: \(error)")
//                completion(false)
//                return
//            }
//
//            if let httpResponse = response as? HTTPURLResponse,
//               (200...299).contains(httpResponse.statusCode) {
//                print("Message sent successfully")
//                completion(true)
//            } else {
//                print("Request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
//                completion(false)
//            }
//        }
//
//        task.resume()
        let value = Double.random(in: 0.0...1.0)
        if value < 0.8 {
            completion(true)
            print("\(Date()) SENT \(message)")
        } else {
            completion(false)
            print("\(Date()) FAILED TO SEND \(message)")

        }

    }

    func markMessageAsSent(id: Int) {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else {
                print("MessageSender or database deallocated")
                return
            }

            do {
//                let updateStatement = self.messages.filter(self.id == Int64(id)).update(self.sent <- 1)
//                try db.run(updateStatement)

                let updateStatement = "UPDATE messages SET sent = 1 WHERE id = ?" // Raw SQL
                try db.run(updateStatement, [Int64(id)]) // Pass id as a parameter
                
//                print("Message with ID \(id) marked as sent.")
//                self.printTableContents() // Optional: Print table contents after update

            } catch {
                print("Error marking message as sent: \(error)")
            }
        }
    }

    func deleteAllMessages() {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else {
                print("MessageSender or database deallocated")
                return
            }

            do {
                let deleteStatement = "DELETE FROM messages" // Raw SQL
                try db.run(deleteStatement)

//                print("All messages deleted.")
//                self.printTableContents() // Optional: Print table contents

            } catch {
                print("Error deleting all messages: \(error)")
            }
        }
    }
    
    private func deleteMessage(id: Int) {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else { return }

            do {
                let messageToDelete = self.messages.filter(self.id == Int64(id)) // Filter by ID
                try db.run(messageToDelete.delete()) // Delete matching rows

//                print("Message with ID \(id) deleted successfully.")
//                self.printTableContents()
            } catch {
                print("Error deleting message: \(error)")
            }
        }
    }

    private func printTableContents() {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else {
                print("MessageSender or database deallocated")
                return
            }

            do {
                for row in try db.prepare("SELECT id, message, timestamp, sent FROM messages ORDER BY timestamp DESC") {
                    print(row)
                }
            } catch {
                print("Error printing table contents: \(error)")
            }
        }
    }
}

// Example usage:
func testMessageSender(messageSender: MessageSender) {
    for i in 1...100 {
        messageSender.sendMessage(message: "Hello, world! \(i)")
    }
//    messageSender.sendMessage(message: "Hello, world!")
//    messageSender.sendMessage(message: "Another message!")
//    messageSender.sendMessage(message: "Third message!")
}
