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
  // entityType needed for fetching the correct properties from viewModel
  var entityType: TMDBEntity { get }
}


class MovieNightSearchController: UITableViewController, UITextFieldDelegate, MovieNightSearchControllerProtocol {
  internal var _entityType: TMDBEntity!
  public var entityType: TMDBEntity {
    return _entityType
  }
  var searchHeaderView: SearchHeaderView!
  var alertController: UIAlertController?
  public weak var movieWatcherViewModel: WatcherViewModelProtocol!
  public weak var tableViewModel: SearchResultsTableViewModeling?
  private var tableViewDataSource: MNightTableviewDataSource!
  private var selectedRows: MutableProperty<Set<IndexPath>> = MutableProperty(Set<IndexPath>()) // allows user to see what their current selections are if they navigate away and come back.
  private var cellModelProducer: SignalProducer<[TMDBEntityProtocol], NoError>? {
    guard let tableViewModel = tableViewModel else { return nil }
    switch entityType {
      case .movieGenre: return tableViewModel.modelData.producer.map { $0[.movieGenre]!.flatMap { $0.entities } }
      case .rating: return tableViewModel.modelData.producer.map { $0[.rating]!.flatMap { $0.entities } }
      default: return tableViewModel.modelData.producer.map { $0[.actor]!.flatMap { $0.entities } }
    }
  }
  private var needInitialFetch: Bool {
    return tableViewModel!.modelData.map { [weak self] data -> Bool in
      guard let strongSelf = self else { return false }
      return data[strongSelf.entityType]!.flatMap { $0.entities }.isEmpty
    }.value
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
    guard tableViewModel != nil && movieWatcherViewModel != nil else {
      alertForError(message: MovieNightControllerAlert.propertyInjectionFailure.rawValue)
      fatalError(MovieNightControllerAlert.propertyInjectionFailure.rawValue)
    }
    refreshControl?.addTarget(self, action: #selector(MovieNightSearchController.handleRefresh(refreshControl:)), for: .valueChanged)
    self.clearsSelectionOnViewWillAppear = false
    self.navigationItem.setHidesBackButton(true, animated: false)
    // data source takes TMDBEntityProtocol types, so map viewModel data to required type
    // set datasource using the above producer
    tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: cellModelProducer!, nibName: cellNibName)
    tableViewDataSource.configureTableView()
    if entityType == .actor {
      let nib = UINib(nibName: Identifiers.searchHeaderView.rawValue, bundle: nil)
      tableView.register(nib, forHeaderFooterViewReuseIdentifier: Identifiers.searchHeaderView.rawValue)
    }
    // reselect rows when user refreshes tableview
    selectUserRowSelections()
    observeForTableViewReload()
    configureNavBarForActiveWatcher()
    configureTabBar()
    configureErrorSignal()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // fetch data if viewModel hasn't already fetched self.entity's cellModels
    if needInitialFetch {
      switch entityType {
        case .actor: tableViewModel?.getPopularPeoplePage(pageNumber: tableViewModel!.currentPeopleResultPage.value + 1)
        case .movieGenre: tableViewModel?.getGenres()
        case .rating: tableViewModel?.getRatings()
        default: break
      }
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
  }

  // keep the searchHeader pinned to the top
  func updateHeaderView() {
    guard let headerView = searchHeaderView else { return }
    // make the searchfield scroll with the tableview
    var headerRect = CGRect(x: 0, y: -kTableHeaderViewHeight, width: tableView.bounds.width, height: kTableHeaderViewHeight)
    headerRect.origin.y = max(0, tableView.contentOffset.y)
    headerView.frame = headerRect
  }
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // return if not .actor type
    guard entityType == .actor else { return }
    // updateHeader when scrolled
    updateHeaderView()
  }
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    // unfocus textfield when user scrolls
    guard entityType == .actor else { return }
    searchHeaderView.searchTextField.resignFirstResponder()
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
    print("Memory warning")
      // Dispose of any resources that can be recreated.
  }
  
  private func configureErrorSignal() {
    // if viewModel receives error when fetching cellModel data, show error message
    tableViewModel!.errorMessage.signal.observe(on: kUIScheduler).observeValues { [weak self] message in
      guard let strongSelf = self else { return }
      guard let message = message else { return }
      strongSelf.alertForError(message: message)
      strongSelf.refreshControl?.endRefreshing()
    }
  }

  func handleRefresh(refreshControl: UIRefreshControl) {
    // currently actor entities are the only pageable entity managed by this
    // viewController class, consider using this controller for viewResults as well
    guard self.entityType.isPageable else { return }
    switch self.entityType {
      case .actor:
        guard (tableViewModel!.peoplePageCountTracker().map { $0.page }).value > 1 else { return }
        if let indexPaths = tableView.indexPathsForSelectedRows {
          selectedRows.value = Set(indexPaths)
        }
        refreshControl.beginRefreshing()
        tableViewModel!.getPopularPeoplePage(pageNumber: tableViewModel!.currentPeopleResultPage.value)
      default: break
    }
    self.tableView.refreshControl?.attributedTitle = tableViewModel!.peoplePageCountTracker().map { $0.tracker }.value
    // observe when network activity ends to end refreshing
    UIApplication.shared.reactive.values(forKeyPath: Identifiers.networkActivityKey.rawValue).on() { [unowned self] value in
      if let value = value as? Bool {
        if value == false {
          self.refreshControl?.endRefreshing()
        }
      }
    }
      .take(during: self.reactive.lifetime)
      .start(on: kUIScheduler).start()
  }
  
  private func observeForTableViewReload() {
    // remember users selections when they refresh the tableview with more people results
    tableView.reactive.trigger(for: #selector(tableView.reloadData)).take(during: self.reactive.lifetime).observeValues { [weak self] in
      guard let strongSelf = self else { return }
      _ = strongSelf.selectedRows.value.map { [] row in
        strongSelf.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
      }
    }
  }
  
  private func alertForError(message: String) {
    alertController = alertController ?? UIAlertController(title: MovieNightControllerAlert.somethingWentWrong.rawValue, message: message, preferredStyle: .alert)
    guard let alertController = alertController else { return }
    let okAction = UIAlertAction(title: MovieNightControllerAlert.ok.rawValue, style: .default, handler: nil)
    if alertController.actions.isEmpty {
      alertController.addAction(okAction)
    }
    // check to make sure another alert is not already being displayed
    if self.presentedViewController == nil {
      self.navigationController?.tabBarController?.present(alertController, animated: true, completion: nil)
    }
  }

  
  // used for if user goes to home page and then resumes searching, their previous selections
  // will already be highlighted
  private func selectUserRowSelections() {
    guard let currentPreferences = movieWatcherViewModel
      .getChoicesForActiveWatcher(choiceType: entityType).value else { return }
    let titles = currentPreferences.map { $0.title }
    guard let indexPaths = tableViewModel?.indexesForTitles(ofEntityType: entityType, titles: titles) else { return }
    indexPaths.forEach { [unowned self] indexPath in
      self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
      self.tableView(self.tableView, didSelectRowAt: indexPath)
    }
  }
  
  // activate or deactivate barbutton items depending on state of active watcher selections
  // forces save if user meets minimum preference requirements
  func configureNavBarForActiveWatcher() {
    navigationItem.rightBarButtonItem!.reactive.isEnabled <~ movieWatcherViewModel.activeWatcherReady.skipRepeats().producer.take(during: self.reactive.lifetime)
    navigationItem.leftBarButtonItem!.reactive.isEnabled <~ movieWatcherViewModel.activeWatcherReady.map { !$0 }.skipRepeats().producer.take(during: self.reactive.lifetime)
  }
  
  func configureTabBar() {
    // tried binding properties to tabBar, but only worked using producer
    let preferenceStatus = movieWatcherViewModel.getStatusForActiveWatcherChoice(choiceType: entityType)
    preferenceStatus.producer.on { [weak self] status in
      guard let strongSelf = self else { return }
      strongSelf.navigationController?.tabBarItem.badgeColor = status.statusColor
      strongSelf.navigationController?.tabBarItem.badgeValue = status.statusMessage
    }
      .take(during: self.reactive.lifetime)
      .observe(on: kUIScheduler).start()
  }
  
  
  // MARK: TableViewDelegate
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard entityType == .actor else { return nil }
    searchHeaderView = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.searchHeaderView.rawValue) as! SearchHeaderView
    searchHeaderView.entityType = self.entityType
    searchHeaderView.viewModel = self.tableViewModel
    return searchHeaderView
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return entityType == .actor ? kTableHeaderViewHeight : 0
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let entities = tableViewModel?.modelData.value[self.entityType]!.flatMap { $0.entities }
    if let preference = entities?[indexPath.row] {
      // activeWatcherAdd returns a bool. Not currently using value, but might be useful when adding
      // diff features
      _ = movieWatcherViewModel.activeWatcherAdd(choice: preference, with: self.entityType)
    }
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    // fetch the model data for the type that matches the controller's entity type
    let entities = tableViewModel?.modelData.value[self.entityType]!.flatMap { $0.entities }
    if let preference = entities?[indexPath.row] {
      // activeWatcherRemove returns a bool. Not currently using value, but might be useful when adding
      // diff features
      _ = movieWatcherViewModel.activeWatcherRemove(choice: preference, with: self.entityType)
    }
    
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let entities = tableViewModel?.modelData.value[self.entityType]!.flatMap { $0.entities }
    // view details for the specified entity (only actors and ratings have details)
    if let entity = entities?[indexPath.row] {
      performSegue(withIdentifier: Identifiers.showDetailsSegue.rawValue, sender: entity)
    }
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
    // segue to homeController if users selections are complete, or alert if preferences not complete. (Save button should not be enabled if preference not set.
    ready ? self.navigationController?.tabBarController?.dismiss(animated: true, completion: nil) : alertForError(message: MovieNightControllerAlert.preferencesNotComplete.rawValue)
  }
  
  deinit {
    alertController = nil
//    print("\(entityType) controller deinit")
  }
}
