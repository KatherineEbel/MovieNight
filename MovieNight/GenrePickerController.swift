//
//  GenrePickerController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import Argo

class GenrePickerController: UITableViewController {

  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  private var tableViewHelper: MovieNightTableviewBindingHelper!
  public var viewModel: SearchResultsTableViewModeling? {
    didSet {
//      if let viewModel = viewModel {
//        viewModel.cellModels.producer
//          .on { _ in
//            self.tableView.reloadData()
//          }
//          .start()
//      }
    }
  }
  
    override func viewDidLoad() {
      super.viewDidLoad()
      self.clearsSelectionOnViewWillAppear = false
      if let viewModel = viewModel {
        tableViewHelper = MovieNightTableviewBindingHelper(tableView: self.tableView, sourceSignal: viewModel.cellModels.producer)
      }
    }
  
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      if !autoSearchStarted {
        autoSearchStarted = true
        if let viewModel = viewModel {
          viewModel.getGenres()
        }
      }
    }
  
  override func viewWillDisappear(_ animated: Bool) {
    autoSearchStarted = false
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    // MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 1
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return viewModel?.cellModels.value.count ?? 0
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//      let cell = tableView.dequeueReusableCell(withIdentifier: "preferenceCell", for: indexPath) as! PreferenceCell
//      cell.viewModel = viewModel?.cellModels.value[indexPath.row] ?? nil
//      return cell
//    }
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var count = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].moviePreference.genreChoices.count
    guard count < 5 else {
      self.navigationController?.tabBarItem.badgeColor = UIColor.red
      return
    }
    let preference = viewModel?.genreCollection.value[indexPath.row]
    if  movieWatcherViewModel.add(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
      count += 1
    }
    self.navigationController?.tabBarItem.badgeColor = count == 5 ?  UIColor.green : UIColor.red
    self.navigationController?.tabBarItem.badgeValue = "\(count)"
  }
  
  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
    return movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].moviePreference.genreChoices.count < 5
  }
}
