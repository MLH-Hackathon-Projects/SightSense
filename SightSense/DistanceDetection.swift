//
//  ObjectRecognition.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import SwiftUI
import Vision
import AVFoundation

class DistanceDetection: CameraBase{
    private var voiceSynthesiser: VoiceSynthesis
    private var MLDepthRequest: VNRequest?
    private var locationRequest = VNRequest()
    private var objectRequest = VNRequest()
    
    var openAIRequest = OpenAIWrapper()
    
    private var segmentationRequest = VNRequest()
    private var depthMode: depthType!
    
    private var outputsync: AVCaptureDataOutputSynchronizer!

    var depthDataOutput: AVCaptureDepthDataOutput!
    
    private let dataInterpreter: DistanceDataInterpreter
    
    let vibrationManager: VibrationController
    private var vibrationStates: VibrationStates
    
    
    @Published var detailLevel: abstraction = .basic
    @Published var isSpeaking = false
    @Published var spokenText = ""
    
    enum depthType{
        case lidar
        case mlmodel
    }
    
    override init(){
        vibrationStates = VibrationStates(vibrationDirections: .center, continuesVibrationIntensity: 0.0, continuesVibrationSharpness: 0.0)
        vibrationManager = VibrationController(vibrationStates: vibrationStates)

        self.voiceSynthesiser = VoiceSynthesis()
        dataInterpreter = DistanceDataInterpreter()
    }
    
    override internal func setUpSession() {
        if (!captureSession.isRunning){
            captureSession.beginConfiguration()
            
            voiceSynthesiser.synthesizer.delegate = self
            
            setupMLModels()
            
            
            if (AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInLiDARDepthCamera], mediaType: .video, position: .unspecified).devices.count > 0){
                setupLidarSession()
                photoOutput.isDepthDataDeliveryEnabled = true
                depthMode = .lidar
            }else{
                print("no lidar sensors are on this device, ml model far metric depth")
                depthMode = .mlmodel
                super.setUpSession()
            }
            
