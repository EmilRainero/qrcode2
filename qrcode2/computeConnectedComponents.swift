//
//  computeConnectedComponents.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/14/24.
//

import UIKit
import CoreImage


struct ConnectedComponent {
    var label: Int
    var pixels: [CGPoint]
    var boundingBox: CGRect
}

// Function to compute connected components and their bounding boxes from a grayscale CIImage
func computeConnectedComponents(from ciImage: CIImage, threshold: CGFloat) -> [ConnectedComponent]? {
    let context = CIContext()

    // Convert the CIImage to a CGImage
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        print("Error: Could not convert CIImage to CGImage")
        return nil
    }
    
    let width = cgImage.width
    let height = cgImage.height
    
    // Create a grayscale color space (8 bits per component)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    
    // Bitmap info with no alpha channel and 8 bits per component
    let bitmapInfo: CGBitmapInfo = [.byteOrderDefault]
    
    // Create a bitmap context with 8 bits per component
    guard let context2 = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        print("Error: Could not create bitmap context")
        return nil
    }
    
    // Draw the image into the context
    context2.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    // Access pixel data from context
    guard let data = context2.data else {
        print("Error: Could not access pixel data")
        return nil
    }
    
    // Bind memory to UInt8 (grayscale value per pixel)
    let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height)
    
    // Create a 2D array to track visited pixels
    var visited = Array(repeating: Array(repeating: false, count: width), count: height)
    
    // Directions for 8-connected neighbors (N, NE, E, SE, S, SW, W, NW)
    let directions: [(Int, Int)] = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]
    
    // A helper function to check if a pixel is within the image bounds
    func isInBounds(x: Int, y: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
    }
    
    // A helper function to perform flood fill and find a connected component
    func floodFill(x: Int, y: Int, label: Int) -> (pixels: [CGPoint], boundingBox: CGRect) {
        var componentPixels: [CGPoint] = []
        var stack: [(Int, Int)] = [(x, y)]
        
        // Variables to track the bounding box
        var minX = x, maxX = x, minY = y, maxY = y
        
        while !stack.isEmpty {
            let (cx, cy) = stack.removeLast()
            
            // Skip if the pixel is already visited or not part of the component
            if visited[cy][cx] || CGFloat(pixelBuffer[cy * width + cx]) < threshold {
                continue
            }
            
            // Mark as visited and add to the component's pixels
            visited[cy][cx] = true
            componentPixels.append(CGPoint(x: cx, y: cy))
            
            // Update the bounding box
            minX = min(minX, cx)
            maxX = max(maxX, cx)
            minY = min(minY, cy)
            maxY = max(maxY, cy)
            
            // Explore all 8-connected neighbors
            for (dx, dy) in directions {
                let nx = cx + dx
                let ny = cy + dy
                
                if isInBounds(x: nx, y: ny) && !visited[ny][nx] && CGFloat(pixelBuffer[ny * width + nx]) >= threshold {
                    stack.append((nx, ny))
                }
            }
        }
        
        // Create the bounding box for this component
        let boundingBox = CGRect(x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(maxX - minX + 1), height: CGFloat(maxY - minY + 1))
        
        return (componentPixels, boundingBox)
    }
    
    // Array to hold all the connected components
    var components: [ConnectedComponent] = []
    
    // Traverse all pixels in the image
    var currentLabel = 1
    for y in 0..<height {
        for x in 0..<width {
            // If the pixel is unvisited and meets the threshold, it's a new component
            if !visited[y][x] && CGFloat(pixelBuffer[y * width + x]) >= threshold {
                // Perform flood fill to find all connected pixels and the bounding box
                let (componentPixels, boundingBox) = floodFill(x: x, y: y, label: currentLabel)
                
                if !componentPixels.isEmpty {
                    components.append(ConnectedComponent(label: currentLabel, pixels: componentPixels, boundingBox: boundingBox))
                    currentLabel += 1
                }
            }
        }
    }
    
    return components
}
