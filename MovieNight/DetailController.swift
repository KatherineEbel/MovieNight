//
//  DetailController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/26/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class DetailController: UIViewController {
  
  @IBOutlet weak var detailLabel: UILabel!
  @IBOutlet weak var detailView: UIView!
  
  var viewModel: DetailViewModelProtocol! {
    didSet {
      print("View model set")
    }
  }
    override func viewDidLoad() {
        super.viewDidLoad()
      detailView.isHidden = true
      detailView.layer.cornerRadius = 8.0
      detailLabel.text = viewModel.entity?.details ?? "No Details"
    }
  
  override func viewDidAppear(_ animated: Bool) {
    UIView.transition(with: detailView, duration: 0.33, options: [.curveEaseIn, .transitionFlipFromLeft], animations: {
      self.detailView.isHidden = false
    }, completion: nil)
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
  
  func setDetails(entity: TMDBEntity) {
    // FIXME: Implement Me
  }
  
  @IBAction func swipeToDismiss(_ sender: UISwipeGestureRecognizer) {
    UIView.transition(with: detailView, duration: 0.33, options: [.curveEaseOut, .transitionFlipFromRight], animations: {
        self.detailView.isHidden = true
    }, completion: { success in
      self.dismiss(animated: true, completion: nil)
    })
  }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
