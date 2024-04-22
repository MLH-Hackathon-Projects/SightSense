//
//  CameraBase.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import UIKit
import SwiftUI
import Vision
import AVFoundation

class CameraBase: NSObject, ObservableObject{
    var videoDevice: AVCaptureDevice?
    let captureSession = AVCaptureSession()
    @Published var previewImage: Image?
    @Published var previewDisplay = true
    @Published var isToggled = false
    var previewDisabled = false
    let photoOutput = AVCapturePhotoOutput()
    var videoDataOutput: AVCaptureVideoDataOutput!
    var deviceInput: AVCaptureDeviceInput?
    
    var HFOV: Float = 0
    var VFOV: Float = 0
    
    override init(){
        super.init()
        setUpSession()
    }
    
    func setUpSession() {
        if (!captureSession.isRunning){
            captureSession.beginConfiguration()
            
            setupCamera()
        
            setVideoOutput()
            setSessionResolution()
            setPhotoOutput()
            setPreview()
            
            captureSession.commitConfiguration()
            //print("camera base set up success")
        }
    }
    
    func setPreview(){
        previewDisabled = UserDefaults.standard.bool(forKey: "previewDisabled")
    }
    
    func setupCamera(){
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            videoDevice = device
            //print("using dual camera")
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            videoDevice = device
            //print("using wideangle camera")
        } else {
            fatalError("Missing expected back camera device.")
        }
        
        HFOV = videoDevice!.activeFormat.videoFieldOfView
        VFOV = HFOV / 16.0 * 9.0
        
        try? deviceInput = AVCaptureDeviceInput(device: videoDevice!)
        
