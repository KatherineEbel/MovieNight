//
//  MovieNightTableViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift
import Argo
import Result

public protocol SearchResultsTableViewModeling {
  var currentPage: Int { get set }
  var cellModels: Property<[SearchResultsTableViewCellModeling]> { get }
  func startSearch()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  public var cellModels: Property<[SearchResultsTableViewCellModeling]> {
    return Property(_cellModels)
  }
  
  private let _cellModels = MutableProperty<[SearchResultsTableViewCellModeling]>([])
  private let client: TMDBClient
  public var currentPage: Int
  
  public init(client: TMDBClient) {
    currentPage = 1
    self.client = client
  }

  public func startSearch() {
    client.searchPopularPeople(pageNumber: currentPage)
     .map { response in
        let cellModels = response.results.flatMap { SearchResultsTableViewCellModel(actor: $0) as SearchResultsTableViewCellModeling }
        return cellModels
      }
      .observe(on: UIScheduler())
      .on { cellModels in
        self._cellModels.value = cellModels
      }
      .start()
  }
}
