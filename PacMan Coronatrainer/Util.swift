//
//  Util.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 6/1/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import AudioToolbox
import UIKit

class Util {
    
    private static var vibrate = false
    
    enum VibrateFrequency {
        case FAST
        case REGULAR
    }
    
    static func startVibration(atFrequency frequency: VibrateFrequency) {
        vibrate = true
        if frequency == .FAST {
            startVibration(delayTime: 0.1)
        } else {
            startVibration(delayTime: 1.0)
        }
    }
    
    static func stopVibration() {
        vibrate = false
    }
    
    private static func startVibration(delayTime: Double) {
        for i in 0...13 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(i) * delayTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                if self.vibrate {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                }
            })
        }
    }
    
    
    
}
