////
////  FirebaseDatabaseHandler.swift
////  PacMan Coronatrainer
////
////  Created by Mathew Joseph on 5/27/20.
////  Copyright © 2020 Avikam Chauhan. All rights reserved.
////
//
//import Foundation
//import CoreLocation
//import Firebase
//import UIKit
//
//class FirebaseDatabaseHandler: NSObject {
//
//    var mapViewDelegate: MapViewControllerDelegate?
//    var userDelegate: UserDelegate?
//
//     let ref = Database.database().reference()
//     var dict: NSDictionary?
//     var username: String?
//     var location: CLLocationCoordinate2D?
//     var score: Int?
//
//
//    override init() {
//
//    }
//
//    func getAllUsers(handler: @escaping ([User]) -> ()) {
//        var outputArray = [User]()
//        ref.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
//            let value = snapshot.value as? NSDictionary
//            for key in value!.allKeys {
//
//                //            print(key)
//                if let userDictionary = value?.value(forKey: key as! String) as? NSDictionary {
//                    let locationDictionary = userDictionary.value(forKey: "location") as? NSDictionary
//                    //            print(userDictionary!["score"]!)
//                    var tempUser = User(UUID: key as? String ?? "", score: userDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary!["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary!["longitude"] as? Double ?? 0)), username: userDictionary["username"] as? String ?? "")
//
//                    outputArray.append(tempUser)
//                }
//            }
//            handler(outputArray)
//        })
//        //        return outputArray
//    }
//
//    func parseUsers(dictionary: NSDictionary) -> [GenericUser]{
//        var outputArray = [GenericUser]()
//
//        var playerLocations = [CLLocation]()
//        var playerScores = [Int]()
//        var positiveResultUUIDs = [String]()
//
//        let userDictionary = dictionary.value(forKey: "users") as? NSDictionary
//        //        ref.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
//        //            let value = snapshot.value as? NSDictionary
//        for key in userDictionary!.allKeys {
//
//            //            print(key)
//            if let subDictionary = userDictionary!.value(forKey: key as! String) as? NSDictionary {
//                let locationDictionary = subDictionary.value(forKey: "location") as? NSDictionary
//                //            print(userDictionary!["score"]!)
//                let tempUser = GenericUser(UUID: key as? String ?? "", score: subDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary!["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary!["longitude"] as? Double ?? 0)), username: subDictionary["username"] as? String ?? "", localRadius: subDictionary["localRegionMiles"] as? Double ?? 0, positiveResult: subDictionary["positiveResult"] as? Bool ?? false)
//
//                playerLocations += [CLLocation(latitude: CLLocationDegrees(locationDictionary!["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary!["longitude"] as? Double ?? 0))]
//
//                playerScores += [subDictionary["score"] as? Int ?? 0]
//
//                if(tempUser.positiveResult){
//                    positiveResultUUIDs += [tempUser.UUID]
//                }
//
//
//                outputArray.append(tempUser)
//            }
//        }
//
//        mapViewDelegate?.didUpdatePlayerLocations(locations: playerLocations)
//        mapViewDelegate?.didUpdatePlayerScores(playerScores: playerScores)
//        userDelegate?.didUpdatePositiveCase(PositiveUUIDs: positiveResultUUIDs)
//
//        return outputArray
//        //            handler(outputArray)
//        //        })
//    }
//
//
//
//     func updateUserInfo() {
//        getUserDatabase { (dict) in
//            self.ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue(["username":self.username ?? self.getUsername(database: dict) , "location":["latitude": self.location?.latitude ?? 0, "longitude": self.location?.longitude ?? 0], "score":self.score ?? self.getScore(database: dict)])
//        }
//    }
//
//     func createUser() {
//        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).setValue(["username":"" , "location":["latitude": 0, "longitude": 0], "score": 0])
//    }
//
//    public  func updateUsername(username: String) { //only set at beginning of app install
//        self.username = username
//        updateUserInfo()
//    }
//    public  func updateLocation(currentLocation coordinate: CLLocationCoordinate2D) {
//        self.location = coordinate
//        updateUserInfo()
//    }
//    public  func updateScore(score: Int) {
//        self.score = score
//        updateUserInfo()
//    }
//
//    public func getUserDatabase(handler: @escaping (NSDictionary) -> ()) {
//        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).observeSingleEvent(of: .value, with: { (snapshot) in
//            if let dictionary = snapshot.value as? NSDictionary {
//                self.dict = dictionary
//                handler(dictionary)
//            }
//        })
//    }
//
//    public func getPositiveUUID(handler: @escaping (NSDictionary) -> ()) {
//        ref.child("users").queryOrdered(byChild: "positiveResult").queryEqual(toValue: "true").observeSingleEvent(of: .value, with: { (DataSnapshot) in
//
//            if let dictionary = DataSnapshot.value as? NSDictionary {
//                print(dictionary)
//            }
//
//        })
//
//
//
//    }
//
//    public func updatingUserLocation(handler: @escaping (NSDictionary) -> ()) {
//        ref.child("users").child(UIDevice.current.identifierForVendor!.uuidString).observeSingleEvent(of: .value, with: { (snapshot) in
//            if let dictionary = snapshot.value as? NSDictionary {
//                self.dict = dictionary
//                handler(dictionary)
//            }
//        })
//    }
//
//    public  func getScore(database: NSDictionary?) -> Int? {
//        if database != nil {
//            return database!["score"] as? Int
//        }
//        return 0
//    }
//
//    public  func getUsername(database: NSDictionary?) -> String {
//        if database != nil {
//            return database!["username"] as? String ?? ""
//        }
//        return ""
//    }
//
//}
//
//protocol MapViewControllerDelegate {
//    func didUpdatePlayerLocations(locations: [CLLocation])
//    func didUpdatePlayerScores(playerScores: [Int])
//}
//
//protocol UserDelegate {
//    func didUpdatePositiveCase(PositiveUUIDs: [String])
//}
//
