//
//  LoggerManager.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/7/25.
//
import SwiftyBeaver


class LoggerManager {
    static let log = SwiftyBeaver.self

    static func setup() {
        // Add a console destination
        let console = ConsoleDestination()
        console.minLevel = .info  // Adjust minimum log level
        log.addDestination(console)
    }
}
