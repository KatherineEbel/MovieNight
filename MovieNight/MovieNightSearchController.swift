//
//  MovieNightSearchPageableControllerTableViewController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 1/19/17.
//  Copyright © 2017 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class MovieNightSearchPageableController: UITableViewController, MovieNightSearchControllerProtocol {
  internal var _entityType: TMDBEntity!
  public var entityType: TMDBEntity {
    return _entityType
  }
  var searchHeaderView: SearchHeaderView!
  var alertController: UIAlertController?
  public weak var tableViewModel: SearchResultsTableViewModeling?
  public weak var watcherViewModel: WatcherViewModelProtocol!
  private var tableViewDataSource: MNightTableviewDataSource!
  private var movieDiscover: MovieDiscoverProtocol {
    return watcherViewModel.movieDiscovery.value
  }
  private var selectedRows: MutableProperty<Set<IndexPath>> = MutableProperty(Set<IndexPath>()) // allows user to see what their current selections are if they navigate away and come back.
  private var cellModelProducer: SignalProducer<[TMDBEntityProtocol], NoError>? {
    guard let tableViewModel = tableViewModel else { return nil }
    switch entityType {
      case .actor: return tableViewModel.modelData.producer.map { $0[.actor]!.flatMap { $0.entities } }
      case .movieGenre: return tableViewModel.modelData.producer.map { $0[.movieGenre]!.flatMap { $0.entities } }
      case .rating: return tableViewModel.modelData.producer.map { $0[.rating]!.flatMap { $0.entities } }
      case .media: return tableViewModel.modelData.producer.map { $0[.media]!.flatMap { $0.entities } }
    }
  }
  private var needInitialFetch: Bool {
    // need initial fetch if model data is empty for entity type
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
    guard tableViewModel != nil && watcherViewModel != nil else {
      alertForError(message: MovieNightControllerAlert.propertyInjectionFailure.rawValue)
      fatalError(MovieNightControllerAlert.propertyInjectionFailure.rawValue)
    }
    refreshControl?.addTarget(self, action: #selector(MovieNightSearchController.handleRefresh(refreshControl:)), for: .valueChanged)
    self.clearsSelectionOnViewWillAppear = false
    if entityType.isSelectable {
      self.navigationItem.setHidesBackButton(true, animated: false)
    } else {
      self.navigationItem.title = movieDiscover.title
    }
    configureDataSource()
    configureErrorSignal()
    observeForTableViewReload()
    configureNavBarForActiveWatcher()
    configureTabBar()
    selectUserRowSelections()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // fetch data if viewModel hasn't already fetched self.entity's cellModels
    if needInitialFetch {
      switch entityType {
        case .actor: tableViewModel?.getPopularPeoplePage(pageNumber: tableViewModel!.currentPeopleResultPage.value + 1)
        case .movieGenre: tableViewModel?.getGenres()
        case .rating: tableViewModel?.getRatings()
        case .media: tableViewModel?.getNextMovieResultPage(pageNumber: tableViewModel!.currentMovieResultPage.value + 1, discover: movieDiscover)
      }
    }
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
    print("Memory warning")
      // Dispose of any resources that can be recreated.
  }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    // currently actor entities are the only pageable entity managed by this
    // should not refresh if the result page has no more than 1 result page, so
    // early return in that case
    guard self.entityType.isPageable else { return }
    switch self.entityType {
      case .actor:
        guard (tableViewModel!.peoplePageCountTracker().map { $0.page }).value > 1 else { return }
        if let indexPaths = tableView.indexPathsForSelectedRows {
          selectedRows.value = Set(indexPaths)
        }
        tableViewModel!.getPopularPeoplePage(pageNumber: tableViewModel!.currentPeopleResultPage.value)
        self.tableView.refreshControl?.attributedTitle = tableViewModel!.peoplePageCountTracker().map { $0.tracker }.value
      case .media:
        guard(tableViewModel!.resultPageCountTracker().map { $0.page }).value > 1 else { return }
        self.tableView.refreshControl?.attributedTitle = tableViewModel!.resultPageCountTracker().map { $0.tracker }.value
      tableViewModel!.getNextMovieResultPage(pageNumber: tableViewModel!.currentMovieResultPage.value, discover: movieDiscover)
      default: break
    }
    refreshControl.beginRefreshing()
  }
  
  // MARK: Scroll methods
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // return if not .actor type
    guard entityType == .actor || entityType == .media else { return }
    // updateHeader when scrolled
    updateHeaderView()
  }
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    // unfocus textfield when user scrolls
    guard entityType == .actor || entityType == .media else { return }
    searchHeaderView.searchTextField.resignFirstResponder()
  }
  
  func scrollToTop(gestureRecognizer: UITapGestureRecognizer) {
    let indexPath = IndexPath(item: 0, section: 0)
    tableView.scrollToRow(at: indexPath, at: .top, animated: true)
  }
  
  func configureDataSource() {
    tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: cellModelProducer!, nibName: cellNibName)
    tableViewDataSource.configureTableView()
    if entityType.isPageable {
      let nib = UINib(nibName: Identifiers.searchHeaderView.rawValue, bundle: nil)
      tableView.register(nib, forHeaderFooterViewReuseIdentifier: Identifiers.searchHeaderView.rawValue)
    }
  }
  
  // MARK: Error helper methods
  private func configureErrorSignal() {
    // if viewModel receives error when fetching cellModel data, show error message
    tableViewModel!.errorMessage.signal.observe(on: kUIScheduler).observeValues { [weak self] message in
      guard let strongSelf = self else { return }
      guard let message = message else { return }
      strongSelf.alertForError(message: message)
      strongSelf.refreshControl?.endRefreshing()
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
      let presenter = entityType.isSelectable ?
        self.navigationController?.tabBarController : self.navigationController
      presenter?.present(alertController, animated: true, completion: nil)
    }
  }

  
  // MARK: "Selectable" helper methods"
  // used for if user goes to home page and then resumes searching, their previous selections
  // will already be highlighted
  private func selectUserRowSelections() {
    guard entityType.isSelectable else { return }
    guard let currentPreferences = watcherViewModel
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
    guard entityType.isSelectable else { return }
    navigationItem.rightBarButtonItem!.reactive.isEnabled <~ watcherViewModel.activeWatcherReady.skipRepeats().producer.take(during: self.reactive.lifetime)
    navigationItem.leftBarButtonItem!.reactive.isEnabled <~ watcherViewModel.activeWatcherReady.map { !$0 }.skipRepeats().producer.take(during: self.reactive.lifetime)
  }
  
  func configureTabBar() {
    guard entityType.isSelectable else { return }
    // tried binding properties to tabBar, but only worked using producer
    // keep tabBar badges in sync with active watcher choice status
    let preferenceStatus = watcherViewModel.getStatusForActiveWatcherChoice(choiceType: entityType)
    preferenceStatus.producer.on { [weak self] status in
      guard let strongSelf = self else { return }
      strongSelf.navigationController?.tabBarItem.badgeColor = status.statusColor
      strongSelf.navigationController?.tabBarItem.badgeValue = status.statusMessage
    }
      .take(during: self.reactive.lifetime)
      .observe(on: kUIScheduler).start()
  }
  
  private func observeForTableViewReload() {
    guard entityType.isPageable else { return }
    // remember users selections when they refresh the tableview with more people results
    tableView.reactive.trigger(for: #selector(tableView.reloadData)).take(during: self.reactive.lifetime).observeValues { [weak self] in
      guard let strongSelf = self else { return }
      if let isRefreshing =  strongSelf.refreshControl?.isRefreshing {
        if isRefreshing { strongSelf.refreshControl?.endRefreshing() }
      }
      if strongSelf.entityType.isSelectable {
        _ = strongSelf.selectedRows.value.map { [] row in
          strongSelf.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
        }
      }
      let numRows = strongSelf.tableView.numberOfRows(inSection: 0)
      if numRows > 20 {
        // scroll user to newest rows
        let indexpath = IndexPath(item: numRows - 1, section: 0)
        strongSelf.tableView.scrollToRow(at: indexpath, at: .top, animated: true)
      }
    }
  }
  
  // MARK: TableViewHeader helper methods
  // keep the searchHeader pinned to the top
  func updateHeaderView() {
    // don't try and move headerview if trying to refresh, (prevent glitchiness)
    if let refreshing = refreshControl?.isRefreshing {
      if refreshing { return }
    }
    guard let headerView = searchHeaderView else { return }
    // make the searchfield scroll with the tableview
    var headerRect = CGRect(x: 0, y: -kTableHeaderViewHeight, width: tableView.bounds.width, height: kTableHeaderViewHeight)
    headerRect.origin.y = max(0, tableView.contentOffset.y)
    headerView.frame = headerRect
  }
  
  private func getSearchHeader() -> UITableViewHeaderFooterView {
    searchHeaderView = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.searchHeaderView.rawValue) as! SearchHeaderView
    let headerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MovieNightSearchController.scrollToTop(gestureRecognizer:)))
    searchHeaderView.addGestureRecognizer(headerTapGestureRecognizer)
    searchHeaderView.entityType = self.entityType
    searchHeaderView.viewModel = self.tableViewModel
    if entityType == .media { searchHeaderView.movieDiscover = self.movieDiscover }
    return searchHeaderView
  }
  
  // MARK: TableViewDelegate
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    // only return a search for actor types since they are the only ones that
    // have multiple pages
    guard entityType.isPageable else { return nil }
    return getSearchHeader()
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return entityType.isPageable ? kTableHeaderViewHeight : 0
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    guard  entityType.hasDetails else { return }
    // cell determines based on data whether it has an accessory button
    let entities = tableViewModel!.modelData.value[self.entityType]!.flatMap { $0.entities }
    // view details for the specified entity (only actors and ratings have details)
    let entity = entities[indexPath.row]
    performSegue(withIdentifier: Identifiers.showDetailsSegue.rawValue, sender: entity)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard entityType.isSelectable else { return }
    let entities = tableViewModel!.modelData.value[self.entityType]!.flatMap { $0.entities }
    let preference = entities[indexPath.row]
      // activeWatcherAdd returns a bool. Not currently using value, but might be useful when adding
      // diff features
    _ = watcherViewModel.activeWatcherAdd(choice: preference, with: self.entityType)
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    guard  entityType.isSelectable else { return }
    // fetch the model data for the type that matches the controller's entity type
    let entities = tableViewModel!.modelData.value[self.entityType]!.flatMap { $0.entities }
    let preference = entities[indexPath.row]
      // activeWatcherRemove returns a bool. Not currently using value, but might be useful when adding
      // diff features
    _ = watcherViewModel.activeWatcherRemove(choice: preference, with: self.entityType)
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
        case let movie where sender is TMDBEntity.Media: detailController.viewModel.entity = movie as! TMDBEntity.Media
        default: break
      }
    }
  }
  
  @IBAction func goHome(_ sender: UIBarButtonItem) {
    guard entityType.isSelectable else { return }
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func preferencesComplete(_ sender: UIBarButtonItem) {
    guard entityType.isSelectable else { return }
    // isReady property is a tuple of bools assigned to nameValid and moviePreference.isSet
    let ready = watcherViewModel.activeWatcher.value.isReady.map { $0.0 && $0.1 }.value
    // segue to homeController if users selections are complete, or alert if preferences not complete. (Save button should not be enabled if preference not set.
    ready ? self.navigationController?.tabBarController?.dismiss(animated: true, completion: nil) : alertForError(message: MovieNightControllerAlert.preferencesNotComplete.rawValue)
  }
  
  deinit {
    alertController = nil
//    print("\(entityType) controller deinit")
  }
}
