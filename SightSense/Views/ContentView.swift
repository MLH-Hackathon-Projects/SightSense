//
//  ContentView.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI
import UIKit
import AVFAudio
import PolyKit

struct ContentView: View {
    @AppStorage("hasDoneTutorial") var hasDoneTutorial: Bool = false
    @ObservedObject var microphone: Microphone
    @ObservedObject var locationManager: LocationManager
    @State var isSpeakerEnabled = false

    init(){
        self.microphone = Microphone.shared
        self.locationManager = LocationManager.shared
    }

    var body: some View {
        ZStack{
            TabView(selection: $locationManager.location) {
                HomeView()
                    .tag(ViewLocations.main)
                    .toolbar(.hidden, for: .tabBar)
                NavigationTabView()
                    .tag(ViewLocations.navigation)
                    .toolbar(.hidden, for: .tabBar)
                ReadTextView()
                    .tag(ViewLocations.text)
                    .toolbar(.hidden, for: .tabBar)
            }
            .toolbar(.hidden, for: .tabBar)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            //.disabled(!locationManager.isTabviewEnabled)
            .edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
            .persistentSystemOverlays(.hidden)
            
            HStack{
                if (isSpeakerEnabled){
                    resizablePolygon(polygonWidth: 200, polygonHeight: 200, cornerRadius: 30, logoWidth: 120, logoHeight: 120)
                        .foregroundStyle(LinearGradient(colors: [Color(UIColor(hexString: "#e4b1d8")), Color(UIColor(hexString: "#a8e1dd"))], startPoint: .topTrailing, endPoint: .bottomLeading))
                }
            }

            UniversalNavigationBar(microphone: microphone, homeAction: homeAction, navigationAction: navigationAction, textAction: textAction)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 20)

        }
        .onChange(of: microphone.location){ newValue in
            if (microphone.command == false){
                return
            }
            switch newValue{
            case .main: locationManager.location = .main
            case .settings: locationManager.location = .main
            case .distanceDetection: locationManager.location = .navigation
            case .objectDetection: locationManager.location = .navigation
            case .textDetection: locationManager.location = .text
            case .textRecognition: locationManager.location = .text
            case .locateClass: locationManager.location = .navigation
            }
        }
        .onChange(of: microphone.location){ newValue in
            withAnimation{
                isSpeakerEnabled = (newValue != .main) && microphone.attention
            }
        }
        .onChange(of: microphone.attention){ newValue in
            withAnimation{
                isSpeakerEnabled = (locationManager.location != .main) && newValue
            }
        }
    }
    func homeAction(){
        if (locationManager.location == .main && microphone.location == .main){
            VoiceSynthesis.shared.textToSpeech(text: "you are already at home")
        }
        microphone.location = .main
        locationManager.location = .main
    }
    func navigationAction(){
        if (locationManager.location == .navigation){
            VoiceSynthesis.shared.textToSpeech(text: "you are already at navigation")
        }
        locationManager.location = .navigation
    }
    func textAction(){
        if (locationManager.location == .text){
            VoiceSynthesis.shared.textToSpeech(text: "you are already at text detection")
        }
        locationManager.location = .text
    }
}
