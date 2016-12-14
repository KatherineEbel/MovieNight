//
//  WatcherView.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift
import ReactiveCocoa
import UIKit

class WatcherView: UIView {
  @IBOutlet weak var watcher1Button: UIButton!
  @IBOutlet weak var watcher2Button: UIButton!
  @IBOutlet weak var watcher1NameLabel: UILabel!
  @IBOutlet weak var watcher2NameLabel: UILabel!
  @IBOutlet weak var watcher1ReadyLabel: UILabel!
  @IBOutlet weak var watcher2ReadyLabel: UILabel!
  @IBOutlet weak var viewResultsButton: UIButton!
  
  internal var viewModel: WatcherViewModeling? {
    didSet {
//      viewResultsButton.reactive.isEnabled <~ watchersReady()
    }
  }
  
  func watchersReady() -> Bool {
    return viewModel?.watchers.reduce(false) { isReady, watcher in
      return watcher.moviePreference != nil && !watcher.name.isEmpty
    } ?? false
  }
  
  
  
}
