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
    static var familyMembers: [Int] = []
    static var minorKey: Int?
    static var numberOfUsers: Int = 0
        
//        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue(["username":username ?? UIDevice.current.identifierForVendor!.uuidString, "location":["latitude": location?.latitude ?? 0, "longitude": location?.longitude ?? 0], "score":score ?? 0, "minorKey": minorKey ?? 0, "familyMembers": familyMembers])
    
        
    public static func updateUsername(username: String) { //only set at beginning of app install
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("username").setValue(username)
    }
    
    public static func updateLocation(currentLocation coordinate: CLLocationCoordinate2D) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("location").setValue(["latitude": coordinate.latitude, "longitude": coordinate.longitude])
    }
    
    public static func updateScore(score: Int) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("score").setValue(score)
    }
    
    public static func addAFamilyMember(familyMemberMinorKey: Int) {
        familyMembers.append(familyMemberMinorKey)
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("familyMembers").setValue(familyMembers)
    }
    
    public static func updateMinorKey(minorKey: Int) {
        self.minorKey = minorKey
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("minorKey").setValue(minorKey)
    }
    
    public static func updateFamilyMemberFamilyMembers(familyMemberUUID: String) {
        var theirFamilyArray: [Int] = []
        getTheirFamilyMemberArray { (theirArrayList) in
            theirFamilyArray = theirArrayList
        }
        theirFamilyArray.append(minorKey ?? 0)
        
        ref.child("users").child(familyMemberUUID).child("familyMembers").setValue(theirFamilyArray)
    }
    
    //
    //
    //
    
    public static func getTheirFamilyMemberArray(handler: @escaping ([Int]) -> ()) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let theirArray = snapshot.childSnapshot(forPath: "users").childSnapshot(forPath: UIDevice.current.identifierForVendor!.uuidString).childSnapshot(forPath: "minorKey").value as? [Int] {
                handler(theirArray)
            }
        })
    }
    
    public static func getuserCount(handler: @escaping (Int) -> ()) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            handler(Int(snapshot.childSnapshot(forPath: "users").childrenCount))
        })
    }

    public static func doesHaveMinorKey(handler: @escaping (Bool) -> ()) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.childSnapshot(forPath: "users").childSnapshot(forPath: UIDevice.current.identifierForVendor!.uuidString).childSnapshot(forPath: "minorKey").exists()) {
                handler(true)
            } else {
                handler(false)
            }
        })
    }

    public static func getCurrentMinorkey(handler: @escaping (Int) -> ()) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let minorkey = snapshot.childSnapshot(forPath: "users").childSnapshot(forPath: UIDevice.current.identifierForVendor!.uuidString).childSnapshot(forPath: "minorKey").value as? Int {
                handler(minorkey)
            }
        })
    }
    
    public static func getUserDatabase(handler: @escaping (NSDictionary) -> ()) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? NSDictionary {
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
