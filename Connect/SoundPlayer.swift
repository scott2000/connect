//
//  SoundPlayer.swift
//  Connect
//
//  Created by Scott Taylor on 6/5/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import AudioToolbox

class SoundPlayer {
    let soundURL: URL
    var id: SystemSoundID = 0
    
    static func getSound(name: String) -> SoundPlayer? {
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            return SoundPlayer(url: url)
        } else {
            print ("Failed to locate \"\(name).wav\"")
            return nil
        }
    }
    
    init(url: URL) {
        soundURL = url
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &id)
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(id)
    }
    
    func play() {
        AudioServicesPlaySystemSound(id)
    }
}
