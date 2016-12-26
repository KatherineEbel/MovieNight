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
  public var watcherViewModel: WatcherViewModelProtocol! {
    didSet {
      self.watcherViewModel.watchers.producer.map { _ in
        return self.watcherViewModel.combineWatchersChoices()
      }.startWithSignal { (observer, disposabel) in
        observer.observe { event in
          if let result = event.value {
            self.tableViewModel.getResults(actorIDs: (result?.actorIDs)!, genreIDs: (result?.genreIDs)!, maxRating: (result?.rating)!)
          }
        }
      }
    }
  }
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
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
    }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    guard (tableViewModel?.resultPageCountTracker.page)! > 1 else {
      return
    }
    self.tableView.refreshControl?.attributedTitle = tableViewModel?.resultPageCountTracker.tracker
    refreshControl.beginRefreshing()
    print("Changed")
    tableViewModel?.getNextPage()
    refreshControl.endRefreshing()
  }
}
