//
//  NavigationManager.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation

enum microphoneLocations{
    case main
    case textDetection
    case textRecognition
    case distanceDetection
    case objectDetection
    case settings
}

enum ViewLocations{
    case main
    case text
    case navigation
}

class LocationManager: NSObject, ObservableObject{
    public static let shared = LocationManager()
    
    @Published var location: ViewLocations = .main
    @Published var isTabviewEnabled = true
    @Published var microphoneLocation: microphoneLocations = .main
    
    override init() {
        super.init()
    }
}
