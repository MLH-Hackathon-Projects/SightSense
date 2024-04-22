//
//  DistanceDataInterpreter.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import CoreML
import Vision

class DistanceDataInterpreter{
    
    private let segmentedClasses = ["wall", "building", "sky", "floor", "tree", "ceiling", "road", "bed ", "windowpane", "grass", "cabinet", "sidewalk", "person", "soil", "door", "table", "mountain", "plant", "curtain", "chair", "car", "water", "painting", "sofa", "shelf", "house", "sea", "mirror", "rug", "field", "armchair", "seat", "fence", "desk", "rock", "wardrobe", "lamp", "bathtub", "railing", "cushion", "base", "box", "column", "signboard", "chest of drawers", "counter", "sand", "sink", "skyscraper", "fireplace", "refrigerator", "grandstand", "path", "stairs", "runway", "case", "pool table", "pillow", "screen door", "stairway", "river", "bridge", "bookcase", "blind", "coffee table", "toilet", "flower", "book", "hill", "bench", "countertop", "stove", "palm", "kitchen island", "computer", "swivel chair", "boat", "bar", "arcade machine", "hovel", "bus", "towel", "light", "truck", "tower", "chandelier", "awning", "streetlight", "booth", "television receiver", "airplane", "dirt track", "apparel", "pole", "land", "bannister", "escalator", "ottoman", "bottle", "buffet", "poster", "stage", "van", "ship", "fountain", "conveyer belt", "canopy", "washer", "plaything", "swimming pool", "stool", "barrel", "basket", "waterfall", "tent", "bag", "minibike", "cradle", "oven", "ball", "food", "step", "tank", "trade name", "microwave", "pot", "animal", "bicycle", "lake", "dishwasher", "screen", "blanket", "sculpture", "hood", "sconce", "vase", "traffic light", "tray", "ashcan", "fan", "pier", "crt screen", "plate", "monitor", "bulletin board", "shower", "radiator", "glass", "clock", "flag"]
    
    func getClassName(index: Int) -> String{
        return segmentedClasses[index]
    }
    
    func recognizeAllSegmentedClasses(classMap: MLMultiArray) -> String{
        var detectedClasses: [Int] = []
        var result: String = ""
        
        for i in 0..<classMap.shape[1].intValue{
            for j in 0..<classMap.shape[2].intValue{
                var alreadyDetected = false
                let value = Int(truncating: classMap[i * classMap.shape[2].intValue + j])
                for k in 0..<detectedClasses.count{
                    if (value == detectedClasses[k]){
                        alreadyDetected = true
                        break
                    }
                }
                if (!alreadyDetected){
                    detectedClasses.append(value)
                    result += getClassName(index: value) + ", "
                }
            }
        }
        
        return result
    }
    
