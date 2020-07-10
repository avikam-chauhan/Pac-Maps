//
//  SettingsViewController.swift
//  PacMan Coronatrainer
//
//  Created by Mihir Chauhan on 7/4/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import UIKit

class ShowQRCodeViewController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = generateQRCode(from: UIDevice.current.identifierForVendor?.uuidString ?? "")
        qrCodeImageView.image = image
        // Do any additional setup after loading the view.
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 100, y: 100)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
        

    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let dvc = segue.destination as? ViewController {
            
        }
    }
    

}
