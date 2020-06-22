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
    static var contactedUsers: Array<String>?
    static var numberOfUsers: Int = 0
    static var dict: NSDictionary?
        
//        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue(["username":username ?? UIDevice.current.identifierForVendor!.uuidString, "location":["latitude": location?.latitude ?? 0, "longitude": location?.longitude ?? 0], "score":score ?? 0, "minorKey": minorKey ?? 0, "familyMembers": familyMembers])
    static func createUser() {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue(["username":"", "location":["latitude": 0, "longitude": 0], "score": 0, "allContactedUsers":[ ["uuid":UIDevice.current.identifierForVendor!.uuidString, "timeStampMS":Date().timeIntervalSince1970*1000, "distance":"Near"]]])
     }
        
    public static func updateUsername(username: String) { //only set at beginning of app install
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("username").setValue(username)
    }
    
    public static func updateLocation(currentLocation coordinate: CLLocationCoordinate2D) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("location").setValue(["latitude": coordinate.latitude, "longitude": coordinate.longitude])
    }
    
    public static func updateScore(score: Int) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("score").setValue(score)
    }
    
    public static func addContacteduserUUID(UUID: String) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").setValue([])
        getContactedUsers { (contactedUsers) in
            var arrayOfContactedUsers: Array<String> = []
            arrayOfContactedUsers = contactedUsers
            print("ACUB: \(arrayOfContactedUsers)")

            arrayOfContactedUsers.append(UUID)
            
            print("ACUA: \(arrayOfContactedUsers)")

            
            ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").setValue(arrayOfContactedUsers)
        }
    }
    
    public static func getContactedUsers(handler: @escaping (Array<Array<String>>) -> ()) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").observeSingleEvent(of: .value) { (snapshot) in
            if let arrayOfContactedUsers = snapshot.value as? Array<Array<String>> {
                print("SNPST: \(snapshot)")
                self.contactedUsers = arrayOfContactedUsers
                handler(arrayOfContactedUsers)
            }
        }
    }

    
    public static func getScore(database: NSDictionary?) -> Int? {
        if database != nil {
            return database!["score"] as? Int
        }
        return 0
    }
    
    public static func getUserDatabase(handler: @escaping (NSDictionary) -> ()) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? NSDictionary {
                self.dict = dictionary
                handler(dictionary)
            }
        })
    }
    
    
    public static func searchUUID(dictionary: NSDictionary, minorKey: Int) -> String? {
        let userDictionary = dictionary.value(forKey: "users") as? NSDictionary
        for key in userDictionary!.allKeys {
            if let subDictionary = userDictionary!.value(forKey: key as! String) as? NSDictionary {
                if(minorKey == subDictionary["minorKey"] as? Int ?? -1){
                    return key as? String
                }
            }
        }
        return nil;
    }
}
