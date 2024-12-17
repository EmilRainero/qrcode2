//
//  CameraView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/20/24.
//


import SwiftUI
import AVFoundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import opencv2


struct CameraView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var appStateMachine: AppStateMachine

    @StateObject private var cameraManager: CameraManager

    init(navigationPath: Binding<NavigationPath>, appStateMachine: Binding<AppStateMachine>) {
        self._navigationPath = navigationPath
        self._appStateMachine = appStateMachine

        // Initialize CameraManager with the unwrapped appStateMachine
        self._cameraManager = StateObject(wrappedValue: CameraManager(appStateMachine: appStateMachine.wrappedValue))
    }
    
    var body: some View {
        ZStack {
            if let image = cameraManager.processedImage {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                // Store the image's size to scale the QR code corners correctly
                                let imageSize = image.size
                                let displaySize = calculateDisplaySize(for: imageSize, in: geometry.size)
                                let scaleFactor = displaySize.width / imageSize.width
                                cameraManager.scaleFactor = scaleFactor
                                cameraManager.imageSize = geometry.size
                            }
                        })
                    VStack {
                        if let currentStateMessage = currentStateMessage() {
                            Text(currentStateMessage)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding()
                        }
                        
                        if let currentStateMessageDetails = currentStateMessageDetails() {
                            Text(currentStateMessageDetails)
                                .font(.system(size: 24))
                                .padding()
                        }
                    }
                    .background(
                        Rectangle()
                            .fill(Color.white)
                            .opacity(0.6) // Semi-transparent white
                            .cornerRadius(10) // Optional: Rounded corners
                    )
                    
                }
                
            } else {
                Color.white
            }
            
