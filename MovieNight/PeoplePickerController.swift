//
//  SearchResultsController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit

class PeoplePickerController: UITableViewController {
  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  public var viewModel: SearchResultsTableViewModeling?
  private var tableViewDataSource: MNightTableviewDataSource!

  override func viewDidLoad() {
    super.viewDidLoad()
    if let viewModel = viewModel {
      tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: viewModel.cellModels.producer)
      movieWatcherViewModel.watchers.signal.observeValues { watchers in
        let activeWatcher = watchers![self.movieWatcherViewModel.activeWatcher]
        let count = activeWatcher.moviePreference.actorChoices.count
        self.navigationController?.tabBarItem.badgeColor = count >= 1 && count <= 5 ? UIColor.green : UIColor.red
        self.navigationController?.tabBarItem.badgeValue = "\(count)/5"
        
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !autoSearchStarted {
      autoSearchStarted = true
      viewModel?.getNextPage()
    }
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var count = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].moviePreference.actorChoices.count
    guard count < 5 else {
      return
    }
    let preference = viewModel?.actorCollection.value[indexPath.row]
    if  movieWatcherViewModel.add(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
      count += 1
    }
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let watcherIndex = movieWatcherViewModel.activeWatcher
    let preference = viewModel!.actorCollection.value[indexPath.row]
    _ = movieWatcherViewModel.remove(preference: preference, watcherAtIndex: watcherIndex)
  }
  
  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
    let notSet = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].moviePreference.actorChoices.count < 5
    let isactiveWatcherChoice = movieWatcherViewModel.watchers.value?[movieWatcherViewModel.activeWatcher].moviePreference.actorChoices.contains(where: { actor in
      actor.name == viewModel?.actorCollection.value[indexPath.row].name
    })
    return notSet || isactiveWatcherChoice!
  }
}
