//
//  SoundManager.swift
//  SightSense
//
//  Created by Peter Zhao on 1/12/24.
//

import Foundation
import AVFoundation

class SoundManagerSingleton{
    static let shared = AVPlayer()
    func play(name: String){
        let url = Bundle.main.url(forResource: name, withExtension: "wav")
        replaceCurrentItem(with: <#T##AVPlayerItem?#>)
    }

}
