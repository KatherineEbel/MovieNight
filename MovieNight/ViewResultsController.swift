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
  internal var _entityType: TMDBEntity!
  public var entityType: TMDBEntity {
    return _entityType
  }
  private var searchHeaderView: SearchHeaderView!
  internal weak var tableViewModel: SearchResultsTableViewModeling!
  private var movieDiscover: MovieDiscoverProtocol {
    return watcherViewModel.movieDiscovery.value
  }
  internal weak var watcherViewModel: WatcherViewModelProtocol!
  private var tableViewDataSource: MNightTableviewDataSource!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl?.addTarget(self, action: #selector(ViewResultsController.handleRefresh(refreshControl:)), for: .valueChanged)
    clearsSelectionOnViewWillAppear = false
    configureTableView()
    self.navigationItem.title = movieDiscover.title
    fetchNextResultPage()
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  
  func updateHeaderView() {
    guard let headerView = searchHeaderView else { return }
    var headerRect = CGRect(x: 0, y: -kTableHeaderViewHeight, width: tableView.bounds.width, height: kTableHeaderViewHeight)
    headerRect.origin.y = tableView.contentOffset.y
    headerView.frame = headerRect
  }
  
  func fetchNextResultPage() {
    tableViewModel?.getNextMovieResultPage(page: self.tableViewModel.currentMovieResultPage.value ,discover: movieDiscover)
  }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    guard (tableViewModel?.resultPageCountTracker().map { $0.page }.value)! > 1 else {
      return
    }
    self.tableView.refreshControl?.attributedTitle = tableViewModel?.resultPageCountTracker().map { $0.tracker }.value
    refreshControl.beginRefreshing()
    fetchNextResultPage()
    // observe when network activity ends to end refreshing
    UIApplication.shared.reactive.values(forKeyPath: Identifiers.networkActivityKey.rawValue).on() { [weak self] value in
      guard let strongSelf = self else { return }
      if let value = value as? Bool {
        if value == false {
          strongSelf.refreshControl?.endRefreshing()
        }
      }
    }
    .take(during: self.reactive.lifetime)
    .start(on: kUIScheduler).start()
  }
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard entityType == .media else { return }
    updateHeaderView()
  }
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    // unfocus textfield when user scrolls
    guard entityType == .media else { return }
    searchHeaderView.searchTextField.resignFirstResponder()
    searchHeaderView.searchTextField.text = ""
  }
  
  func configureTableView() {
    let resultsCellModelProducer = tableViewModel.modelData.producer.map { $0[.media]!.flatMap { $0.entities } }
    tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: resultsCellModelProducer, nibName: Identifiers.movieResultCellNibName.rawValue)
    tableViewDataSource.configureTableView()
    tableViewModel.clearMediaData()
    if entityType == .media {
      let nib = UINib(nibName: "SearchHeaderView", bundle: nil)
      tableView.register(nib, forHeaderFooterViewReuseIdentifier: Identifiers.searchHeaderView.rawValue)
    }
  }
  
  // MARK: TableViewDelegate
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard entityType == .media else { return nil }
    searchHeaderView = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.searchHeaderView.rawValue) as! SearchHeaderView
    // make sure  header has the correct properties to keep ui in sync
    searchHeaderView.entityType = self.entityType
    searchHeaderView.viewModel = self.tableViewModel
    searchHeaderView.movieDiscover = self.movieDiscover
    return searchHeaderView
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    // should be no height and no header if not .media type
    return entityType == .media ? kTableHeaderViewHeight : 0
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    // show the detail controller when the accessory for a row is tapped
    let entities = tableViewModel!.modelData.value[self.entityType]!.flatMap { $0.entities }
    let entity = entities[indexPath.row] as TMDBEntityProtocol
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
  
  deinit {
    print("Results controller deinit")
  }
  
}
