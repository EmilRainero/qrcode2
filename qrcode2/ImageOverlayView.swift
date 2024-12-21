//
//  ImageOverlayView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/13/24.
//


import SwiftUI
import opencv2

// Example usage
struct IContentView: View {
    @State private var processedImage: UIImage? // Use @State for dynamic updates

    var body: some View {
        VStack {
            if let image = processedImage {
                // Show the processed image using ImageOverlayView for example
                Image(uiImage: image)
            }
        }
        .onAppear {
            dowork()
        }
    }
    
    func dowork() {
        print("Loaded")
        // Simulate some image processing or loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.processedImage = UIImage(named: "4qrcodes_rectified")
            x(image: self.processedImage!)
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
    
    func drawOnImage(image: UIImage, rects: [CGRect]) -> UIImage? {
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
            
            for rect in rects {
                cgContext.stroke(rect)
            }
        }
    }
    
    func x(image: UIImage) {
        
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
        
        print("boxes \(boxes.count)")
        let newImage = self.drawOnImage(image: image, rects: boxes)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("bboxes.jpg")
        saveUIImage(newImage!, to: fileURL)
        self.processedImage = newImage
    }
    
    func y(image: UIImage) {
        
        let src = Mat(uiImage: image)
        let grayMat = Mat()

        // Convert to grayscale
        Imgproc.cvtColor(src: src, dst: grayMat, code: ColorConversionCodes.COLOR_BGR2GRAY)

        // Apply Threshold to create a binary mask where darker pixels (blackish) are white
        let thresholdMat = Mat()
        Imgproc.threshold(src: grayMat, dst: thresholdMat, thresh: 128, maxval: 255, type: .THRESH_BINARY_INV)

        saveMatToFile(mat: thresholdMat, fileName: "thresholdMat.png")

//        let dilatedMat = Mat()
//        let dilateKernel = Mat.ones(rows: 7, cols: 7, type: CvType.CV_8U)  // 3x3 square kernel
//        Imgproc.dilate(src: thresholdMat, dst: dilatedMat, kernel: dilateKernel)
//
        // Define the kernel for morphological operations
        let kernel = Imgproc.getStructuringElement(shape: MorphShapes.MORPH_RECT, ksize: Size(width: 3, height: 3))

        // Apply Dilation
        let dilatedMat = Mat()
        Imgproc.dilate(src: thresholdMat, dst: dilatedMat, kernel: kernel)

        // Apply Erosion (after dilation)
        let erodedMat = Mat()
        Imgproc.erode(src: dilatedMat, dst: erodedMat, kernel: kernel)

        
        // Prepare variables for contours
        let contours = NSMutableArray()
        let hierarchy = Mat()

        // Find contours
        Imgproc.findContours(
            image: erodedMat,
            contours: contours,
            hierarchy: hierarchy,
            mode: RetrievalModes.RETR_TREE,
            method: ContourApproximationModes.CHAIN_APPROX_SIMPLE
        )

//        var boundingBoxes: [Rect] = []  // Create an array to store bounding boxes

        print(contours.count)
        
        var boxes: [CGRect] = []
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
                let origin = CGPoint(x: Int(boundingBox.x), y: Int(boundingBox.y))
                let size = CGSize(width: Int(boundingBox.width), height: Int(boundingBox.height))
                let rect = CGRect(origin: origin, size: size)
                
                
                if boundingBox.width >= 8 && boundingBox.height >= 8 {
                    print("Bounding Box (x: \(boundingBox.x), y: \(boundingBox.y), width: \(boundingBox.width), height: \(boundingBox.height))")
                    var found = false
                    for j in 0..<boxes.count {
                        let percent = percentageIntersection(rect1: rect, rect2: boxes[j])
                        print(rect, boxes[j], percent)
                        if percent > 0.85 {
                            found = true
                            if rect.width * rect.height > boxes[j].width * boxes[j].height {
                                print("replacing \(boxes[j]) with \(rect)")
                                boxes[j] = rect
                            } else {
                                print("skipping \(rect)")
                            }
                            break
                        }
                    }
                    if !found {
                        print("adding box \(rect)")
                        boxes.append(rect)
                    }
                }
            }
        }
        print("boxes \(boxes.count)")
        let newImage = self.drawOnImage(image: image, rects: boxes)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("bboxes.jpg")
        saveUIImage(newImage!, to: fileURL)
    }
    func percentageIntersection(rect1: CGRect, rect2: CGRect) -> CGFloat {
        // Calculate the intersection rectangle
        let intersection = rect1.intersection(rect2)
        
        // If there is no intersection, return 0% intersection
        guard !intersection.isNull else {
            return 0.0
        }
        
        // Calculate areas
        let intersectionArea = intersection.width * intersection.height
        let rect1Area = rect1.width * rect1.height
        let rect2Area = rect2.width * rect2.height
        
        // Calculate union area using the inclusion-exclusion principle
        let unionArea = rect1Area + rect2Area - intersectionArea
        
        // Calculate the percentage intersection of the area
        let percentageIntersection = (intersectionArea / unionArea)
        
        return percentageIntersection
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
}

