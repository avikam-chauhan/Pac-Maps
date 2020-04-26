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
    
    static func updateUserInfo() {
        getUserDatabase { (dict) in
            ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue(["username":username ?? getUsername(database: dict) , "location":["latitude": location?.latitude ?? 0, "longitude": location?.longitude ?? 0], "score":score ?? getScore(database: dict)])
        }
    }
    
    static func createUser() {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue(["username":"" , "location":["latitude": 0, "longitude": 0], "score": 0])
    }
    
    public static func updateUsername(username: String) { //only set at beginning of app install
        self.username = username
        updateUserInfo()
    }
    public static func updateLocation(currentLocation coordinate: CLLocationCoordinate2D) {
        self.location = coordinate
        updateUserInfo()
    }
    public static func updateScore(score: Int) {
        self.score = score
        updateUserInfo()
    }
    
    public static func getUserDatabase(handler: @escaping (NSDictionary) -> ()) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? NSDictionary {
                self.dict = dictionary
                handler(dictionary)
            }
        })
    }
    
    public static func getScore(database: NSDictionary?) -> Int? {
        if database != nil {
            return database!["score"] as? Int
        }
        return 0
    }
    
    public static func getUsername(database: NSDictionary?) -> String {
        if database != nil {
            return database!["username"] as? String ?? ""
        }
        return ""
    }
    
    //Reads all of the user info
    
}
