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
    
    static var contactedUsersDictionary = [[String: Any]]()
    
    public static func addContacteduserUUID(UUID: String, Distance distance: String) {
        
        getContactedUsers { (contactedUsers) in
            contactedUsersDictionary = [[String: Any]]()
            if contactedUsers != nil {
                for contactedusers in 0..<(contactedUsers?.count)! {
                    contactedUsersDictionary.append(contactedUsers?[contactedusers] as! [String : Any])
                }
            }
            
            var arrayOfSingleContactedUser = [String: Any]()
            arrayOfSingleContactedUser = ["uuid":UUID, "distance":distance, "timeStampMS":Date().timeIntervalSince1970 * 1000]
            contactedUsersDictionary.append(arrayOfSingleContactedUser)
            ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").setValue(contactedUsersDictionary)
        }
    
        
    }
    
    public static func getContactedUsers(handler: @escaping (Array<NSDictionary>?) -> ()) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").observeSingleEvent(of: .value) { (snapshot) in
            print("SNPST:: \(snapshot.value!)")
            if let arrayOfContactedUsers = snapshot.value as? Array<NSDictionary> {
                print("SNPST: \(snapshot)")
                handler(arrayOfContactedUsers)
                
            } else {
                handler(nil)
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
