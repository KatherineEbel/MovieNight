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
  private var _cellModels = MutableProperty<[SearchResultsTableViewCellModeling]>([])
  private var network: MovieNightNetworkProtocol!
  weak var tableView: UITableView?
  let sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>!
  var nibName: String
  public var cellModels: Property<[SearchResultsTableViewCellModeling]> {
    return Property(_cellModels)
  }
  
  var cellIdentifier: String {
    switch self.nibName {
      case "PreferenceCell": return "preferenceCell"
      case "MovieResultCell": return "movieResultCell"
      default: break
    }
    return "Unknown"
  }
  
  init(tableView: UITableView, sourceSignal: SignalProducer<[TMDBEntityProtocol], NoError>, nibName: String) {
    self.tableView = tableView
    self.sourceSignal = sourceSignal
    self.nibName = nibName
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cellModels.value.count
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch cellIdentifier {
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
  
  func dataToCellModels(data: [TMDBEntityProtocol]) -> [SearchResultsTableViewCellModeling] {
    return data.flatMap { SearchResultsTableViewCellModel(model: $0)  as SearchResultsTableViewCellModeling }
  }
  
  
  func configureTableView() {
    guard let tableView = tableView else { return }
    tableView.dataSource = self
    if cellIdentifier == "preferenceCell" {
      tableView.rowHeight = 60
    } else {
      // FIXME: remove after final tableview decided for movie result cells
//      tableView.rowHeight = UITableViewAutomaticDimension
//      tableView.estimatedRowHeight = 200
      tableView.rowHeight = 470
    }
    tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: cellIdentifier)
    sourceSignal.producer.take(during: self.reactive.lifetime).on { [weak self] value in
      guard let strongSelf = self else { return }
      strongSelf._cellModels.value = strongSelf.dataToCellModels(data: value)
      strongSelf.tableView!.reloadData()
    }.observe(on: kUIScheduler)
    .start()
  }
  
  deinit {
    _cellModels.value = []
    print("Data source deinit")
  }
}
