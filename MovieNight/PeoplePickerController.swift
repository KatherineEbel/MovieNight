//
//  SearchResultsController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class PeoplePickerController: UITableViewController {
  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  public var viewModel: SearchResultsTableViewModeling?
  private var tableViewDataSource: MNightTableviewDataSource!
  private var watcherSignal: Signal<[MovieWatcherProtocol]?, NoError>!

  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl?.addTarget(self, action: #selector(PeoplePickerController.handleRefresh(refreshControl:)), for: .valueChanged)
    self.clearsSelectionOnViewWillAppear = false
    if let viewModel = viewModel {
      let actorCellModelProducer = viewModel.actorModelData.producer.map { actors in
        return actors .flatMap { $0 as TMDBEntityProtocol }
      }
      tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: actorCellModelProducer, nibName: "PreferenceCell")
      tableViewDataSource.configureTableView()
      watcherSignal = movieWatcherViewModel.watchers.signal
      let activeWatcherReadySignal = watcherSignal.map { signal in
        return signal![self.movieWatcherViewModel.activeWatcher].isReady
        }
      configureNavBarWithSignal(watcherReady: activeWatcherReadySignal)
      configureTabBar()
    } else {
      fatalError("No view model!")
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !autoSearchStarted {
      autoSearchStarted = true
      viewModel?.getNextPage()
    }
  }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    guard (viewModel?.peoplePageCountTracker.page)! > 1 else {
      return
    }
    self.tableView.refreshControl?.attributedTitle = viewModel?.peoplePageCountTracker.tracker
    refreshControl.beginRefreshing()
    viewModel?.getNextPage()
    refreshControl.endRefreshing()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    //autoSearchStarted = false
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
        let count = activeWatcher.actorChoices.count
        let readyColor = TMDBColor.ColorFromRGB(color: .green, withAlpha: 1.0)
        let notReadyColor = UIColor.red
        self.navigationController?.tabBarItem.badgeColor = count >= 1 && count <= 5 ? readyColor : notReadyColor
        self.navigationController?.tabBarItem.badgeValue = "\(count)/5"
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var count = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].actorChoices.count
    guard count < 5 else {
      return
    }
    let preference = viewModel?.actorModelData.value[indexPath.row]
    if  movieWatcherViewModel.add(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
      count += 1
    }
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let watcherIndex = movieWatcherViewModel.activeWatcher
    let preference = viewModel!.actorModelData.value[indexPath.row]
    _ = movieWatcherViewModel.remove(preference: preference, watcherAtIndex: watcherIndex)
    
  }
  
  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
    let notSet = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].actorChoices.count < 5
    let isactiveWatcherChoice = movieWatcherViewModel.watchers.value?[movieWatcherViewModel.activeWatcher].actorChoices.contains(where: { actor in
      actor.name == viewModel?.actorModelData.value[indexPath.row].name
    })
    return notSet || isactiveWatcherChoice!
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let entity = viewModel!.actorModelData.value[indexPath.row] as TMDBEntityProtocol
    performSegue(withIdentifier: "showDetails", sender: entity)
  }
  
  @IBAction func preferencesComplete(_ sender: UIBarButtonItem) {
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
      if let sender = sender as? TMDBEntity.Actor {
        detailController.viewModel.entity = sender
      }
    }
  }
}
