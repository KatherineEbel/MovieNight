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
  var genreModelData: Property<[TMDBEntity.MovieGenre]> { get }
  var actorModelData: Property<[TMDBEntity.Actor]> { get }
  var ratingModelData: Property<[TMDBEntity.Rating]> { get }
  var resultsModelData: Property<[TMDBEntity.Movie]> { get }
  func getResults(actorIDs: Set<Int>, genreIDs: Set<Int>, maxRating: String)
  func getNextPage()
  func getGenres()
  func getRatings()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  private let _genreModelData = MutableProperty<[TMDBEntity.MovieGenre]>([])
  private let _actorModelData = MutableProperty<[TMDBEntity.Actor]>([])
  private let _ratingModelData = MutableProperty<[TMDBEntity.Rating]>([])
  private let _resultsModelData = MutableProperty<[TMDBEntity.Movie]>([])
  private let client: TMDBSearching
  private var nextPage: Int
  private let maxPages = 5
  private var resultPage = 1
  
  public var genreModelData: Property<[TMDBEntity.MovieGenre]> {
    return Property(_genreModelData)
  }
  
  public var actorModelData: Property<[TMDBEntity.Actor]> {
    return Property(_actorModelData)
  }
  
  public var ratingModelData: Property<[TMDBEntity.Rating]> {
    return Property(_ratingModelData)
  }
  
  public var resultsModelData: Property<[TMDBEntity.Movie]> {
    return Property(_resultsModelData)
  }
  public init(client: TMDBSearching) {
    nextPage = 1
    self.client = client
  }
  
  public func getResults(actorIDs: Set<Int>, genreIDs: Set<Int>, maxRating: String) {
    client.searchMovieDiscover(page: resultPage, actorIDs: actorIDs, genreIDs: genreIDs, rating: maxRating)
      .map { response in
        return response.results
      }
      .observe(on: UIScheduler())
      .on { results in
        self._resultsModelData.value.append(contentsOf: results)
      }.start()
  }

  public func getNextPage() {
    client.searchPopularPeople(pageNumber: nextPage)
     .map { response in
        return response.results
      }
    .observe(on: UIScheduler())
    .on { actors in
      self._actorModelData.value.append(contentsOf: actors)
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
        self._genreModelData.value = genres
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
        self._ratingModelData.value = ratings.certifications
      }
      .start()
  }
}
