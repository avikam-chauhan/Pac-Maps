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
    static var dict = [String: Any]()
    public var firebaseInterfaceDelegate: FirebaseInterfaceDelegate?
    
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
        dict["score"] = score
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
    
    
    public static func addTimeInContactToLastContactedUser(timeInContact: Int) {
        getContactedUsers { (contactedUsers) in
            contactedUsersDictionary = [[String: Any]]()
            if contactedUsers != nil {
                for contactedusers in 0..<(contactedUsers?.count)! {
                    contactedUsersDictionary.append(contactedUsers?[contactedusers] as! [String : Any])
                }
            }
            if contactedUsersDictionary.count > 0 {
                var arrayOfSingleContactedUser = contactedUsersDictionary[contactedUsersDictionary.count - 1]
                arrayOfSingleContactedUser["timeInContact"] = timeInContact
                contactedUsersDictionary.remove(at: contactedUsersDictionary.count - 1)
                contactedUsersDictionary.append(arrayOfSingleContactedUser)
                ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").setValue(contactedUsersDictionary)
            }
        }
    }
    
    public static func getContactedUsers(handler: @escaping (Array<NSDictionary>?) -> ()) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").observeSingleEvent(of: .value) { (snapshot) in
            if let arrayOfContactedUsers = snapshot.value as? Array<NSDictionary> {
                handler(arrayOfContactedUsers)
                
            } else {
                handler(nil)
            }
        }
    }
    
    public static func getContactedUsers(uuid: UUID, handler: @escaping (Array<NSDictionary>?) -> ()) {
        ref.child("users").child(uuid.uuidString).child("allContactedUsers").observeSingleEvent(of: .value) { (snapshot) in
            if let arrayOfContactedUsers = snapshot.value as? Array<NSDictionary> {
                handler(arrayOfContactedUsers)
            } else {
                handler(nil)
            }
        }
    }
    
    
    
    static var familyMembersArrayList = Array<String>()
    
    public static func addFamilyMember(uuid: String) {
        self.isAFamilyMember = true
        
        getFamilyMembers { (familyMembers) in
            familyMembersArrayList = Array<String>()
            if familyMembers != nil {
                for familyMember in 0..<(familyMembers?.count)! {
                    familyMembersArrayList.append((familyMembers?[familyMember])!)
                }
            }
            
            let arrayOfFamilyMember = uuid
            familyMembersArrayList.append(arrayOfFamilyMember)
            ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("familyMembers").setValue(familyMembersArrayList)
        }
        
        
        getContactedUsers { (contactedUsers) in
            contactedUsersDictionary = [[String: Any]]()
            if contactedUsers != nil {
                for contactedusers in 0..<(contactedUsers?.count)! {
                    contactedUsersDictionary.append(contactedUsers?[contactedusers] as! [String : Any])
                }
            }
            var arrayOfRemovalItems: Array<Int> = []
            for contactedUserInfo in 0..<contactedUsersDictionary.count {
                let a = contactedUsersDictionary[contactedUserInfo]
                for value in a.values {
                    if UUID(uuidString: (value as? String) ?? "") != nil && UUID(uuidString: value as! String)?.uuidString == uuid {
                        arrayOfRemovalItems.append(contactedUserInfo)
                    }
                }
            }
            for removalIndex in 0..<arrayOfRemovalItems.count {
                print("removal index \(arrayOfRemovalItems.count - removalIndex) and  \(arrayOfRemovalItems[arrayOfRemovalItems.count - 1 - removalIndex])")
                contactedUsersDictionary.remove(at: arrayOfRemovalItems[arrayOfRemovalItems.count - 1 - removalIndex])
            }
            
            ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").setValue(contactedUsersDictionary)
        }
    }
    
    public static func addFamilyMemberToPlayer(withUUID uuid: UUID) {
        getFamilyMembers(withUUID: uuid) { (familyMembers) in
            var familyMembersArrayList = Array<String>()
            if familyMembers != nil {
                for familyMember in 0..<(familyMembers?.count)! {
                    familyMembersArrayList.append((familyMembers?[familyMember])!)
                }
            }
            
            let arrayOfFamilyMember = UIDevice.current.identifierForVendor!.uuidString
            familyMembersArrayList.append(arrayOfFamilyMember)
            ref.child("users").child(uuid.uuidString).child("familyMembers").setValue(familyMembersArrayList)
        }
        
        
        getContactedUsers(uuid: uuid) { (contactedUsers) in
            var contactedUsersDictionary = [[String: Any]]()
            if contactedUsers != nil {
                for contactedusers in 0..<(contactedUsers?.count)! {
                    contactedUsersDictionary.append(contactedUsers?[contactedusers] as! [String : Any])
                }
            }
            var arrayOfRemovalItems: Array<Int> = []
            for contactedUserInfo in 0..<contactedUsersDictionary.count {
                let a = contactedUsersDictionary[contactedUserInfo]
                for value in a.values {
                    if UUID(uuidString: (value as? String) ?? "") != nil && UUID(uuidString: value as! String)?.uuidString == UIDevice.current.identifierForVendor?.uuidString {
                        arrayOfRemovalItems.append(contactedUserInfo)
                    }
                }
            }
            for removalIndex in 0..<arrayOfRemovalItems.count {
                contactedUsersDictionary.remove(at: arrayOfRemovalItems[arrayOfRemovalItems.count - 1 - removalIndex])
            }
            
            ref.child("users").child(uuid.uuidString).child("allContactedUsers").setValue(contactedUsersDictionary)
        }
    }
    
    public static func removeAllInstancesOfAllContactedUsers(yourUUID: UUID, familyMemberUUID: UUID?) {
        if familyMemberUUID == nil {
            return
        }
        
        getContactedUsers { (contactedUsers) in
            contactedUsersDictionary = [[String: Any]]()
            if contactedUsers != nil {
                for contactedusers in 0..<(contactedUsers?.count)! {
                    contactedUsersDictionary.append(contactedUsers?[contactedusers] as! [String : Any])
                }
            }
            var arrayOfRemovalItems: Array<Int> = []
            for contactedUserInfo in 0..<contactedUsersDictionary.count {
                let a = contactedUsersDictionary[contactedUserInfo]
                for value in a.values {
                    if UUID(uuidString: (value as? String) ?? "") != nil && UUID(uuidString: value as! String)?.uuidString == familyMemberUUID!.uuidString {
                        arrayOfRemovalItems.append(contactedUserInfo)
                    }
                }
            }
            for removalIndex in 0..<arrayOfRemovalItems.count {
                print("removal index \(arrayOfRemovalItems.count - removalIndex) and  \(arrayOfRemovalItems[arrayOfRemovalItems.count - 1 - removalIndex])")
                contactedUsersDictionary.remove(at: arrayOfRemovalItems[arrayOfRemovalItems.count - 1 - removalIndex])
            }
            
            ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("allContactedUsers").setValue(contactedUsersDictionary)
        }
        
        getContactedUsers(uuid: familyMemberUUID!) { (contactedUsers) in
            var contactedUsersDictionary = [[String: Any]]()
            if contactedUsers != nil {
                for contactedusers in 0..<(contactedUsers?.count)! {
                    contactedUsersDictionary.append(contactedUsers?[contactedusers] as! [String : Any])
                }
            }
            var arrayOfRemovalItems: Array<Int> = []
            for contactedUserInfo in 0..<contactedUsersDictionary.count {
                let a = contactedUsersDictionary[contactedUserInfo]
                for value in a.values {
                    if UUID(uuidString: (value as? String) ?? "") != nil && UUID(uuidString: value as! String)?.uuidString == UIDevice.current.identifierForVendor?.uuidString {
                        arrayOfRemovalItems.append(contactedUserInfo)
                    }
                }
            }
            for removalIndex in 0..<arrayOfRemovalItems.count {
                contactedUsersDictionary.remove(at: arrayOfRemovalItems[arrayOfRemovalItems.count - 1 - removalIndex])
            }
            
            ref.child("users").child(familyMemberUUID!.uuidString).child("allContactedUsers").setValue(contactedUsersDictionary)
        }
    }
    
    public func restorePoints(forUUID uuid: UUID, withContactUUID contactedUUID: UUID) {
        FirebaseInterface.getContactedUsers(uuid: uuid) { (contactedUsers) in
            var contactedUsersDictionary = [[String: Any]]()
            if contactedUsers != nil {
                for contactedusers in 0..<(contactedUsers?.count)! {
                    contactedUsersDictionary.append(contactedUsers?[contactedusers] as! [String : Any])
                }
            }
            
            var timeInContactWithFamilyMember: Int = 0
            
            for contactedUserInfo in 0..<contactedUsersDictionary.count {
                let a = contactedUsersDictionary[contactedUserInfo]
                if (a["uuid"] as? String)! == contactedUUID.uuidString {
                    print("is a contacted user")
                    timeInContactWithFamilyMember += a["timeInContact"] as? Int ?? 0
                }
            }
            
            if uuid.uuidString == UIDevice.current.identifierForVendor!.uuidString {
                FirebaseInterface.getScore(forUUID: uuid) { (currentScore) in
                    self.firebaseInterfaceDelegate?.didUpdate(points: (timeInContactWithFamilyMember * 50))
                }
            } else {
                var currentScore: Int? = nil
                FirebaseInterface.getScore(forUUID: uuid) { (score) in
                    print("score  \(score) + \(timeInContactWithFamilyMember)")
                    FirebaseInterface.setScore(forUUID: uuid.uuidString, newScore: score + (timeInContactWithFamilyMember * 50))
                }
            }
            
        }
    }
    
    public static func setScore(forUUID uuid: String, newScore: Int) {
        ref.child("users").child(uuid).child("score").setValue(newScore)
    }
    
    public static func getAllFamilyMembers(forUUID uuid: String, handler: @escaping ([String]) -> ()) {
        ref.child("users").child(uuid).child("familyMembers").observeSingleEvent(of: .value) { (snapshot) in
            if let allFamilyMembers = snapshot.value as? [String] {
                handler(allFamilyMembers)
            }
        }
    }
    
    public static func getFamilyMemberName(fromUUID uuid: String, handler: @escaping (String) -> ()) {
        
        ref.child("users").child(uuid).child("username").observeSingleEvent(of: .value) { (snapshot) in
            if let username = snapshot.value as? String {
                handler(username)
            }
        }
    }
    
    public static func removeFamilyMember(familyMemberUUID: String) {
        getFamilyMembers(withUUID: UIDevice.current.identifierForVendor!) { (familyMembers) in
            if familyMembers != nil {
                var updatedFamilyMembers: [String] = []
                for familyMember in familyMembers! {
                    if familyMember != familyMemberUUID {
                        updatedFamilyMembers.append(familyMember)
                    }
                }
                ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("familyMembers").setValue(updatedFamilyMembers)
            }
        }
        getFamilyMembers(withUUID: UUID(uuidString: familyMemberUUID)!) { (familyMembers) in
            if familyMembers != nil {
                var updatedFamilyMembers: [String] = []
                for familyMember in familyMembers! {
                    if familyMember != UIDevice.current.identifierForVendor!.uuidString {
                        updatedFamilyMembers.append(familyMember)
                    }
                }
                ref.child("users").child(familyMemberUUID).child("familyMembers").setValue(updatedFamilyMembers)
            }
        }
    }
    
    public static func getScore(forUUID uuid: UUID, handler: @escaping (Int) -> ()) {
        ref.child("users").child(uuid.uuidString).child("score").observeSingleEvent(of: .value) { (snapshot) in
            if let currentScore = snapshot.value as? Int {
                userScore = currentScore
                handler(currentScore)
            } else {
                userScore = 0
                handler(0)
            }
        }
    }
    
    public static var isAFamilyMember: Bool = false
    
    public static func checkIfIsAFamilyMember(withUUID uuid: UUID?) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("familyMembers").observeSingleEvent(of: .value) { (snapshot) in
            if let arrayOfContactedUsers = snapshot.value as? Array<String> {
                if arrayOfContactedUsers.firstIndex(of: uuid!.uuidString) != nil {
                    self.isAFamilyMember = true
                }
            } else {
                self.isAFamilyMember = false
            }
        }
        
    }
    
    
    public static func getFamilyMembers(handler: @escaping (Array<String>?) -> ()) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("familyMembers").observeSingleEvent(of: .value) { (snapshot) in
            if let arrayOfContactedUsers = snapshot.value as? Array<String> {
                handler(arrayOfContactedUsers)
            } else {
                handler(nil)
            }
        }
    }
    
    public static func getFamilyMembers(withUUID uuid: UUID, handler: @escaping (Array<String>?) -> ()) {
        ref.child("users").child(uuid.uuidString).child("familyMembers").observeSingleEvent(of: .value) { (snapshot) in
            if let arrayOfContactedUsers = snapshot.value as? Array<String> {
                handler(arrayOfContactedUsers)
            } else {
                handler(nil)
            }
        }
    }
    
    public static func getUserScore(forUUID uuid: String, handler: @escaping (Int) -> ()) {
        ref.child("users").child(uuid).child("score").observeSingleEvent(of: .value) { (snapshot) in
            if let userScore = snapshot.value as? Int {
                handler(userScore)
            }
        }
    }
    
    public static func getScore(database: [String: Any]) -> Int {
        return database["score"] as! Int
    }
    
    public static var userScore: Int = 0
    
    public static func getScore() {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).child("score").observeSingleEvent(of: .value) { (snapshot) in
            if let score = snapshot.value as? Int {
                userScore = score
            } else {
                userScore = 0
            }
        }
    }
    
    public static func getUserDatabase(handler: @escaping (NSDictionary) -> ()) {
        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).observe(DataEventType.value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String : Any] {
                self.dict = dictionary
                handler(dictionary as NSDictionary)
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

protocol FirebaseInterfaceDelegate {
    func didUpdate(points: Int)
}
