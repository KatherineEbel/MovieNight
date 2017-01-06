//
//  MovieNightSearchController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 1/4/17.
//  Copyright © 2017 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result

public protocol MovieNightSearchControllerProtocol {
  var entityType: TMDBEntity { get }
}

class MovieNightSearchController: UITableViewController, MovieNightSearchControllerProtocol {

  internal var _entityType: TMDBEntity!
  public var entityType: TMDBEntity {
    return _entityType
  }
  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  public var viewModel: SearchResultsTableViewModeling? {
    didSet {
      print("View Model!")
    }
  }
  private var tableViewDataSource: MNightTableviewDataSource!
  private var watcherSignal: Signal<[MovieWatcherProtocol]?, NoError>!
  private var selectedRows: MutableProperty<Set<IndexPath>> = MutableProperty(Set<IndexPath>())
  private var activeWatcherSignal: Signal<MovieWatcherProtocol, NoError> {
    return movieWatcherViewModel.activeWatcher.signal
  }
  private var cellModelProducer: SignalProducer<[TMDBEntityProtocol], NoError>? {
    guard let viewModel = viewModel else { return nil }
    switch entityType {
      case .actor: return viewModel.modelData.producer.map { $0[.actor]! }
      case .movieGenre: return viewModel.modelData.producer.map { $0[.movieGenre]! }
      case .rating: return viewModel.modelData.producer.map { $0[.rating]! }
      case .media: return viewModel.resultsModelData.producer.map { $0.flatMap {$0 as TMDBEntityProtocol} }
    }
  }
  
  private var cellNibName: String {
    switch entityType {
      case .actor, .movieGenre, .rating: return "PreferenceCell"
      case .media: return "MovieResultCell"
    }
  }
  
  override func viewDidLoad() {
    refreshControl?.addTarget(self, action: #selector(MovieNightSearchController.handleRefresh(refreshControl:)), for: .valueChanged)
    self.clearsSelectionOnViewWillAppear = false
    if let viewModel = viewModel {
//      data source takes TMDBEntityProtocol types, so map viewModel data to required type
      selectUserRowSelections()
      viewModel.errorMessage.signal.take(last: 1).observeValues { message in
        if let message = message {
          DispatchQueue.main.async {
            self.alertForError(message: message)
            self.refreshControl?.endRefreshing()
          }
        }
      }
      // set datasource using the above producer
      tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: cellModelProducer!, nibName: cellNibName)
      tableViewDataSource.configureTableView()
//      watcherSignal = movieWatcherViewModel.watchers.signal
      configureNavBarForActiveWatcher()
      configureTabBar()
      // reselect rows when user refreshes tableview
      observeForTableViewReload()
    } else {
      print("No viewModel")
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !autoSearchStarted {
      autoSearchStarted = true
      switch entityType {
        case .actor: viewModel?.getNextPage()
        case .movieGenre: viewModel?.getGenres()
        case .rating: viewModel?.getRatings()
        default: break
      }
    }
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  func handleRefresh(refreshControl: UIRefreshControl) {
    guard self.entityType.isPageable else { return }
    switch self.entityType {
      case .actor:
        guard viewModel!.peoplePageCountTracker.page > 1 else { return }
        refreshControl.beginRefreshing()
        viewModel!.getNextPage()
      default: break
    }
    guard (viewModel?.peoplePageCountTracker.page)! > 1 else {
      return
    }
    self.tableView.refreshControl?.attributedTitle = viewModel?.peoplePageCountTracker.tracker
    refreshControl.beginRefreshing()
    viewModel?.getNextPage()
    refreshControl.endRefreshing()
  }
  
  func observeForTableViewReload() {
    _ = tableView.reactive.trigger(for: #selector(tableView.reloadData)).observeValues {
      _ = self.selectedRows.value.map { row in
        self.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
      }
    }
  }
  
  func alertForError(message: String) {
    let alertController = UIAlertController(title: "Sorry! Something went wrong.", message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(okAction)
    present(alertController, animated: true, completion: nil)
  }
  
  func selectUserRowSelections() {
    if viewModel != nil {
      let activeWatcher = movieWatcherViewModel.activeWatcher
      cellModelProducer?.combineLatest(with: activeWatcher.producer).on(value: { (models, currentWatcher) in
        guard self.tableView.indexPathsForSelectedRows == nil else { return }
        let watcherSelections = self.movieWatcherViewModel.getPreferenceForActiveWatcher(preferenceType: self.entityType)
        guard (watcherSelections.value?.count)! > 0 else { return }
        let indexes = models.enumerated().reduce(Set<IndexPath>()) { (result, nextResult: (idx: Int, selection: TMDBEntityProtocol)) in
          var copy = result
          if (watcherSelections.value?.contains(where: {$0.title == nextResult.selection.title}))! {
            copy.insert(IndexPath(row: nextResult.idx, section: 0))
          }
          return copy
        }
        _ = indexes.map { row in
          self.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
          self.tableView(self.tableView, didSelectRowAt: row)
        }
      })
        .take(first: 1).observe(on: UIScheduler()).start()
    }
  }
  
  func configureNavBarForActiveWatcher() {
    // FIXME: Implement navbar actions
    if let rightNavBarItem = navigationItem.rightBarButtonItem?.reactive {
      rightNavBarItem.isEnabled <~ movieWatcherViewModel.activeWatcher.map { $0.isReady }.flatten(.merge)
    }
  }
  
  func configureTabBar() {
    let preferenceStatus = movieWatcherViewModel.getStatusForActiveWatcherPreference(preferenceType: self.entityType)
    MutableProperty(self.navigationController?.tabBarItem.badgeColor) <~ preferenceStatus.statusColor.producer
    MutableProperty(self.navigationController?.tabBarItem.badgeValue) <~ preferenceStatus.statusMessage.producer
  }
  
  
  // MARK: TableViewDelegate
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedRows.value.insert(indexPath)
    if let preference = viewModel?.modelData.value[self.entityType]?[indexPath.row] {
      _ = movieWatcherViewModel.activeWatcherAdd(preference: preference, with: self.entityType)
    }
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    selectedRows.value.remove(indexPath)
    if let preference = viewModel!.modelData.value[self.entityType]?[indexPath.row] {
      _ = movieWatcherViewModel.activeWatcherRemove(preference: preference, with: self.entityType)
    }
    
  }
  
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetails" {
      let detailController = segue.destination as! DetailController
      if let sender = sender as? TMDBEntityProtocol {
        detailController.viewModel.entity = sender
      }
    }
  }
  
  @IBAction func goHome(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func preferencesComplete(_ sender: UIBarButtonItem) {
    if movieWatcherViewModel.activeWatcher.value.isReady.value {
      self.navigationController?.tabBarController?.dismiss(animated: true) { self.movieWatcherViewModel.updateActiveWatcher() }
    } else {
      print("Not finished yet!")
    }
  }
}