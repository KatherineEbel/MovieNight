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

public protocol SearchTableViewModeling {
  var currentPage: Int { get set }
  var cellModels: Property<[SearchTableViewCellModeling]> { get }
  func startSearch()
}

public final class MovieNightTableViewModel: SearchTableViewModeling {
  public var cellModels: Property<[SearchTableViewCellModeling]> {
    return Property(_cellModels)
  }
  
  private let _cellModels = MutableProperty<[SearchTableViewCellModeling]>([])
  private let tmdbSearchController: TMDBSearchController
  public var currentPage: Int
  
  public init(searchController: TMDBSearchController) {
    currentPage = 1
    tmdbSearchController = searchController
  }

  public func startSearch() {
    tmdbSearchController.searchPopularPeople(pageNumber: currentPage)
     .map { response in
        let cellModels = response.results.flatMap { SearchTableViewCellModel(actor: $0) as SearchTableViewCellModeling }
        return cellModels
      }
      .observe(on: UIScheduler())
      .on { cellModels in
        self._cellModels.value = cellModels
      }
      .start()
  }
}
