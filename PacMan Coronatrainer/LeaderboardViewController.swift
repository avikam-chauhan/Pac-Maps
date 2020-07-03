//
//  LeaderboardViewController.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 4/25/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreLocation

class LeaderboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var ref: DatabaseReference!
    var users = [User]() {
        didSet {
            users = users.sorted(by: { (a, b) -> Bool in
                a.score > b.score
            })
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.delegate = self
        tableView.dataSource = self
        
        ref = Database.database().reference()
        getAllUsers { (users) in
            self.users = users
        }
        
        var refHandle = ref.observe(DataEventType.value, with: { (snapshot) in
            let postDict = snapshot.value as? NSDictionary
            self.users = self.parseUsers(dictionary: postDict!)
            self.tableView.reloadData()
            
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "leaderboardCell", for: indexPath)
        
        cell.textLabel?.text = "\(indexPath.row + 1). " + users[indexPath.row].username
        cell.detailTextLabel?.text = "\(users[indexPath.row].score)"
        
        return cell
    }
    
    
    
    
    
    func getAllUsers(handler: @escaping ([User]) -> ()) {
        var outputArray = [User]()
        ref.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            for key in value!.allKeys {
                
                //            print(key)
                if let userDictionary = value?.value(forKey: key as! String) as? NSDictionary {
                    let locationDictionary = userDictionary.value(forKey: "location") as? NSDictionary
                    //            print(userDictionary!["score"]!)
                    var tempUser = User(UUID: key as? String ?? "", score: userDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary?["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary?["longitude"] as? Double ?? 0)), username: userDictionary["username"] as? String ?? "")
                    
                    outputArray.append(tempUser)
                }
            }
            handler(outputArray)
        })
        //        return outputArray
    }
    
    func parseUsers(dictionary: NSDictionary) -> [User]{
        var outputArray = [User]()
        let userDictionary = dictionary.value(forKey: "users") as? NSDictionary
        //        ref.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
        //            let value = snapshot.value as? NSDictionary
        for key in userDictionary!.allKeys {
            
            //            print(key)
            if let subDictionary = userDictionary!.value(forKey: key as! String) as? NSDictionary {
                let locationDictionary = subDictionary.value(forKey: "location") as? NSDictionary
                //            print(userDictionary!["score"]!)
                var tempUser = User(UUID: key as? String ?? "", score: subDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary?["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary?["longitude"] as? Double ?? 0)), username: subDictionary["username"] as? String ?? "")
                
                outputArray.append(tempUser)
            }
        }
        return outputArray
        //            handler(outputArray)
        //        })
    }
    
}
