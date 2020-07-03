//
//  FirebaseInterface.swift
//  iBeaconRadar
//
//  Created by Mihir Chauhan on 4/25/20.
//  Copyright © 2020 Mihir Chauhan. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase
import UIKit

class FirebaseInterface {
    static let ref = Database.database().reference()
    static var username: String?
    static var location: CLLocationCoordinate2D?
    static var score: Int?
    
    static var dict: NSDictionary?
    
    //Setting all of the user info
    
    static func createUser() {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue([])
    }
    
    public static func updateUsername(username: String) { //only set at beginning of app install
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("username").setValue(username)
    }
    public static func updateLocation(currentLocation coordinate: CLLocationCoordinate2D) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("location").child("latitude").setValue(coordinate.latitude)
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("location").child("longitude").setValue(coordinate.longitude)
    }
    public static func updateScore(score: Int) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("score").setValue(score)
    }
    
    public static func getScore() -> Int {
        return 0 // ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).value(forKeyPath: "score") as? Int ?? 0 //  (forKey: "score") as? Int ?? 0
    }
    
    public static func getUsername(database: NSDictionary?) -> String {
        if database != nil {
            return database!["username"] as? String ?? ""
        }
        return ""
    }
    
    //Reads all of the user info
    
}
