//
//  ViewResultsController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/21/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift

class ViewResultsController: UITableViewController {
  
  @IBOutlet weak var tableHeaderView: UIView!
  @IBOutlet weak var tableHeaderStackView: UIStackView!
  @IBOutlet weak var searchTextField: UITextField!
  
  
  internal var _entityType: TMDBEntity!
  public var entityType: TMDBEntity {
    return _entityType
  }
  public var tableViewModel: SearchResultsTableViewModeling!
  private var movieDiscover: MovieDiscoverProtocol {
    return watcherViewModel.movieDiscovery.value
  }
  public var watcherViewModel: WatcherViewModelProtocol!
  private var tableViewDataSource: MNightTableviewDataSource!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl?.addTarget(self, action: #selector(ViewResultsController.handleRefresh(refreshControl:)), for: .valueChanged)
    clearsSelectionOnViewWillAppear = false
    setupSearchTextField()
    configureHeaderView()
    let resultsCellModelProducer = tableViewModel.modelData.producer.map { $0[.media]! }
    tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: resultsCellModelProducer, nibName: Identifiers.movieResultCellNibName.rawValue)
    tableViewDataSource.configureTableView()
    tableViewModel.getNextMovieResultPage(page: tableViewModel.currentMovieResultPage.value, discover: movieDiscover)
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  
  func configureHeaderView() {
    guard entityType == .media else { return }
    tableViewModel!.resultPageCountTracker().map {  (numPages, tracker) in
      return "Go to (?) of \(numPages) Result Pages"
      }.signal.observeValues { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.searchTextField.placeholder = text
      }
    tableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderViewHeight)
    updateHeaderView()
  }

  func updateHeaderView() {
    guard !searchTextField.isEditing else { return }
    var headerRect = CGRect(x: 0, y: -kTableHeaderViewHeight, width: tableView.bounds.width, height: kTableHeaderViewHeight)
    headerRect.origin.y = tableView.contentOffset.y
    tableHeaderView.frame = headerRect
  }
  
  func setupSearchTextField() {
    guard entityType == .media else { return }
    let search = searchTextField.reactive.continuousTextValues
    search.throttle(0.5, on: QueueScheduler.main).observeValues { [weak self] value in
      guard let strongSelf = self else { return }
      guard let pageNumber = Int(value!) else { return }
      strongSelf.tableViewModel.getNextMovieResultPage(page: pageNumber, discover: strongSelf.movieDiscover)
    }
    searchTextField.isHidden = true
  }
  
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    guard (tableViewModel?.resultPageCountTracker().map { $0.page }.value)! > 1 else {
      return
    }
    self.tableView.refreshControl?.attributedTitle = tableViewModel?.resultPageCountTracker().map { $0.tracker }.value
    refreshControl.beginRefreshing()
    tableViewModel?.getNextMovieResultPage(page: self.tableViewModel.currentMovieResultPage.value ,discover: movieDiscover)
    // observe when network activity ends to end refreshing
    UIApplication.shared.reactive.values(forKeyPath: Identifiers.networkActivityKey.rawValue).on() { [weak self] value in
      guard let strongSelf = self else { return }
      if let value = value as? Bool {
        if value == false {
          strongSelf.refreshControl?.endRefreshing()
        }
      }
    }.start(on: UIScheduler()).start()
  }
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard entityType == .media else { return }
    updateHeaderView()
  }
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    // unfocus textfield when user scrolls
    guard entityType == .media else { return }
    searchTextField.resignFirstResponder()
    searchTextField.text = ""
  }
  
  // MARK: TableViewDelegate
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return tableHeaderView ?? nil
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return entityType == .media ? kTableHeaderViewHeight : 0
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let entity = tableViewModel!.modelData.value[self.entityType]![indexPath.row] as TMDBEntityProtocol
    performSegue(withIdentifier: Identifiers.showDetailsSegue.rawValue, sender: entity)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Identifiers.showDetailsSegue.rawValue {
      let detailController = segue.destination as! DetailController
      if let sender = sender as? TMDBEntity.Media {
        detailController.viewModel.entity = sender
      }
    }
  }
  
  @IBAction func showSearchResultsButtonPressed(_ sender: UIButton) {
    toggleTextField()
  }
  
  deinit {
    print("Results controller deinit")
  }
  
}

extension ViewResultsController: UITextFieldDelegate {
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
          self.tableHeaderStackView.addArrangedSubview(self.searchTextField)
          self.searchTextField.isHidden = false
          self.searchTextField.becomeFirstResponder()
        } else {
          self.tableHeaderStackView.removeArrangedSubview(self.searchTextField)
          self.searchTextField.isHidden = true
        }
      }, completion: nil)
  }
}
