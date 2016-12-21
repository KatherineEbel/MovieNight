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

//protocol MovieNightTableviewBindingProtocol: UITableViewDataSource {
//  
//}

class MNightTableviewDataSource: NSObject, UITableViewDataSource {
  var data: [SearchResultsTableViewCellModeling] = []
  var tableView: UITableView
  let sourceSignal: SignalProducer<[SearchResultsTableViewCellModeling], NoError>!
  var nibName: String
  
  private init(tableView: UITableView, sourceSignal: SignalProducer<[SearchResultsTableViewCellModeling], NoError>, nibName: String) {
    self.tableView = tableView
    self.sourceSignal = sourceSignal
    self.nibName = nibName
    super.init()
  }
  
  convenience init(tableView: UITableView, sourceSignal: SignalProducer<[SearchResultsTableViewCellModeling], NoError>) {
    self.init(tableView: tableView, sourceSignal: sourceSignal, nibName: "PreferenceCell")
    tableView.dataSource = self
    tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: "preferenceCell")
    sourceSignal.producer.on { value in
      self.data = value
      self.tableView.reloadData()
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
