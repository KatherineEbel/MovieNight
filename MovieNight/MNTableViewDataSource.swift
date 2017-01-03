//
//  MovieNightTableviewBindingHelper.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/20/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
// modified from http://blog.scottlogic.com/2014/05/11/reactivecocoa-tableview-binding.html

import UIKit
import ReactiveSwift
import Result
import Argo

//protocol MNightTableviewDataSource: UITableViewDataSource {
//  
//}

class MNightTableviewDataSource: NSObject, UITableViewDataSource {
  //private var data: [SearchResultsTableViewCellModeling] = []
  private var _cellModels = MutableProperty<[SearchResultsTableViewCellModeling]>([])
  private var network: MovieNightNetworkProtocol!
  var tableView: UITableView
  let sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>!
  var nibName: String
  public var cellModels: Property<[SearchResultsTableViewCellModeling]> {
    return Property(_cellModels)
  }
  
  init(tableView: UITableView, sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>, nibName: String) {
    self.tableView = tableView
    self.sourceSignal = sourceSignal
    self.nibName = nibName
    super.init()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cellModels.value.count
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch getIdentifier() {
      case "movieResultCell":
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieResultCell", for: indexPath) as! MovieResultCell
        cell.viewModel = cellModels.value[indexPath.row]
        return cell
      default:
        let cell = tableView.dequeueReusableCell(withIdentifier: "preferenceCell", for: indexPath) as! PreferenceCell
        cell.viewModel = cellModels.value[indexPath.row]
        return cell
    }
  }
  
  func getIdentifier() -> String {
    switch self.nibName {
      case "PreferenceCell": return "preferenceCell"
      case "MovieResultCell": return "movieResultCell"
      default: break
    }
    return "Unknown"
  }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    refreshControl.beginRefreshing()
    refreshControl.endRefreshing()
  }
  
  func configureTableView() {
    tableView.dataSource = self
    if getIdentifier() == "preferenceCell" {
      tableView.rowHeight = 60
    } else {
//      tableView.rowHeight = UITableViewAutomaticDimension
//      tableView.estimatedRowHeight = 200
      tableView.rowHeight = 470
    }
    self.tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: getIdentifier())
    sourceSignal.producer.on { value in
      let models = value.flatMap { SearchResultsTableViewCellModel(model: $0 ) as SearchResultsTableViewCellModeling }
      self._cellModels.value = models
      self.tableView.reloadData()
    }.observe(on: UIScheduler())
    .start()
  }
}
