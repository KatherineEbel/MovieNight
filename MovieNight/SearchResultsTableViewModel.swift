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
  var cellModels: Property<[SearchResultsTableViewCellModeling]> { get }
  func getNextPage()
  func getGenres()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  public var cellModels: Property<[SearchResultsTableViewCellModeling]> {
    return Property(_cellModels)
  }
  
  private let _cellModels = MutableProperty<[SearchResultsTableViewCellModeling]>([])
  private let client: TMDBSearching
  private var nextPage: Int
  private let maxPages = 5
  
  public init(client: TMDBSearching) {
    nextPage = 1
    self.client = client
  }

  public func getNextPage() {
    client.searchPopularPeople(pageNumber: nextPage)
     .map { response in
        let cellModels = response.results.flatMap { SearchResultsTableViewCellModel(title: $0.name) as SearchResultsTableViewCellModeling }
        return cellModels
      }
    .observe(on: UIScheduler())
    .on { cellModels in
      self._cellModels.value = cellModels
    }
    .start()
    nextPage += 1
  }
  
  public func getGenres() {
    client.searchMovieGenres()
      .map { response in
        let cellModels = response.genres.flatMap { SearchResultsTableViewCellModel(title: $0.name) as SearchResultsTableViewCellModeling }
        return cellModels
      }
    .observe(on: UIScheduler())
    .on { cellModels in
      self._cellModels.value = cellModels
    }
    .start()
  }
}
