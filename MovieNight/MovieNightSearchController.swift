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
  @IBOutlet weak var savePreferenceButton: UIBarButtonItem!

  internal var _entityType: TMDBEntity!
  public var entityType: TMDBEntity {
    return _entityType
  }
  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  public var viewModel: SearchResultsTableViewModeling?
  private var tableViewDataSource: MNightTableviewDataSource!
  private var watcherSignal: Signal<[MovieWatcherProtocol]?, NoError>!
  private var selectedRows: MutableProperty<Set<IndexPath>> = MutableProperty(Set<IndexPath>())
  private var cellModelProducer: SignalProducer<[TMDBEntityProtocol], NoError>? {
    guard let viewModel = viewModel else { return nil }
    switch entityType {
      case .movieGenre: return viewModel.modelData.producer.map { $0[.movieGenre]! }
      case .rating: return viewModel.modelData.producer.map { $0[.rating]! }
      default: return viewModel.modelData.producer.map { $0[.actor]! } 
    }
  }
  
  private var cellNibName: String {
    switch entityType {
      case .actor, .movieGenre, .rating: return Identifiers.preferenceCellNibName.rawValue
      case .media: return Identifiers.movieResultCellNibName.rawValue
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // crash if no viewModel, and also make sure safe to force unwrap viewModel property
    guard viewModel != nil && movieWatcherViewModel != nil else {
      alertForError(message: MovieNightControllerAlert.propertyInjectionFailure.rawValue)
      fatalError(MovieNightControllerAlert.propertyInjectionFailure.rawValue)
    }
    
    refreshControl?.addTarget(self, action: #selector(MovieNightSearchController.handleRefresh(refreshControl:)), for: .valueChanged)
    self.clearsSelectionOnViewWillAppear = false
    // data source takes TMDBEntityProtocol types, so map viewModel data to required type
      selectUserRowSelections()
      configureErrorSignal()
      // set datasource using the above producer
      tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: cellModelProducer!, nibName: cellNibName)
      tableViewDataSource.configureTableView()
      // reselect rows when user refreshes tableview
      observeForTableViewReload()
      configureNavBarForActiveWatcher()
      configureTabBar()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // fetch data if viewModel hasn't already fetched self.entity's cellModels
    if (viewModel!.modelData.map { ($0[self.entityType]!).isEmpty }).value {
      switch entityType {
        case .actor: viewModel?.getNextPopularPeoplePage()
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
  
  func configureErrorSignal() {
    // if viewModel receives error when fetching cellModel data, show error message
    viewModel!.errorMessage.signal.take(last: 1).observeValues { message in
      if let message = message {
        DispatchQueue.main.async {
          self.alertForError(message: message)
          self.refreshControl?.endRefreshing()
        }
      }
    }
  }

  func handleRefresh(refreshControl: UIRefreshControl) {
    // currently actor entities are the only pageable entity managed by this
    // viewController class, consider using this controller for viewResults as well
    guard self.entityType.isPageable else { return }
    switch self.entityType {
      case .actor:
        guard viewModel!.peoplePageCountTracker.page > 1 else { return }
        refreshControl.beginRefreshing()
        viewModel!.getNextPopularPeoplePage()
      default: break
    }
    self.tableView.refreshControl?.attributedTitle = viewModel?.peoplePageCountTracker.tracker
    // observe when network activity ends to end refreshing
    UIApplication.shared.reactive.values(forKeyPath: Identifiers.networkActivityKey.rawValue).on() { value in
      if let value = value as? Bool {
        if value == false {
          self.refreshControl?.endRefreshing()
        }
      }
    }.start(on: UIScheduler()).start()
  }
  
  func observeForTableViewReload() {
    // remember users selections when they refresh the tableview with more people results
    _ = tableView.reactive.trigger(for: #selector(tableView.reloadData)).observeValues {
      _ = self.selectedRows.value.map { row in
        self.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
      }
    }
  }
  
public func alertForError(message: String) {
    let alertController = UIAlertController(title: MovieNightControllerAlert.somethingWentWrong.rawValue, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: MovieNightControllerAlert.ok.rawValue, style: .default, handler: nil)
    alertController.addAction(okAction)
    present(alertController, animated: true, completion: nil)
  }

  
  // used for if user goes to home page and then resumes searching, their previous selections
  // will already be highlighted
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
  
  // activate or deactivate barbutton items depending on state of active watcher selections
  // forces save if user meets minimum preference requirements
  func configureNavBarForActiveWatcher() {
    savePreferenceButton.reactive.isEnabled <~ movieWatcherViewModel.activeWatcherReady
    navigationItem.leftBarButtonItem!.reactive.isEnabled <~ movieWatcherViewModel.activeWatcherReady.map { !$0 }
  }
  
  func configureTabBar() {
   movieWatcherViewModel.activeWatcher.value
    .moviePreference.preferences.map { $0[self.entityType]!.count }.signal.observeValues { count in
      let readyColor = TMDBColor.ColorFromRGB(color: .green, withAlpha: 1.0)
      let notReadyColor = UIColor.red
      var statusText: String = ""
      var statusColor = notReadyColor
        switch self.entityType {
          case .actor, .movieGenre:
            statusText = "\(count)/5"
            statusColor = count >= 1 && count <= 5 ? readyColor : notReadyColor
          case .rating:
            statusText = "\(count)/1"
            statusColor = count == 1 ? readyColor : notReadyColor
          default: break
        }
      self.navigationController?.tabBarItem.badgeColor = statusColor
      self.navigationController?.tabBarItem.badgeValue = statusText
    }
  }
  
  
  // MARK: TableViewDelegate
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedRows.value.insert(indexPath)
    if let preference = viewModel?.modelData.value[self.entityType]?[indexPath.row] {
      // activeWatcherAdd returns a bool. Not currently using value, but might be useful when adding
      // diff features
      _ = movieWatcherViewModel.activeWatcherAdd(preference: preference, with: self.entityType)
    }
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    selectedRows.value.remove(indexPath)
    if let preference = viewModel!.modelData.value[self.entityType]?[indexPath.row] {
      // activeWatcherRemove returns a bool. Not currently using value, but might be useful when adding
      // diff features
      _ = movieWatcherViewModel.activeWatcherRemove(preference: preference, with: self.entityType)
    }
    
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let entity = viewModel!.modelData.value[self.entityType]![indexPath.row] as TMDBEntityProtocol
    performSegue(withIdentifier: Identifiers.showDetailsSegue.rawValue, sender: entity)
  }
  
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Identifiers.showDetailsSegue.rawValue {
      let detailController = segue.destination as! DetailController
      switch sender {
        // only the actor and rating entities have details
        case let actor where sender is TMDBEntity.Actor: detailController.viewModel.entity = actor as! TMDBEntity.Actor
        case let rating where sender is TMDBEntity.Rating: detailController.viewModel.entity = rating as! TMDBEntity.Rating
      default: break
      }
      
    }
  }
  
  @IBAction func goHome(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func preferencesComplete(_ sender: UIBarButtonItem) {
    // isReady property is a tuple of bools assigned to nameValid and moviePreference.isSet
    let ready = movieWatcherViewModel.activeWatcher.value.isReady.map { $0.0 && $0.1 }.value
    if ready {
      self.navigationController?.tabBarController?.dismiss(animated: true) { self.movieWatcherViewModel.updateActiveWatcher() }
    } else {
      alertForError(message: MovieNightControllerAlert.preferencesNotComplete.rawValue)
    }
  }
}
