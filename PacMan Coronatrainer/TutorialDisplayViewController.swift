//
//  TutorialDisplayViewController.swift
//  PacMan Coronatrainer
//
//  Created by Mihir Chauhan on 7/15/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import UIKit

class TutorialDisplayViewController: UIViewController {
    @IBOutlet weak var displayView: UIView!
    
    let dataSource = ["Make a route", "Run around", "Get points", "Stay away from others"]
    var currentViewControllerIndex = 0
    let colorDataSource = ["Blue", "Aquamarine", "Yellow", "Orange"]
    let pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 50,width: UIScreen.main.bounds.width,height: 50))
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        
        
        pageControl.numberOfPages = dataSource.count
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.black
        self.view.addSubview(pageControl)
        
        configurePageViewController()
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
        
        let views: [String: Any] = ["pageView": pageViewController.view]
        
        displayView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        displayView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        
        guard let startingViewController = detailViewControllerAt(index: currentViewControllerIndex) else {
            return
        }
        
        pageViewController.setViewControllers([startingViewController], direction: .forward, animated: true)
    }
    
    func detailViewControllerAt(index: Int) -> TutorialPageViewController? {
        
        if index >= dataSource.count || dataSource.count == 0 {
            return nil
        }
        
        guard let dataViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: TutorialPageViewController.self)) as? TutorialPageViewController else {
            return nil
        }
        
        dataViewController.index = index
        dataViewController.displayText = dataSource[index]
        let backgroundColor = colorDataSource[index] == "Blue" ? #colorLiteral(red: 0.09153518826, green: 0.2464473248, blue: 0.3731117845, alpha: 1) : colorDataSource[index] == "Aquamarine" ? #colorLiteral(red: 0.1841040552, green: 0.616987884, blue: 0.5613076091, alpha: 1) : colorDataSource[index] == "Yellow" ? #colorLiteral(red: 0.9129590392, green: 0.767173171, blue: 0.4142659903, alpha: 1) : colorDataSource[index] == "Orange" ? #colorLiteral(red: 0.9576900601, green: 0.6367803216, blue: 0.3825422525, alpha: 1) : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        dataViewController.view.backgroundColor = backgroundColor
                
        return dataViewController
    }
}

extension TutorialDisplayViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let dataViewController = viewController as? TutorialPageViewController
        
        guard var currentIndex = dataViewController?.index else {
            return nil
        }
        
        currentViewControllerIndex = currentIndex
        print("before \(currentViewControllerIndex)")
        self.pageControl.currentPage = currentViewControllerIndex

        
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
        print("after \(currentViewControllerIndex)")
        self.pageControl.currentPage = currentViewControllerIndex - 1

        
        return detailViewControllerAt(index: currentIndex)
    }
}
