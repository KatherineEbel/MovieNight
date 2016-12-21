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
  private var tableViewDataSource: MNightTableviewDataSource!
  public var viewModel: SearchResultsTableViewModeling?
  
    override func viewDidLoad() {
      super.viewDidLoad()
      self.clearsSelectionOnViewWillAppear = false
      if let viewModel = viewModel {
        tableViewDataSource = MNightTableviewDataSource(tableView: self.tableView, sourceSignal: viewModel.cellModels.producer)
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
    let notSet = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].moviePreference.genreChoices.count < 5
    let isactiveWatcherChoice = movieWatcherViewModel.watchers.value?[movieWatcherViewModel.activeWatcher].moviePreference.genreChoices.contains(where: { genre in
      genre.name == viewModel?.genreCollection.value[indexPath.row].name
    })
    return notSet || isactiveWatcherChoice!
  }
}
