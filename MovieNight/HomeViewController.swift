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
  @IBOutlet weak var popupView: PopupView!
  
  var updateWatcherNameAction: Action<Int,Bool,NoError>!
  var watchersReadySignal: SignalProducer<Bool, NoError>!
  var viewModel: WatcherViewModelProtocol! {
    didSet {
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    watchersReadySignal = viewModel.watchers.producer.map { _ in
      self.viewModel.watcher1Ready() && self.viewModel.watcher2Ready()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
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
    viewModel.watchers.signal.observeValues { watchers in
      let (readyImage, undecidedImage) = (UIImage(named: "bubble-filled")!, UIImage(named: "bubble-empty-1")!)
      if let watcher1 = watchers?.first, let watcher2 = watchers?.last {
        self.watcher1Button.setBackgroundImage(watcher1.isReady ? readyImage : undecidedImage, for: .normal)
        self.watcher2Button.setBackgroundImage(watcher2.isReady ? readyImage : undecidedImage, for: .normal)
      }
    }
    watcher1Button.reactive.pressed = CocoaAction(updateWatcherNameAction, input: 0)
    watcher2Button.reactive.pressed = CocoaAction(updateWatcherNameAction, input: 1)
    watcher2StackView.reactive.isHidden <~ viewModel.watchers.map { $0!.first!.isReady }
    
    configureWatcherLabels()
    configureObservers()
  }
  
//  func showUpdateAlert(_ success: Bool) {
//    let title = success ? "Succesful" : "Failed to update"
//    let message = success ? "Name updated!" : "Name must have at least two characters"
//    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
//      if success {
//        self.performSegue(withIdentifier: "choosePreferences", sender: self)
//      } else {
//        self.updateWatcherNameAction.apply(0).start()
//      }
//    }
//    alert.addAction(okAction)
//    present(alert, animated: true, completion: nil)
//    
//  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func configureWatcherLabels() {
    watcher2StackView.reactive.isHidden <~ viewModel.watchers.map { !(($0?.first?.isReady)!) }
    watcher1ReadyLabel.reactive.text <~ viewModel.watchers.map { watchers in
      (watchers?.first?.isReady)! ? "Ready" : "Undecided"
    }
    
    watcher2ReadyLabel.reactive.text <~ viewModel.watchers.map { watchers in
      (watchers?.last?.isReady)! ? "Ready" : "Undecided"
    }
    watcher1NameLabel.reactive.text <~ viewModel.watchers.map { $0?.first?.name }
    watcher2NameLabel.reactive.text <~ viewModel.watchers.map {$0?.last?.name }
  }
  
  func configureObservers() {
    updateWatcherNameAction.values.observeValues { value in
      self.popupView.success = MutableProperty(value)
      self.popupView.popUp() {
      self.performSegue(withIdentifier: "choosePreferences", sender: self)
      }
    }
    self.viewResultsButton.reactive.isEnabled <~ watchersReadySignal
    watchersReadySignal.on { value in
      self.viewResultsButton.isEnabled = value
    }.observe(on: UIScheduler()).start()
  }
  @IBAction func clearPreferencesButtonPressed(_ sender: UIBarButtonItem) {
    let controller = UIAlertController(title: "Proceeding, will clear all selected preferences", message: "Are you sure you want to continue?", preferredStyle: .alert)
    let resetAction = UIAlertAction(title: "Reset", style: .destructive) { _ in
      DispatchQueue.main.async {
        self.viewModel.clearWatcherChoices()
      }
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    controller.addAction(resetAction)
    controller.addAction(cancelAction)
    present(controller, animated: true, completion: nil)
  }
  
}

