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
  var currentPeopleResultPage: Property<Int> { get }
  var currentMovieResultPage: Property<Int> { get }
  var errorMessage: Property<String?> { get }
  func getNextMovieResultPage(page: Int, discover: MovieDiscoverProtocol)
  func getPopularPeoplePage(pageNumber: Int)
  func peoplePageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)>
  func resultPageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)>
  func getGenres()
  func getRatings()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  private let _modelData = MutableProperty<[TMDBEntity: [TMDBEntityProtocol]]>([.actor: [], .movieGenre: [], .rating: [], .media: []])
  private let _errorMessage = MutableProperty<String?>(nil)
  private let client: TMDBClientPrototcol
  private var _currentPeopleResultPage = MutableProperty(0)
  private var _currentMovieResultPage = MutableProperty(1)
  private var movieResultPageCount = 0
  private var peoplePageCount = 0
  
  public var currentPeopleResultPage: Property<Int> {
    return Property(_currentPeopleResultPage)
  }
  public var currentMovieResultPage: Property<Int> {
    return Property(_currentMovieResultPage)
  }
  
  public var modelData: Property<[TMDBEntity : [TMDBEntityProtocol]]> {
    return Property(_modelData)
  }
  
  
  public var errorMessage: Property<String?> {
    return Property(_errorMessage)
  }
  
  public init(client: TMDBClientPrototcol) {
    print("Initializing tableviewModel")
    self.client = client
  }
  
  public func peoplePageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)> {
    return currentPeopleResultPage.map { pageNumber in
      let result = NSAttributedString(string: "Fetching \(pageNumber) out of \(self.peoplePageCount) result pages")
      return (self.peoplePageCount, result)
    }
  }
  
  public func resultPageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)> {
    return currentMovieResultPage.map { pageNumber in
      let result = NSAttributedString(string: "Fetching \(pageNumber) out of \(self.movieResultPageCount) result pages")
      return (self.movieResultPageCount, result)
    }
  }
  
  public func getNextMovieResultPage(page: Int, discover: MovieDiscoverProtocol) {
    if currentMovieResultPage.value > 1 {
      guard movieResultPageCount > currentMovieResultPage.value else {
        return
      }
    }
    client.searchMovieDiscover(page: currentMovieResultPage.value, discover: discover)
      .take(first: 1)
      .map { $0 }
      .observe(on: UIScheduler())
      .on(event: { [weak self] event in
        guard let strongSelf = self else { return }
        switch event {
          case .value(let value):
            strongSelf._modelData.value[.media]?.append(contentsOf: value.results as [TMDBEntityProtocol])
            strongSelf.movieResultPageCount = value.totalPages
            strongSelf._currentMovieResultPage.value += 1
          case .failed(let error): strongSelf._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }

  public func getPopularPeoplePage(pageNumber: Int) {
    if currentPeopleResultPage.value > 1 {
      guard currentPeopleResultPage.value < peoplePageCount else {
        return
      }
    }
    client.searchPopularPeople(pageNumber: pageNumber)
      .take(first: 1)
     .map { $0 }
    .observe(on: UIScheduler())
    .on(event: { [weak self] event in
      guard let strongSelf = self else { return }
      switch event {
        case .value(let value):
          strongSelf._modelData.value[.actor]?.append(contentsOf: value.results as [TMDBEntityProtocol])
          strongSelf.peoplePageCount = value.totalPages
          strongSelf._currentPeopleResultPage.value = pageNumber + 1
        case .failed(let error): strongSelf._errorMessage.value = error.localizedDescription
        default: break
      }
    }).start()
  }
  
  public func getGenres() {
    client.searchMovieGenres()
      .take(first: 1)
      .map { response in
        return response.genres
      }
      .observe(on: UIScheduler())
      .on(event: { [weak self] event in
        guard let strongSelf = self else { return }
        switch event {
          case .value(let value):
            strongSelf._modelData.value[.movieGenre] = value as [TMDBEntityProtocol]
          case .failed(let error): strongSelf._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }
  
  public func getRatings() {
    client.searchUSRatings()
      .take(first: 1)
      .map { response in
          return response
      }
      .observe(on: UIScheduler())
      .on(event: { [weak self] event in
        guard let strongSelf = self else { return }
        switch event {
          case .value(let value):
            strongSelf._modelData.value[.rating] = value.certifications as [TMDBEntityProtocol]
          case .failed(let error): strongSelf._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }
}
