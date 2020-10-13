//
//  GhostAnnotation.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 4/24/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class CustomAnnotation: MKPointAnnotation {
    
    enum AnnotationType {
        case pac_man
        case ghost_red
        case flag
    }

    var pinCustomImageName: String!
    var UUID: String?
        
    init (annotationType: AnnotationType, location: CLLocation, UUID: String) {
        self.UUID = UUID
        if annotationType == .flag {
            pinCustomImageName = "flag"
        } else if annotationType == .pac_man {
            pinCustomImageName = "player"
        } else if annotationType == .ghost_red {
            pinCustomImageName = "ghost"
        }
    }
    
}
