//
//  MoviePreferenceTabBarController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/19/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit

class MoviePreferenceTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.unselectedItemTintColor = UIColor(red: 255/255.0, green: 142/255.0, blue: 138/255.0, alpha: 0.3) 
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
