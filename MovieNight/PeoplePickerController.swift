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
  private var selectedRows: MutableProperty<Set<IndexPath>> = MutableProperty(Set<IndexPath>())
  private var activeWatcherSignal: Signal<MovieWatcherProtocol?, NoError> {
    let watcherSignal = movieWatcherViewModel.watchers.signal
    return watcherSignal.map { signal in
      return signal![self.movieWatcherViewModel.activeWatcher]
      }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl?.addTarget(self, action: #selector(PeoplePickerController.handleRefresh(refreshControl:)), for: .valueChanged)
    self.clearsSelectionOnViewWillAppear = false
    if let viewModel = viewModel {
//      data source takes TMDBEntityProtocol types, so map viewModel data to required type
      let actorCellModelProducer = viewModel.actorModelData.producer.map { actors in
        return actors .flatMap { $0 as TMDBEntityProtocol }
      }
      let activeWatcher = movieWatcherViewModel.watchers.map { $0?[self.movieWatcherViewModel.activeWatcher] }
      viewModel.actorModelData.combineLatest(with: activeWatcher).signal.observeValues {(actors, activeWatcher) in
        guard self.tableView.indexPathsForSelectedRows == nil else { return }
        if let currentChoices = activeWatcher?.actorChoices {
          let indexes = actors.enumerated().reduce(Set<IndexPath>()) { (result, nextResult: (idx: Int, actor: TMDBEntity.Actor)) in
            var copy = result
            if currentChoices.contains(where: { $0.name == nextResult.actor.name }) {
              copy.insert(IndexPath(row: nextResult.idx, section: 0))
            }
            return copy
          }
          _ = indexes.map { row in
            self.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
            self.tableView(self.tableView, didSelectRowAt: row)
          }
        }
      }
      // set datasource using the above producer
      tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: actorCellModelProducer, nibName: "PreferenceCell")
      tableViewDataSource.configureTableView()
//      watcherSignal = movieWatcherViewModel.watchers.signal
      configureNavBarForActiveWatcher()
      configureTabBar()
      // reselect rows when user refreshes tableview
      observeForTableViewReload()
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
  
  func observeForTableViewReload() {
    _ = tableView.reactive.trigger(for: #selector(tableView.reloadData)).observeValues {
      _ = self.selectedRows.value.map { row in
        self.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
      }
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
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  func configureNavBarForActiveWatcher() {
    // FIXME: Implement navbar actions
    if let rightNavBarItem = navigationItem.rightBarButtonItem?.reactive {
      let isReady = activeWatcherSignal.map { $0!.isReady }
      rightNavBarItem.isEnabled <~ isReady
    }
  }
  
  func configureTabBar() {
    activeWatcherSignal.observeValues { watcher in
      if let watcher = watcher {
        let count = watcher.actorChoices.count
        let readyColor = TMDBColor.ColorFromRGB(color: .green, withAlpha: 1.0)
        let notReadyColor = UIColor.red
        self.navigationController?.tabBarItem.badgeColor = count >= 1 && count <= 5 ? readyColor : notReadyColor
        self.navigationController?.tabBarItem.badgeValue = "\(count)/5"
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedRows.value.insert(indexPath)
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
    selectedRows.value.remove(indexPath)
    let watcherIndex = movieWatcherViewModel.activeWatcher
    let preference = viewModel!.actorModelData.value[indexPath.row]
    _ = movieWatcherViewModel.remove(preference: preference, watcherAtIndex: watcherIndex)
    
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let entity = viewModel!.actorModelData.value[indexPath.row] as TMDBEntityProtocol
    performSegue(withIdentifier: "showDetails", sender: entity)
  }
  
  @IBAction func goHome(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
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
