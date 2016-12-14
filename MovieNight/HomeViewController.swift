//
//  ViewController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/9/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveCocoa

class HomeViewController: UIViewController {
  
  @IBOutlet weak var userOneButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func userOneButtonSelected(_ sender: UIButton) {
    performSegue(withIdentifier: "pickPeople", sender: self)
  }

}

