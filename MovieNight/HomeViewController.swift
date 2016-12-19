//
//  ViewController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/9/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result

class HomeViewController: UIViewController {
  @IBOutlet weak var watcher1Button: UIButton!
  @IBOutlet weak var watcher2Button: UIButton!
  @IBOutlet weak var watcher1NameLabel: UILabel!
  @IBOutlet weak var watcher2NameLabel: UILabel!
  @IBOutlet weak var watcher1ReadyLabel: UILabel!
  @IBOutlet weak var watcher2ReadyLabel: UILabel!
  @IBOutlet weak var viewResultsButton: UIButton!
  @IBOutlet weak var watcher2StackView: UIStackView!
  var updateWatcherNameAction: Action<Int,Bool,NoError>!
  var viewModel: WatcherViewModelProtocol! {
    didSet {
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureBindings()
  }
  
  func configureBindings() {
    updateWatcherNameAction = Action { input in
      return SignalProducer { observer, disposable in
        let watcherToUpdate: String = self.viewModel.watchers.value![input].name
        let alert = UIAlertController(title: "\(watcherToUpdate.capitalized)'s Name", message: "Update your name?", preferredStyle: .alert)
        alert.addTextField { textField in
          textField.placeholder = "Name"
        }
        let updateNameAction = UIAlertAction(title: "Update Name", style: .default) { _ in
          let prospectiveName = alert.textFields?[0].text ?? watcherToUpdate
          let success = self.viewModel.setNameForWatcher(at: input, with: prospectiveName)
          DispatchQueue.main.async {
            observer.send(value: success)
            observer.sendCompleted()
          }
        }
        alert.addAction(updateNameAction)
        self.present(alert, animated: true)
      }
    }
    watcher1Button.reactive.pressed = CocoaAction(updateWatcherNameAction, input: 0)
    watcher2Button.reactive.pressed = CocoaAction(updateWatcherNameAction, input: 1)
    configureWatcherLabels()
    configureObservers()
    watcher2StackView.reactive.isHidden <~ MutableProperty(!self.viewModel.watcher1Ready())
  }
  
  func showUpdateAlert(_ success: Bool) {
    let title = success ? "Succesful" : "Failed to update"
    let message = success ? "Name updated!" : "Name must have at least two characters"
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
      if success {
        self.performSegue(withIdentifier: "choosePreferences", sender: self)
      } else {
        self.updateWatcherNameAction.apply(0).start()
      }
    }
    alert.addAction(okAction)
    present(alert, animated: true, completion: nil)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func configureWatcherLabels() {
    self.watcher1ReadyLabel.reactive.text <~ MutableProperty((viewModel.watcher1Ready()) ? "Ready!" : "Undecided")
    self.watcher2ReadyLabel.reactive.text <~ MutableProperty(viewModel.watcher2Ready() ? "Ready!" : "Undecided")
    if let viewModel = viewModel {
      viewModel.watchers.signal.observeValues { value in
        self.watcher1NameLabel.reactive.text <~ MutableProperty(value?.first?.name)
        self.watcher2NameLabel.reactive.text <~ MutableProperty(value?.last!.name)
        self.watcher1ReadyLabel.reactive.text <~ MutableProperty((viewModel.watcher1Ready()) ? "Ready!" : "Undecided")
        self.watcher2ReadyLabel.reactive.text <~ MutableProperty(viewModel.watcher2Ready() ? "Ready!" : "Undecided")
      }
    } else {
      print("No view model")
    }
  }
  
  func configureObservers() {
    updateWatcherNameAction.values.observeValues { value in
      self.showUpdateAlert(value)
    }
  }
  
}

