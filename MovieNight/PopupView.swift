//
//  PopupView.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/26/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift

class PopupView: UIView {
  var success: MutableProperty<Bool> = MutableProperty(false) {
    didSet {
      self.successImageView.reactive.image <~ success.map { success in
        success ? UIImage(named: "ok")! : UIImage(named: "failed")!
      }
    }
  }
  @IBOutlet weak var successImageView: UIImageView!
  
  required init?(coder aDecoder: NSCoder) {
    print("Popup initialized")
    super.init(coder: aDecoder)
    self.alpha = 0
  }
  func popUp(completion: @escaping () -> ()) {
    UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
      self.alpha = 1.0
      self.successImageView.bounds.size.height += 20
      self.successImageView.bounds.size.width += 20
      
    }, completion: { _ in
      UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
        self.successImageView.bounds.size.height -= 20
        self.successImageView.bounds.size.height -= 20
      }, completion: { _ in
        self.alpha = 0
        completion()
      })
    })
  }
  
  deinit {
    print("Popup deinit")
  }
}
