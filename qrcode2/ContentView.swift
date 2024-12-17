//
//  ContentView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/14/24.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import opencv2

// Struct to store QR code data and corners
struct DetectedQRCode {
    let message: String
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    let width: Int32
    let height: Int32
    var frame: Int32?
}

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}

struct ContentView: View {
    @Binding var navigationPath: NavigationPath

    @State private var detectedCodes: [DetectedQRCode] = []
    @State private var rectifiedImage: UIImage? = nil

    // Store the image size for scaling coordinates
    @State private var imageSize: CGSize = .zero
    @State private var imagePosition: CGPoint = .zero

    @State private var originalImageSize: CGSize = .zero
    @State private var imageName: String = "laser"
//    @State private var imageName: String = "corners4"
//    @State private var imageName: String = "image4corners"

    var body: some View {
        
        ScrollView([.vertical], showsIndicators: true) {
            VStack(spacing: 20) {
                ZStack {
                    Image(uiImage: UIImage(named: self.imageName)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear {
                            testOpenCV()
//                            detectQRCodes()
//                            detectLaser()
                        }
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                // Store the image's size to scale the QR code corners correctly
                                self.imageSize = geometry.size
                                self.imagePosition = geometry.frame(in: .global).origin
                            }
                        })
                    // Overlay detected QR code boundaries
                    ForEach(detectedCodes.indices, id: \.self) { index in
                        let code = detectedCodes[index]
                        QRCodeOverlay(corners: [
                            self.scalePoint(code.topLeft),
                            self.scalePoint(code.topRight),
                            self.scalePoint(code.bottomRight),
                            self.scalePoint(code.bottomLeft)
                        ])
                        .stroke(Color.red, lineWidth: 2)
                    }

                    QRCodesBoundingRect(codes: detectedCodes)
                        .stroke(Color.red, lineWidth: 2)
                }

                if let rectifiedImage = rectifiedImage {
                    // Display rectified image if available
                    Image(uiImage: rectifiedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .navigationTitle("Calibrate")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func rectifyImageWithPoints(image: UIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> UIImage? {
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
    
    // Function to scale the points from image coordinates to view coordinates
    func scalePoint(_ point: CGPoint) -> CGPoint {
        // Scale the point based on the image size relative to the view

        let offsetY = 0.0
        return CGPoint(
            x: point.x / originalImageSize.width * imageSize.width,
            y: (1 - point.y / originalImageSize.height) * imageSize.height + offsetY
        )
    }

    func detectLaser() {
        print("detect laser")
        guard let uiImage = UIImage(named: self.imageName),
              let cgImage = uiImage.cgImage else {
            print("Failed to load image")
            return
        }
        
        var spot = detectLaserSpot(in: uiImage)
        print(spot)
    }


    func testOpenCV() {
        // Load the image as UIImage
        guard let uiImage = UIImage(named: self.imageName) else {
            print("Failed to load image: \(self.imageName)")
            return
        }
        originalImageSize = uiImage.size

        // Convert UIImage to OpenCV Mat
        let src = Mat(uiImage: uiImage)
           

        // Convert to grayscale
        let hsvMat = Mat()
        Imgproc.cvtColor(src: src, dst: hsvMat, code: ColorConversionCodes.COLOR_BGR2HSV)

        // Define the lower and upper bounds for "white"
        let lowerWhite = Scalar(0, 0, 240)
        let upperWhite = Scalar(180, 30, 255)
        
        // Create a mask for white regions
        let whiteMask = Mat()
        Core.inRange(src: hsvMat, lowerb: lowerWhite, upperb: upperWhite, dst: whiteMask)
        
        // Apply morphological opening with an elliptical kernel
        let kernel = Imgproc.getStructuringElement(
            shape: MorphShapes.MORPH_ELLIPSE,
            ksize: Size(width: 5, height: 5)
        )
        Imgproc.morphologyEx(src: whiteMask, dst: whiteMask, op: MorphTypes.MORPH_OPEN, kernel: kernel)
            
        let contours = NSMutableArray() // Create NSMutableArray to hold contours
        let hierarchy = Mat()
        Imgproc.findContours(
            image: whiteMask,
            contours: contours, // Pass NSMutableArray
            hierarchy: hierarchy,
            mode: RetrievalModes.RETR_EXTERNAL,
            method: ContourApproximationModes.CHAIN_APPROX_SIMPLE
        )

        var boundingBoxes: [Rect] = []  // Create an array to store bounding boxes

        var codes: [DetectedQRCode] = []

        for i in 0..<contours.count {
            if let contourArray = contours[i] as? NSArray {
                var points: [Point2i] = []
                for item in contourArray {
                    if let point = item as? Point2i {
                        points.append(point)
                    }
                }
                
                // Create MatOfPoint from points array
                let contourMatOfPoint = MatOfPoint(array: points)
                
                // Calculate the bounding box
                let boundingBox = Imgproc.boundingRect(array: contourMatOfPoint)
                
//                print("Bounding Box (x: \(boundingBox.x), y: \(boundingBox.y), width: \(boundingBox.width), height: \(boundingBox.height))")
                
                boundingBoxes.append(boundingBox)
                let y: Int = Int(originalImageSize.height)
                let code = DetectedQRCode(
                    message: "message",
                    topLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y)),
                    topRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y)),
                    bottomLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y + boundingBox.height)),
                    bottomRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y + boundingBox.height)),
                    width: boundingBox.width,
                    height: boundingBox.height
                )
                if 10 <= code.width && code.width <= 50 && 10 <= code.height && code.height <= 50 {
                    codes.append(code)
                }
            }
        }
        DispatchQueue.main.async {
            if codes.count > 0 {
                AudioServicesPlaySystemSound(1057)
            }
            self.detectedCodes = codes
        }
    }

    
    func detectQRCodes() {
        
        guard let uiImage = UIImage(named: self.imageName),
              let cgImage = uiImage.cgImage else {
            print("Failed to load image")
            return
        }
        
        originalImageSize = uiImage.size
        // Create a CoreImage context and QR code detector
        let ciImage = CIImage(cgImage: cgImage)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        // Detect QR codes in the image
        if let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] {
            var codes: [DetectedQRCode] = []
            for feature in features {
                if let message = feature.messageString {
                    // Create DetectedQRCode objects with corner points
                    let code = DetectedQRCode(
                        message: message,
                        topLeft: feature.topLeft,
                        topRight: feature.topRight,
                        bottomLeft: feature.bottomLeft,
                        bottomRight: feature.bottomRight,
                        width: Int32(feature.topRight.x - feature.topLeft.x),
                        height: Int32(feature.topLeft.y - feature.bottomLeft.y)
                    )
                    codes.append(code)
                    
                    let corners = [
                        "Top Left: \(feature.topLeft)",
                        "Top Right: \(feature.topRight)",
                        "Bottom Left: \(feature.bottomLeft)",
                        "Bottom Right: \(feature.bottomRight)"
                    ]
//                    print("Detected QR Code with message: \(message)")
//                    print("Corners:")
//                    corners.forEach { print($0) }
                }
            }
            DispatchQueue.main.async {
                self.detectedCodes = codes
//                self.rectifyImage(using: codes)
            }
        } else {
            print("No QR codes detected.")
        }
    }
    
    func rectifyImage(using codes: [DetectedQRCode]) {
        if codes.count > 1 {
            // For multiple QR codes, rectify using all detected corners
            rectifyImageForMultipleCodes(using: codes)
        } else if let singleCode = codes.first {
            // For a single QR code, rectify using that one QR code
            rectifyImageForSingleCode(using: singleCode)
        }
    }

    // Function to rectify the image using a single QR code
    func rectifyImageForSingleCode(using code: DetectedQRCode) {
        let inputPoints = [
            code.topLeft,
            code.topRight,
            code.bottomRight,
            code.bottomLeft
        ]
        
        let targetPoints = [
            CIVector(x: 0, y: 0),
            CIVector(x: 1, y: 0),
            CIVector(x: 1, y: 1),
            CIVector(x: 0, y: 1)
        ]
        
        applyPerspectiveCorrection(inputPoints: inputPoints, targetPoints: targetPoints)
    }

    func classifyCorners(points: [CGPoint]) -> (upperLeft: CGPoint, upperRight: CGPoint, lowerLeft: CGPoint, lowerRight: CGPoint)? {
        // Ensure we have exactly 4 points
        guard points.count == 4 else { return nil }
        
        // Sort points by their y-coordinates (ascending)
        let sortedByY = points.sorted { $0.y < $1.y }
        
        // The first two points are the "upper" points, and the last two are the "lower" points
        let upperPoints = sortedByY.prefix(2)
        let lowerPoints = sortedByY.suffix(2)
        
        // Sort each pair by their x-coordinates to determine left and right
        let upperLeft = upperPoints.min(by: { $0.x < $1.x })!
        let upperRight = upperPoints.max(by: { $0.x < $1.x })!
        let lowerLeft = lowerPoints.min(by: { $0.x < $1.x })!
        let lowerRight = lowerPoints.max(by: { $0.x < $1.x })!
        
        return (upperLeft: upperLeft, upperRight: upperRight, lowerLeft: lowerLeft, lowerRight: lowerRight)
    }
    
    
    
    // Function to rectify the image using multiple QR codes
    func rectifyImageForMultipleCodes(using codes: [DetectedQRCode]) {
        // Aggregate all the corner points from the detected QR codes
        var allPoints: [CGPoint] = []
        for code in codes {
            allPoints.append(contentsOf: [code.topLeft, code.topRight, code.bottomLeft, code.bottomRight])
        }
        
        var topLeftPoints: [CGPoint] = []
        for code in codes {
            topLeftPoints.append(code.topLeft)
        }

        if let corners = classifyCorners(points: topLeftPoints) {
            
            var lowerLeft: CGPoint?
            var lowerRight: CGPoint?
            var upperLeft: CGPoint?
            var upperRight: CGPoint?

            let padding = 40
            for code in codes {
                if code.topLeft == corners.upperLeft {
                    upperLeft = code.bottomLeft + CGPoint(x: -padding, y: -padding)
                }
                if code.topLeft == corners.upperRight {
                    upperRight = code.bottomRight + CGPoint(x: padding, y: -padding)
                }
                if code.topLeft == corners.lowerLeft {
                    lowerLeft = code.topLeft + CGPoint(x: -padding, y: padding)
                }
                if code.topLeft == corners.lowerRight {
                    lowerRight = code.topRight + CGPoint(x: padding, y: padding)
                }
            }
                
            let image = UIImage(named: self.imageName)!
            self.rectifiedImage = rectifyImageWithPoints(image: image,
                                                         topLeft: lowerLeft!,
                                                         topRight: lowerRight!,
                                                         bottomLeft: upperLeft!,
                                                         bottomRight: upperRight!)
            return
        }
        
        // Sort the points to get the four outermost corners (this simplifies the homography transformation)
        let sortedPoints = allPoints.sorted {
            $0.x < $1.x || $0.y < $1.y
        }
        
        // Choose 4 outermost points (top-left, top-right, bottom-left, bottom-right)
        let inputPoints = [
//            sortedPoints.first!,      // top-left
//            sortedPoints.last!,       // bottom-right
//            sortedPoints[sortedPoints.count / 2], // mid-right
//            sortedPoints[sortedPoints.count / 2 + 1] // mid-left
            
            self.scalePoint(CGPoint(x: 75.81271362304688, y: 1645.3375854492188)),

            self.scalePoint(CGPoint(x: 227.71217346191406, y: 345.548583984375)),
            self.scalePoint(CGPoint(x: 1029.3531494140625, y: 536.287841796875)),
            self.scalePoint(CGPoint(x: 961.8091430664062, y: 1644.1079406738281)),
        ]
        // Define the target points for perspective correction
        let targetPoints = [
            CIVector(x: 0, y: 0),
            CIVector(x: 1, y: 0),
            CIVector(x: 1, y: 1),
            CIVector(x: 0, y: 1)
        ]
        
        // Apply perspective correction using the outermost points
        applyPerspectiveCorrection(inputPoints: inputPoints, targetPoints: targetPoints)
    }

    func QRCodesBoundingRect(codes: [DetectedQRCode]) -> Path {
        var path = Path()
        guard codes.count == 4 else { return path }

        let corners = findQRCodesBoundingRect(codes: codes)
        
        // Draw lines connecting the four corners
        path.move(to: scalePoint(corners.lowerLeft))
        path.addLine(to: scalePoint(corners.upperLeft))
        path.addLine(to: scalePoint(corners.upperRight))
        path.addLine(to: scalePoint(corners.lowerRight))
        path.closeSubpath()
        
        return path
    }
    
    func perspectiveCorrection(inputImage: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage? {
        let perspectiveCorrectionFilter = CIFilter.perspectiveCorrection()
        perspectiveCorrectionFilter.inputImage = inputImage
        perspectiveCorrectionFilter.topRight = topRight
        perspectiveCorrectionFilter.topLeft = topLeft
        perspectiveCorrectionFilter.bottomRight = bottomRight
        perspectiveCorrectionFilter.bottomLeft = bottomLeft
        return perspectiveCorrectionFilter.outputImage
    }
    
    func applyPerspectiveCorrectionCorners(to image: UIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let filter = CIFilter(name: "CIPerspectiveCorrection")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        // Using key paths instead of deprecated keys
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")

        
        guard let outputImage = filter.outputImage else { return nil }
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)

    }
    
    // Function to apply perspective correction using given input and target points
    func applyPerspectiveCorrection(inputPoints: [CGPoint], targetPoints: [CIVector]) {

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            print("Failed to create filter")
            return
        }

        // Set the perspective correction filter's input points
        filter.setValue(inputPoints.map { CIVector(x: $0.x, y: $0.y) }, forKey: "inputTopLeft")
        filter.setValue(inputPoints[1], forKey: "inputTopRight")
        filter.setValue(inputPoints[2], forKey: "inputBottomRight")
        filter.setValue(inputPoints[3], forKey: "inputBottomLeft")
        
        // Get the input image (the original image)
        guard let ciImage = CIImage(image: UIImage(named: self.imageName)!) else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        
