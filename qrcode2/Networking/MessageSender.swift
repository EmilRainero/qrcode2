//
//  MessageSender.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/30/25.
//

import Foundation
import SQLite

// Define notification name
extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
}

class MessageSender {

    private let messageQueue: DispatchQueue
    private let dbPath: String
    private let url: String
    private var db: Connection?
    private let dbQueue: DispatchQueue
    private let authToken: String?
    public let server: Server?
    private let fake_send: Bool = true

    init(dbPath: String, url: String) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentDirectory.appendingPathComponent(dbPath).path
        self.url = url
        
        if let token = KeychainManager.shared.retrieveToken(forKey: "authToken") {
            self.authToken = token
        } else {
            self.authToken = nil
        }
        self.dbPath = fullPath
        self.messageQueue = DispatchQueue(label: "com.example.messageQueue", qos: .userInitiated)
        self.dbQueue = DispatchQueue(label: "com.example.dbQueue")
        self.server = Server(baseURL: "http://192.168.5.6:5001", token: self.authToken)

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
    private var retryDelay: Double = 2.0
    private var checkMessages: Double = 0.5

    private var isProcessing = false // Flag to track processing state

//    private func processQueue() {
//        guard !isProcessing else { return } // Already processing, do nothing
//
//        isProcessing = true // Set flag to true
//
//        messageQueue.async { [weak self] in
//            guard let self = self else { return }
//
//            let messageData = self.getNextMessage()
//
//            if let (id, message) = messageData {
//                self.sendRESTRequest(message: message) { [weak self] success in
//                    guard let self = self else { return }
//
//                    if success {
//                        self.markMessageAsSent(id: id)
//                        self.deleteMessage(id: id)
//                        self.isProcessing = false // Reset flag *after* successful processing
//                        self.processQueue() // Process the next message immediately
//                    } else {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay) { [weak self] in
//                            guard let self = self else { return }
//                            self.isProcessing = false // Reset flag *before* retrying
//                            self.processQueue() // Retry after delay
//                        }
//                    }
//                }
//            } else {
//                // No messages to process currently. Check again later.
//                DispatchQueue.main.asyncAfter(deadline: .now() + self.checkMessages) { [weak self] in
//                    guard let self = self else { return }
//                    self.isProcessing = false // Reset flag *before* checking again
//                    self.processQueue()
//                }
//            }
//        }
//    }
    
    private func processQueue() {
        guard !isProcessing else { return } // Already processing, do nothing

        isProcessing = true // Set flag to true

        messageQueue.async { [weak self] in
            guard let self = self else { return }

            let messageData = self.getNextMessage()

            if let (id, message) = messageData {
                self.sendRESTRequest(message: message) { [weak self] success in
                    guard let self = self else { return }

                    if success {
                        self.markMessageAsSent(id: id)
                        self.deleteMessage(id: id)
                        self.isProcessing = false // Reset flag *after* successful processing
                        self.processQueue() // Process the next message immediately
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay) { [weak self] in
                            guard let self = self else { return }
                            self.isProcessing = false // Reset flag *before* retrying
                            self.processQueue() // Retry after delay
                        }
                    }
                }
            } else {
                // No messages to process currently. Wait for a new message or check later
                isProcessing = false // Reset flag to allow new triggers
            }
        }
    }

    // Call this when adding new messages to the queue
    func addMessage(_ message: String) {
        sendMessage(message: message) // Assume this stores message persistently
        NotificationCenter.default.post(name: .newMessageReceived, object: nil) // Notify
    }

    // Start listening for new messages
    private func setupMessageListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewMessage), name: .newMessageReceived, object: nil)
    }

    // Handle notification and restart queue processing
    @objc private func handleNewMessage() {
        processQueue()
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
        print("\(Date())  SEND URL: \(self.url)  command: \(message)")
        if self.fake_send {
            completion(true)
            return
        }
        
        let result = self.server!.sendUpdates(body: message)
        if result.success {
            print("\(Date()) SENT \(message)")
        } else {
            print("\(Date()) FAILED TO SEND \(message)")
            if result.errorMessage != nil {
                print("Error: \(result)")
            }
        }
        completion(result.success)
//        let value = Double.random(in: 0.0...1.0)
//        if value < 0.8 {
//            completion(true)
//            print("\(Date()) SENT \(message)")
//        } else {
//            completion(false)
//            print("\(Date()) FAILED TO SEND \(message)")
//
//        }

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
    for i in 1...10 {
        let message = "Hello, world! \(i)"
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(i)) { // Delay each message
            print("\(Date())  TRY TO SEND \(message)")
            messageSender.sendMessage(message: message)
        }
        
    }
}