    func advancedLidarDistanceInterpretation(depthMap: CVPixelBuffer) -> VibrationStates{
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer: UnsafeMutablePointer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)
        
        
        let distanceStates = generalAdvancedDistanceInterpretation(height: height, width: width, lidarDepthMap: floatBuffer)
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue:0))
        return distanceStates
    }
    
    func advancedMLDistanceInterpretation(depthMap: MLMultiArray) -> VibrationStates{
        let height = depthMap.shape[1].intValue
        let width = depthMap.shape[2].intValue
        
        return generalAdvancedDistanceInterpretation(height: height, width: width, mlDepthMap: depthMap)
    }
    
    private func generalAdvancedDistanceInterpretation(height: Int, width: Int, lidarDepthMap: UnsafeMutablePointer<Float32>? = nil, mlDepthMap: MLMultiArray? = nil) -> VibrationStates{
        let result = VibrationStates(vibrationDirections: VibrationController.VibrationDirections.center, continuesVibrationIntensity: 0, continuesVibrationSharpness: 0)
        var biggestDistance: Float = 0
        var direction: VibrationController.VibrationDirections = .center
        
        let upDistance = configurableInterpreter(configuration: true, XtoConfigure: true, height: height, width: width, lidarDepthMap: lidarDepthMap)
        compareDistanceValues(originalValue: &direction, originalMax: &biggestDistance, newValue: upDistance[0], valueIfTrue: .up)
        
        let rightDistance = configurableInterpreter(configuration: true, XtoConfigure: false, height: height, width: width, lidarDepthMap: lidarDepthMap)
        compareDistanceValues(originalValue: &direction, originalMax: &biggestDistance, newValue: rightDistance[0], valueIfTrue: .right)
        
        let leftDistance = configurableInterpreter(configuration: false, XtoConfigure: false, height: height, width: width, lidarDepthMap: lidarDepthMap)
        compareDistanceValues(originalValue: &direction, originalMax: &biggestDistance, newValue: leftDistance[0], valueIfTrue: .left)
        
        let downDistance = configurableInterpreter(configuration: false, XtoConfigure: true, height: height, width: width, lidarDepthMap: lidarDepthMap)
        compareDistanceValues(originalValue: &direction, originalMax: &biggestDistance, newValue: downDistance[0], valueIfTrue: .down)
        
        result.vibrationDirections = direction
        return result
    }
    
    private func compareDistanceValues(originalValue: inout VibrationController.VibrationDirections, originalMax: inout Float, newValue: Float, valueIfTrue: VibrationController.VibrationDirections) {
        if newValue > originalMax {
            originalValue = valueIfTrue
            originalMax = newValue
        }
    }
    
    
    private func configurableInterpreter(configuration: Bool, XtoConfigure: Bool, height: Int, width: Int, lidarDepthMap: UnsafeMutablePointer<Float32>? = nil, mlDepthMap: MLMultiArray? = nil) -> [Float]{
        var total: Float = 0
        var size = 0
        var max: Float = 0
        let axis1 = XtoConfigure ? height : width
        let axis2 = XtoConfigure ? width : height
        var offset = 0
        
        for i in (configuration ? 0 : Int(round(3.0*Float(axis1)/4.0)))..<(configuration ? Int(round(Float(axis1)/4.0)) : axis1){
            for j in 0..<axis2{
                let heightValue = XtoConfigure ? i : j
                let widthValue  = XtoConfigure ? j : i
                var value: Float
                let index = heightValue * height + widthValue
                if (lidarDepthMap == nil){
                    value = Float(truncating: mlDepthMap![heightValue * (height-1) + widthValue])
                }else{
                    //TODO: shits retarded the value of heightValue*Height+widthValue goes past total value
                    value = Float(lidarDepthMap![heightValue * widthValue + widthValue])
                    //value = Float(lidarDepthMap![1 * height + 1])
                }
                if (value > max){
                    max = value
                }
                total += value
                size += 1
            }
            offset += 1
        }
        return [total/Float(size), max]
    }
    
//TODO: this shit sucks, please fix
    private func pixelBufferToCenterAverage(height: Int, width: Int, lidarDepthMap: UnsafeMutablePointer<Float32>? = nil, mlDepthMap: MLMultiArray? = nil) -> Float{
        var convertedCenterDepth: Float = 0
        
        let centerFocusSize = 10
        let halfWidth: Int = width/2
        let halfHeight: Int = height/2
        for row in (halfHeight-centerFocusSize) ..< (halfHeight+centerFocusSize) {
            for col in (halfWidth-centerFocusSize) ..< (halfWidth+centerFocusSize) {
                if (lidarDepthMap != nil){
                    convertedCenterDepth += lidarDepthMap![width * row + col]
                } else {
                    convertedCenterDepth += Float(truncating: mlDepthMap![width * (row-1) + col])
                }
            }
        }
        
        return Float((centerFocusSize*centerFocusSize*4))/convertedCenterDepth
    }

    
    func advancedObjectDetection(detectionResult: [VNRecognizedObjectObservation]) -> String{
        
        
        return ""
    }
}
