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
    let soundURL: NSURL
    var id: SystemSoundID = 0
    
    static func getSound(name: String) -> SoundPlayer? {
        if let url = NSBundle.mainBundle().URLForResource(name, withExtension: "wav") {
            return SoundPlayer(url: url)
        } else {
            print ("Failed to locate \"\(name).wav\"")
            return nil
        }
    }
    
    init(url: NSURL) {
        soundURL = url
        AudioServicesCreateSystemSoundID(soundURL, &id)
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(id)
    }
    
    func play() {
        AudioServicesPlaySystemSound(id)
    }
}