//
//  GenrePickerController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class GenrePickerController: UITableViewController {

  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  private var tableViewDataSource: MNightTableviewDataSource!
  public var viewModel: SearchResultsTableViewModeling?
  private var watcherSignal: Signal<[MovieWatcherProtocol]?, NoError>!
  
    override func viewDidLoad() {
      super.viewDidLoad()
      self.clearsSelectionOnViewWillAppear = false
      if let viewModel = viewModel {
        let genreCellModelProducer = viewModel.genreModelData.producer.map { genres in
          return genres.flatMap { $0 as TMDBEntityProtocol }
          
        }
        tableViewDataSource = MNightTableviewDataSource(tableView: self.tableView, sourceSignal: genreCellModelProducer)
        watcherSignal = movieWatcherViewModel.watchers.signal
        configureTabBar()
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
  
  func configureTabBar() {
    watcherSignal.observeValues { watchers in
      if let watchers = watchers {
        let activeWatcher = watchers[self.movieWatcherViewModel.activeWatcher]
        let count = activeWatcher.genreChoices.count
        self.navigationController?.tabBarItem.badgeColor = count >= 1 && count <= 5 ? UIColor.green : UIColor.red
        self.navigationController?.tabBarItem.badgeValue = "\(count)/5"
      }
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    //autoSearchStarted = false
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let count = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].genreChoices.count
    guard count < 5 else {
      return
    }
    let preference = viewModel?.genreModelData.value[indexPath.row]
    if  movieWatcherViewModel.add(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
      print("Success")
//      count += 1
    }
  }
  
  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let preference = viewModel!.genreModelData.value[indexPath.row]
    if movieWatcherViewModel.remove(preference: preference, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
      print("Removed")
    }
  }
  
  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
    
    let notSet = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].genreChoices.count < 5
    let isactiveWatcherChoice = movieWatcherViewModel.watchers.value?[movieWatcherViewModel.activeWatcher].genreChoices.contains(where: { genre in
      genre.name == viewModel?.genreModelData.value[indexPath.row].name
    })
    return notSet || isactiveWatcherChoice!
  }
}
