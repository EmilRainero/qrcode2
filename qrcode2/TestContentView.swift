//
//  TestContentView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/18/24.
//

import SwiftUI


struct TestContentView: View {
    @State private var imageName: String = "image4corners"
    @State private var processedImage: UIImage?
    
    var body: some View {
        ScrollView([.vertical], showsIndicators: true) {
            VStack(spacing: 20) {
                Image(uiImage: UIImage(named: self.imageName)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                // Display the processed image if available, otherwise a placeholder
                Image(uiImage: processedImage ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        loadAndProcessImage()
                    }
            }
        }
    }
    
        // Function to load and process the image
        private func loadAndProcessImage() {
            if let image = UIImage(named: imageName) {
                // Apply perspective transformation to the image
                let processed = applyPerspectiveTransform(to: image)
                self.processedImage = processed
            } else {
                print("Failed to load image")
            }
        }
        
        func rectifyImage(_ image: UIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> UIImage? {
            // Convert UIImage to CIImage
            guard let ciImage = CIImage(image: image) else { return nil }
            
            // Create the perspective correction filter
            let perspectiveCorrection = CIFilter.perspectiveCorrection()
            perspectiveCorrection.inputImage = ciImage
            perspectiveCorrection.topLeft = topLeft
            perspectiveCorrection.topRight = topRight
            perspectiveCorrection.bottomLeft = bottomLeft
            perspectiveCorrection.bottomRight = bottomRight
            
            // Apply the filter
            guard let outputImage = perspectiveCorrection.outputImage else { return nil }
            
                       // Convert the CIImage back to UIImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
            return UIImage(cgImage: cgImage)
        }
    
        // Apply a perspective transformation to the image
        private func applyPerspectiveTransform(to image: UIImage) -> UIImage {
            guard let ciImage = CIImage(image: image) else { return image }

            let padding = 40
            let bottomLeft = CGPoint(x: 227, y: 345) + CGPoint(x: -padding, y: -padding)
            let bottomRight = CGPoint(x: 1029, y: 536) + CGPoint(x: padding, y: -padding)
            let topLeft = CGPoint(x: 75, y: 1644) + CGPoint(x: -padding, y: padding)
            let topRight = CGPoint(x: 961, y: 1645) + CGPoint(x: padding, y: padding)
            
            if let rectifiedImage = rectifyImage(image, topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight) {
                return rectifiedImage
            }

            return image // Return original image if transformation fails
        }
}
