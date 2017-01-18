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
  var alertController = UIAlertController()
  
  // prevent memory leaks by cancelling the observers when this controller isn't active
  lazy var triggerForViewDidDisappear: () -> Signal<(),NoError> = {
    [unowned self] in
    return self.reactive.trigger(for: #selector(HomeViewController.viewDidDisappear(_:)))
  }
  
  lazy var updateWatcherNameHandler: (String, @escaping (Bool) -> ()) -> () = {
    [unowned self] name, completion in
    self.alertController = UIAlertController(title: "\(name)'s Name", message: MovieNightControllerAlert.updateNameMessage.rawValue, preferredStyle: .alert)
    self.alertController.addTextField { textField in
      textField.placeholder = "Name"
    }
    let updateNameAction = UIAlertAction(title: MovieNightControllerAlert.updateName.rawValue, style: .default) {
      [unowned self] _ in
      let prospectiveName = self.alertController.textFields?[0].text ?? name
      let success = self.viewModel.setActiveWatcherName(name: prospectiveName)
      completion(success)
    }
    let cancelAction = UIAlertAction(title: MovieNightControllerAlert.keepDefaultName.rawValue, style: .cancel) { _ in
      completion(true)
    }
    self.alertController.addAction(updateNameAction)
    self.alertController.addAction(cancelAction)
    self.present(self.alertController, animated: true)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    guard viewModel != nil else {
      alertForError(message: MovieNightControllerAlert.propertyInjectionFailure.rawValue)
      fatalError(MovieNightControllerAlert.propertyInjectionFailure.rawValue)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    // do bindings in viewWillAppear, since this will retrigger setting bindings
    // whenever this controller is displayed.
    configureButtonBindings()
    configureWatcherLabels()
    configureObservers()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    updateActiveWatcherAction = nil
  }
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  public func alertForError(message: String) {
      alertController = UIAlertController(title: MovieNightControllerAlert.somethingWentWrong.rawValue, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: MovieNightControllerAlert.ok.rawValue, style: .default, handler: nil)
      alertController.addAction(okAction)
      present(alertController, animated: true, completion: nil)
    }

  func configureButtonBindings() {
    // action to be performed when user presses one of the watcher buttons (could have just been IBAction but
    // wanted to use for practice with ReactiveSwift framework
    updateActiveWatcherAction = Action { input in
      return SignalProducer<Bool, NoError> { [weak self] (observer, disposable) in
        guard let innerStrongSelf = self else { return }
        innerStrongSelf.viewModel.updateActiveWatcher(index: input)
        let watcherName = innerStrongSelf.viewModel.activeWatcher.value.name
        innerStrongSelf.updateWatcherNameHandler(watcherName) { success in
          observer.send(value: success)
          observer.sendCompleted()
        }
      }.take(first: 1)
    }
    guard viewModel.watchers.value != nil && viewModel.watchers.value?.count == 2 else {
      return
    }
    watcher1Button.reactive.pressed = CocoaAction(updateActiveWatcherAction, input: 0)
    watcher2Button.reactive.pressed = CocoaAction(updateActiveWatcherAction, input: 1)
    viewResultsButton.reactive.isEnabled <~ Property.combineLatest(viewModel.watcher1Ready(), viewModel.watcher2Ready()).map { $0.0 && $0.1 }.producer.take(until: triggerForViewDidDisappear())
  }
  
  func configureWatcherLabels() {
    let ready = MovieNightControllerAlert.ready.rawValue
    let undecided = MovieNightControllerAlert.undecided.rawValue
    watcher1ReadyLabel.reactive.text <~ viewModel.watcher1Ready().map { $0 ? ready : undecided }
      .producer.take(until: triggerForViewDidDisappear())
    watcher2ReadyLabel.reactive.text <~ viewModel.watcher2Ready().map { $0 ? ready : undecided }
      .producer.take(until: triggerForViewDidDisappear())
    watcher1NameLabel.reactive.text <~ viewModel.watchers.map { $0?.first?.name }
      .producer.take(until: triggerForViewDidDisappear())
    watcher2NameLabel.reactive.text <~ viewModel.watchers.map {$0?.last?.name }
      .producer.take(until: triggerForViewDidDisappear())
  }
  
  func configureObservers() {
    // change image for when watchers have completed choosing preferences (checked or unchecked bubble)
    viewModel.watchers.signal.take(until: triggerForViewDidDisappear()).observeValues { [weak self] watchers in
      guard let strongSelf = self else { return }
      let (readyImage, undecidedImage) = (UIImage(named: ImageAssetName.ready.rawValue )!, UIImage(named: ImageAssetName.undecided.rawValue)!)
      let (watcher1Ready, watcher2Ready) = (strongSelf.viewModel.watcher1Ready(), strongSelf.viewModel.watcher2Ready())
        strongSelf.watcher1Button.setBackgroundImage(watcher1Ready.value ? readyImage : undecidedImage, for: .normal)
        strongSelf.watcher2Button.setBackgroundImage(watcher2Ready.value ? readyImage : undecidedImage, for: .normal)
    }
    // if the users updated name is valid or they choose to keep current name, then an checkmark or x popup will display
    // to indicate success or failure.
    updateActiveWatcherAction.values.take(until: triggerForViewDidDisappear()).observeValues { [weak self] value in
      guard let strongSelf = self else { return }
      strongSelf.popupView.success = MutableProperty(value)
      strongSelf.popupView.popUp() {
      strongSelf.performSegue(withIdentifier: Identifiers.choosePreferencesSegue.rawValue, sender: strongSelf)
      }
    }
  }
  
  @IBAction func clearPreferencesButtonPressed(_ sender: UIBarButtonItem) {
    alertController = UIAlertController(title: MovieNightControllerAlert.clearSelectionsMessage.rawValue, message: MovieNightControllerAlert.clearSelectionsConfirmation.rawValue, preferredStyle: .alert)
    let resetAction = UIAlertAction(title: MovieNightControllerAlert.reset.rawValue, style: .destructive) {
      [unowned self] _ in
      DispatchQueue.main.async {
        self.viewModel.clearAllChoices()
      }
    }
    let cancelAction = UIAlertAction(title: MovieNightControllerAlert.cancel.rawValue, style: .cancel, handler: nil)
    alertController.addAction(resetAction)
    alertController.addAction(cancelAction)
    present(alertController, animated: true, completion: nil)
  }
}

