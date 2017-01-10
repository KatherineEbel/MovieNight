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



class MovieNightSearchController: UITableViewController, UITextFieldDelegate, MovieNightSearchControllerProtocol {
  
  @IBOutlet weak var searchFieldStackView: UIStackView!
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var textFieldView: UIView!
  
  internal var _entityType: TMDBEntity!
  public var entityType: TMDBEntity {
    return _entityType
  }
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
    self.navigationItem.setHidesBackButton(true, animated: false)
    // data source takes TMDBEntityProtocol types, so map viewModel data to required type
    setupSearchTextField()
    configureHeaderView()
    configureErrorSignal()
    // set datasource using the above producer
    tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: cellModelProducer!, nibName: cellNibName)
    tableViewDataSource.configureTableView()
    // reselect rows when user refreshes tableview
    selectUserRowSelections()
    observeForTableViewReload()
    configureNavBarForActiveWatcher()
    configureTabBar()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // fetch data if viewModel hasn't already fetched self.entity's cellModels
    if (viewModel!.modelData.map { ($0[self.entityType]!).isEmpty }).value {
      switch entityType {
        case .actor: viewModel?.getPopularPeoplePage(pageNumber: viewModel!.currentPeopleResultPage.value + 1)
        case .movieGenre: viewModel?.getGenres()
        case .rating: viewModel?.getRatings()
        default: break
      }
    }
  }

  func configureHeaderView() {
    guard entityType == .actor else { return }
    // get the number of pages to guide user when searching pages
    viewModel!.peoplePageCountTracker().map { (numPages, _) in
      return "Go to (?) of \(numPages) Result Pages"
      }.signal.observeValues { text in
        self.searchTextField.placeholder = text
      }
    tableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderViewHeight)
    updateHeaderView()
  }

  func updateHeaderView() {
    // make the searchfield scroll with the tableview
    var headerRect = CGRect(x: 0, y: -kTableHeaderViewHeight, width: tableView.bounds.width, height: kTableHeaderViewHeight)
    headerRect.origin.y = max(0, tableView.contentOffset.y)
    textFieldView.frame = headerRect
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
    searchTextField.resignFirstResponder()
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func setupSearchTextField() {
    guard entityType == .actor else { return }
    // map user input to search viewmodels people result pages
    let search = searchTextField.reactive.continuousTextValues
    search.throttle(0.5, on: QueueScheduler.main).observeValues { value in
      guard let pageNumber = Int(value!) else { return }
      self.viewModel!.getPopularPeoplePage(pageNumber: pageNumber)
    }
    searchFieldStackView.removeArrangedSubview(searchTextField)
    searchTextField.isHidden = true
  }
  
  func configureErrorSignal() {
    // if viewModel receives error when fetching cellModel data, show error message
    viewModel!.errorMessage.signal.throttle(0.5, on: QueueScheduler.main).observeValues { message in
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
        guard (viewModel!.peoplePageCountTracker().map { $0.page }).value > 1 else { return }
        if let indexPaths = tableView.indexPathsForSelectedRows {
          selectedRows.value = Set(indexPaths)
        }
        refreshControl.beginRefreshing()
        viewModel!.getPopularPeoplePage(pageNumber: viewModel!.currentPeopleResultPage.value)
      default: break
    }
    self.tableView.refreshControl?.attributedTitle = viewModel!.peoplePageCountTracker().map { $0.tracker }.value
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
      indexes.forEach { indexPath in
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView, didSelectRowAt: indexPath)
      }
    })
    .take(first: 1).observe(on: UIScheduler()).start()
  }
  
  // activate or deactivate barbutton items depending on state of active watcher selections
  // forces save if user meets minimum preference requirements
  func configureNavBarForActiveWatcher() {
    navigationItem.rightBarButtonItem!.reactive.isEnabled <~ movieWatcherViewModel.activeWatcherReady
    navigationItem.leftBarButtonItem!.reactive.isEnabled <~ movieWatcherViewModel.activeWatcherReady.map { !$0 }
  }
  
  func configureTabBar() {
    // tried binding properties to tabBar, but only worked using producer
    let preferenceStatus = movieWatcherViewModel.getStatusForActiveWatcherPreference(preferenceType: entityType)
    preferenceStatus.producer.on { status in
      self.navigationController?.tabBarItem.badgeColor = status.statusColor
      self.navigationController?.tabBarItem.badgeValue = status.statusMessage
    }.observe(on: UIScheduler()).start()
  }
  
  
  // MARK: TableViewDelegate
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return textFieldView ?? nil
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return entityType == .actor ? kTableHeaderViewHeight : 0
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let preference = viewModel?.modelData.value[self.entityType]?[indexPath.row] {
      // activeWatcherAdd returns a bool. Not currently using value, but might be useful when adding
      // diff features
      _ = movieWatcherViewModel.activeWatcherAdd(preference: preference, with: self.entityType)
    }
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    // fetch the model data for the type that matches the controller's entity
    if let preference = viewModel!.modelData.value[self.entityType]?[indexPath.row] {
      // activeWatcherRemove returns a bool. Not currently using value, but might be useful when adding
      // diff features
      _ = movieWatcherViewModel.activeWatcherRemove(preference: preference, with: self.entityType)
    }
    
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    // view details for the specified entity (only actors and ratings have details)
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
    ready ? self.navigationController?.tabBarController?.dismiss(animated: true, completion: nil) : alertForError(message: MovieNightControllerAlert.preferencesNotComplete.rawValue)
  }
  
  @IBAction func showSearchButtonPressed(_ sender: UIButton) {
    toggleTextField()
  }
  
  
}

extension MovieNightSearchController {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    searchTextField.text = ""
  }
  
  func toggleTextField() {
      UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseInOut], animations: {
        if self.searchTextField.isHidden {
          self.searchFieldStackView.addArrangedSubview(self.searchTextField)
          self.searchTextField.isHidden = false
          self.searchTextField.becomeFirstResponder()
        } else {
          self.searchFieldStackView.removeArrangedSubview(self.searchTextField)
          self.searchTextField.isHidden = true
        }
      }, completion: nil)
  }
  
}
