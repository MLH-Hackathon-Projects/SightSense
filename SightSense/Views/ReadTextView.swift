//
//  ReadTextView.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation

import SwiftUI
import UIKit
import AVFAudio

struct ReadTextView: View {
    
    @StateObject var camera: TextRecognition
    @ObservedObject var microphone: Microphone
    @StateObject var readButtonProperties: ButtonModifier
    @ObservedObject var locationManager: LocationManager
    
    init(){
        self.microphone = Microphone.shared
        self.locationManager = LocationManager.shared
        //print("init reading")
        _camera = StateObject(wrappedValue: TextRecognition())
        _readButtonProperties = StateObject(wrappedValue: ButtonModifier(bg1: Color(UIColor(hexString: "#3C3D59")), bg2: Color(UIColor(hexString: "#27283a")), fg: Color.white, text: "Read", secondaryBg1: Color.red, secondaryBg2: Color.blue, secondaryFg: Color.white, secondaryText: "Stop"))
    }
    
    var body: some View {
        GeometryReader { geometry in
            camera.previewImage?
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        
        .overlay(alignment: .center){
            VStack{
                buttonsView()
                //UniversalNavigationBar(microphone: microphone, voiceSynthesizer: voiceSynthesiser, homeAction:revertToRoot, navigationAction: {locationManager.toggle1()}, textAction: {voiceSynthesiser.textToSpeech(text: "you are already at text detection")})
            }
        }
        .onChange(of: camera.previewDisplay){newValue in
            readButtonProperties.toggleAllProperties()
            //print("yfsesduifh")
        }
        
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        
        .onChange(of: locationManager.location){newValue in
            if(locationManager.location == .text){
                //print("text appeared")
                camera.vibrationManager.startEngine()
                camera.stopHaptics()
                
                camera.syncStartCamera()
                camera.isToggled = true
                
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if (microphone.location == .textRecognition){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        photoButtonHandler()
                    }
                }
                microphone.updateLocation(newLocation: .textDetection)
            }
        }
        .onDisappear{
            if (!readButtonProperties.primaryState){
                readButtonProperties.toggleAllProperties()
            }
            camera.isToggled = false
            //print("text disappeared")
            endEverything()
            camera.vibrationManager.end()
        }
        .gesture(MagnificationGesture()
            .onChanged { scale in
                camera.updateZoom(zoom: min(max(scale.magnitude, 1), 5.0))
            }
            .onEnded { scale in
                camera.updateZoom(zoom: 1)
            }
        )
    }
    
    func buttonsView() -> some View {
        VStack {
            StaticButtonViewWithIcon(display: AnyView(ScalableImageIcon(name: "exit_page", width: 60, height: 60)), primaryAction: revertToRoot, secondaryAction: VoiceSynthesis.shared.textToSpeech, width: 350, height: 100, text: "Back", bg1: Color(UIColor(hexString: "#EE6666")), bg2: Color(UIColor(hexString: "#a36565")), fg: Color.white, corner: 15)
            Spacer()
            DynamicButtonViewWitIcon(display1: AnyView(ScalableImageIcon(name: "activate_text", width: 50, height: 50)), display2: AnyView(ScalableImageIcon(name: "stop_action", width: 50, height: 50)), primaryAction: photoButtonHandler, secondaryAction: VoiceSynthesis.shared.textToSpeech, width: 350, height: 100, text: $readButtonProperties.text, bg1: $readButtonProperties.bg1, bg2: $readButtonProperties.bg2, fg: $readButtonProperties.fg, onPrimaryView: $readButtonProperties.primaryState, corner: 20)
                .offset(y: -80)
        }
    }
    
    func revertToRoot(){
        microphone.commandLocation(newLocation: .main)
    }
    
    func endEverything(){
        camera.stopCamera()
        camera.stopVoice()
    }
    
    func photoButtonHandler(){
        if (readButtonProperties.primaryState){
            camera.takePhoto()
        } else {
            camera.stopVoice()
        }
        microphone.location = .textDetection
    }
}
