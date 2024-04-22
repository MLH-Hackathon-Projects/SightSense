//
//  UserDefaultsManager.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    func initialSetup(){
        if (!bool(forKey: "hasOpened")){
            set(true, forKey: "showCameraPreview")
        }
    }
    
    func set<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func string(forKey key: String, defaultValue: String = "") -> String {
        return UserDefaults.standard.string(forKey: key) ?? defaultValue
    }
    
    func integer(forKey key: String, defaultValue: Int = 0) -> Int {
        let value: Int = UserDefaults.standard.integer(forKey: key)
        return value != 0 ? value : defaultValue
    }
    
    func double(forKey key: String, defaultValue: Double = 0.0) -> Double {
        let value: Double = UserDefaults.standard.double(forKey: key)
        return value != 0.0 ? value : defaultValue
    }
    
    func bool(forKey key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }
}
