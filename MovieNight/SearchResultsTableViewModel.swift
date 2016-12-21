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
  var genreCollection: MutableProperty<[TMDBEntity.MovieGenre]> { get }
  var actorCollection: MutableProperty<[TMDBEntity.Actor]> { get }
  var ratingCollection: MutableProperty<[TMDBEntity.Rating]> { get }
  func getNextPage()
  func getGenres()
  func getRatings()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  private let _cellModels = MutableProperty<[SearchResultsTableViewCellModeling]>([])
  public var cellModels: Property<[SearchResultsTableViewCellModeling]> {
    return Property(_cellModels)
  }
  public var genreCollection = MutableProperty<[TMDBEntity.MovieGenre]>([]) 
  public var actorCollection = MutableProperty<[TMDBEntity.Actor]>([])
  public var ratingCollection = MutableProperty<[TMDBEntity.Rating]>([])
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
        return response.results
      }
    .observe(on: UIScheduler())
    .on { actors in
      self.actorCollection.value = actors
      self._cellModels.value = actors.flatMap { SearchResultsTableViewCellModel(title: $0.name) as SearchResultsTableViewCellModeling }
    }
    .start()
    nextPage += 1
  }
  
  public func getGenres() {
    client.searchMovieGenres()
      .map { response in
        return response.genres
      }
      .observe(on: UIScheduler())
      .on { genres in
        self.genreCollection.value = genres
        self._cellModels.value = genres.flatMap {
          SearchResultsTableViewCellModel(title: $0.name) as SearchResultsTableViewCellModeling
        }
      }
    .start()
  }
  
  public func getRatings() {
    client.searchUSRatings()
      .map { response in
          return response
      }
      .observe(on: UIScheduler())
      .on { ratings in
        self.ratingCollection.value = ratings.certifications
        self._cellModels.value = ratings.certifications.flatMap {
          print($0)
          return SearchResultsTableViewCellModel(title: $0.certification) as SearchResultsTableViewCellModeling
        }
      }
      .start()
  }
}
