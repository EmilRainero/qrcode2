//
//  DetectLaserSpot.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/14/24.
//

import UIKit
import CoreImage

func detectLaserSpot(in image: UIImage) -> CGRect? {
    // Convert the UIImage to a CIImage
    guard let cgImage = image.cgImage else { return nil }
    let ciImage = CIImage(cgImage: cgImage)
    
    // Convert the image to grayscale
    guard let grayscaleImage = applyGrayscaleFilter(to: ciImage) else { return nil }
    
    print("threshold")
    // Apply thresholding to find bright spots
    guard let thresholdImage = applyThreshold(to: grayscaleImage, threshold: 230) else { return nil }
    
    print("thresholded")
    print(thresholdImage)
    
    let dilatedImage = dilateImage(thresholdImage)!
    
    print("dialated")

    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("thresholded_image.jpg")
    saveImage(dilatedImage, to: fileURL)
    
    if let connectedComponents = computeConnectedComponents(from: dilatedImage, threshold: 230) {
        for component in connectedComponents {
            // Print the label and the bounding box of each component
            print("Component \(component.label):")
            print("Bounding Box: \(component.boundingBox)")
        }
    }

    return nil
}

