//
//  TutorialPageViewController.swift
//  TrailPlay
//
//  Created by Mihir Chauhan on 7/15/20.
//  Copyright © 2020 Mihir Chauhan. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var displayText: String?
    var displayImage: UIImage?
    var index: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = displayText
        imageView.image = displayImage
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
