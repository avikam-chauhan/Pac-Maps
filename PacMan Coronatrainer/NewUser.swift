////
////  NewUser.swift
////  PacMan Coronatrainer
////
////  Created by Mathew Joseph on 5/27/20.
////  Copyright © 2020 Avikam Chauhan. All rights reserved.
////
//
//import Foundation
//import CoreLocation
//
//class NewUser{
//    static var UUID = ""
//    static var score = 0
//    static var location: CLLocationCoordinate2D?
//    static var longitude = -122.406417
//    static var latitude = 37.78
//    static var username = ""
//    static var localRadius: Double = 30
//    static var positiveResult: Bool = false
//
//    init(UUID: String, score: Int, location: CLLocationCoordinate2D, username: String, localRadius: Double, positiveResult: Bool){
//        NewUser.UUID = UUID
//        NewUser.score = score
//        NewUser.location = location
//        NewUser.username = username
//        NewUser.localRadius = localRadius
//        NewUser.positiveResult = positiveResult
//    }
//
//    static func getLocalRadius() -> Double{
//        return localRadius
//    }
//
//    static func addPoints(points: Int) {
//        score += points
//    }
//}
