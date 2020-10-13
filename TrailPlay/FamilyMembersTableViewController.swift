//
//  FamilyMembersTableViewController.swift
//  TrailPlay
//
//  Created by Mihir Chauhan on 7/9/20.
//  Copyright © 2020 Mihir Chauhan. All rights reserved.
//

import UIKit

class FamilyMembersTableViewController: UITableViewController {
    
    var allFamilyMembers: [String] = []
    var allFamilyMemberUUIDs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = UIColor.systemBackground
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        FirebaseInterface.getAllFamilyMembers(forUUID: UIDevice.current.identifierForVendor!.uuidString) { (familyMembers) in
            self.allFamilyMemberUUIDs = familyMembers
            for familyMember in familyMembers {
                FirebaseInterface.getFamilyMemberName(fromUUID: familyMember) { (username) in
                    self.allFamilyMembers.append(username)
                    self.tableView.reloadData()
                }
            }
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // You other cell selected functions here ...
        // then add the below at the end of it.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return allFamilyMembers.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = allFamilyMembers[indexPath.row]
        
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueID" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = segue.destination as! FamilyMemberDetailsViewController
                controller.selectedUUID = allFamilyMemberUUIDs[indexPath.row]
            }
            
            // perform custom segue operation.
        }
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            FirebaseInterface.removeFamilyMember(familyMemberUUID: allFamilyMemberUUIDs[indexPath.row])
            allFamilyMembers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
