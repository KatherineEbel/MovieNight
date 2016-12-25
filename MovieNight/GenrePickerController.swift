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
        tableViewDataSource = MNightTableviewDataSource(tableView: self.tableView, sourceSignal: genreCellModelProducer, nibName: "PreferenceCell")
        tableViewDataSource.configureTableView()
        watcherSignal = movieWatcherViewModel.watchers.signal
        
        let activeWatcherReadySignal = watcherSignal.map { signal in
          return signal![self.movieWatcherViewModel.activeWatcher].isReady
        }
        configureNavBarWithSignal(watcherReady: activeWatcherReadySignal)
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
  
  func configureNavBarWithSignal(watcherReady: Signal<Bool, NoError>) {
    // FIXME: Implement navbar actions
    watcherReady.observeValues { isReady in
      self.navigationItem.rightBarButtonItem?.isEnabled = isReady
    }
  }
  
  func configureTabBar() {
    watcherSignal.observeValues { watchers in
      if let watchers = watchers {
        let activeWatcher = watchers[self.movieWatcherViewModel.activeWatcher]
        let count = activeWatcher.genreChoices.count
        let readyColor =  UIColor(red: 138/255.0, green: 199/255.0, blue: 223/255.0, alpha: 1.0)
        let notReadyColor = UIColor(red: 255/255.0, green: 142/255.0, blue: 138/255.0, alpha: 1.0)
        self.navigationController?.tabBarItem.badgeColor = count >= 1 && count <= 5 ? readyColor : notReadyColor
        self.navigationController?.tabBarItem.badgeValue = "\(count)/5"
        self.editButtonItem.reactive.isEnabled <~ MutableProperty(activeWatcher.isReady)
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
  
  @IBAction func savePreferences(_ sender: UIBarButtonItem) {
    if movieWatcherViewModel.watcher1Ready() || movieWatcherViewModel.watcher2Ready() {
      self.navigationController?.tabBarController?.dismiss(animated: true) {
        self.movieWatcherViewModel.updateActiveWatcher()
      }
    } else {
      print("Not finished yet!")
    }
  }
  
}
