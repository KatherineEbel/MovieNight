//
//  GenrePickerController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit

class GenrePickerController: UITableViewController {

  private var autoSearchStarted = false
  public var movieWatcherViewModel: WatcherViewModelProtocol!
  public var viewModel: SearchResultsTableViewModeling? {
    didSet {
      if let viewModel = viewModel {
        viewModel.cellModels.producer
          .on { _ in
            self.tableView.reloadData()
          }
          .start()
      }
    }
  }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
      self.tableView.register(UINib(nibName: "PreferenceCell", bundle: nil), forCellReuseIdentifier: "preferenceCell")
    }
  
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      if !autoSearchStarted {
        autoSearchStarted = true
        viewModel?.getGenres()
      }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return viewModel?.cellModels.value.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "preferenceCell", for: indexPath) as! PreferenceCell
      cell.viewModel = viewModel?.cellModels.value[indexPath.row] ?? nil
      return cell
    }
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].moviePreference.genreChoices.count < 5 else {
      return
    }
    let preference = viewModel?.genreCollection.value[indexPath.row]
    _ = movieWatcherViewModel.add(preference: preference!, watcherAtIndex: movieWatcherViewModel.activeWatcher)
    print(movieWatcherViewModel.watchers.value?[movieWatcherViewModel.activeWatcher].moviePreference.genreChoices ?? "No values")
  }
  
  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
    return movieWatcherViewModel.watchers.value![movieWatcherViewModel.activeWatcher].moviePreference.genreChoices.count < 5
  }
}
