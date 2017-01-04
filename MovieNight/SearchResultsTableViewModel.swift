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
  var resultsModelData: Property<[TMDBEntity.Media]> { get }
  var resultPageCountTracker: (page: Int, tracker: NSAttributedString) { get }
  var peoplePageCountTracker: (page: Int, tracker: NSAttributedString) { get }
  var errorMessage: Property<String?> { get }
  var isSearching: Property<Bool> { get }
  func getResultPage(discover: MovieDiscoverProtocol)
  func getNextPage()
  func getGenres()
  func getRatings()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  private let _genreModelData = MutableProperty<[TMDBEntity.MovieGenre]>([])
  private let _actorModelData = MutableProperty<[TMDBEntity.Actor]>([])
  private let _ratingModelData = MutableProperty<[TMDBEntity.Rating]>([])
  private let _resultsModelData = MutableProperty<[TMDBEntity.Media]>([])
  private let _errorMessage = MutableProperty<String?>(nil)
  private let _isSearching = MutableProperty<Bool>(false)
  private let client: TMDBClientPrototcol
  private var currentPeoplePage: Int = 1
  private var resultPageCount = 0
  private var peoplePageCount = 0
  private var currentResultPage = 1
  
  public var peoplePageCountTracker: (page: Int, tracker: NSAttributedString) {
    let result = "\(currentPeoplePage - 1) out of \(peoplePageCount)"
    return (peoplePageCount, NSAttributedString(string: result, attributes: nil))
  }
  public var resultPageCountTracker: (page: Int, tracker: NSAttributedString) {
    return (resultPageCount, NSAttributedString(string: "\(currentResultPage - 1) out of \(resultPageCount)", attributes: nil))
  }
  
  public var genreModelData: Property<[TMDBEntity.MovieGenre]> { return Property(_genreModelData) }
  
  public var actorModelData: Property<[TMDBEntity.Actor]> { return Property(_actorModelData) }
  
  public var ratingModelData: Property<[TMDBEntity.Rating]> {
    return Property(_ratingModelData)
  }
  
  public var resultsModelData: Property<[TMDBEntity.Media]> {
    return Property(_resultsModelData)
  }
  
  public var errorMessage: Property<String?> {
    return Property(_errorMessage)
  }
  
  public var isSearching: Property<Bool> {
    return Property(_isSearching)
  }
  
  public init(client: TMDBClientPrototcol) {
    self.client = client
  }
  
  public func getResultPage(discover: MovieDiscoverProtocol) {
    if currentResultPage > 1 {
      guard resultPageCount > currentResultPage else {
        return
      }
    }
    client.searchMovieDiscover(page: currentResultPage, discover: discover)
      .map { $0 }
      .observe(on: UIScheduler())
      .on(event: { event in
        switch event {
          case .value(let value):
            self._resultsModelData.value.append(contentsOf: value.results)
            self._isSearching.value = true
            self.resultPageCount = value.totalPages
            self.currentResultPage += 1
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          case .completed, .interrupted: self._isSearching.value = false
        }
      }).start()
  }

  public func getNextPage() {
    if currentPeoplePage > 1 {
      guard currentPeoplePage < peoplePageCount else {
        return
      }
    }
    client.searchPopularPeople(pageNumber: currentPeoplePage)
     .map { $0 }
    .observe(on: UIScheduler())
    .on(event: { event in
      switch event {
        case .value(let value):
          self._actorModelData.value.append(contentsOf: value.results)
          self._isSearching.value = true
          self.peoplePageCount = value.totalPages
          self.currentPeoplePage += 1
        case .failed(let error): self._errorMessage.value = error.localizedDescription
        case .completed, .interrupted: self._isSearching.value = false
      }
    }).start()
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
