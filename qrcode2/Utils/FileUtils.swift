//
//  FileUtils.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/24/25.
//
import Foundation

func deleteAllTemporaryFiles() {
    let fileManager = FileManager.default
    let tempDirectory = NSTemporaryDirectory()

    do {
        // Get the list of all files in the temporary directory
        let tempFiles = try fileManager.contentsOfDirectory(atPath: tempDirectory)
        
        for file in tempFiles {
            let filePath = (tempDirectory as NSString).appendingPathComponent(file)
            
            do {
                // Delete each file
                try fileManager.removeItem(atPath: filePath)
//                print("Deleted: \(filePath)")
            } catch let error {
                print("Failed to delete \(filePath): \(error)")
            }
        }
//        print("All temporary files deleted successfully.")
    } catch let error {
        print("Failed to get contents of temp directory: \(error)")
    }
}

