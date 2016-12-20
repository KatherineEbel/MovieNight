//
//  RatingPickerController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit

class RatingPickerController: UITableViewController {

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
    self.tableView.register(UINib(nibName: "PreferenceCell", bundle: nil), forCellReuseIdentifier: "preferenceCell")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !autoSearchStarted {
      autoSearchStarted = true
      viewModel?.getRatings()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    autoSearchStarted = false
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return viewModel?.cellModels.value.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "preferenceCell", for: indexPath) as! PreferenceCell
      cell.viewModel = viewModel?.cellModels.value[indexPath.row] ?? nil
      return cell
    }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let preference = viewModel?.ratingCollection.value[indexPath.row] {
      // FIXME: implement use of returned bool value to add badge to tabbar.
      if movieWatcherViewModel.add(preference: preference, watcherAtIndex: movieWatcherViewModel.activeWatcher) {
        self.navigationController?.tabBarItem.badgeColor = UIColor.green
        self.navigationController?.tabBarItem.badgeValue = "\u{2705}"
      } else {
        print("Couldn't update")
      }
    }
  }
}
