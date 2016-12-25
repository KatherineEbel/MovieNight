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
  private var data: [SearchResultsTableViewCellModeling] = []
  private var cellModels = MutableProperty<[SearchResultsTableViewCellModel]>([])
  private var network: MovieNightNetworkProtocol!
  var tableView: UITableView
  let sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>!
  var nibName: String
  
  init(tableView: UITableView, sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>, nibName: String) {
    self.tableView = tableView
    self.sourceSignal = sourceSignal
    self.nibName = nibName
    super.init()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return data.count
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch getIdentifier() {
      case "movieResultCell":
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieResultCell", for: indexPath) as! MovieResultCell
        cell.viewModel = data[indexPath.row]
        return cell
      default:
        let cell = tableView.dequeueReusableCell(withIdentifier: "preferenceCell", for: indexPath) as! PreferenceCell
        cell.viewModel = data[indexPath.row]
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
  
  func configureTableView() {
    self.tableView.dataSource = self
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 60
    self.tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: getIdentifier())
    sourceSignal.producer.on { value in
      let cellModels = value.flatMap { SearchResultsTableViewCellModel(title: $0.description, imagePath: $0.thumbnailPath) as SearchResultsTableViewCellModeling }
      self.data = cellModels
      self.tableView.reloadData()
    }.observe(on: UIScheduler())
    .start()
  }
}
