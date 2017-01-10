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
  
  @IBOutlet weak var detailView: UIView!
  @IBOutlet weak var detailLabel: UILabel!
  var viewModel: DetailViewModelProtocol!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    detailView.isHidden = true
    detailView.layer.cornerRadius = 8.0
    navigationItem.title = viewModel.entity?.title
    navigationItem.hidesBackButton = true
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
  
  
  @IBAction func swipeToDismiss(_ sender: UISwipeGestureRecognizer) {
    UIView.transition(with: detailView, duration: 0.33, options: [.curveEaseOut, .transitionFlipFromRight], animations: {
        self.detailView.isHidden = true
    }, completion: { success in
      _ = self.navigationController?.popViewController(animated: true)
//      switch self.viewModel.entity {
//      case _ as TMDBEntity.Actor:
//        _ = self.navigationController?.popToRootViewController(animated: true)
//      case _ as TMDBEntity.Rating:
//        _ = self.navigationController?.popToRootViewController(animated: true)
//      case _ as TMDBEntity.Media:
//        _ = self.navigationController?.popViewController(animated: true)
//      default: break
//      }
    })
  }
}
