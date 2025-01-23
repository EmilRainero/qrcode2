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
