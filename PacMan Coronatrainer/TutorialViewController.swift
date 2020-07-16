//
//  TutorialViewController.swift
//  PacMan Coronatrainer
//
//  Created by Mihir Chauhan on 7/15/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {
    @IBOutlet weak var tutorialScrollView: UIScrollView!
    
    let tutorialPage1 = ["title":"Plan your route", "image":"image1", "detail":"Make it."]
    let tutorialPage2 = ["title":"Gain Points", "image":"image2", "detail":"Make it."]
    let tutorialPage3 = ["title":"Stay away from other users!", "image":"image3", "detail":"Make it."]
    var tutorialArray = [Dictionary<String,String>]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tutorialArray = [tutorialPage1, tutorialPage2, tutorialPage3]
        tutorialScrollView.isPagingEnabled = true
        tutorialScrollView.contentSize = CGSize(width: self.view.bounds.width * CGFloat(tutorialArray.count), height: tutorialScrollView.bounds.height)
        tutorialScrollView.showsHorizontalScrollIndicator = false
        
        loadTutorialPages()
        // Do any additional setup after loading the view.
    }
    
    func loadTutorialPages() {
        for (index, tutorial) in tutorialArray.enumerated() {
            if let tutorialView = Bundle.main.loadNibNamed("PacMapsTutorialPages", owner: nil, options: nil)?.first as? PacMapsTutorialView {
                tutorialView.imageView.image = UIImage(named: tutorial["image"]!)
                tutorialView.titleLabel.text = tutorial["title"]
                tutorialView.titleLabel.text = tutorial["detail"]
                
                tutorialScrollView.addSubview(tutorialView)
                tutorialView.frame.size.width = self.view.bounds.size.width
                tutorialView.frame.origin.x = CGFloat(index) * self.view.bounds.size.width
            }
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
