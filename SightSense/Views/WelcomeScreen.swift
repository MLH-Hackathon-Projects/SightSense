//
//  LaunchScreen.swift
//  SightSense
//
//  Created by Peter Zhao & Owen Gregson on 4/6/24.
//

import SwiftUI

struct LaunchScreen: View {
    @AppStorage("hasDoneTutorial") var hasDoneTutorial: Bool = false
    
    
    private var microphone: Microphone
    @StateObject var welcomeManager: WelcomeManager
    
    @State var location: ViewLocations = .main
    @State var oldLocation: ViewLocations = .main
    
    init(){
        self.microphone = Microphone.shared
        _welcomeManager = StateObject(wrappedValue: WelcomeManager())
    }

    var body: some View {
        ZStack{
            TabView(selection: $location) {
                GeometryReader { geometry in
                    backgroundGradient
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                    .tag(ViewLocations.main)
                    .toolbar(.hidden, for: .tabBar)
                GeometryReader { geometry in
                    backgroundGradient
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                    .tag(ViewLocations.navigation)
                    .toolbar(.hidden, for: .tabBar)
                GeometryReader { geometry in
                    backgroundGradient
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                    .tag(ViewLocations.text)
                    .toolbar(.hidden, for: .tabBar)
            }
            .toolbar(.hidden, for: .tabBar)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
            .persistentSystemOverlays(.hidden)

            
            Button(action: {hasDoneTutorial = true}, label: {
                Text("exit tutorial cuz")
            })
            
            UniversalNavigationBar(microphone: microphone, homeAction: homeAction, navigationAction: navigationAction, textAction: textAction)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 20)
        }
        .onChange(of: location){ newLocation in
            switch location{
            case .navigation: if (oldLocation == .main){welcomeManager.nextStep(); oldLocation = .navigation}
            case .text: if (oldLocation == .navigation){welcomeManager.nextStep(); oldLocation = .text}
            case .main: if (oldLocation == .text){welcomeManager.nextStep(); oldLocation = .text}
            }
        }
        .onChange(of: welcomeManager.isSpeaking){ mode in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if (welcomeManager.isSpeaking == false && welcomeManager.progress == .complete){
                    hasDoneTutorial = true
                }
            }
        }
        .onDisappear{
            VoiceSynthesis.shared.stopVoice()
        }
    }
    
    func homeAction(){
        location = .main
    }
    func navigationAction(){
        location = .navigation
    }
    func textAction(){
        location = .text
    }
}
