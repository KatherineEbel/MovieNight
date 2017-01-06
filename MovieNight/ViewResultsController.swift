//
//  ViewResultsController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/21/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit

class ViewResultsController: UITableViewController {
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
      let resultsCellModelProducer = tableViewModel.resultsModelData.producer.map { results in
        return results.flatMap { $0 as TMDBEntityProtocol }
      }
      tableViewDataSource = MNightTableviewDataSource(tableView: tableView, sourceSignal: resultsCellModelProducer, nibName: "MovieResultCell")
      tableViewDataSource.configureTableView()
      self.tableViewModel.getResultPage(discover: movieDiscover)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    guard (tableViewModel?.resultPageCountTracker.page)! > 1 else {
      return
    }
    self.tableView.refreshControl?.attributedTitle = tableViewModel?.resultPageCountTracker.tracker
    refreshControl.beginRefreshing()
    tableViewModel?.getResultPage(discover: movieDiscover)
    refreshControl.endRefreshing()
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let entity = tableViewModel!.resultsModelData.value[indexPath.row] as TMDBEntityProtocol
    performSegue(withIdentifier: "showDetails", sender: entity)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetails" {
      let detailController = segue.destination as! DetailController
      if let sender = sender as? TMDBEntityProtocol {
        detailController.viewModel.entity = sender
      }
    }
  }
}
