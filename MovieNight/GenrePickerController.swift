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

//class GenrePickerController: UITableViewController, MovieNightSearchControllerProtocol {
//
//  var entityType: TMDBEntity {
//    return _entityType
//  }
//  private let _entityType = TMDBEntity.movieGenre
//  private var autoSearchStarted = false
//  public var movieWatcherViewModel: WatcherViewModelProtocol!
//  private var tableViewDataSource: MNightTableviewDataSource!
//  public var viewModel: SearchResultsTableViewModeling?
//  private var watcherSignal: Signal<[MovieWatcherProtocol]?, NoError>!
//  private var activeWatcherSignal: Signal<MovieWatcherProtocol, NoError> {
//    return movieWatcherViewModel.activeWatcher.signal
//  }
//    
//    override func viewDidLoad() {
//      super.viewDidLoad()
//      self.clearsSelectionOnViewWillAppear = false
//      if let viewModel = viewModel {
//        let genreCellModelProducer = viewModel.genreModelData.producer.map { genres in
//          return genres.flatMap { $0 as TMDBEntityProtocol }
//        }
//        
//        viewModel.errorMessage.signal.take(last: 1).observeValues { message in
//          if let message = message {
//            DispatchQueue.main.async {
//              self.alertForError(message: message)
//              self.refreshControl?.endRefreshing()
//            }
//          }
//        }
//        tableViewDataSource = MNightTableviewDataSource(tableView: self.tableView, sourceSignal: genreCellModelProducer, nibName: "PreferenceCell")
//        tableViewDataSource.configureTableView()
//        watcherSignal = movieWatcherViewModel.watchers.signal
//        
//        let activeWatcherReadySignal = movieWatcherViewModel.activeWatcher.value.isReady.signal
//        configureNavBar()
//        configureTabBar()
//        observeForTableViewReload()
//      }
//    }
//  
//    override func viewWillAppear(_ animated: Bool) {
//      super.viewWillAppear(animated)
//      if !autoSearchStarted {
//        autoSearchStarted = true
//        if let viewModel = viewModel {
//          viewModel.getGenres()
//        }
//      }
//    }
//  
//  func observeForTableViewReload() {
//    _ = tableView.reactive.trigger(for: #selector(tableView.reloadData)).observeValues {
//      let activeWatcher = self.movieWatcherViewModel.activeWatcher
//      let currentSelections = self.viewModel?.modelData.value[self.entityType].combineLatest(with: activeWatcher)
//      let allGenres = currentSelections?.value.0
//        if let watcherChoices = currentSelections?.value.1.genreChoices {
//          let indexes = allGenres?.enumerated().reduce(Set<IndexPath>()) { (result, nextResult: (idx: Int, genre: TMDBEntity.MovieGenre)) in
//            var copy = result
//            if watcherChoices.contains(where: { $0.name == nextResult.genre.name }) {
//              copy.insert(IndexPath(row: nextResult.idx, section: 0))
//            }
//            return copy
//          }
//          if let indexes = indexes {
//            _ = indexes.map { row in
//              self.tableView.selectRow(at: row, animated: true, scrollPosition: .none)
//              self.tableView(self.tableView, didSelectRowAt: row)
//            }
//          }
//        }
//    }
//  }
//  
//  func alertForError(message: String) {
//    let alertController = UIAlertController(title: "Sorry! Something went wrong.", message: message, preferredStyle: .alert)
//    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//    alertController.addAction(okAction)
//    present(alertController, animated: true, completion: nil)
//  }
//  
//  func configureNavBar() {
//    // FIXME: Implement navbar actions
//    if let rightNavBarItem = navigationItem.rightBarButtonItem?.reactive {
//      rightNavBarItem.isEnabled <~ movieWatcherViewModel.activeWatcher.map { $0.isReady }.flatten(.merge)
//    }
//  }
//  
//  func configureTabBar() {
//    let status = movieWatcherViewModel.getStatusForActiveWatcherPreference(preferenceType: self.entityType)
//    self.navigationController?.tabBarItem.badgeColor = movieWatcherViewModel.getStatusForActiveWatcherPreference(preferenceType: self.entityType)
//    self.navigationController?.tabBarItem.badgeValue = mov
//  }
//  
//  override func viewWillDisappear(_ animated: Bool) {
//    //autoSearchStarted = false
//  }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//
//  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    let count = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcherIndex].genreChoices.count
//    guard count < 5 else {
//      return
//    }
//    let preference = viewModel?.genreModelData.value[indexPath.row]
//    if  movieWatcherViewModel.add(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcherIndex) {
//      
//    }
//  }
//  
//  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//    let preference = viewModel!.genreModelData.value[indexPath.row]
//    if movieWatcherViewModel.remove(preference: preference, watcherAtIndex: movieWatcherViewModel.activeWatcherIndex) {
//      
//    }
//  }
//  
//  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
//    
//    let notSet = movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcherIndex].genreChoices.count < 5
//    let isactiveWatcherChoice = movieWatcherViewModel.watchers.value?[movieWatcherViewModel.activeWatcherIndex].genreChoices.contains(where: { genre in
//      genre.name == viewModel?.genreModelData.value[indexPath.row].name
//    })
//    return notSet || isactiveWatcherChoice!
//  }
//  
//  @IBAction func savePreferences(_ sender: UIBarButtonItem) {
//    if movieWatcherViewModel.watcher1Ready() || movieWatcherViewModel.watcher2Ready() {
//      self.navigationController?.tabBarController?.dismiss(animated: true) {
//        self.movieWatcherViewModel.updateActiveWatcher()
//      }
//    } else {
//      print("Not finished yet!")
//    }
//  }
//  @IBAction func goHome(_ sender: UIBarButtonItem) {
//    dismiss(animated: true, completion: nil)
//  }
//  
//  
//}