//        self.rectifiedImage = applyPerspectiveCorrectionCorners(to: UIImage(named: self.imageName)!,
//                                                topLeft: self.scalePoint(CGPoint(x: 75.81271362304688, y: 1920-1645.3375854492188)),
//                                                topRight: self.scalePoint(CGPoint(x: 961.8091430664062, y: 1920-1644.1079406738281)),
//                                                bottomLeft: self.scalePoint(CGPoint(x: 227.71217346191406, y: 1920-345.548583984375)),
//                                                bottomRight: self.scalePoint(CGPoint(x: 1029.3531494140625, y: 1920-536.287841796875)))
        let topLeft = (CGPoint(x: 0.0, y: ciImage.extent.height))
        let topRight = (CGPoint(x: ciImage.extent.width, y: ciImage.extent.height))
        let bottomLeft = (CGPoint(x: 0.0, y: 0.0))
        let bottomRight = (CGPoint(x: ciImage.extent.width, y: 0.0))
        if let resultCIImage = perspectiveCorrection(inputImage: ciImage,
                                                     topLeft: topLeft,
                                                     topRight: topRight,
                                                     bottomLeft: bottomLeft,
                                                     bottomRight: bottomRight) {
            print("Filter output extent: \(resultCIImage.extent)")
            let context = CIContext()
            if let cgImage = context.createCGImage(resultCIImage, from: resultCIImage.extent) {
                self.rectifiedImage = UIImage(cgImage: cgImage)
                print(resultCIImage)
                self.rectifiedImage = UIImage(ciImage: resultCIImage)
            } else {
                print("Failed to create CGImage from CIImage.")
            }
        } else {
            print("Perspective correction filter failed.")
        }
        
        
        // Apply the perspective correction filter
