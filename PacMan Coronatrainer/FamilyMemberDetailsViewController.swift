//
//  FamilyMemberDetailsViewController.swift
//  PacMan Coronatrainer
//
//  Created by Mihir Chauhan on 7/9/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import UIKit

class FamilyMemberDetailsViewController: UIViewController {
    var selectedUUID: String? = nil
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var rankImageView: UIImageView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(selectedUUID)
        FirebaseInterface.getFamilyMemberName(fromUUID: selectedUUID!) { (username) in
            self.usernameLabel.text = username
        }
        
        FirebaseInterface.getUserScore(forUUID: selectedUUID!) { (userScore) in
            self.scoreLabel.text = "Score: \(userScore)"
            if userScore <= 2500 {
                self.rankLabel.text = "Rank: Bronze I"
                self.rankImageView.image = UIImage(named: "bronze1")
            } else if userScore <= 5000 {
                self.rankLabel.text = "Rank: Bronze II"
                self.rankImageView.image = UIImage(named: "bronze2")
            } else if userScore <= 7500 {
                self.rankLabel.text = "Rank: Silver I"
                self.rankImageView.image = UIImage(named: "silver1")
            } else if userScore <= 10000 {
                self.rankLabel.text = "Rank: Silver II"
                self.rankImageView.image = UIImage(named: "silver2")
            } else if userScore <= 12500 {
                self.rankLabel.text = "Rank: Gold I"
                self.rankImageView.image = UIImage(named: "gold1")
            } else if userScore <= 15000 {
                self.rankLabel.text = "Rank: Gold II"
                self.rankImageView.image = UIImage(named: "gold2")
            } else if userScore <= 17500 {
                self.rankLabel.text = "Rank: Platinum I"
                self.rankImageView.image = UIImage(named: "platinum1")
            } else if userScore <= 20000 {
                self.rankLabel.text = "Rank: Platinum II"
                self.rankImageView.image = UIImage(named: "platinum2")
            } else {
                self.rankLabel.text = "Rank: Diamond"
                self.rankImageView.image = UIImage(named: "diamond1")
            }
        }
    }
}
