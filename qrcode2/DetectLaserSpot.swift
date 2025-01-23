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
     
    // Find the bright spot (laser) - the position with the highest intensity
//    if let laserPosition = findBrightestSpot(in: thresholdImage) {
//        print(laserPosition)
//        return laserPosition
//    }
    
    return nil
}

func dilateImage(_ image: CIImage, kernelSize: Int = 3) -> CIImage? {
    // Create a filter to apply the morphology gradient, simulating dilation
    guard let dilateFilter = CIFilter(name: "CIMorphologyGradient") else {
        print("Failed to create dilate filter")
        return nil
    }
    
    // Set the input image
    dilateFilter.setValue(image, forKey: kCIInputImageKey)
    
    // Create a structuring element (kernel size) to control dilation extent
    let radius = CGFloat(kernelSize)
    let kernel = CIVector(x: radius, y: radius) // Size of dilation
    
    // Apply the dilation filter
    dilateFilter.setValue(kernel, forKey: "inputRadius")
    
    // Return the dilated image
    return dilateFilter.outputImage
}

func saveImage(_ ciImage: CIImage, to url: URL) {
    // Convert CIImage to CGImage using CIContext
    let context = CIContext()
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        print("Error: Could not create CGImage from CIImage")
        return
    }

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


func applyGrayscaleFilter(to image: CIImage) -> CIImage? {
    let grayscaleFilter = CIFilter(name: "CIColorControls")
    grayscaleFilter?.setValue(image, forKey: kCIInputImageKey)
    grayscaleFilter?.setValue(0.0, forKey: kCIInputSaturationKey)  // Remove color (grayscale)
    
    return grayscaleFilter?.outputImage
}

func applyThreshold(to image: CIImage, threshold: CGFloat) -> CIImage? {
    // Create a CIVector for min and max components
    let minComponents = CIVector(x: 0, y: 0, z: 0, w: 0)  // All components set to black (0)
    let maxComponents = CIVector(x: threshold, y: threshold, z: threshold, w: 1) // All components set to the threshold for white (threshold)
    
    // Apply the clamp filter to restrict pixel values based on the threshold
    let clampFilter = CIFilter(name: "CIColorClamp")
    clampFilter?.setValue(image, forKey: kCIInputImageKey)
    clampFilter?.setValue(minComponents, forKey: "inputMinComponents")  // Set minimum values to 0
    clampFilter?.setValue(maxComponents, forKey: "inputMaxComponents")  // Set max values to threshold
    
    return clampFilter?.outputImage
}

