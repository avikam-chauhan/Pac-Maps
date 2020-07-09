//
//  SettingsTableViewController.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 7/8/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var textfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 { return 2 }
        return 1
    }

    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            sender.selectedSegmentTintColor = UIColor.systemRed
            let alert = UIAlertController(title: "Warning", message: "Marking yourself as positive for COVID-19 should only be done if you have verified with an official testing method. Please only mark yourself as positive if you are actually positive. If you falsely mark yourself as positive, people you have been in contact with recently will be advised to get tested for COVID-19. We will maintain your privacy and no personal details will be shared with anyone.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok, mark me as positive.", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                sender.selectedSegmentIndex = 0
                sender.selectedSegmentTintColor = UIColor.systemRed
            }))
            alert.addAction(UIAlertAction(title: "Cancel, mark me as negative.", style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) in
                sender.selectedSegmentIndex = 1
                sender.selectedSegmentTintColor = UIColor.systemGreen
            }))
            self.present(alert, animated: true, completion: nil)
        } else if sender.selectedSegmentIndex == 1 {
            sender.selectedSegmentTintColor = UIColor.systemGreen
            let alert = UIAlertController(title: "Warning", message: "Marking yourself as negative for COVID-19 should only be done if you have verified with an official testing method. Please only mark yourself as negative if you are actually negative. If you falsely mark yourself as negative, our contract tracing methods would be able to alert other people to be tested. We will maintain your privacy and no personal details will be shared with anyone.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok, mark me as negative.", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                sender.selectedSegmentIndex = 1
                sender.selectedSegmentTintColor = UIColor.systemGreen
            }))
            alert.addAction(UIAlertAction(title: "Cancel, mark me as positive.", style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) in
                sender.selectedSegmentIndex = 0
                sender.selectedSegmentTintColor = UIColor.systemRed
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
