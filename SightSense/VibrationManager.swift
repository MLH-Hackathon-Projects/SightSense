//
//  DistanceDataInterpreter.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import CoreHaptics
import UIKit

class VibrationController {
    private var engine: CHHapticEngine!
    
    private var hapticTimer: Timer!
    
//    private var periodicVibrater: Timer!
    
    private let continuousPlayer: CHHapticAdvancedPatternPlayer
    
    private var vibrationStates: VibrationStates
    
    enum VibrationDirections{
        case center
        case left
        case right
        case up
        case down
    }
    
    init(vibrationStates: VibrationStates) {
        self.vibrationStates = vibrationStates
        engine = try! CHHapticEngine()
        
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters: [], relativeTime: 0, duration: 30)
        
        let pattern = try! CHHapticPattern(events: [continuousEvent], parameters: [])
        continuousPlayer = try! engine.makeAdvancedPlayer(with: pattern)
        
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine.stoppedHandler = { reason in self.restartEngine() }
        engine.resetHandler = { [self] in restartEngine() }
    }
    
    
    private func restartEngine() {
        do {
            try self.engine.start()
        } catch {
            print("Failed to start the engine")
        }
    }
    
    func startEngine() {
        try? engine.start()
        try? continuousPlayer.start(atTime: CHHapticTimeImmediate)
        scheduleHapticTimer()
    }
    
    private func restartHapticPattern() {
        do {
            try continuousPlayer.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to restart haptic pattern: \(error)")
        }
    }
    
    private func scheduleHapticTimer() {
        hapticTimer?.invalidate()
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.restartHapticPattern()
        }
        
//        periodicVibrater = Timer.scheduledTimer(withTimeInterval: vibrationStates.directionalVibrationPeriod, repeats: true){ timer in
//            self.periodicVibration()
//        }
    }
    
    private func vibrationEvent(duration: Double, relativeTime: Double = 0) -> CHHapticEvent{
        let hapticIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: vibrationStates.directionalVibrationIntensity)
        let hapticSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: vibrationStates.directionalVibrationSharpness)
        return CHHapticEvent(eventType: .hapticContinuous, parameters: [hapticIntensity, hapticSharpness], relativeTime: relativeTime, duration: duration)
    }
    
    private func periodicVibration() {
        print(vibrationStates.vibrationDirections)
        /*
        // testing shit so that i can get used to it
        switch Int.random(in: 1...5){
        case 1: centerVibration(); print("center")
        case 2: downVibration(); print("down")
        case 3: leftVibration(); print("left")
        case 4: rightVibration(); print("right")
        default: upVibration(); print("up")
        }*/

    
        switch vibrationStates.vibrationDirections{
        case .center: centerVibration()
        case .down: downVibration()
        case .left: leftVibration()
        case .right: rightVibration()
        case .up: upVibration()
        }
    }
    
    private func centerVibration(){
        let long = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.7)
        do {
            let pattern = try CHHapticPattern(events: [long], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    
    private func downVibration(){
        
        let short1 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.1)
        let short2 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.1, relativeTime: 0.25)
        let short3 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.1, relativeTime: 0.5)

        do {
            let pattern = try CHHapticPattern(events: [short1, short2, short3], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    
    private func upVibration(){
        
        let short1 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.1)
        
        do {
            let pattern = try CHHapticPattern(events: [short1], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    private func leftVibration(){

        let short1 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.1)
        let long2 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.3, relativeTime: 0.2)

        do {
            let pattern = try CHHapticPattern(events: [short1, long2], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    private func rightVibration(){
        
        let long1 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.3)
        let short2 = vibrationEvent(duration: vibrationStates.directionalVibrationPeriod * 0.1, relativeTime: 0.4)

        do {
            let pattern = try CHHapticPattern(events: [long1, short2], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    
    func stopPeriodicVibration(){
        hapticTimer?.invalidate()
    }

    public func updateVibrationPattern() {

        let intensityValue: Float = vibrationStates.continuesVibrationIntensity
        let sharpnessValue: Float = vibrationStates.continuesVibrationSharpness


        let parameterIntensity = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensityValue, relativeTime: CHHapticTimeImmediate)
        let parameterSharpness = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpnessValue, relativeTime: CHHapticTimeImmediate)
        
        do {
            try continuousPlayer.sendParameters([parameterIntensity], atTime: CHHapticTimeImmediate)
            try continuousPlayer.sendParameters([parameterSharpness], atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to send haptic parameters: \(error)")
        }
    }
    
    func end() {
        try? continuousPlayer.stop(atTime: CHHapticTimeImmediate)
        if (hapticTimer != nil){
            hapticTimer.invalidate()
        }
        //periodicVibrater?.invalidate()
    }
}

class VibrationStates {
    public var vibrationDirections: VibrationController.VibrationDirections
    public var directionalVibrationIntensity: Float
    public var directionalVibrationSharpness: Float
    public var directionalVibrationPeriod: Double
    public var continuesVibrationIntensity: Float
    public var continuesVibrationSharpness: Float
    
    init(vibrationDirections: VibrationController.VibrationDirections, directionalVibrationIntensity: Float = 1.0, directionalVibrationSharpness: Float = 1.0, directionalVibrationPeriod: Double = 1.0, continuesVibrationIntensity: Float, continuesVibrationSharpness: Float){
        self.vibrationDirections = vibrationDirections
        self.directionalVibrationIntensity = directionalVibrationIntensity
        self.directionalVibrationSharpness = directionalVibrationSharpness
        self.directionalVibrationPeriod = directionalVibrationPeriod
        self.continuesVibrationIntensity = continuesVibrationIntensity
        self.continuesVibrationSharpness = continuesVibrationSharpness
    }
}

class UIImpactMediumSingleton{
    static let shared = UIImpactFeedbackGenerator(style: .medium)
}

class UIImpactRigidSingleton{
    static let shared = UIImpactFeedbackGenerator(style: .rigid)
}

class UIImpactSoftSingleton{
    static let shared = UIImpactFeedbackGenerator(style: .soft)
}

class UIImpactLightSingleton{
    static let shared = UIImpactFeedbackGenerator(style: .light)
}

class UIImpactHeavySingleton{
    static let shared = UIImpactFeedbackGenerator(style: .heavy)
}

class UINotificationSingleton{
    static let shared = UINotificationFeedbackGenerator()
}
