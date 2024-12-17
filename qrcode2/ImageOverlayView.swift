//
//  ImageOverlayView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/13/24.
//


import SwiftUI

struct ImageOverlayView: View {
    let image: UIImage
    let rect: CGRect // Rectangle in image coordinates

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Display the image scaled to fit
                let imageSize = image.size
                let displaySize = calculateDisplaySize(for: imageSize, in: geometry.size)
                let scaleFactor = displaySize.width / imageSize.width
                let scaledRect = scaleRect(rect, by: scaleFactor)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: displaySize.width, height: displaySize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Overlay the rectangle, ensuring alignment with the displayed image
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: scaledRect.width, height: scaledRect.height)
                    .position(
                        x: scaledRect.midX + (geometry.size.width - displaySize.width) / 2,
                        y: scaledRect.midY + (geometry.size.height - displaySize.height) / 2
                    )
            }
        }
    }

    // Calculate the display size of the image based on aspect-fit scaling
    func calculateDisplaySize(for imageSize: CGSize, in containerSize: CGSize) -> CGSize {
        let aspectWidth = containerSize.width / imageSize.width
        let aspectHeight = containerSize.height / imageSize.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        return CGSize(width: imageSize.width * aspectRatio, height: imageSize.height * aspectRatio)
    }

    // Scale the rectangle by a uniform scale factor
    func scaleRect(_ rect: CGRect, by scaleFactor: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x * scaleFactor,
            y: rect.origin.y * scaleFactor,
            width: rect.width * scaleFactor,
            height: rect.height * scaleFactor
        )
    }
}
// Example usage
struct IContentView: View {
    var body: some View {
        if let image = UIImage(named: "corners4") {
            let exampleRect = CGRect(x: 0, y: 0, width: 100, height: 1920) // Rectangle in image coordinates
            ImageOverlayView(image: image, rect: exampleRect)
        }
    }
}