        if (captureSession.canAddInput(deviceInput!)){
            captureSession.addInput(deviceInput!)
        }
    }
    
    func setVideoOutput(){
        videoDataOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoStream")
        if captureSession.canAddOutput(videoDataOutput) {
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
            captureSession.addOutput(videoDataOutput)
        }
    }
    func setPhotoOutput(){
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        if (captureSession.canAddOutput(photoOutput)){
            captureSession.addOutput(photoOutput)
        }else{
            //print("Unable to get photo output for some reason")
        }
    }
    
    func setSessionResolution(){
        switch UserDefaults.standard.float(forKey: "detectionSpeed") {
        case 1: captureSession.sessionPreset = .hd4K3840x2160
        case 3: captureSession.sessionPreset = .hd1280x720
        default: captureSession.sessionPreset = .hd1920x1080
        }
    }
    
    func getDeviceOrientation() -> UIDeviceOrientation{
        var orientation = UIDevice.current.orientation
        if orientation == UIDeviceOrientation.unknown {
            orientation = .portrait
        }
        return orientation
    }
    
    func getCGRectAveragePoint(location: CGRect) -> (Float, Float){
        return (Float(location.midX), Float(location.midY))
    }
    
    func correctCordForRotation(input: (Float, Float)) -> (Float, Float){
        switch getDeviceOrientation(){
        case .landscapeLeft: return (1-input.0, 1-input.1)
        case .landscapeRight: return input
        case .portraitUpsideDown: return (1-input.1, input.0)
        default: return (input.1, 1-input.0)
        }
    }
    
    func getRelativeObjectLocationForVibration(location: (Float, Float)) -> VibrationController.VibrationDirections{
        
        return .center
    }
    
    func getAbsoluteObjectLocation(location: (Float, Float), distance: Float) -> String{
        let xFOVR = HFOV / 360 * Float.pi
        let yFOVR = VFOV / 360 * Float.pi
        var xLocation = "center"
        var yLocation = "center"
        let xOffset = getObjectOffsetFromCenter(point: Float(location.0), distance: distance, FOV: xFOVR)
        let yOffset = getObjectOffsetFromCenter(point: Float(location.1), distance: distance, FOV: yFOVR)

        if (xOffset > 0.75){
            xLocation = "far left"
        } else if(xOffset > 0.3){
            xLocation = "left"
        }else if (xOffset < -0.75){
            xLocation = "far right"
        } else if(xOffset < -0.3){
            xLocation = "right"
        }
        
        if (yOffset < -0.75){
            yLocation = "far upper"
        } else if(yOffset < -0.3){
            yLocation = "upper"
        }else if (yOffset > 0.75){
            yLocation = "far lower"
        } else if(yOffset > 0.3){
            yLocation = "lower"
        }
        if (xLocation == yLocation){
            return "center"
        }
        return yLocation + " " + xLocation
    }
    
    /*
                | (0.5, 1)
                |
     (0, 0.5)   |   (1, 0.5)
     -----------------------
                |
                |
                | (0.5, 0)
     */
    
    func getObjectOffsetFromCenter(point: Float, distance: Float, FOV: Float) -> Float{
        let ratio = 0.5 - point
        let cameraAngle = ratio * FOV
        return sin(cameraAngle) * distance
    }
    
    func reduceImageResolution(ciImage: CIImage, scale: Float) -> CIImage{
        let filter = CIFilter(name: "CILanczosScaleTransform")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        filter?.setValue(1.0, forKey: kCIInputAspectRatioKey)
        return (filter?.outputImage)!
    }
    
    func getVideoOrientation() -> AVCaptureVideoOrientation? {
        //return AVCaptureVideoOrientation.portrait
        
         let orientation = getDeviceOrientation()
         switch orientation {
         case .portrait: return AVCaptureVideoOrientation.portrait
         case .portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
         case .landscapeLeft: return AVCaptureVideoOrientation.landscapeRight
         case .landscapeRight: return AVCaptureVideoOrientation.landscapeLeft
         default: return AVCaptureVideoOrientation.portrait
         }
    }
    func retainCIImageOrientation(image: CIImage) -> CIImage{
        return image.oriented(.right)
    }

    func correctCIImageOrientation(image: CIImage) -> CIImage{
        let orientation = getDeviceOrientation()
        switch orientation {
        case .portrait:
            return image.oriented(.right)
        case .landscapeRight:
            return image.oriented(.down)
        case .landscapeLeft:
            return image.oriented(.up)
        case .portraitUpsideDown:
            return image.oriented(.left)
        default:
            return image.oriented(.right)
        }
    }
    
    func retainCorrectedCIImageOrientation(image: CIImage) -> CIImage{
        let orientation = getDeviceOrientation()
        switch orientation {
        case .portrait:
            return image.oriented(.up)
        case .landscapeRight:
            return image.oriented(.left)
        case .landscapeLeft:
            return image.oriented(.right)
        case .portraitUpsideDown:
            return image.oriented(.down)
        default:
            return image.oriented(.right)
        }
    }
    
    func googleImageOrientation(
      deviceOrientation: UIDeviceOrientation,
      cameraPosition: AVCaptureDevice.Position
    ) -> UIImage.Orientation {
      switch deviceOrientation {
      case .portrait:
        return cameraPosition == .front ? .leftMirrored : .right
      case .landscapeLeft:
        return cameraPosition == .front ? .downMirrored : .up
      case .portraitUpsideDown:
        return cameraPosition == .front ? .rightMirrored : .left
      case .landscapeRight:
        return cameraPosition == .front ? .upMirrored : .down
      case .faceDown, .faceUp, .unknown:
        return .up
      @unknown default:
         fatalError()
      }
    }
    
    func pixelBufferToUIImage(imageBuffer: CVImageBuffer) -> UIImage{
        let image = CIImage(cvPixelBuffer: imageBuffer, options: [.applyOrientationProperty: true])
        let context = CIContext()
        if let cgImg = context.createCGImage(image, from: image.extent) {
            return UIImage(cgImage: cgImg)
        }
        return UIImage()
    }
    func syncStartCamera(){
        Task{
            await startCamera()
        }
    }

    func startCamera() async{
        if (!captureSession.isRunning){
            captureSession.startRunning()
        }
    }
    
    func stopCamera() {
        captureSession.stopRunning()
        print(captureSession.isRunning)
    }
    
    func restartCamera(){
        
        previewDisplay = true
        updateZoom(zoom: 1)
        
        if (!captureSession.isRunning){
            Task{
                await startCamera()
            }
            //print("restarting camera")

        }
    }
    func addPreview(imageBuffer: CVImageBuffer) {
        let image = CIImage(cvPixelBuffer: imageBuffer, options: [.applyOrientationProperty: true])
        addCIPreview(ciImage: image)
    }
    func addCIPreview(ciImage: CIImage) {
        let context = CIContext()
        if let cgImg = context.createCGImage(ciImage, from: ciImage.extent) {
            addCGPreview(cgImage: cgImg)
        }
    }
    func addCGPreview(cgImage: CGImage){
        Task { @MainActor in
            if (!previewDisabled){
                let uiImage = UIImage(cgImage: cgImage)
                previewImage = Image(uiImage: uiImage)
            }
        }
    }
    
    func takePhoto(){
        previewDisplay = false
        var photoSettings = AVCapturePhotoSettings()
        photoSettings.photoQualityPrioritization = .quality
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            photoSettings.flashMode = AVCaptureDevice.FlashMode.auto
        }
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func updateZoom(zoom: CGFloat){
        do {
            try videoDevice?.lockForConfiguration()
            defer { videoDevice?.unlockForConfiguration() }
                videoDevice?.videoZoomFactor = zoom
            } catch {
                //print("zoom failed check camerabase 337")
        }
    }

}

extension CameraBase: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.isVideoOrientationSupported,
            let videoOrientation = getVideoOrientation() {
            connection.videoOrientation = videoOrientation
        }
        addPreview(imageBuffer: sampleBuffer.imageBuffer!)
    }
}

extension CameraBase: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        AudioServicesDisposeSystemSoundID(1108)
    }
}
