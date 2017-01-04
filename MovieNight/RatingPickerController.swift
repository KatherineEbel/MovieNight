//
//  RatingPickerController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class RatingPickerController: UITableViewController {

  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  public var viewModel: SearchResultsTableViewModeling?
  public var tableViewDataSource: MNightTableviewDataSource!
  private var watcherSignal: Signal<[MovieWatcherProtocol]?, NoError>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.clearsSelectionOnViewWillAppear = false
    if let viewModel = viewModel {
      viewModel.errorMessage.signal.take(first: 1).observeValues { message in
        if let message = message {
          DispatchQueue.main.async {
            self.alertForError(message: message)
            self.refreshControl?.endRefreshing()
          }
        }
      }
      let ratingCellProducer = viewModel.ratingModelData.producer.map { ratings in
        return ratings.flatMap { $0 as TMDBEntityProtocol }
      }
      tableViewDataSource = MNightTableviewDataSource(tableView: self.tableView, sourceSignal: ratingCellProducer, nibName: "PreferenceCell")
      tableViewDataSource.configureTableView()
      watcherSignal = movieWatcherViewModel.watchers.signal
      let activeWatcherReadySignal = watcherSignal.map { signal in
        return signal![self.movieWatcherViewModel.activeWatcher].isReady
      }
      configureNavBarWithSignal(watcherReady: activeWatcherReadySignal)
      configureTabBar()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !autoSearchStarted {
      autoSearchStarted = true
      viewModel?.getRatings()
    }
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func alertForError(message: String) {
    let alertController = UIAlertController(title: "Sorry! Something went wrong.", message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(okAction)
    present(alertController, animated: true, completion: nil)
  }
  
  func configureNavBarWithSignal(watcherReady: Signal<Bool, NoError>) {
    // FIXME: Implement navbar actions
    if let rightNavBarItem = navigationItem.rightBarButtonItem?.reactive {
      rightNavBarItem.isEnabled <~ movieWatcherViewModel.watchers.map { $0![self.movieWatcherViewModel.activeWatcher].isReady }
    }
  }

  func configureTabBar() {
    watcherSignal.observeValues { watchers in
      if let watchers = watchers {
        let activeWatcher = watchers[self.movieWatcherViewModel.activeWatcher]
        let ratingChoice = activeWatcher.maxRatingChoice
        let readyColor = TMDBColor.ColorFromRGB(color: .green, withAlpha: 1.0)
        let notReadyColor = UIColor.red
        self.navigationController?.tabBarItem.badgeColor = ratingChoice != nil ? readyColor : notReadyColor
        self.navigationController?.tabBarItem.badgeValue = ratingChoice != nil ? "Set" : "!"
        //self.editButtonItem.reactive.isEnabled <~ MutableProperty(activeWatcher.isReady)
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let entity = viewModel!.ratingModelData.value[indexPath.row] as TMDBEntityProtocol
    performSegue(withIdentifier: "showDetails", sender: entity)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let preference = viewModel?.ratingModelData.value[indexPath.row] {
      _ = movieWatcherViewModel.add(preference: preference, watcherAtIndex: movieWatcherViewModel.activeWatcher)
    }
  }
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let preference = viewModel?.ratingModelData.value[indexPath.row]
    // remove method returns a bool. Not currently using value
    _ = movieWatcherViewModel.remove(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcher)
  }
  
  // save allowed when minium requirements for preferences are set
  @IBAction func savePreferences(_ sender: UIBarButtonItem) {
    if movieWatcherViewModel.watcher1Ready() || movieWatcherViewModel.watcher2Ready() {
      self.navigationController?.tabBarController?.dismiss(animated: true) {
        self.movieWatcherViewModel.updateActiveWatcher()
      }
    } else {
      print("Not finished yet!")
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetails" {
      let detailController = segue.destination as! DetailController
      if let sender = sender as? TMDBEntity.Rating {
        detailController.viewModel.entity = sender
      }
    }
  }
  
}
