//
//  ImageUtils.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/23/25.
//
import UIKit
import CoreImage


func saveCGImage(_ cgImage: CGImage, to url: URL) {
    // Create a UIImage from CGImage
    let image = UIImage(cgImage: cgImage)

    // Save the UIImage to disk
    if let data = image.jpegData(compressionQuality: 1.0) { // Save as JPEG
        do {
            try data.write(to: url)
            print("Image saved successfully at \(url)")
        } catch {
            print("Error saving image: \(error)")
        }
    } else {
        print("Error: Could not convert UIImage to JPEG data")
    }
}
