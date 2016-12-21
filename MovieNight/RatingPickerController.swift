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
    if let viewModel = viewModel {
      tableViewDataSource = MNightTableviewDataSource(tableView: self.tableView, sourceSignal: viewModel.cellModels.producer)
      watcherSignal = movieWatcherViewModel.watchers.signal
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
  
  override func viewWillDisappear(_ animated: Bool) {
    autoSearchStarted = false
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  func configureTabBar() {
    watcherSignal.observeValues { watchers in
      if let watchers = watchers {
        let activeWatcher = watchers[self.movieWatcherViewModel.activeWatcher]
        let ratingChoice = activeWatcher.maxRatingChoice
        self.navigationController?.tabBarItem.badgeColor = ratingChoice != nil ? UIColor.green : UIColor.red
        self.navigationController?.tabBarItem.badgeValue = ratingChoice != nil ? "Set" : "!"
      }
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let preference = viewModel?.ratingCollection.value[indexPath.row] {
      if movieWatcherViewModel.add(preference: preference, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
        self.navigationController?.tabBarItem.badgeColor = UIColor.green
        self.navigationController?.tabBarItem.badgeValue = "Set"
      } else {
        self.navigationController?.tabBarItem.badgeColor = UIColor.red
        self.navigationController?.tabBarItem.badgeValue = "!"
        print("Couldn't update")
      }
    }
  }
}
