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
  
  var updateActiveWatcherAction: Action<Int,Bool,NoError>!
  var viewModel: WatcherViewModelProtocol!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    guard viewModel != nil else {
      alertForError(message: MovieNightControllerAlert.propertyInjectionFailure.rawValue)
      fatalError(MovieNightControllerAlert.propertyInjectionFailure.rawValue)
    }
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    configureWatcherButtons()
    configureWatcherLabels()
    configureObservers()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  public func alertForError(message: String) {
      let alertController = UIAlertController(title: MovieNightControllerAlert.somethingWentWrong.rawValue, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: MovieNightControllerAlert.ok.rawValue, style: .default, handler: nil)
      alertController.addAction(okAction)
      present(alertController, animated: true, completion: nil)
    }

  func configureWatcherButtons() {
    // action to be performed when user presses one of the watcher buttons (could have just been IBAction but
    // wanted to use for practice with ReactiveSwift framework
    updateActiveWatcherAction = Action { [weak self] input in
      guard let strongSelf = self else { return SignalProducer.empty }
      return SignalProducer<Bool, NoError> { (observer, disposable) in
        strongSelf.viewModel.updateActiveWatcher(index: input)
        let watcherName = strongSelf.viewModel.activeWatcher.value.name
        let alert = UIAlertController(title: "\(watcherName)'s Name", message: MovieNightControllerAlert.updateNameMessage.rawValue, preferredStyle: .alert)
        alert.addTextField { textField in
          textField.placeholder = "Name"
        }
        let updateNameAction = UIAlertAction(title: MovieNightControllerAlert.updateName.rawValue, style: .default) { _ in
          let prospectiveName = alert.textFields?[0].text ?? watcherName
          let success = strongSelf.viewModel.setActiveWatcherName(name: prospectiveName)
          DispatchQueue.main.async {
            observer.send(value: success)
            observer.sendCompleted()
          }
        }
        let cancelAction = UIAlertAction(title: MovieNightControllerAlert.keepDefaultName.rawValue, style: .cancel) { _ in
          DispatchQueue.main.async {
            observer.send(value: true)
            observer.sendCompleted()
          }
        }
        alert.addAction(updateNameAction)
        alert.addAction(cancelAction)
        strongSelf.present(alert, animated: true)
      }.take(first: 1)
    }
    guard viewModel.watchers.value != nil && viewModel.watchers.value?.count == 2 else {
      return
    }
    watcher1Button.reactive.pressed = CocoaAction(updateActiveWatcherAction, input: 0)
    watcher2Button.reactive.pressed = CocoaAction(updateActiveWatcherAction, input: 1)
  }
  
  func configureWatcherLabels() {
    let ready = MovieNightControllerAlert.ready.rawValue
    let undecided = MovieNightControllerAlert.undecided.rawValue
    watcher1ReadyLabel.reactive.text <~ viewModel.watcher1Ready().map { $0 ? ready : undecided }
    watcher2ReadyLabel.reactive.text <~ viewModel.watcher2Ready().map { $0 ? ready : undecided }
    watcher1NameLabel.reactive.text <~ viewModel.watchers.map { $0?.first?.name }
    watcher2NameLabel.reactive.text <~ viewModel.watchers.map {$0?.last?.name }
  }
  
  func configureObservers() {
    // change image for when watchers have completed choosing preferences
    viewModel.watchers.signal.observeValues { [weak self] watchers in
      guard let strongSelf = self else { return }
      let (readyImage, undecidedImage) = (UIImage(named: ImageAssetName.ready.rawValue )!, UIImage(named: ImageAssetName.undecided.rawValue)!)
      let (watcher1Ready, watcher2Ready) = (strongSelf.viewModel.watcher1Ready(), strongSelf.viewModel.watcher2Ready())
        strongSelf.watcher1Button.setBackgroundImage(watcher1Ready.value ? readyImage : undecidedImage, for: .normal)
        strongSelf.watcher2Button.setBackgroundImage(watcher2Ready.value ? readyImage : undecidedImage, for: .normal)
    }
    updateActiveWatcherAction.values.observeValues { [weak self] value in
      guard let strongSelf = self else { return }
      strongSelf.popupView.success = MutableProperty(value)
      strongSelf.popupView.popUp() {
      strongSelf.performSegue(withIdentifier: Identifiers.choosePreferencesSegue.rawValue, sender: strongSelf)
      }
    }
    let watchersReady = viewModel.watcher1Ready().combineLatest(with: viewModel.watcher2Ready()).map { $0.0 && $0.1 }
    viewResultsButton.reactive.isEnabled <~ watchersReady
  }
  
  @IBAction func clearPreferencesButtonPressed(_ sender: UIBarButtonItem) {
    let controller = UIAlertController(title: MovieNightControllerAlert.clearSelectionsMessage.rawValue, message: MovieNightControllerAlert.clearSelectionsConfirmation.rawValue, preferredStyle: .alert)
    let resetAction = UIAlertAction(title: MovieNightControllerAlert.reset.rawValue, style: .destructive) { _ in
      DispatchQueue.main.async {
        self.viewModel.clearAllPreferences()
      }
    }
    let cancelAction = UIAlertAction(title: MovieNightControllerAlert.cancel.rawValue, style: .cancel, handler: nil)
    controller.addAction(resetAction)
    controller.addAction(cancelAction)
    present(controller, animated: true, completion: nil)
  }
}