//            if let laserSpots = cameraManager.laserSpots {
//                ForEach(laserSpots.indices, id: \.self) { index in
//                    let code = laserSpots[index]
//                    QRCodeOverlay(corners: [
//                        scalePointDebug(code.topLeft),
//                        scalePointDebug(code.topRight),
//                        scalePointDebug(code.bottomRight),
//                        scalePointDebug(code.bottomLeft)
//                    ])
//                    QRCodeOverlay(corners: [
//                        scalePointDebug(CGPoint(x:0, y:0)),
//                        scalePointDebug(CGPoint(x:100, y:0)),
//                        scalePointDebug(CGPoint(x:100, y:cameraManager.imageSize.height)),
//                        scalePointDebug(CGPoint(x:0, y:cameraManager.imageSize.height))
//                    ])
//                    .stroke(Color.red, lineWidth: 2)
//                }
//            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
//            appStateMachine.handle(event: .startCalibration)
            cameraManager.startCapture()
        }
        .onDisappear {
            cameraManager.stopCapture()
        }
    }
    
    func currentStateMessage() -> String? {
        var result: String?

        switch (appStateMachine.currentState) {
        case (.initial):
            result = .none
        case (.calibrating):
            result = "Calibrating \((cameraManager.calibrationTime - cameraManager.frameCount + cameraManager.frameRate - 1) / cameraManager.frameRate)"
        case (.runningSession):
            result = .none
        case (.calibrationFailed):
            result = "Calibration Failed"
        case (.sessionEnded):
            result = "Session Ended"
        case (.startRunningSession):
            result = "Get ready to start \((cameraManager.delayStartTime - cameraManager.frameCount + cameraManager.frameRate - 1) / cameraManager.frameRate)"
        default:
            result = "\(appStateMachine.currentState)"
        }
            
        return result
    }
    
    func currentStateMessageDetails() -> String? {
        var result: String? = .none

        switch (appStateMachine.currentState) {
        case (.initial):
            result = .none
        case (.calibrating):
            result = "Put QR Codes into video frame"
        case (.startRunningSession):
            result = .none
        case (.runningSession):
            result = .none
        case (.sessionEnded):
            result = .none
        case (.calibrationFailed):
            result = .none
        default:
            result = "\(appStateMachine.currentState)"
        }
            
        return result
    }
    
    func scalePoint2(_ point: CGPoint) -> CGPoint {
        // Scale the point based on the image size relative to the view
        let offsetY = 32.0
//        print(cameraManager.originalImageSize, cameraManager.imageSize)
        
//        let result = CGPoint(
//            x: point.x / cameraManager.originalImageSize.width * cameraManager.imageSize.width,
//            y: (1 - point.y / cameraManager.originalImageSize.height) * cameraManager.imageSize.height + offsetY
//        )
        
        let result = CGPoint(
            x: point.x * cameraManager.scaleFactor,
            y: (cameraManager.processedImage!.size.height - point.y) * cameraManager.scaleFactor + offsetY
        )

        return result
    }
    
    func scalePointDebug(_ point: CGPoint) -> CGPoint {
        // Scale the point based on the image size relative to the view
        let offsetY = -50.0
        print(cameraManager.originalImageSize, cameraManager.imageSize)
        let result = CGPoint(
            x: point.x / cameraManager.originalImageSize.width * cameraManager.imageSize.width,
            y: (1 - point.y / cameraManager.originalImageSize.height) * cameraManager.imageSize.height + offsetY
        )
//        print("from \(point.x), \(point.y)  to  \(result.x), \(result.y)")
        return result
    }
    
    func calculateDisplaySize(for imageSize: CGSize, in containerSize: CGSize) -> CGSize {
        let aspectWidth = containerSize.width / imageSize.width
        let aspectHeight = containerSize.height / imageSize.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        return CGSize(width: imageSize.width * aspectRatio, height: imageSize.height * aspectRatio)
    }
}

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var processedImage: UIImage?
    @Published var laserSpots: [DetectedQRCode]?
    @Published var originalImageSize: CGSize = .zero
    @Published var imageSize: CGSize = .zero
    @Published var scaleFactor: CGFloat = 0.0
    @Published var appStateMachine: AppStateMachine
    @Published var frameRate: Int32 = 30
    @Published var calibrationTime: Int32 = 15 * 30
    @Published var delayStartTime: Int32 = 5 * 30
    @Published var sessionTime: Int32 = 60 * 30

    private var detectedQRCodes: [DetectedQRCode]? = []

    private var captureSession: AVCaptureSession?
    private let context = CIContext()
    
    public var frameCount: Int32 = 0
    private var qrCodeMap: [Int32: [DetectedQRCode]] = [:]
    
    public var rectifiedImage: UIImage? = .none
    private var corners: [DetectedQRCode] = []

    
    init(appStateMachine: AppStateMachine) {
        self.appStateMachine = appStateMachine
    }
    
    func testFindLaser() {
        let images = [
            "image_00280",
            "image_00294", "image_00295", "image_00389", "image_00390", "image_00479", "image_00480",
            "image_00543", "image_00544", "image_00598", "image_00656", "image_00705", "image_00706"
        ]
        
        for imageFilename in images {
            let image = UIImage(named: imageFilename)!
            let result = self.detectLaser(image: image, frameCount: 0)
            print(imageFilename, result.found)
        }
    }
    
    func startCapture() {
//        testFindLaser()
//        return
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }

        if captureSession?.canAddInput(videoInput) ?? false {
            captureSession?.addInput(videoInput)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        if captureSession?.canAddOutput(videoOutput) ?? false {
            captureSession?.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }

        frameCount = 0
        qrCodeMap = [:]
        appStateMachine.handle(event: .startCalibration)
        captureSession?.startRunning()
    }

    func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
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
            saveUIImage(dilatedImage, to: fileURL3)
        } else {
            print("Failed to convert Mat to UIImage.")
        }
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
    
    func detectLaser(image: UIImage, frameCount: Int32) -> (found: Bool, codes: [DetectedQRCode]) {
        let cropRect = CGRect(x: 0, y: 200, width: Int(image.size.width), height: 1000)
        let newImage = cropImage(image, toRect: cropRect)
        let uiImage = newImage!
        
        DispatchQueue.main.async {
//            self.originalImageSize = uiImage.size
//            self.imageSize = CGSize(width: 450, height: 801)
//            self.processedImage = uiImage
        }
        
        
        let src = Mat(uiImage: uiImage)
//        let cropRect = Rect(x: 0, y: 200, width: Int32(uiImage.size.width), height: 1000)
//        let croppedMat = cropMat(src, toRect: cropRect)
//        print(src)
//        print(croppedMat)
        
        // Convert to Grayscale
        let grayMat = Mat()
        Imgproc.cvtColor(src: src, dst: grayMat, code: ColorConversionCodes.COLOR_BGR2GRAY)

        // Apply Threshold to create a binary mask where pixels < 230 are black
        let thresholdMat = Mat()
        Imgproc.threshold(src: grayMat, dst: thresholdMat, thresh: 230, maxval: 255, type: .THRESH_BINARY)

//        writeMaskToFile(thresholdMat, filename: "thresholdMat.jpg")

        // Perform Dilation: Restores the white regions
        let dilatedMat = Mat()
        let dilateKernel = Mat.ones(rows: 7, cols: 7, type: CvType.CV_8U)  // 3x3 square kernel
        Imgproc.dilate(src: thresholdMat, dst: dilatedMat, kernel: dilateKernel)
//        writeMaskToFile(dilatedMat, filename: "dilated.jpg")
    
        // Perform Erosion: Removes small white regions
        let erodedMat = Mat()
        let erodeKernel = Mat.ones(rows: 7, cols: 7, type: CvType.CV_8U)  // 3x3 square kernel
        Imgproc.erode(src: dilatedMat, dst: erodedMat, kernel: erodeKernel)
//        writeMaskToFile(erodedMat, filename: "erodedMat.jpg")

        let resultMat = Mat()
        Core.bitwise_and(src1: src, src2: src, dst: resultMat, mask: dilatedMat)

        // Invert the image
        Core.bitwise_not(src: resultMat, dst: resultMat)

        // Convert the result back to UIImage
//        DispatchQueue.main.async {
//            if let resultImage = UIImage(mat: resultMat) {
//                self.rectifiedImage = resultImage
//            } else {
//                print("Failed to convert Mat to UIImage.")
//            }
//        }
        
        let contours = NSMutableArray() // Create NSMutableArray to hold contours
        let hierarchy = Mat()
        Imgproc.findContours(
            image: dilatedMat,
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
                let y: Int = Int(dilatedMat.size().height)
                let code = DetectedQRCode(
                    message: "frame \(frameCount)",
                    topLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y)),
                    topRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y)),
                    bottomLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y + boundingBox.height)),
                    bottomRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y + boundingBox.height)),
                    width: boundingBox.width,
                    height: boundingBox.height
                )
                if boundingBox.width >= 8 && boundingBox.height >= 8 && boundingBox.width < 100 && boundingBox.height < 100 {
                    if codes.count == 0 {
                        codes.append(code)
                    } else {
                        if boundingBox.width * boundingBox.height > codes[0].width * codes[0].height {
                            codes = [code]
                        }
                    }
//                    print(code)
                }
            }
        }
        
        DispatchQueue.main.async {
            if codes.count > 0 {
                AudioServicesPlaySystemSound(1057)
            }
        }
        return (found: codes.count > 0, codes: codes)
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        frameCount += 1
//        if frameCount % 30 == 0 {
//            print(frameCount)
//        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        var tempImage = convertCIImageToUIImage(ciImage)
        
        if self.processedImage == nil {
            DispatchQueue.main.async {
                self.originalImageSize = ciImage.extent.size
            }
        }
                
        let grayscaleFilter = CIFilter(name: "CIColorControls")
        grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter?.setValue(0, forKey: kCIInputSaturationKey)
        let outputImage = grayscaleFilter?.outputImage

        if outputImage != nil {
            if appStateMachine.currentState == .runningSession {
                let result = rectifyImageForMultipleCodes(image: tempImage!, using: self.corners)
//                testOpenCV2(uiImage: result.image!)
                let detect = detectLaser(image: result.image!, frameCount: frameCount)
                if detect.found {
                    print(frameCount, "LASER")
                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("laser-\(frameCount).jpg")
                    saveUIImage(result.image!, to: fileURL)
                    
                    let code = detect.codes[0]
                    print(code)
                    
                    DispatchQueue.main.async {
                         
                        if self.laserSpots == nil {
                            self.laserSpots = [code]
                        } else {
                            self.laserSpots!.append(code)
                        }
                        
                        let drawImage = self.drawOnImage(image: result.image!, codes: self.laserSpots, color: UIColor.red)
                        let fileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent("laser-\(self.frameCount).jpg")
                        self.saveUIImage(drawImage!, to: fileURL2)

                        print(self.laserSpots!.count)
                        self.laserSpots?.forEach { spot in
                            print(spot)
                        }
                        self.processedImage = drawImage
                        self.originalImageSize = result.image!.size
                        print("cropped image \(self.originalImageSize)")
                    }
                }
                
            }
            
            if appStateMachine.currentState == .initial || appStateMachine.currentState == .calibrating{
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
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
                        }
                    }
                    if codes.count == 4 {
                        if appStateMachine.currentState == .initial {
                            appStateMachine.handle(event: .startCalibration)
                            frameCount = 0
                        }

                        qrCodeMap[frameCount] = codes
                        let numberSequentialKeys: Int32 = 10
                        if qrCodeMap.count >= numberSequentialKeys {
                            let lastNkeys = qrCodeMap.keys.sorted().suffix(Int(numberSequentialKeys))
                            print(lastNkeys)
                            if let firstKey = lastNkeys.first, let lastKey = lastNkeys.last, lastKey - firstKey < numberSequentialKeys + 10 {
//                                 Iterate through the last 10 sorted keys and process the dictionary values
                                for key in lastNkeys {
                                    var detectedQRCodes = qrCodeMap[key]
                                    print("\(key)  \(detectedQRCodes!.count)")
                                }
                                appStateMachine.handle(event: .startRunSession)
                                frameCount = 0
                                
                                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("4qrcodes.jpg")
                                saveImage(ciImage, to: fileURL)
//                                let drawImage = self.drawOnImage(image: tempImage!, codes: self.detectedQRCodes, color: UIColor.green)
//                                let fileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent("4qrcode-draw.jpg")
//                                self.saveUIImage(drawImage!, to: fileURL2)
                                
                                let result = rectifyImageForMultipleCodes(image: tempImage!, using: codes)
                                
                                self.corners = codes  // remember corners
                                
                                let rectifiedImage = result.image
                                
                                if rectifiedImage != nil {
                                    let fileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent("4qrcodes_rectified.jpg")
                                    saveUIImage(rectifiedImage!, to: fileURL2)
                                    self.rectifiedImage = rectifiedImage
                                } else {
                                    print("nil rectifiedImage")
                                }
                                let code = DetectedQRCode(
                                    message: "hello",
                                    topLeft: result.upperLeft!,
                                    topRight: result.upperRight!,
                                    bottomLeft: result.lowerLeft!,
                                    bottomRight: result.lowerRight!,
                                    width: Int32(result.upperRight!.x - result.upperLeft!.x),
                                    height: Int32(result.upperLeft!.y - result.lowerLeft!.y)
                                )
                                codes = []
                                self.detectedQRCodes = codes
                            }
                        }
                    }
                    self.detectedQRCodes = codes
                                   }
            }
