//
//  TextRecognition.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import UIKit
import SwiftUI
import Vision
import AVFoundation
import MLKit

class TextRecognition: CameraBase {
    private var voiceSynthesiser: VoiceSynthesis
    private var textConfidence = 0
    private var vibrationPeriodCounter = 0
    
    private var textRequest = VNRecognizeTextRequest()
    
    private var documentRequest = VNDetectDocumentSegmentationRequest()
    
    private var detectionRequest: VNRecognizeTextRequest?
    //private var advancedDetectionRequest: TextRecognizer?
    
    let vibrationManager: VibrationController
    private var vibrationStates: VibrationStates
    
    private var previousDetectedText = ""
    
    override init(){
        self.voiceSynthesiser = VoiceSynthesis()
        vibrationStates = VibrationStates(vibrationDirections: .center, continuesVibrationIntensity: 0.0, continuesVibrationSharpness: 0.0)
        vibrationManager = VibrationController(vibrationStates: vibrationStates)
    }
    
    override internal func setUpSession() {
        super.setUpSession()
        voiceSynthesiser.synthesizer.delegate = self
        self.textRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = [UserDefaults.standard.string(forKey: "readingLanguage") ?? "en-US"]
        detectionRequest = VNRecognizeTextRequest()
        detectionRequest!.recognitionLevel = .fast
        
        textRequest.usesLanguageCorrection = true
    }
    
    public func stopHaptics(){
        vibrationStates.continuesVibrationIntensity = 0.0
        vibrationManager.updateVibrationPattern()
    }
    
    private func hapticFeedBack() {
        if (vibrationPeriodCounter >= (10-textConfidence)) {
            vibrationPeriodCounter = 0
            if (textConfidence <= 4 && textConfidence >= 2){
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else if (textConfidence <= 7 && textConfidence >= 2) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } else if (textConfidence <= 10 && textConfidence >= 2) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        vibrationPeriodCounter += 1
    }
    
    func stopVoice(){
        voiceSynthesiser.stopVoice()
    }
    
    func documentSegmentation(sampleBuffer: CMSampleBuffer) -> [VNRectangleObservation]?{
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
        try? handler.perform([self.documentRequest])
        return detectionRequest?.results
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let recognizedStrings = observations.compactMap { observation in
            return observation.topCandidates(1).first?.string
        }
        
        if(!recognizedStrings.isEmpty){
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    func textInFrameConfidence(ciImage: CIImage) ->Int{
        var confidence: Int = 0
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([self.detectionRequest!])
        let results = detectionRequest?.results as? [VNRecognizedTextObservation]
        
        var detectedString = ""
        for recognizedText in results! {
            guard let topCandidate = recognizedText.topCandidates(1).first else { continue }
            detectedString += topCandidate.string
        }
        
        if (detectedString != "" && (detectedString.count > 50 || (detectedString.similarity(to: previousDetectedText) > 0.35))){
            confidence = 1
        }else{
            confidence = 0
        }
        previousDetectedText = detectedString
        return confidence
    }
    
        
    func readText(image: CIImage){
        let requestHandler = VNImageRequestHandler(ciImage: image)
        try? requestHandler.perform([textRequest])
        guard let observations = textRequest.results else { return }
        let recognizedStrings = observations.compactMap { observation in
            if (observation.confidence >= 0.25 && observation.topCandidates(1).first?.string.count ?? 0 >= 1){
                return observation.topCandidates(1).first?.string
            }
            return ""
        }
        voiceSynthesiser.textToSpeech(text: recognizedStrings.joined(separator:". "))
    }
    
    func saliencyCrop(image: CIImage, type: VNImageBasedRequest) -> CIImage{
        let cropRequests = type
        let handler = VNImageRequestHandler(ciImage: image)
        try? handler.perform([cropRequests])
        guard let result = cropRequests.results?.first else {return image}
        if let observation = result as! VNSaliencyImageObservation?{
            let objects = observation.salientObjects
            let salientRect = VNImageRectForNormalizedRect((objects?.first?.boundingBox) ?? CGRect(x: 0,y: 0,width: Int(image.extent.size.width), height: Int(image.extent.size.height)), Int(image.extent.size.width), Int(image.extent.size.height))
            return image.cropped(to: salientRect)
        }
        return image
    }
    
    func findDocumentCenter(rectangle: [VNRectangleObservation]) -> [Double]?{
        if ((rectangle.first?.topLeft) != nil){
            return nil
        }
        return [Double((rectangle.first?.topLeft.x ?? 0) + (rectangle.first?.bottomRight.x ?? 0)) / 2, Double((rectangle.first?.topLeft.y)! + (rectangle.first?.bottomRight.y)!) / 2]
    }
    
    func OCRPreprocessing(image: CIImage) -> CIImage{
        let filters = image.autoAdjustmentFilters()
        let noiseReductionFilter = CIFilter(name: "CINoiseReduction")

        noiseReductionFilter!.setValue(image, forKey: kCIInputImageKey)
        noiseReductionFilter!.setValue(0.4, forKey: kCIInputSharpnessKey)
        noiseReductionFilter!.setValue(0.4, forKey: kCIInputContrastKey)

        return noiseReductionFilter!.outputImage!
    }
    
    func textPositionDetection(sampleBuffer: CMSampleBuffer) -> [Double]?{
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
        try? handler.perform([self.detectionRequest!])
        let results = detectionRequest?.results
        let boxes = results?.compactMap{observation in
            return observation.boundingBox
        }
//        let confidences = results?.compactMap{observation in
//            return observation.confidence
//        }
        if (boxes != nil) {
            var xTotal: CGFloat = 0
            var yTotal: CGFloat = 0
            for i in 0..<boxes!.count{
                xTotal += boxes![i].midX
                yTotal += boxes![i].midY
            }
            return [Double(xTotal)/Double(boxes!.count), Double(yTotal)/Double(boxes!.count)]
        }
        return nil
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        if connection.isVideoOrientationSupported,
//            let videoOrientation = getVideoOrientation() {
//            connection.videoOrientation = videoOrientation
//        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let aiImage = correctCIImageOrientation(image: ciImage)
        
        let displayImage = retainCIImageOrientation(image: ciImage)
        
        addCIPreview(ciImage: displayImage)

        if (textInFrameConfidence(ciImage: aiImage) == 1){
            //UINotificationFeedbackGenerator().notificationOccurred(.success)
            vibrationStates.continuesVibrationIntensity = 1.0
        }else{
            vibrationStates.continuesVibrationIntensity = 0.0
        }
        vibrationManager.updateVibrationPattern()
    }
    
    override func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        super.photoOutput(output, didFinishProcessingPhoto: photo, error: error)
        stopCamera()
        vibrationManager.end()
        
        let ciImage = CIImage(data: photo.fileDataRepresentation()!)
        
        addCIPreview(ciImage: retainCIImageOrientation(image: ciImage!))
        
        let aiImage = correctCIImageOrientation(image: ciImage!)
        let croppedImage = saliencyCrop(image: aiImage, type: VNGenerateAttentionBasedSaliencyImageRequest())
        
        readText(image: croppedImage)
        //addCIPreview(ciImage: image)
    }
}

extension TextRecognition: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        //print ("hahaha hohohoho")
        if (isToggled){
            restartCamera()
            vibrationManager.startEngine()
            stopHaptics()
        }
    }
}