            captureSession.commitConfiguration()
            previewDisabled = UserDefaults.standard.bool(forKey: "previewDisabled")
        }
    }
    func setupLidarSession(){
        setPreview()
        setPhotoOutput()
        rawLidarSetup()
        setSessionResolution()
    }
    
    func setupMLModels(){
        guard let detectionModelURL = Bundle.main.url(forResource: "yolov8x6-oiv7", withExtension: "mlmodelc") else {
            print("missing detection model url")
            return
        }
        
        guard let detectionModel = try? VNCoreMLModel(for: MLModel(contentsOf: detectionModelURL)) else{
            print("failed to get detection model")
            return
        }
        objectRequest = VNCoreMLRequest(model: detectionModel)
        
        guard let locationModelURL = Bundle.main.url(forResource: "GoogLeNetPlaces", withExtension: "mlmodelc") else {
            print("missing location model url")
            return
        }
        
        guard let locationModel = try? VNCoreMLModel(for: MLModel(contentsOf: locationModelURL)) else{
            print("failed to get location model")
            return
        }
        locationRequest = VNCoreMLRequest(model: locationModel)
        
        
        guard let segmentationModelURL = Bundle.main.url(forResource: "SightSeg-Nano16", withExtension: "mlmodelc") else {
            print("missing segmentation model url")
            return
        }
        do { let segmentationModel = try VNCoreMLModel(for: MLModel(contentsOf: segmentationModelURL));
            segmentationRequest = VNCoreMLRequest(model: segmentationModel)}
        catch{
            print(error)
        }

    }
    
    func setupDepthOutput(){
        depthDataOutput = AVCaptureDepthDataOutput()
        if (captureSession.canAddOutput(depthDataOutput)){
            depthDataOutput.alwaysDiscardsLateDepthData = true
            depthDataOutput.isFilteringEnabled = true
            depthDataOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "distance queue"))
            captureSession.addOutput(depthDataOutput)
            
        }
    }
    
    private func setupLidarCaptureInput() throws {
        let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back)
        
        let format = (device!.formats.last { format in
            format.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange &&
            !format.isVideoBinned &&
            !format.supportedDepthDataFormats.isEmpty
        })
        
        let depthFormat = (format!.supportedDepthDataFormats.last { depthFormat in
            depthFormat.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_DepthFloat16
        })
        
        try? device!.lockForConfiguration()
        device!.activeFormat = format!
        device!.activeDepthDataFormat = depthFormat
        
        device!.unlockForConfiguration()
        
        HFOV = device!.activeFormat.videoFieldOfView
        VFOV = ((HFOV) / 16.0) * 9.0
        
        let depthInput = try? AVCaptureDeviceInput(device: device!)
        captureSession.addInput(depthInput!)
    }

    func rawLidarSetup(){
        try? setupLidarCaptureInput()
        setVideoOutput()
        setupDepthOutput()
    }
    
    func stopVoice(){
        voiceSynthesiser.stopVoice()
    }
    
    override func stopCamera() {
        super.stopCamera()
        vibrationManager.end()
    }
    
    func averageCenterDistance(heatmap: MLMultiArray) -> Float {
        var total: Float = 0
        let size: Float = 5
        
        let smallRatio: Float = floor(size/2)/size
        let bigRatio: Float = round(size/2)/size

        let xRange: [Int] = [Int(round(smallRatio * Float(heatmap.shape[1].intValue))), Int(round(bigRatio * Float(heatmap.shape[1].intValue)))]
        let yRange: [Int] = [Int(round(smallRatio * Float(heatmap.shape[2].intValue))), Int(round(bigRatio * Float(heatmap.shape[2].intValue)))]
    
        for i in xRange[0]..<xRange[1]{
            for j in yRange[0]..<yRange[1]{
                total += Float(truncating: heatmap[i * heatmap.shape[2].intValue + j])
            }
        }
        
        return total / Float((xRange[1] - xRange[0]) * (yRange[1] - yRange[0]))
    }
    
    func makeMLRequest(sampleBuffer: CMSampleBuffer, request: VNRequest){
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
        
        do {
            try requestHandler.perform([request])
        } catch {
            print(error)
        }
    }
    
    override func takePhoto() {
        previewDisplay = false
        if (depthMode == .lidar){
            var photoSettings = AVCapturePhotoSettings()
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                photoSettings.flashMode = AVCaptureDevice.FlashMode.auto
            }
            photoSettings.photoQualityPrioritization = .quality
            photoSettings.isDepthDataDeliveryEnabled = true
            photoSettings.embedsDepthDataInPhoto = true
            photoSettings.isDepthDataFiltered = true
            
            photoOutput.capturePhoto(with: photoSettings, delegate: self)

        }else{
            super.takePhoto()
        }
    }
    override func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        super.photoOutput(output, didFinishProcessingPhoto: photo, error: error)
        
        stopCamera()
        
        let ogCIImage = CIImage(cgImage: photo.cgImageRepresentation()!)
        let displayCIImage = retainCIImageOrientation(image: ogCIImage)
        let calculationCIImage = correctCIImageOrientation(image: ogCIImage)
        addCIPreview(ciImage: displayCIImage)
        
        if ConnectivityChecker.shared.checkConnection(){
            openAIRequest.makeRequest(payload: openAIRequest.imageRequestPayload(base64Image: openAIRequest.convertImageToBase64(input: calculationCIImage), prompt: openAIRequest.promptsForImage(abstraction: detailLevel)), completion: takeOpenAIResponse(_:))
        } else {
            
            //TODO: fix depthmap direction
            Task{
                await onDeviceSceneDescription(ciImage: calculationCIImage, depthData: photo.depthData!)
            }
        }
    }
    
    func onDeviceSceneDescription(ciImage: CIImage, depthData: AVDepthData) async {
        let requestHandler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try requestHandler.perform([segmentationRequest])
        } catch {
            print(error)
        }
        if let results = segmentationRequest.results as? [VNCoreMLFeatureValueObservation], let classMap = results.first?.featureValue.multiArrayValue {
            //print(dataInterpreter.recognizeAllSegmentedClasses(classMap: classMap))
        }
        
        if (depthMode == .lidar){
            var convertedDepth: AVDepthData
            if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
              convertedDepth = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
            } else {
              convertedDepth = depthData
            }
            

            textToSpeech(text: recognizeLocation(ciImage: ciImage) + ". and " + objectRecognitionWithDistance(ciImage: ciImage, depthMap: convertedDepth.depthDataMap))
        }else{
            //MLDepth
        }

    }
    
    private func textToSpeech(text: String){
        isSpeaking = true
        spokenText = text
        voiceSynthesiser.textToSpeech(text: text)
    }
    
    func takeOpenAIResponse(_ input:String){
        if isToggled{
            print(input)
            textToSpeech(text: input)
        }
    }
    
    func mlModelDepth(sampleBuffer: CMSampleBuffer){
        makeMLRequest(sampleBuffer: sampleBuffer, request: self.MLDepthRequest!)
        if let results = MLDepthRequest?.results as? [VNCoreMLFeatureValueObservation], let heatmap = results.first?.featureValue.multiArrayValue {
            //print(heatmap.shape)
            let distance = 300/averageCenterDistance(heatmap: heatmap)
            //print(distance)
            if (distance <= 1.5){
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } else if (distance <= 2.5){
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else if (distance <= 3.5){
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    func recognizeLocation(ciImage: CIImage) -> String{
        let requestHandler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try requestHandler.perform([self.locationRequest])
        } catch {
            print(error)
        }
        guard let observations = self.locationRequest.results as? [VNClassificationObservation] else {print("failed to perform location detection request"); return "failed to perform location detection request"}
        print("location regonition success")
        var locations: [String] = []
        var probablities: [Float] = []
        let _: [()] = observations.compactMap{ observation in
            locations.append(observation.identifier)
            probablities.append(observation.confidence)
        }
        //print(locations)
        var result = ""
        for i in 0..<2{
            result.append(locations[i])
            if (probablities[i] >= 0.5){
                break
            }else if(probablities[i] < 0.15 && result == ""){
                return ""
            }
            if (i==0){
                result += ". or a "
            }
        }
        return "you are at a " + result
    }
    
    func recognizeObjects(ciImage: CIImage) -> [VNRecognizedObjectObservation]{
        let requestHandler = VNImageRequestHandler(ciImage: ciImage)
        try? requestHandler.perform([self.objectRequest])
        
        guard let observations = self.objectRequest.results as? [VNRecognizedObjectObservation] else {
            print("failed to perform object detection request")
            return []
        }
        //TODO: somehow add duplicate objects
        for i in 0..<observations.count{
            // ik there is a bias towards the first detected objects future me can rest in peace that im not stupid
            
        }
        
        print("object regonition success")
        return observations
    }
    
    func objectRecognitionWithDistance(ciImage: CIImage, depthMap: CVPixelBuffer) -> String{
        let width = Float(CVPixelBufferGetWidth(depthMap))
        let height = Float(CVPixelBufferGetHeight(depthMap))
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)

        let observations = recognizeObjects(ciImage: ciImage)
        
        let recognizedStrings = observations.compactMap { observation in
            let object = (Float(observation.boundingBox.midX), Float(observation.boundingBox.midY))
            let generalIndex = Int(height * Float(object.1) * width)
            let specificIndex = Int(Float(object.0) * width)
            let distance = 1 / floatBuffer[generalIndex + specificIndex]
            
            return " a " + observation.labels[0].identifier + " at your " + getAbsoluteObjectLocation(location: object, distance: distance)
        }
        if (recognizedStrings.joined(separator:". ") == ""){
            return "there arent't any objects near you"
        }
        
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        return "there is" + recognizedStrings.joined(separator:". ")
    }
    
    private func pixelBufferToCenterAverage(depthMap: CVPixelBuffer) -> Float{
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        var convertedCenterDepth: Float = 0
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)
        let centerFocusSize = 10
        let halfWidth: Int = width/2
        let halfHeight: Int = height/2
        for row in (halfHeight-centerFocusSize) ..< (halfHeight+centerFocusSize) {
            for col in (halfWidth-centerFocusSize) ..< (halfWidth+centerFocusSize) {
                convertedCenterDepth += floatBuffer[width * row + col]
            }
        }
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
        return Float((centerFocusSize*centerFocusSize*4))/convertedCenterDepth
    }
    
    private func distanceVibration(depth: Float){
        let maxDistance: Float = 2.5
        let minDistance: Float = 1.0

        let clampedDepth = min(max(depth, minDistance), maxDistance)
        let intensity: Float = 1.0 - ((clampedDepth - minDistance) / (maxDistance - minDistance))
        vibrationStates.continuesVibrationIntensity = intensity
        vibrationManager.updateVibrationPattern()
        //UIImpactHeavySingleton.shared.impactOccurred(intensity: CGFloat(intensity))
    }
    
    private func convertDepthData(depthData: AVDepthData) -> AVDepthData{
        var convertedDepth: AVDepthData
        if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
          convertedDepth = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        } else {
          convertedDepth = depthData
        }
        return convertedDepth
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if connection.isVideoOrientationSupported, let videoOrientation = getVideoOrientation() {
            connection.videoOrientation = videoOrientation
        }
        DispatchQueue.global(qos: .default).async { [self] in
            let ciImage = CIImage(cvPixelBuffer: sampleBuffer.imageBuffer!, options: [.applyOrientationProperty: true])
            let smallerciImage = self.reduceImageResolution(ciImage: ciImage, scale: 0.5)
            let requestHandler = VNImageRequestHandler(ciImage: smallerciImage)
            
            
            do {
                try requestHandler.perform([segmentationRequest])
            } catch {
                print(error)
            }
            if let results = segmentationRequest.results as? [VNCoreMLFeatureValueObservation], let classMap = results.first?.featureValue.multiArrayValue {
                //print(dataInterpreter.recognizeAllSegmentedClasses(classMap: classMap))
            }
            //addPreview(imageBuffer: sampleBuffer.imageBuffer!)
            
        }
    }
}

extension DistanceDetection: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if (isToggled){
            restartCamera()
            isSpeaking = false
            vibrationManager.startEngine()
        }
    }
}

extension DistanceDetection: AVCaptureDepthDataOutputDelegate{
    
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        if connection.isVideoOrientationSupported, let videoOrientation = getVideoOrientation() {
            connection.videoOrientation = videoOrientation
        }
        var convertedDepth = convertDepthData(depthData: depthData)
        addPreview(imageBuffer: convertDepthData(depthData: depthData).depthDataMap)
        let ciContext = CIContext()
        let ciImage = CIImage(cvImageBuffer: convertedDepth.depthDataMap)
        let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        CFDataGetBytePtr(cgImage?.dataProvider?.data)
        
        //addPreview(imageBuffer: convertedDepth.depthDataMap)
        //distanceVibration(depth: pixelBufferToCenterAverage(depthMap: convertedDepth.depthDataMap))
        
        
        distanceVibration(depth: pixelBufferToCenterAverage(depthMap: convertedDepth.depthDataMap))
        //vibrationStates.vibrationDirections = dataInterpreter.advancedLidarDistanceInterpretation(depthMap: convertedDepth.depthDataMap).vibrationDirections
        //print(vibrationStates.vibrationDirections)
      }
}