//        if let outputImage = filter.outputImage {
//            let context = CIContext()
//            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
//                let rectifiedUIImage = UIImage(cgImage: cgImage)
//                self.rectifiedImage = rectifiedUIImage
//                print("created rectified image")
//            }
//        }
    }
}

// SwiftUI shape for the QR code overlay
struct QRCodeOverlay: Shape {
    let corners: [CGPoint]
    
    func path(in rect: CGRect) -> Path {

        var path = Path()
        guard corners.count == 4 else { return path }

        // Draw lines connecting the four corners
        path.move(to: corners[0])
        path.addLine(to: corners[1])
        path.addLine(to: corners[2])
        path.addLine(to: corners[3])
        path.closeSubpath()
        return path
    }
}

func findQRCodesBoundingRect(codes: [DetectedQRCode]) -> (upperLeft: CGPoint, upperRight: CGPoint, lowerLeft: CGPoint, lowerRight: CGPoint)
{
    var points: [CGPoint] = []
    for code in codes {
        points.append(code.topLeft)
    }
    
    guard points.count == 4 else { return (upperLeft: points[0], upperRight: points[0], lowerLeft: points[0], lowerRight: points[0]) }
    
    // Sort points by their y-coordinates (ascending)
    let sortedByY = points.sorted { $0.y < $1.y }
    
    // The first two points are the "upper" points, and the last two are the "lower" points
    let upperPoints = sortedByY.prefix(2)
    let lowerPoints = sortedByY.suffix(2)
    
    // Sort each pair by their x-coordinates to determine left and right
    let cornerUpperLeft = upperPoints.min(by: { $0.x < $1.x })!
    let cornerUpperRight = upperPoints.max(by: { $0.x < $1.x })!
    let cornerLowerLeft = lowerPoints.min(by: { $0.x < $1.x })!
    let cornerLowerRight = lowerPoints.max(by: { $0.x < $1.x })!
    
    var lowerLeft: CGPoint?
    var lowerRight: CGPoint?
    var upperLeft: CGPoint?
    var upperRight: CGPoint?

    let padding = 0
    for code in codes {
        if code.topLeft == cornerUpperLeft {
            upperLeft = code.bottomLeft + CGPoint(x: -padding, y: -padding)
        }
        if code.topLeft == cornerUpperRight {
            upperRight = code.bottomRight + CGPoint(x: padding, y: -padding)
        }
        if code.topLeft == cornerLowerLeft {
            lowerLeft = code.topLeft + CGPoint(x: -padding, y: padding)
        }
        if code.topLeft == cornerLowerRight {
            lowerRight = code.topRight + CGPoint(x: padding, y: padding)
        }
    }
    
    return (upperLeft: upperLeft!, upperRight: upperRight!, lowerLeft: lowerLeft!, lowerRight: lowerRight!)
//    return (upperLeft: cornerUpperLeft, upperRight: cornerUpperRight, lowerLeft: cornerLowerLeft, lowerRight: cornerLowerRight)
}

