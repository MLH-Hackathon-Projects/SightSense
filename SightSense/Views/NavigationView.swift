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

struct NavigationTabView: View {
    @ObservedObject var microphone: Microphone
    @ObservedObject var locationManager: LocationManager
    @StateObject var camera: DistanceDetection
    @StateObject var detectButtonProperties: ButtonModifier
    @State var textPreviewOpacity: Double = 0
    @State var isLoading = false
    @State var isAnswering = false
    
    
    init(){
        self.microphone = Microphone.shared
        self.locationManager = LocationManager.shared
        //print("init navigation")
        _camera = StateObject(wrappedValue: DistanceDetection())
        _detectButtonProperties = StateObject(wrappedValue: ButtonModifier(bg1: Color(UIColor(hexString: "#3C3D59")), bg2: Color(UIColor(hexString: "#27283a")), fg: Color.white, text: "Navigate", secondaryBg1: Color.red, secondaryBg2: Color.blue, secondaryFg: Color.white, secondaryText: "Stop"))
        
    }
    
    var body: some View {
        ZStack{
            GeometryReader { geometry in
                camera.previewImage?
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            ZStack{
//                AskGPTMore()
//                    .frame(width: 300, height: 100)
                TextPreview(text: $camera.spokenText)
                    .opacity(textPreviewOpacity)
                    
                
                if (isLoading){
                    ZStack{
                        Rectangle()
                            .fill(Color(UIColor(hexString: "#383948")).opacity(0.4))
                            .cornerRadius(20)
                            .frame(width: 200, height: 120)
                            .opacity(0.75)
                    }
                    LoadingView()
                }
            }
            ScrollViewWithVerticalScrollDetection(scrollLocation: $camera.detailLevel)
            
        }
        .overlay(alignment: .center){
            buttonsView()
        }
        .onChange(of: camera.previewDisplay){ newValue in
            if (!newValue){
                detectButtonProperties.toggleAllProperties()
            }
        }
        
        .onChange(of: camera.isSpeaking){newValue in
            if (newValue){
                //print ("epic gamering")
                withAnimation{
                    isLoading = false
                    isAnswering = true
                }
            }else{
                detectButtonProperties.toggleAllProperties()
            }
            withAnimation{
                textPreviewOpacity = newValue ? 1.0 : 0.0
            }
        }
        
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onChange(of: locationManager.location) { newValue in
            if(locationManager.location == .navigation){
                ConnectivityChecker.shared.startMonitoring()
                camera.vibrationManager.startEngine()
                textPreviewOpacity = 0.0
                camera.syncStartCamera()
                camera.isToggled = true
                isLoading = false
                isAnswering = false
                //print("distance appeared")
                if (microphone.location == .objectDetection){
                    //print("doing gamer")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        photoButtonHandler()
                    }
                }
                microphone.updateLocation(newLocation: .distanceDetection)
            }
        }
        .onDisappear{
            if (!detectButtonProperties.primaryState){
                detectButtonProperties.toggleAllProperties()
            }
            camera.isToggled = false
            endEverything()
            ConnectivityChecker.shared.stopMonitoring()
            //print("distance disappeared")
        }
    }
    
    func buttonsView() -> some View {
        VStack {
            StaticButtonViewWithIcon(display: AnyView(ScalableImageIcon(name: "exit_page", width: 60, height: 60)), primaryAction: revertToRoot, secondaryAction: VoiceSynthesis.shared.textToSpeech, width: 350, height: 100, text: "Back", bg1: Color(UIColor(hexString: "#EE6666")), bg2: Color(UIColor(hexString: "#a36565")), fg: Color.white, corner: 15)
            
            Spacer()
            
            DynamicButtonViewWitIcon(display1: AnyView(ScalableImageIcon(name: "activate_navigation", width: 50, height: 50)), display2: AnyView(ScalableImageIcon(name: "stop_action", width: 50, height: 50)), primaryAction: photoButtonHandler, secondaryAction: VoiceSynthesis.shared.textToSpeech, width: 350, height: 100, text: $detectButtonProperties.text, bg1: $detectButtonProperties.bg1, bg2: $detectButtonProperties.bg2, fg: $detectButtonProperties.fg, onPrimaryView: $detectButtonProperties.primaryState, corner: 20)
                .offset(y: -80)
        }
    }
    
    func revertToRoot(){
        microphone.commandLocation(newLocation: .main)
    }
    
    func endEverything(){
        camera.stopCamera()
        camera.stopVoice()
        textPreviewOpacity = 0
        isLoading = false
        isAnswering = false
    }
    func photoButtonHandler(){
        if (detectButtonProperties.primaryState){
            takePhoto()
        } else {
            camera.stopVoice()
        }
        microphone.location = .distanceDetection
    }
    
    func takePhoto(){
        camera.takePhoto()
        withAnimation{
            isLoading = true
        }
    }
}
