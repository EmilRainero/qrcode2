//
//  TimeUtils.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/18/25.
//
import Foundation

func formatDateToLocalTime(date: Date, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.timeZone = TimeZone.current // Set to the device's local time zone
    return formatter.string(from: date)
}

func computeDuration(start: Date, finish: Date) -> String {
    let duration = finish.timeIntervalSince(start) // Duration in seconds

    // Convert duration to hours, minutes, and seconds
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60

    guard duration != 0 else { return "0s" }

    var result = ""
    if hours > 0 {
        result = String(format: "%dh", hours)
    }
    if minutes > 0 {
        if result.count > 0 {
            result = result + ":"
        }
        result = result + String(format: "%02dm", minutes)
    }
    if seconds > 0 {
        if result.count > 0 {
            result = result + ":"
        }
        result = result + String(format: "%02ds", seconds)
    }
    
    return result
}
