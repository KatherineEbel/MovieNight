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
  var data: [SearchResultsTableViewCellModeling] = []
  var tableView: UITableView
  let sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>!
  var nibName: String
  
  private init(tableView: UITableView, sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>, nibName: String) {
    self.tableView = tableView
    self.sourceSignal = sourceSignal
    self.nibName = nibName
    super.init()
  }
  
  convenience init(tableView: UITableView, sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>) {
    self.init(tableView: tableView, sourceSignal: sourceSignal, nibName: "PreferenceCell")
    self.tableView.dataSource = self
    self.tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: "preferenceCell")
    sourceSignal.producer.on { value in
      let cellModels = value.flatMap { SearchResultsTableViewCellModel(title: $0.description) as SearchResultsTableViewCellModeling }
      self.data = cellModels
      tableView.reloadData()
    }.observe(on: UIScheduler())
    .start()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return data.count
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "preferenceCell", for: indexPath) as! PreferenceCell
    cell.viewModel = data[indexPath.row]
    return cell
  }
  
}
