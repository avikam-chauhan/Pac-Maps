//
//  TutorialDisplayViewController.swift
//  PacMan Coronatrainer
//
//  Created by Mihir Chauhan on 7/15/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import UIKit

class TutorialDisplayViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var getStartedButtonOutlet: UIButton!
    @IBAction func getStartedButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    let dataSource = ["Welcome To Pac-Maps!", "Long Press to Add Waypoints", "Shake to Remove", "Compete with Friends", "Stay Away from Others", "Contact Tracing", "Update COVID-19 Results", "Add Family Members", "Swipe Down to Play!"]
    let images = ["1", "2", "2", "3", "4", "5", "6", "7", "1"]
    var currentViewControllerIndex = 0
    let pageControl = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 175, width: UIScreen.main.bounds.width, height: 150))
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        getStartedButtonOutlet.layer.zPosition = 1
        getStartedButtonOutlet.isHidden = true
        getStartedButtonOutlet.isEnabled = true
        self.view.backgroundColor = #colorLiteral(red: 0.09153518826, green: 0.2464473248, blue: 0.3731117845, alpha: 1)
        configurePageViewController()
        pageControl.numberOfPages = dataSource.count
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.black
        pageControl.isUserInteractionEnabled = false
        self.view.addSubview(pageControl)
        
        if let gestureRecognizers = self.pageControl.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers     {
                if gestureRecognizer is UITapGestureRecognizer {
                    gestureRecognizer.isEnabled = false
                }
            }
        }

    }
    
    func configurePageViewController() {
        guard let pageViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: UIPageViewController.self)) as? UIPageViewController else {
            return
        }
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        displayView.addSubview(pageViewController.view)
        
        let views: [String: UIView] = ["pageView": pageViewController.view]
        
        displayView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        displayView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        
        guard let startingViewController = detailViewControllerAt(index: currentViewControllerIndex) else {
            return
        }
        
        pageViewController.setViewControllers([startingViewController], direction: .forward, animated: true)
    }
    
    func detailViewControllerAt(index: Int) -> TutorialPageViewController? {
//        if currentViewControllerIndex == 10 {
//            UIView.transition(with: getStartedButtonOutlet, duration: 0.4,
//                              options: .transitionCrossDissolve,
//                              animations: {
//                                self.getStartedButtonOutlet.isHidden = false
//            })
//        }
        if index >= dataSource.count || dataSource.count == 0 {
            return nil
        }
        
        guard let dataViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: TutorialPageViewController.self)) as? TutorialPageViewController else {
            return nil
        }
        
        dataViewController.index = index
        dataViewController.displayText = dataSource[index]
        let backgroundColor = #colorLiteral(red: 0.09153518826, green: 0.2464473248, blue: 0.3731117845, alpha: 1) //  = index == 0 ? #colorLiteral(red: 0.7806749683, green: 0.4807832242, blue: 0.1013923447, alpha: 1) : index == 1 ? #colorLiteral(red: 0.1388415396, green: 0.4637764692, blue: 0.5640690923, alpha: 1) : index == 2 ? #colorLiteral(red: 0.02455679327, green: 0.1435554624, blue: 0.2232916653, alpha: 1) : index == 3 ? #colorLiteral(red: 0.7556511739, green: 0.2484094252, blue: 0.3051345811, alpha: 1) : index == 4 ? #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1) : index == 5 ? #colorLiteral(red: 0.5808190107, green: 0.0884276256, blue: 0.3186392188, alpha: 1) : index == 6 ? #colorLiteral(red: 0.5787474513, green: 0.3215198815, blue: 0, alpha: 1) : index == 7 ? #colorLiteral(red: 0.1755147576, green: 0.1388972402, blue: 0.2225093246, alpha: 1) : index == 8 ? #colorLiteral(red: 0.3569092012, green: 0.1325056174, blue: 0.6159184645, alpha: 1) : #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        dataViewController.displayImage = UIImage(named: images[index])
        
        dataViewController.view.backgroundColor = backgroundColor
//        self.view.backgroundColor = index - 2 <= 0 ? #colorLiteral(red: 0.7806749683, green: 0.4807832242, blue: 0.1013923447, alpha: 1) : #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        
        
        return dataViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let dataViewController = viewController as? TutorialPageViewController
        
        guard var currentIndex = dataViewController?.index else {
            return nil
        }
        
        currentViewControllerIndex = currentIndex
        self.pageControl.currentPage = currentViewControllerIndex
        pageControl.updateCurrentPageDisplay()
        
        
        if currentIndex == 0 {
            return nil
        }
        
        currentIndex -= 1
        
        return detailViewControllerAt(index: currentIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let dataViewController = viewController as? TutorialPageViewController
        
        guard var currentIndex = dataViewController?.index else {
            return nil
        }
        
        if currentIndex == dataSource.count {
            return nil
        }
        
        currentIndex += 1
        
        currentViewControllerIndex = currentIndex
        self.pageControl.currentPage = currentViewControllerIndex - 1
        pageControl.updateCurrentPageDisplay()
        
        
        return detailViewControllerAt(index: currentIndex)
    }
}
