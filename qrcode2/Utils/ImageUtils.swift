//
//  ImageUtils.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/23/25.
//
import UIKit
import CoreImage
import opencv2


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

func saveUIImage(_ image: UIImage, to fileURL: URL) -> Bool {
    // Choose the image format: JPEG or PNG
    guard let data = image.jpegData(compressionQuality: 1.0) else {
        print("Error: Could not create image data")
        return false
    }
    
    do {
        // Write the data to the file
        try data.write(to: fileURL)
        print("Image saved successfully at \(fileURL)")
        return true
    } catch {
        print("Error saving image: \(error)")
        return false
    }
}

func saveMatToFile(mat: Mat, fileName: String) {
    // Define the file path where the image will be saved
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsURL.appendingPathComponent(fileName)

    // Save the Mat to the file path
    if Imgcodecs.imwrite(filename: fileURL.path, img: mat) {
        print("Image successfully saved to \(fileURL.path)")
    } else {
        print("Failed to save the image.")
    }
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

func convertCIImageToUIImage(_ ciImage: CIImage) -> UIImage? {
    // Create a CIContext
    let context = CIContext(options: nil)
    
    // Render the CIImage to a CGImage
    if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
        // Convert the CGImage to a UIImage
        return UIImage(cgImage: cgImage)
    }
    
    // Return nil if conversion fails
    return nil
}

func cropMat(_ src: Mat, toRect rect: Rect) -> Mat {
    // Ensure the rectangle is within the bounds of the source Mat
    let srcWidth = src.cols()
    let srcHeight = src.rows()

    if rect.x >= 0 && rect.y >= 0 && rect.x + rect.width <= srcWidth && rect.y + rect.height <= srcHeight {
        return src.submat(roi: rect) // Crop the Mat using submat
    } else {
        print("Crop rectangle is out of bounds.")
        return src.clone() // Return a copy of the original Mat if out of bounds
    }
}

func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
    // Ensure the rectangle is within the bounds of the image's pixel dimensions
    let scaledRect = CGRect(
        x: rect.origin.x * image.scale,
        y: rect.origin.y * image.scale,
        width: rect.size.width * image.scale,
        height: rect.size.height * image.scale
    )

    // Check if the crop rectangle is valid within the image bounds
    guard let croppedCGImage = image.cgImage?.cropping(to: scaledRect) else {
        print("Failed to crop image.")
        return nil
    }

    // Create and return a new UIImage from the cropped CGImage
    return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
}

fileprivate func writeMaskToFile(_ dilatedMat: Mat, filename: String) {
    // Ensure the dilatedMat is continuous in memory and properly aligned
    let continuousMat = dilatedMat.clone()
    
    // Convert single-channel dilatedMat to 4-channel RGBA (which is compatible with UIImage)
    let colorDilatedMat = Mat()
    Imgproc.cvtColor(src: continuousMat, dst: colorDilatedMat, code: ColorConversionCodes.COLOR_GRAY2RGBA)
    
    // Save the image
    if let dilatedImage = UIImage(mat: colorDilatedMat) {
        let fileURL3 = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        _ = saveUIImage(dilatedImage, to: fileURL3)
    } else {
        print("Failed to convert Mat to UIImage.")
    }
}

