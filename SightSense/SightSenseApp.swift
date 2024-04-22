//
//  SightSenseApp.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI

@main
struct SightSenseApp: App {
    @AppStorage("hasDoneTutorial") var hasDoneTutorial: Bool = false
    
    var body: some Scene {
        
        WindowGroup {
            if (hasDoneTutorial == true){
                ContentView()
            }else{
                LaunchScreen()
            }
        }
    }
}