//            let startTime = Date()
            var newImage = self.processedImage
            if appStateMachine.currentState == .calibrating && frameCount % 5 == 0 {
                newImage = self.drawOnImage(image: tempImage!, codes: self.detectedQRCodes, color: UIColor.green)
//                let endTime = Date()
//                let elapsedTime = endTime.timeIntervalSince(startTime)
//                print("Drawing time: \(elapsedTime) seconds")
            }
//            let newImage = self.drawOnImage(image: tempImage!, codes: self.detectedQRCodes, color: UIColor.green)
            
            if appStateMachine.currentState != .runningSession {
                DispatchQueue.main.async {
                    if self.rectifiedImage != nil {
                        self.processedImage = self.rectifiedImage
                    } else {
                        self.processedImage = newImage
                    }
                }
            }
        }
        
        if appStateMachine.currentState == .calibrating && frameCount == calibrationTime {
//            for key in qrCodeMap.keys.sorted() {
//                if let detectedQRCodes = qrCodeMap[key] {
//                    print("Frame: \(key)  Count: \(detectedQRCodes.count)")
//                }
//            }
            appStateMachine.handle(event: .calibrationFailed)
            self.detectedQRCodes = []

            DispatchQueue.main.async {
                self.processedImage = tempImage
            }
            frameCount = 0
        }
        if appStateMachine.currentState == .startRunningSession && frameCount % frameRate == 0 {
            DispatchQueue.main.async {
                AudioServicesPlaySystemSound(1057)
            }
        }
        if appStateMachine.currentState == .startRunningSession && frameCount == delayStartTime {
            appStateMachine.handle(event: .running)
            frameCount = 0
        }
        if appStateMachine.currentState == .runningSession && frameCount == sessionTime {
            self.detectedQRCodes = []
            DispatchQueue.main.async {
                self.appStateMachine.handle(event: .endRunSession)
            }
        }
    }
    
    func drawOnImage(image: UIImage, codes: [DetectedQRCode]?, color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw the original image
            image.draw(at: .zero)

            // Configure the context for drawing
            let cgContext = context.cgContext
            cgContext.setStrokeColor(color.cgColor)
            cgContext.setLineWidth(2)
            cgContext.setLineJoin(.miter)
            cgContext.setLineCap(.square)

            // Draw the QR code boundaries
            if let codes = codes {
                for qrCode in codes {
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: CGFloat(qrCode.topLeft.x), y: CGFloat(image.size.height - qrCode.topLeft.y)))
                    path.addLine(to: CGPoint(x: CGFloat(qrCode.topRight.x), y: CGFloat(image.size.height - qrCode.topRight.y)))
                    path.addLine(to: CGPoint(x: CGFloat(qrCode.bottomRight.x), y: CGFloat(image.size.height - qrCode.bottomRight.y)))
                    path.addLine(to: CGPoint(x: CGFloat(qrCode.bottomLeft.x), y: CGFloat(image.size.height - qrCode.bottomLeft.y)))
                    path.closeSubpath()
                    cgContext.addPath(path)
                }
                cgContext.strokePath()
            }
        }
    }
    
    func drawOnImage2(image: UIImage, codes: [DetectedQRCode]?, color: UIColor) -> UIImage? {
        
        // Create a graphics context matching the image size
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        let updatedImage = renderer.image { context in
            // Draw the original image
            image.draw(at: .zero)
            
            // Configure the context for drawing
            let cgContext = context.cgContext
            cgContext.setStrokeColor(color.cgColor)
            cgContext.setLineWidth(2)
            cgContext.setLineJoin(.miter)
            cgContext.setLineCap(.square)
            
            let y = image.size.height
            if codes != nil {
                for qrCode in codes! {
                    
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: CGFloat(qrCode.topLeft.x), y: CGFloat(y-qrCode.topLeft.y)))
                    path.addLine(to: CGPoint(x: CGFloat(qrCode.topRight.x), y: CGFloat(y-qrCode.topRight.y)))
                    path.addLine(to: CGPoint(x: CGFloat(qrCode.bottomRight.x), y: CGFloat(y-qrCode.bottomRight.y)))
                    path.addLine(to: CGPoint(x: CGFloat(qrCode.bottomLeft.x), y: CGFloat(y-qrCode.bottomLeft.y)))
                    path.addLine(to: CGPoint(x: CGFloat(qrCode.topLeft.x), y: CGFloat(y-qrCode.topLeft.y)))
                    cgContext.addPath(path)
                    
                    cgContext.strokePath()
                }
            }
        }
        
        return updatedImage
    }
    
    func testOpenCV2(uiImage: UIImage) {
        // Convert UIImage to OpenCV Mat
        let src = Mat(uiImage: uiImage)

        // Convert to Grayscale
        let grayMat = Mat()
        Imgproc.cvtColor(src: src, dst: grayMat, code: ColorConversionCodes.COLOR_BGR2GRAY)

        // Apply Threshold to create a binary mask where pixels < 230 are black
        let thresholdMat = Mat()
        Imgproc.threshold(src: grayMat, dst: thresholdMat, thresh: 230, maxval: 255, type: .THRESH_BINARY)

        // Perform Erosion: Removes small white regions
        let erodedMat = Mat()
        let erodeKernel = Mat.ones(rows: 7, cols: 7, type: CvType.CV_8U)  // 3x3 square kernel
        Imgproc.erode(src: thresholdMat, dst: erodedMat, kernel: erodeKernel)

        // Perform Dilation: Restores the white regions
        let dilatedMat = Mat()
        let dilateKernel = Mat.ones(rows: 7, cols: 7, type: CvType.CV_8U)  // 3x3 square kernel
        Imgproc.dilate(src: erodedMat, dst: dilatedMat, kernel: dilateKernel)

        // Set pixels below 230 to black using the modified mask (pixels >= 230 are white)
        let resultMat = Mat()
        Core.bitwise_and(src1: src, src2: src, dst: resultMat, mask: dilatedMat)

        // Invert the image
        Core.bitwise_not(src: resultMat, dst: resultMat)

        // Convert the result back to UIImage
//        DispatchQueue.main.async {
//            if let resultImage = UIImage(mat: resultMat) {
//                self.rectifiedImage = resultImage
//            } else {
//                print("Failed to convert Mat to UIImage.")
//            }
//        }
        
        let contours = NSMutableArray() // Create NSMutableArray to hold contours
        let hierarchy = Mat()
        Imgproc.findContours(
            image: dilatedMat,
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
                if boundingBox.width >= 10 && boundingBox.height >= 10 {
                    codes.append(code)
                }
            }
        }
        
        if codes.count > 0 {
            print("Laser Codes: \(codes)")
            DispatchQueue.main.async {
                AudioServicesPlaySystemSound(1057)
            }
        }
