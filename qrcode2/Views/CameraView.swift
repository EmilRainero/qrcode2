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
    @State private var temporaryNumber: Int? = nil // Holds the number to display temporarily

    init(navigationPath: Binding<NavigationPath>, appStateMachine: Binding<AppStateMachine>) {
        self._navigationPath = navigationPath
        self._appStateMachine = appStateMachine

        // Initialize CameraManager with the unwrapped appStateMachine
        self._cameraManager = StateObject(wrappedValue: CameraManager(appStateMachine: appStateMachine.wrappedValue))
    }
    
    var body: some View {
        ZStack {
            if let image = cameraManager.processedImage {
                ZStack(alignment: .top) { // Align child views to the top
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                let imageSize = image.size
                                let displaySize = calculateDisplaySize(for: imageSize, in: geometry.size)
                                let scaleFactor = displaySize.width / imageSize.width
                                cameraManager.scaleFactor = scaleFactor
                                cameraManager.imageSize = geometry.size
                            }
                        })
                    
                    VStack(alignment: .center) {
                        if let currentStateMessage = currentStateMessage() {
                            Text(currentStateMessage)
                                .font(.system(size: 24))
                                .fontWeight(.bold)
//                                .padding()
                        }

                        if let currentStateMessageDetails = currentStateMessageDetails() {
                            Text(currentStateMessageDetails)
                                .font(.system(size: 24))
//                                .padding()
                        }
                    }
                    .background(
                        Rectangle()
                            .fill(Color.white)
                            .opacity(0.3)
                            .cornerRadius(10)
                    )
                    .frame(maxWidth: .infinity)
                    .padding() // Add some padding to avoid overlapping the top edge
                }
                
            } else {
                Color.white
            }
            
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
            let secondsRemaining = (cameraManager.sessionTime - cameraManager.frameCount) / cameraManager.frameRate
            result = "Session - Seconds remaining: \(secondsRemaining)"
        case (.calibrationFailed):
            result = "Calibration Failed"
        case (.sessionEnded):
            result = "Session Final Score"
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
            if cameraManager.shotsFired > 0 {
                result = "Shots: \(cameraManager.shotsFired)  Score: +\(cameraManager.score) = \(cameraManager.totalScore)"
            } else {
                result = "Shots: \(cameraManager.shotsFired)  Score: \(cameraManager.totalScore)"
            }
        case (.sessionEnded):
            result = .none
            if cameraManager.shotsFired > 0  {
                result = "Shots: \(cameraManager.shotsFired)  Score: \(cameraManager.totalScore)"
            }
        case (.calibrationFailed):
            result = .none
        default:
            result = "\(appStateMachine.currentState)"
        }
            
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
    @Published var originalImageSize: CGSize = .zero
    @Published var imageSize: CGSize = .zero
    @Published var scaleFactor: CGFloat = 0.0
    @Published var appStateMachine: AppStateMachine
    @Published var frameRate: Int32 = 30
    @Published var calibrationTime: Int32 = 15 * 30
    @Published var delayStartTime: Int32 = 5 * 30
    @Published var sessionTime: Int32 = 30 * 30
    @Published var score: Int32 = 0
    @Published var totalScore: Int32 = 0
    @Published var shotsFired: Int32 = 0

    let messageSender = MessageSender(dbPath: "messages.db", url: "http://192.168.5.6:5001/updates") // Instance property

    private var detectedQRCodes: [Models.DetectedQRCode]? = []
    private var laserSpots: [Models.DetectedQRCode]?

    private var captureSession: AVCaptureSession?
    private let context = CIContext()
    public var frameCount: Int32 = 0
    private var qrCodeMap: [Int32: [Models.DetectedQRCode]] = [:]
    public var rectifiedImage: UIImage? = .none
    private var corners: [Models.DetectedQRCode] = []
    private var lastFrame: UIImage? = .none
    private var session: Models.Session? = .none
    
    private var shotRadiusPixels: Double = 2.5
    private var inShot: Bool = false
    private var lastShotFrame: Int32 = 0
    
    init(appStateMachine: AppStateMachine) {
        self.appStateMachine = appStateMachine
    }
    
    func testDetectLaser() {
        let images = [
//            "laser-25"
//            , 
            "laser-26"
//            "image_00280",
//            "image_00294",
//            "image_00295"
//            ,
//            "image_00389", "image_00390", "image_00479", "image_00480",
//            "image_00543"
//            ,
//            "image_00544"
//            , "image_00598", "image_00656", "image_00705", "image_00706"
        ]
        
        for imageFilename in images {
            let image = UIImage(named: imageFilename)!
            let result = self.detectLaser(image: image, frameCount: 0)
            print(imageFilename, result.found)
        }
        
        print("done")
    }
    
    func startCapture() {
//        testDetectLaser()
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
        inShot = false
        appStateMachine.handle(event: .startCalibration)
        captureSession?.startRunning()
    }

    func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
        appStateMachine.handle(event: .initial)
    }
    
    func detectLaserOriginal(image: UIImage, frameCount: Int32) -> (found: Bool, codes: [Models.DetectedQRCode]) {
        let cropRect = CGRect(x: 0, y: 200, width: Int(image.size.width), height: 1000)
        let newImage = cropImage(image, toRect: cropRect)
        let uiImage = newImage!
        
        let src = Mat(uiImage: uiImage)
        
        // Convert to Grayscale
        let grayMat = Mat()
        Imgproc.cvtColor(src: src, dst: grayMat, code: ColorConversionCodes.COLOR_BGR2GRAY)

        // Apply Threshold to create a binary mask where pixels < 230 are black
        let thresholdMat = Mat()
        Imgproc.threshold(src: grayMat, dst: thresholdMat, thresh: 230, maxval: 255, type: .THRESH_BINARY)

        // Perform Dilation: Restores the white regions
        let dilatedMat = Mat()
        let dilateKernel = Mat.ones(rows: 7, cols: 7, type: CvType.CV_8U)  // 3x3 square kernel
        Imgproc.dilate(src: thresholdMat, dst: dilatedMat, kernel: dilateKernel)
    
        // Perform Erosion: Removes small white regions
        let erodedMat = Mat()
        let erodeKernel = Mat.ones(rows: 7, cols: 7, type: CvType.CV_8U)  // 3x3 square kernel
        Imgproc.erode(src: thresholdMat, dst: erodedMat, kernel: erodeKernel)
//        writeMaskToFile(erodedMat, filename: "erodedMat.jpg")

        let resultMat = Mat()
        Core.bitwise_and(src1: src, src2: src, dst: resultMat, mask: dilatedMat)

        // Invert the image
        Core.bitwise_not(src: resultMat, dst: resultMat)

        // Convert the result back to UIImage
        
        let contours = NSMutableArray() // Create NSMutableArray to hold contours
        let hierarchy = Mat()
        Imgproc.findContours(
            image: thresholdMat,
            contours: contours, // Pass NSMutableArray
            hierarchy: hierarchy,
            mode: RetrievalModes.RETR_EXTERNAL,
            method: ContourApproximationModes.CHAIN_APPROX_SIMPLE
        )

        var boundingBoxes: [Rect] = []  // Create an array to store bounding boxes

        var codes: [Models.DetectedQRCode] = []

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
                
                print("Bounding Box (x: \(boundingBox.x), y: \(boundingBox.y), width: \(boundingBox.width), height: \(boundingBox.height))")
                
                boundingBoxes.append(boundingBox)
                let y: Int = Int(dilatedMat.size().height)
                let code = Models.DetectedQRCode(
                    message: "frame \(frameCount)",
                    topLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y)),
                    topRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y)),
                    bottomLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y + boundingBox.height)),
                    bottomRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y + boundingBox.height)),
                    width: CGFloat(boundingBox.width),
                    height: CGFloat(boundingBox.height)
                )
                if boundingBox.width >= 6 && boundingBox.height >= 6 && boundingBox.width < 100 && boundingBox.height < 100 {
                    if codes.count == 0 {
                        codes.append(code)
                    } else {
                        if CGFloat(boundingBox.width * boundingBox.height) > codes[0].width * codes[0].height {
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
    
    func detectLaser(image: UIImage, frameCount: Int32) -> (found: Bool, codes: [Models.DetectedQRCode]) {
        let writeImages = false
        
        let cropRect = CGRect(x: 0, y: 200, width: Int(image.size.width), height: 1000)
        guard let newImage = cropImage(image, toRect: cropRect) else {
            return (found: false, codes: [])
        }

        let src = Mat(uiImage: newImage)
        let hsvMat = Mat()

        // Convert to HSV color space
        Imgproc.cvtColor(src: src, dst: hsvMat, code: ColorConversionCodes.COLOR_BGR2HSV)
//        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("laser-\(frameCount).jpg")
//        if writeImages { saveUIImage(image, to: fileURL) }

        var hsvChannels: [Mat] = []
        Core.split(m: hsvMat, mv: &hsvChannels)

        // Access the Hue channel
        let valueChannel = Mat()
        Imgproc.threshold(src: hsvChannels[2], dst: valueChannel, thresh: 230, maxval: 255, type: .THRESH_BINARY)


//        if writeImages { saveMatToFile(mat: hsvChannels[0], fileName: "hueChannel.png") }
//        if writeImages { saveMatToFile(mat: hsvChannels[1], fileName: "saturationChannel.png") }
//        if writeImages { saveMatToFile(mat: hsvChannels[2], fileName: "valueChannel.png") }

        // Create masks for bright white and reddish spots
        var whiteMask = Mat()

        // Bright white mask (high value, low saturation)
        Core.inRange(
            src: hsvMat,
            lowerb: Scalar(0, 0, 230),      // Low saturation, high value
            upperb: Scalar(180, 30, 255),  // Low saturation, maximum value
            dst: whiteMask
        )
        if writeImages { saveMatToFile(mat: whiteMask, fileName: "original-whiteMask.png") }

        let kernel = Mat.ones(rows: 3, cols: 3, type: CvType.CV_8U)  // 3x3 square kernel
        var erodedMat = Mat()
        Imgproc.erode(src: whiteMask, dst: erodedMat, kernel: kernel)
        var dilatedMat = Mat()
        Imgproc.dilate(src: erodedMat, dst: dilatedMat, kernel: kernel)
        whiteMask = dilatedMat
        if writeImages { saveMatToFile(mat: whiteMask, fileName: "whiteMask.png") }

        let lowerb = Scalar(0, 30, 128)   // Minimum saturation and value to exclude gray and dark regions
        let upperb = Scalar(180, 255, 255) // Maximum saturation and value to include all bright colors

        // Apply the mask
        var nonGrayMask = Mat()
        Core.inRange(
            src: hsvMat,
            lowerb: lowerb,
            upperb: upperb,
            dst: nonGrayMask
        )
        
        nonGrayMask = valueChannel
        
        if writeImages { saveMatToFile(mat: nonGrayMask, fileName: "original-nonGrayMask.png") }
        erodedMat = Mat()
        Imgproc.erode(src: nonGrayMask, dst: erodedMat, kernel: kernel)
        if writeImages { saveMatToFile(mat: erodedMat, fileName: "aftererode-nonGrayMask.png") }
        dilatedMat = Mat()
        Imgproc.dilate(src: erodedMat, dst: dilatedMat, kernel: kernel)
        if writeImages { saveMatToFile(mat: dilatedMat, fileName: "afterdilate-nonGrayMask.png") }

        nonGrayMask = dilatedMat
        if writeImages { saveMatToFile(mat: nonGrayMask, fileName: "nonGrayMask.png") }
        
        // Combine white and non grey
        let combinedMask = Mat()
        Core.bitwise_or(src1: whiteMask, src2: nonGrayMask, dst: combinedMask)

        // Save the mask for debugging
//        saveMatToFile(mat: combinedMask, fileName: "combinedMask.png")
        
        // Perform Dilation: Restores the white regions
        dilatedMat = Mat()
        Imgproc.dilate(src: combinedMask, dst: dilatedMat, kernel: kernel)
        erodedMat = Mat()
        Imgproc.erode(src: dilatedMat, dst: erodedMat, kernel: kernel)
        if writeImages { saveMatToFile(mat: erodedMat, fileName: "erodedMat.png") }
        
        
        // Use connectedComponents to find connected components in the binary mask
        let labels = Mat()
        let stats = Mat()
        let centroids = Mat()

        if writeImages { saveMatToFile(mat: combinedMask, fileName: "combinedMask.png") }

        // ConnectedComponents with connectivity 8
        let numComponents = Imgproc.connectedComponentsWithStats(
            image: erodedMat,
            labels: labels,
            stats: stats,
            centroids: centroids,
            connectivity: 8
        )

//        print("Number of components: \(numComponents)")

        // Process the components to identify regions of interest
        var codes: [Models.DetectedQRCode] = []
        for i in 0..<numComponents { // Skip the background (component 0)
            let stat = stats.row(i)
            let x = Int32(stat.get(row: 0, col: 0)[0])
            let y = Int32(stat.get(row: 0, col: 1)[0])
            let width = Int32(stat.get(row: 0, col: 2)[0])
            let height = Int32(stat.get(row: 0, col: 3)[0])
//            let area = Int32(stat.get(row: 0, col: 4)[0])

//            if area > 50 { // Filter out small noise
////                print("Component \(i): x=\(x), y=\(y), width=\(width), height=\(height), area=\(area)")
//                return (found: true, codes: codes)
////                detectedCodes.append(DetectedQRCode(x: x, y: y, width: width, height: height))
//            }
            
//            print("Component \(i): x=\(x), y=\(y), width=\(width), height=\(height), area=\(area)")

            let maxY: Int = Int(dilatedMat.size().height)
            var code = Models.DetectedQRCode(
                message: "frame \(frameCount)",
                topLeft: CGPoint(x: Int(x), y: maxY - Int(y)),
                topRight: CGPoint(x: Int(x + width), y: maxY - Int(y)),
                bottomLeft: CGPoint(x: Int(x), y: maxY - Int(y + height)),
                bottomRight: CGPoint(x: Int(x + width), y: maxY - Int(y + height)),
                width: CGFloat(width),
                height: CGFloat(height)
            )
            code.frame = frameCount
            if width >= 6 && height >= 6 && width < 100 && height < 100 {
                if codes.count == 0 {
                    codes.append(code)
                } else {
                    if CGFloat(width * height) > codes[0].width * codes[0].height {
                        codes = [code]
                    }
                }
//                    print(code)
            }
        }

        return (found: codes.count > 0, codes: codes)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        frameCount += 1
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let tempImage = convertCIImageToUIImage(ciImage)
        
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
                                
                let detect = detectLaser(image: result.image!, frameCount: frameCount)
                if detect.found && self.frameCount > self.lastShotFrame + 10 {
                    self.inShot = true
                    
                    let target = Models.processTarget(image: self.lastFrame!)
                    let code = detect.codes[0]
                    
                    var skip = false
                    if self.laserSpots == nil {
                        self.laserSpots = [code]
                    } else {
                        if !self.laserSpots!.isEmpty &&
                            frameCount - self.laserSpots![self.laserSpots!.count-1].frame! == frameCount - 1 {
                            self.laserSpots![self.laserSpots!.count-1].frame = frameCount
                            let shot = self.session!.shots.last!
                            
                            let x = (code.topLeft.x + code.topRight.x) / 2
                            let y = (code.topLeft.y + code.bottomLeft.y) / 2
                            let (_, distance, angle) = target.getScoreDistanceAndAngle(x: x, y: y, radius: shotRadiusPixels)
                            shot.addAdditionalShots(time: Date(), angle: angle, distance: distance)
                            LoggerManager.log.info("add addional shots")
//                            LoggerManager.log.info(self.session!.toJson())

                            skip = true
                        } else {
                            self.laserSpots!.append(code)
                        }
                    }
                    if !skip {
                        let x = (code.topLeft.x + code.topRight.x) / 2
                        let y = (code.topLeft.y + code.bottomLeft.y) / 2
//                        let score = target.getScore(x: x, y: y, radius:2.5)
                        let (score, distance, angle) = target.getScoreDistanceAndAngle(x: x, y: y, radius: shotRadiusPixels)

                        let shot = Models.Shot(time: Date(), angle: angle, distance: distance, score: score)
                        self.session!.addShot(shot: shot)

//                        print("LASER Frame: \(frameCount) SCORE \(score) ")
                        LoggerManager.log.info("LASER Frame: \(frameCount) SCORE \(score) ")
//                        LoggerManager.log.info(self.session!.toJson())

//                        let drawImage = self.drawOnImage(image: self.lastFrame!, codes: self.laserSpots, color: UIColor.red)
                        let drawImage = self.drawOnImage(image: result.image!, codes: self.laserSpots, color: UIColor.red)
                        DispatchQueue.main.async {
                            self.score = score
                            self.totalScore += self.score
                            self.shotsFired += 1
                            self.processedImage = drawImage
                            AudioServicesPlaySystemSound(1057)
                        }
                    }
                } else {
                    if self.inShot {
                        let lastShot = self.session!.shots[self.session!.shots.count-1]
                        let add_shot_command = messageSender.server!.generateAddShotCommand(session: self.session!, shot: lastShot)!
                        messageSender.sendMessage(message: add_shot_command)
                        print("Add Shot framecount \(frameCount)")
                        self.lastShotFrame = self.frameCount
                    }
                    self.inShot = false
                    
                    self.lastFrame = result.image
                }
                DispatchQueue.main.async {
                    self.processedImage = self.processedImage  // causes UI to refresh to show seconds remaining
                }
            }
            
            if appStateMachine.currentState == .initial || appStateMachine.currentState == .calibrating{
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                if let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] {
                    var codes: [Models.DetectedQRCode] = []
                    for feature in features {
                        if let message = feature.messageString {
                            // Create DetectedQRCode objects with corner points
                            let code = Models.DetectedQRCode(
                                message: message,
                                topLeft: feature.topLeft,
                                topRight: feature.topRight,
                                bottomLeft: feature.bottomLeft,
                                bottomRight: feature.bottomRight,
                                width: CGFloat(feature.topRight.x - feature.topLeft.x),
                                height: CGFloat(feature.topLeft.y - feature.bottomLeft.y)
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
                        let numberSequentialKeys: Int32 = 5
                        if qrCodeMap.count >= numberSequentialKeys {
                            let lastNkeys = qrCodeMap.keys.sorted().suffix(Int(numberSequentialKeys))
                            if let firstKey = lastNkeys.first, let lastKey = lastNkeys.last, lastKey - firstKey < numberSequentialKeys + 10 {
                                appStateMachine.handle(event: .startRunSession)
                                frameCount = 0
                                
                                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("4qrcodes.jpg")
                                saveImage(ciImage, to: fileURL)
                                
                                let result = rectifyImageForMultipleCodes(image: tempImage!, using: codes)
                                
                                self.corners = codes  // remember corners
                                let rectifiedImage = result.image
                                
                                if rectifiedImage != nil {
                                    let fileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent("4qrcodes_rectified.jpg")
                                    _ = saveUIImage(rectifiedImage!, to: fileURL2)
                                    self.rectifiedImage = rectifiedImage
                                } else {
                                    print("nil rectifiedImage")
                                }
                                let code = Models.DetectedQRCode(
                                    message: "hello",
                                    topLeft: result.upperLeft!,
                                    topRight: result.upperRight!,
                                    bottomLeft: result.lowerLeft!,
                                    bottomRight: result.lowerRight!,
                                    width: CGFloat(result.upperRight!.x - result.upperLeft!.x),
                                    height: CGFloat(result.upperLeft!.y - result.lowerLeft!.y)
                                )
                                codes = [code]
                                self.detectedQRCodes = codes
                            }
                        }
                    }
                    self.detectedQRCodes = codes
                                   }
            }
//            let startTime = Date()
            var newImage = self.processedImage
            if appStateMachine.currentState == .calibrating && frameCount % 2 == 0 {
                newImage = self.drawOnImage(image: tempImage!, codes: self.detectedQRCodes, color: UIColor.green)
            }
            
            if appStateMachine.currentState != .runningSession && appStateMachine.currentState != .sessionEnded {
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
            self.session = Models.Session(starttime: Date())
            let new_session_command = messageSender.server!.generateStartSessionCommand(session: self.session!)!
            messageSender.sendMessage(message: new_session_command)
            frameCount = 0
        }
        if appStateMachine.currentState == .runningSession && frameCount == sessionTime {
//            self.detectedQRCodes = []
            self.session!.finish(finishtime: Date())
            let finish_session_command = messageSender.server!.generateFinishSessionCommand(session: self.session!)!

            messageSender.sendMessage(message: finish_session_command)

            let dataAccess = DB.DataAccess("db.sqlite3")
            let _ = dataAccess.createSession(session: DB.Session(id: UUID().uuidString, data: self.session!.toJson(), starttime: self.session!.starttime))
            LoggerManager.log.info("FINISHED")

//            LoggerManager.log.info(self.session!.toJson())

            DispatchQueue.main.async {
                self.appStateMachine.handle(event: .endRunSession)
                self.processedImage = self.processedImage
            }
        }
    }
    
    func drawOnImage(image: UIImage, codes: [Models.DetectedQRCode]?, color: UIColor) -> UIImage? {
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

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]

            // Draw the QR code boundaries
            if let codes = codes {
                for i in 0..<codes.count{
                    let qrCode = codes[i]
                    let path = CGMutablePath()
                    if color == UIColor.red {
                        let centerX = (qrCode.topLeft.x + qrCode.topRight.x + qrCode.bottomRight.x + qrCode.bottomLeft.x) / 4
                        let centerY = (qrCode.topLeft.y + qrCode.topRight.y + qrCode.bottomRight.y + qrCode.bottomLeft.y) / 4

                        // Convert the y-coordinate to match the image's coordinate system
                        let center = CGPoint(x: CGFloat(centerX), y: CGFloat(image.size.height - centerY))

                        // Calculate the radius based on the largest distance from the center to any corner
                        let distances = [
                            hypot(CGFloat(qrCode.topLeft.x) - center.x, CGFloat(image.size.height - qrCode.topLeft.y) - center.y),
                            hypot(CGFloat(qrCode.topRight.x) - center.x, CGFloat(image.size.height - qrCode.topRight.y) - center.y),
                            hypot(CGFloat(qrCode.bottomRight.x) - center.x, CGFloat(image.size.height - qrCode.bottomRight.y) - center.y),
                            hypot(CGFloat(qrCode.bottomLeft.x) - center.x, CGFloat(image.size.height - qrCode.bottomLeft.y) - center.y)
                        ]
                        var radius = distances.max() ?? 0

                        radius = 10
                        // Draw the circle
                        let circleRect = CGRect(
                            x: center.x-radius,
                            y: center.y-radius,
                            width: radius * 2,
                            height: radius * 2
                        )

                        cgContext.setFillColor(UIColor.red.cgColor) // Set the fill color for the circle
                        cgContext.addEllipse(in: circleRect)
                        cgContext.fillPath()
                        
                        let text = "\(i+1)"
                                
                        let attributedText = NSAttributedString(string: text, attributes: attributes)
                        attributedText.draw(at: CGPoint(x: center.x-6, y: center.y-11))
                    } else {
                        path.move(to: CGPoint(x: CGFloat(qrCode.topLeft.x), y: CGFloat(image.size.height - qrCode.topLeft.y)))
                        path.addLine(to: CGPoint(x: CGFloat(qrCode.topRight.x), y: CGFloat(image.size.height - qrCode.topRight.y)))
                        path.addLine(to: CGPoint(x: CGFloat(qrCode.bottomRight.x), y: CGFloat(image.size.height - qrCode.bottomRight.y)))
                        path.addLine(to: CGPoint(x: CGFloat(qrCode.bottomLeft.x), y: CGFloat(image.size.height - qrCode.bottomLeft.y)))
                        path.closeSubpath()
                        cgContext.addPath(path)
                    }
                }
                cgContext.strokePath()
            }
        }
    }
    
    func drawOnImage2(image: UIImage, codes: [Models.DetectedQRCode]?, color: UIColor) -> UIImage? {
        
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

        var codes: [Models.DetectedQRCode] = []

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
                let code = Models.DetectedQRCode(
                    message: "message",
                    topLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y)),
                    topRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y)),
                    bottomLeft: CGPoint(x: Int(boundingBox.x), y: y - Int(boundingBox.y + boundingBox.height)),
                    bottomRight: CGPoint(x: Int(boundingBox.x + boundingBox.width), y: y - Int(boundingBox.y + boundingBox.height)),
                    width: CGFloat(boundingBox.width),
                    height: CGFloat(boundingBox.height)
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
    
    func rectifyImageForMultipleCodes(image: UIImage, using codes: [Models.DetectedQRCode]) -> (image: UIImage?,
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
