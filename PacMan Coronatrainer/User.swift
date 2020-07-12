//
//  User.swift
//  Quarantraining
//
//  Created by Mathew Joseph on 4/25/20.
//  Copyright © 2020 Mathew Joseph. All rights reserved.
//

import Foundation
import CoreLocation

class User{
    var UUID = ""
    var score = 0
    var location: CLLocationCoordinate2D?
    var username = ""
    var localRadius: Double = 0
    var positiveResult = false

    init(UUID: String, score: Int, location: CLLocationCoordinate2D, username: String){
        self.UUID = UUID
        self.score = score
        self.location = location
        self.username = username
    }
    init(UUID: String, score: Int, location: CLLocationCoordinate2D, username: String, localRadius: Double, positiveResult: Bool){
        self.UUID = UUID
        self.score = score
        self.location = location
        self.username = username
        self.localRadius = localRadius
    }

    func getLocalRadius() -> Double{
        return localRadius
    }
}