//        DispatchQueue.main.async {
//            self.detectedQRCodes = codes
//        }
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
    
    func rectifyImageForMultipleCodes(image: UIImage, using codes: [DetectedQRCode]) -> (image: UIImage?,
                                                                                         upperLeft: CGPoint?, upperRight: CGPoint?, lowerLeft: CGPoint?, lowerRight: CGPoint?) {
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
            
            let padding = 0
            for code in codes {
                if code.topLeft == corners.upperLeft {
                    upperLeft = code.topRight + CGPoint(x: padding, y: padding)
                }
                if code.topLeft == corners.upperRight {
                    upperRight = code.topLeft + CGPoint(x: -padding, y: padding)
                }
                if code.topLeft == corners.lowerLeft {
                    lowerLeft = code.bottomRight + CGPoint(x: padding, y: -padding)
                }
                if code.topLeft == corners.lowerRight {
                    lowerRight = code.bottomLeft + CGPoint(x: -padding, y: -padding)
                }
            }
            
            let rectifiedImage = rectifyImageWithPoints(image: image,
                                                         topLeft: lowerLeft!,
                                                         topRight: lowerRight!,
                                                         bottomLeft: upperLeft!,
                                                         bottomRight: upperRight!)
            return (image: rectifiedImage, upperLeft: upperLeft, upperRight: upperRight, lowerLeft: lowerLeft, lowerRight: lowerRight)
        }
        return (image: .none, upperLeft: .none, upperRight: .none, lowerLeft: .none, lowerRight: .none)
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
    
    func rectifyImageWithPoints(image: UIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> UIImage? {
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

        // Calculate the scale factor to maintain aspect ratio
        let outputExtent = outputImage.extent
        let outputAspectRatio = outputExtent.width / outputExtent.height
        let originalAspectRatio = ciImage.extent.width / ciImage.extent.height

        let scaleFactor = originalAspectRatio / outputAspectRatio

        // Create a transform to scale the image
        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)

        // Apply the transform to the output image
        let transformedImage = outputImage.transformed(by: scaleTransform)

        // Convert the CIImage back to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

func rectifyImageWithPoints2(image: UIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> UIImage? {
    // Convert UIImage to CIImage
    guard let ciImage = CIImage(image: image) else { return nil }
    
    // Calculate width and height based on the provided points
    let width = max(topRight.x - topLeft.x, bottomRight.x - bottomLeft.x)
    let height = max(topLeft.y - bottomLeft.y, topRight.y - bottomRight.y)
    
    // Calculate the original image's aspect ratio
    let originalAspectRatio = ciImage.extent.width / ciImage.extent.height
    
    // Adjust height to match the aspect ratio of the original image
    let adjustedHeight = width / originalAspectRatio

    // Adjust corner points to form a rectangle with the correct aspect ratio
    let correctedTopLeft = CIVector(x: topLeft.x, y: topLeft.y)
    let correctedTopRight = CIVector(x: topLeft.x + width, y: topLeft.y)
    let correctedBottomLeft = CIVector(x: topLeft.x, y: topLeft.y - adjustedHeight)
    let correctedBottomRight = CIVector(x: topLeft.x + width, y: topLeft.y - adjustedHeight)

    // Create the perspective correction filter
    guard let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
    perspectiveCorrection.setValue(ciImage, forKey: kCIInputImageKey)
    perspectiveCorrection.setValue(correctedTopLeft, forKey: "inputTopLeft")
    perspectiveCorrection.setValue(correctedTopRight, forKey: "inputTopRight")
    perspectiveCorrection.setValue(correctedBottomLeft, forKey: "inputBottomLeft")
    perspectiveCorrection.setValue(correctedBottomRight, forKey: "inputBottomRight")

    // Apply the filter
    guard let outputImage = perspectiveCorrection.outputImage else { return nil }

    // Convert the CIImage back to UIImage
    let context = CIContext()
    guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
    return UIImage(cgImage: cgImage)
}

class FeatureView: UIView {
    var features: [CIFeature] = []

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)

        for feature in features {
//            if let boundingBox = feature.boundingBox {
//                let rect = boundingBox.scaled(to: bounds.size)
//                context.stroke(rect)
//            }
        }
    }
}
