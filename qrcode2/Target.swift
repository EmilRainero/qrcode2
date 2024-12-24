//
//  Target.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/22/24.
//

import Foundation
import SwiftUI
import opencv2

class TargetRing: Codable {
    var score: Int
    var ellipse: Ellipse
    
    init(score: Int, ellipse: Ellipse) {
        self.score = score
        self.ellipse = ellipse
    }
    
    func toJson() -> String? {
        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted // Makes JSON output readable
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to encode TargetRing to JSON: \(error)")
            return nil
        }
    }
}

class Target {
    var name: String
    var rings: [TargetRing]
    
    init(name: String) {
        self.name = name
        self.rings = []
    }
    
    func addRing(ring: TargetRing) {
        self.rings.append(ring)
    }
    
    func sortRings() {
        self.rings.sort { $0.score > $1.score }
    }
    
    func assignScores() {
        self.rings.sort { $0.ellipse.area() < $1.ellipse.area() }

        for i in 0..<self.rings.count {
            self.rings[i].score = 10 - i
        }
    }
    
    func printdetails() {
        print("Name: \(self.name)")
        for i in 0..<self.rings.count {
            print("    \(i) \(self.rings[i].toJson()!)")
        }
    }
    
    func getScore(x: Double, y: Double, radius: Double) -> Int {
        let circle = Circle(x: x, y: y, radius: radius)
        for i in 0..<self.rings.count {
            if isCircleOverlappingEllipse(circle: circle, ellipse: self.rings[i].ellipse) {
//                print("getScore \(i) \(self.rings[i].score)")
//                print("circle: \(circle.toJson()!) ellipse: \(self.rings[i].ellipse.toJson()!)")
                return self.rings[i].score
            }
        }
//        print("getScore failed")
        return 0
    }
}

func processTarget(image: UIImage) -> Target {
    let src = Mat(uiImage: image)
    let grayMat = Mat()

    // Convert to grayscale
    Imgproc.cvtColor(src: src, dst: grayMat, code: ColorConversionCodes.COLOR_BGR2GRAY)

    // Apply Threshold to create a binary mask where darker pixels (blackish) are white
    let thresholdMat = Mat()
    Imgproc.threshold(src: grayMat, dst: thresholdMat, thresh: 128, maxval: 255, type: .THRESH_BINARY_INV)

    saveMatToFile(mat: thresholdMat, fileName: "thresholdMat.png")

    // Use connectedComponents to find connected components in the binary image
    let labels = Mat()
    let stats = Mat()
    let centroids = Mat()
    
    // ConnectedComponents with connectivity 8 (for 8-connected components)
    let numComponents = Imgproc.connectedComponentsWithStats(image: thresholdMat, labels: labels, stats: stats, centroids: centroids, connectivity: 4)
    // Print the number of connected components
    print("Number of connected components: \(numComponents)")

    var boxes: [CGRect] = []
    for i in 0..<numComponents {
        let stat = stats.row(i)
        let x = Int(stat.get(row: 0, col: 0)[0])
        let y = Int(stat.get(row: 0, col: 1)[0])
        let width = Int(stat.get(row: 0, col: 2)[0])
        let height = Int(stat.get(row: 0, col: 3)[0])
        let area = Int(stat.get(row: 0, col: 4)[0])
        
        if x != 0 && height >= 12 && width >= 12 {
            print("x: \(x), y: \(y), width: \(width), height: \(height), area: \(width * height)")
            
            let origin = CGPoint(x: x, y: y)
            let size = CGSize(width: width, height: height)
            let rect = CGRect(origin: origin, size: size)
            boxes.append(rect)
        }
    }
    
    let target = Target(name: "Test")
    for i in 0..<boxes.count {
        let score = Int(boxes[i].width * boxes[i].height)
        let centerx = boxes[i].minX + boxes[i].width/2
        let centery = boxes[i].minY + boxes[i].height/2
        let ellipse = Ellipse(centerx: centerx, centery: centery, majorAxis: boxes[i].width, minorAxis: boxes[i].height)
        let ring = TargetRing(score: score, ellipse: ellipse)
        target.addRing(ring: ring)
    }
    target.assignScores()
    target.printdetails()
    
    print("boxes \(boxes.count)")
    let newImage = drawOnImage(image: image, rects: boxes, target: target)
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("bboxes.jpg")
    saveUIImage(newImage!, to: fileURL)
    return target
}

func drawOnImage(image: UIImage, rects: [CGRect], target: Target) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    
    return renderer.image { context in
        // Draw the original image
        image.draw(at: .zero)
        
        // Configure the context for drawing
        let cgContext = context.cgContext
        cgContext.setStrokeColor(UIColor.red.cgColor)
        cgContext.setLineWidth(2)
        cgContext.setLineJoin(.miter)
        cgContext.setLineCap(.square)
        
        let uniqueColors: [UIColor] = [
            UIColor.black,
            UIColor.systemPink,
            UIColor.brown,
            UIColor.magenta,
            UIColor.cyan,
            UIColor.purple,
            UIColor.orange,
            UIColor.yellow,
            UIColor.green,
            UIColor.blue,
            UIColor.red
        ]
        
        for i in 0..<target.rings.count{
            let ring = target.rings[i]
            let score = ring.score
            cgContext.setStrokeColor(uniqueColors[score].cgColor)
            let rect = CGRect(origin: ring.ellipse.getCGPoint(), size: ring.ellipse.getCGSize())

            cgContext.addEllipse(in: rect)
            cgContext.strokePath()
        }
        
        let spacing = 10.0
        let x = rects[0].minX + rects[0].width/2
        let minY = rects[0].minY - 2 * spacing
        let maxY = rects[0].maxY + 2 * spacing
        for y in stride(from: minY, through: maxY, by: spacing) {
            let rect = CGRect(origin: CGPoint(x: x-2, y: y-2), size: CGSize(width:5, height:5))
            let score = target.getScore(x: x, y: y, radius:2.5)
            
//            print("color \(uniqueColors[score])")
            cgContext.setFillColor(uniqueColors[score].cgColor)

            cgContext.addEllipse(in: rect)
            cgContext.fillPath()
        }
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
