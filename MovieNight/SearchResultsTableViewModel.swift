//
//  MovieNightTableViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation
import ReactiveSwift
import Argo
import Result

public protocol SearchResultsTableViewModeling {
  var genreModelData: Property<[TMDBEntity.MovieGenre]> { get }
  var actorModelData: Property<[TMDBEntity.Actor]> { get }
  var ratingModelData: Property<[TMDBEntity.Rating]> { get }
  var resultsModelData: Property<[TMDBEntity.Movie]> { get }
  var resultPageCountTracker: (page: Int, tracker: NSAttributedString) { get }
  var peoplePageCountTracker: (page: Int, tracker: NSAttributedString) { get }
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
  private var nextPage: Int = 1
  private var resultPageCount = 0
  private var peoplePageCount = 0
  private var resultPage = 1
  
  public var peoplePageCountTracker: (page: Int, tracker: NSAttributedString) {
    let result = "\(nextPage - 1) out of \(peoplePageCount)"
    return (peoplePageCount, NSAttributedString(string: result, attributes: nil))
  }
  public var resultPageCountTracker: (page: Int, tracker: NSAttributedString) {
    return (resultPageCount, NSAttributedString(string: "\(resultPage - 1) out of \(resultPageCount)", attributes: nil))
  }
  
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
    self.client = client
  }
  
  public func getResults(actorIDs: Set<Int>, genreIDs: Set<Int>, maxRating: String) {
    client.searchMovieDiscover(page: resultPage, actorIDs: actorIDs, genreIDs: genreIDs, rating: maxRating)
      .map { $0 }
      .observe(on: UIScheduler())
      .on { response in
        self._resultsModelData.value.append(contentsOf: response.results)
        self.resultPageCount = response.totalPages
        print(response.totalPages)
      }.start()
    resultPage += 1
  }

  public func getNextPage() {
    client.searchPopularPeople(pageNumber: nextPage)
     .map { $0 }
    .observe(on: UIScheduler())
    .on { response in
      self._actorModelData.value.append(contentsOf: response.results)
      print(response.totalPages)
      self.peoplePageCount = response.totalPages
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
