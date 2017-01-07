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
  var modelData: Property<[TMDBEntity: [TMDBEntityProtocol]]> { get }
  var resultPageCountTracker: (page: Int, tracker: NSAttributedString) { get }
  var peoplePageCountTracker: (page: Int, tracker: NSAttributedString) { get }
  var errorMessage: Property<String?> { get }
  func getNextMovieResultPage(discover: MovieDiscoverProtocol)
  func getNextPopularPeoplePage()
  func getGenres()
  func getRatings()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  private let _modelData = MutableProperty<[TMDBEntity: [TMDBEntityProtocol]]>([.actor: [], .movieGenre: [], .rating: [], .media: []])
  private let _errorMessage = MutableProperty<String?>(nil)
  private let client: TMDBClientPrototcol
  private var currentPeopleResultPage: Int = 1
  private var movieResultPageCount = 0
  private var peoplePageCount = 0
  private var currentMovieResultPage = 1
  
  public var modelData: Property<[TMDBEntity : [TMDBEntityProtocol]]> {
    return Property(_modelData)
  }
  
  public var peoplePageCountTracker: (page: Int, tracker: NSAttributedString) {
    let result = "\(currentPeopleResultPage) out of \(peoplePageCount) result pages"
    return (peoplePageCount, NSAttributedString(string: result, attributes: nil))
  }
  public var resultPageCountTracker: (page: Int, tracker: NSAttributedString) {
    return (movieResultPageCount, NSAttributedString(string: "\(currentMovieResultPage) out of \(movieResultPageCount) result pages", attributes: nil))
  }
  
  public var errorMessage: Property<String?> {
    return Property(_errorMessage)
  }
  
  public init(client: TMDBClientPrototcol) {
    self.client = client
  }
  
  public func getNextMovieResultPage(discover: MovieDiscoverProtocol) {
    if currentMovieResultPage > 1 {
      guard movieResultPageCount > currentMovieResultPage else {
        return
      }
    }
    client.searchMovieDiscover(page: currentMovieResultPage, discover: discover)
      .map { $0 }
      .observe(on: UIScheduler())
      .on(event: { event in
        switch event {
          case .value(let value):
            self._modelData.value[.media]?.append(contentsOf: value.results as [TMDBEntityProtocol])
            self.movieResultPageCount = value.totalPages
            self.currentMovieResultPage += 1
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }

  public func getNextPopularPeoplePage() {
    if currentPeopleResultPage > 1 {
      guard currentPeopleResultPage < peoplePageCount else {
        return
      }
    }
    client.searchPopularPeople(pageNumber: currentPeopleResultPage)
     .map { $0 }
    .observe(on: UIScheduler())
    .on(event: { event in
      switch event {
        case .value(let value):
          self._modelData.value[.actor]?.append(contentsOf: value.results as [TMDBEntityProtocol])
          self.peoplePageCount = value.totalPages
          self.currentPeopleResultPage += 1
        case .failed(let error): self._errorMessage.value = error.localizedDescription
        default: break
      }
    }).start()
  }
  
  public func getGenres() {
    client.searchMovieGenres()
      .map { response in
        return response.genres
      }
      .observe(on: UIScheduler())
      .on(event: { event in
        switch event {
          case .value(let value):
            self._modelData.value[.movieGenre] = value as [TMDBEntityProtocol]
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }
  
  public func getRatings() {
    client.searchUSRatings()
      .map { response in
          return response
      }
      .observe(on: UIScheduler())
      .on(event: { event in
        switch event {
          case .value(let value):
            self._modelData.value[.rating] = value.certifications as [TMDBEntityProtocol]
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }
}
