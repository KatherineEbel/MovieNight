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
  private var autoSearchStarted = false
  public var tableViewModel: SearchResultsTableViewModeling!
  private var movieDiscover: MovieDiscoverProtocol {
    return watcherViewModel.movieDiscovery.value
  }
  public var watcherViewModel: WatcherViewModelProtocol!
  private var tableViewDataSource: MNightTableviewDataSource!
  
    override func viewDidLoad() {
      super.viewDidLoad()
      refreshControl?.addTarget(self, action: #selector(ViewResultsController.handleRefresh(refreshControl:)), for: .valueChanged)
      self.clearsSelectionOnViewWillAppear = false
      
      let resultsCellModelProducer = tableViewModel.modelData.producer.map { $0[.media]! }
      tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: resultsCellModelProducer, nibName: Identifiers.movieResultCellNibName.rawValue)
      tableViewDataSource.configureTableView()
      self.tableViewModel.getNextMovieResultPage(discover: movieDiscover)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    guard (tableViewModel?.resultPageCountTracker().map { $0.page }.value)! > 1 else {
      return
    }
    self.tableView.refreshControl?.attributedTitle = tableViewModel?.resultPageCountTracker().map { $0.tracker }.value
    refreshControl.beginRefreshing()
    tableViewModel?.getNextMovieResultPage(discover: movieDiscover)
    // observe when network activity ends to end refreshing
    UIApplication.shared.reactive.values(forKeyPath: Identifiers.networkActivityKey.rawValue).on() { value in
      if let value = value as? Bool {
        if value == false {
          self.refreshControl?.endRefreshing()
        }
      }
    }.start(on: UIScheduler()).start()
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
}
