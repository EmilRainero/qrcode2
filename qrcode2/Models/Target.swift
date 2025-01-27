//
//  Target.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/22/24.
//

import Foundation
import SwiftUI
import opencv2

extension Models {
    
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
        
        func getScore(x: Double, y: Double, radius: Double) -> Int32 {
            let circle = Models.Circle(x: x, y: y, radius: radius)
            for i in 0..<self.rings.count {
                if Models.isCircleOverlappingEllipse(circle: circle, ellipse: self.rings[i].ellipse) {
                    return Int32(self.rings[i].score)
                }
            }
            return 0
        }
        
        func getScoreDistanceAndAngle(x: Double, y: Double, radius: Double) -> (score: Int32, distance: Double, angle: Double) {
            let circle = Models.Circle(x: x, y: y, radius: radius)
            for i in 0..<self.rings.count {
                let ellipse = self.rings[i].ellipse
                if Models.isCircleOverlappingEllipse(circle: circle, ellipse: ellipse) {
                    // Compute the distance
                    let dx = x - ellipse.centerx
                    let dy = y - ellipse.centery
                    
                    let distanceToPoint = sqrt(dx * dx + dy * dy)
                    let outerEllipse = self.rings[self.rings.count-1].ellipse  // outermost ellipse
                    let angle = atan2(dy, dx) * (180.0 / .pi)
                    
                    let distanceToEdge = outerEllipse.distanceToEdge(angle: angle)
                    let distance = distanceToPoint / distanceToEdge  // percent of distance to edge of outer ellipse
                    //                LoggerManager.log.info("dx: \(dx)  dy: \(dy)  distanceToPoint: \(distanceToPoint)  distanceToEdge: \(distanceToEdge)  distance: \(distance)  angle: \(angle)")
                    return (score: Int32(self.rings[i].score), distance: distance, angle: angle)
                }
            }
            return (score: 0, distance: -1.0, angle: 0.0) // Return 0.0 as angle if no overlap is found
        }
    }
    
    class func processTarget(image: UIImage) -> Target {
        let src = Mat(uiImage: image)
        let grayMat = Mat()

        // Convert to grayscale
        Imgproc.cvtColor(src: src, dst: grayMat, code: ColorConversionCodes.COLOR_BGR2GRAY)

        // Apply Threshold to create a binary mask where darker pixels (blackish) are white
        let thresholdMat = Mat()
        Imgproc.threshold(src: grayMat, dst: thresholdMat, thresh: 128, maxval: 255, type: .THRESH_BINARY_INV)

    //    saveMatToFile(mat: thresholdMat, fileName: "thresholdMat.png")

        // Use connectedComponents to find connected components in the binary image
        let labels = Mat()
        let stats = Mat()
        let centroids = Mat()
        
        // ConnectedComponents with connectivity 8 (for 8-connected components)
        let numComponents = Imgproc.connectedComponentsWithStats(image: thresholdMat, labels: labels, stats: stats, centroids: centroids, connectivity: 4)
        // Print the number of connected components
    //    print("Number of connected components: \(numComponents)")

        var boxes: [CGRect] = []
        for i in 0..<numComponents {
            let stat = stats.row(i)
            let x = Int(stat.get(row: 0, col: 0)[0])
            let y = Int(stat.get(row: 0, col: 1)[0])
            let width = Int(stat.get(row: 0, col: 2)[0])
            let height = Int(stat.get(row: 0, col: 3)[0])
//            let area = Int(stat.get(row: 0, col: 4)[0])
            
            if x != 0 && height >= 12 && width >= 12 {
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
            let ellipse = Models.Ellipse(centerx: centerx, centery: centery, majorAxis: boxes[i].width, minorAxis: boxes[i].height)
            let ring = TargetRing(score: score, ellipse: ellipse)
            target.addRing(ring: ring)
        }
        target.assignScores()

        return target
    }

    class func drawOnImage(image: UIImage, rects: [CGRect], target: Target) -> UIImage? {
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
                
                cgContext.setFillColor(uniqueColors[Int(score)].cgColor)

                cgContext.addEllipse(in: rect)
                cgContext.fillPath()
            }
        }
    }
}


