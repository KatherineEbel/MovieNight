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
        let readyColor =  UIColor(red: 138/255.0, green: 199/255.0, blue: 223/255.0, alpha: 1.0)
        let notReadyColor = UIColor(red: 255/255.0, green: 95/255.0, blue: 138/255.0, alpha: 1.0)
        self.navigationController?.tabBarItem.badgeColor = ratingChoice != nil ? readyColor : notReadyColor
        self.navigationController?.tabBarItem.badgeValue = ratingChoice != nil ? "Set" : "!"
        //self.editButtonItem.reactive.isEnabled <~ MutableProperty(activeWatcher.isReady)
      }
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let preference = viewModel?.ratingModelData.value[indexPath.row] {
      _ = movieWatcherViewModel.add(preference: preference, watcherAtIndex: movieWatcherViewModel.activeWatcher)
    }
  }
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let preference = viewModel?.ratingModelData.value[indexPath.row]
    if movieWatcherViewModel.remove(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
      print("Success")
    }
  }
  @IBAction func savePreferences(_ sender: UIBarButtonItem) {
    if movieWatcherViewModel.watcher1Ready() || movieWatcherViewModel.watcher2Ready() {
      self.navigationController?.tabBarController?.dismiss(animated: true) {
        self.movieWatcherViewModel.updateActiveWatcher()
      }
    } else {
      print("Not finished yet!")
    }
  }
  
}
