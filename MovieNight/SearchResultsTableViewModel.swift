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

public protocol SearchResultsTableViewModeling: class {
  var modelData: Property<[TMDBEntity: [(page: Int, entities: [TMDBEntityProtocol])]]> { get }
  var currentPeopleResultPage: Property<Int> { get }
  var currentMovieResultPage: Property<Int> { get }
  var errorMessage: Property<String?> { get }
  func isPageCached(pageNumber: Int, entityType: TMDBEntity) -> Bool
  func validatePageSearch(pageNumber: Int, entityType: TMDBEntity) -> Bool
  func indexesForTitles(ofEntityType type: TMDBEntity, titles: [String]) -> Set<IndexPath>?
  func getPopularPeoplePage(pageNumber: Int)
  func getNextMovieResultPage(page: Int, discover: MovieDiscoverProtocol)
  func peoplePageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)>
  func resultPageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)>
  func getGenres()
  func getRatings()
  func clearMediaData()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  private let _modelData  = MutableProperty<[TMDBEntity: [(page: Int, entities: [TMDBEntityProtocol])]]>(
    [.actor: [], .media: [], .movieGenre: [], .rating: []])
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
  
  public var modelData: Property<[TMDBEntity : [(page: Int, entities: [TMDBEntityProtocol])]]> {
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
    return currentPeopleResultPage.map { [unowned self] pageNumber in
      let result = NSAttributedString(string: "Fetching \(pageNumber) out of \(self.peoplePageCount) result pages")
      return (self.peoplePageCount, result)
    }
  }
  
  public func resultPageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)> {
    return currentMovieResultPage.map { [unowned self] pageNumber in
      let result = NSAttributedString(string: "Fetching \(pageNumber) out of \(self.movieResultPageCount) result pages")
      return (self.movieResultPageCount, result)
    }
  }
  
  public func isPageCached(pageNumber: Int, entityType: TMDBEntity) -> Bool {
    guard let data = modelData.value[entityType] else { return false }
    return data.contains { $0.page == pageNumber }
  }
  
  public func validatePageSearch(pageNumber: Int, entityType: TMDBEntity) -> Bool {
    let (actorCount, movieCount) = (peoplePageCountTracker().value.page, resultPageCountTracker().value.page)
    let pageInRange: Bool = {
      switch entityType {
        case .actor:
          if actorCount == 0 && pageNumber == 1 {
            return true
          } else {
            return actorCount >= pageNumber
          }
        case .media:
          if movieCount == 0 && pageNumber == 1 {
            return true
          } else {
            return movieCount >= pageNumber
          }
        default: return false
      }
    }()
    return !isPageCached(pageNumber: pageNumber, entityType: entityType) && pageInRange
  }
  
  public func indexesForTitles(ofEntityType type: TMDBEntity, titles: [String]) -> Set<IndexPath>? {
    guard let entities = modelData.value[type]?.flatMap({ $0.entities }) else { return nil }
    return entities.enumerated().reduce(Set<IndexPath>()) { (result, nextResult: (idx: Int, selection: TMDBEntityProtocol)) in
      var copy = result
      if titles.contains(nextResult.selection.title) {
        copy.insert(IndexPath(row: nextResult.idx, section: 0))
      }
      return copy
    }
  }
  
  public func clearMediaData() {
    _modelData.value[.media]!.removeAll()
  }
  
  public func getNextMovieResultPage(page: Int, discover: MovieDiscoverProtocol) {
    guard validatePageSearch(pageNumber: page, entityType: .media) else { return }
    client.searchMovieDiscover(page: currentMovieResultPage.value, discover: discover)
      .take(first: 1)
      .map { $0 }
      .observe(on: kUIScheduler)
      .on(event: { [unowned self] event in
        switch event {
          case .value(let value):
            self._modelData.value[.media]?.append((page, value.results))
            self.movieResultPageCount = value.totalPages
            self._currentMovieResultPage.value += 1
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }

  public func getPopularPeoplePage(pageNumber: Int) {
    guard validatePageSearch(pageNumber: pageNumber, entityType: .actor) else { return }
    client.searchPopularPeople(pageNumber: pageNumber)
      .take(first: 1)
      .map { $0 }
      .observe(on: kUIScheduler)
      .on(event: { [unowned self] event in
        switch event {
          case .value(let value):
            self._modelData.value[.actor]?.append((pageNumber, value.results))
            self.peoplePageCount = value.totalPages
            self._currentPeopleResultPage.value = pageNumber + 1
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
    }).start()
  }
  
  public func getGenres() {
    guard let genres = modelData.value[.movieGenre] else { return }
    guard genres.isEmpty else { return }
    client.searchMovieGenres()
      .take(first: 1)
      .map { response in
        return response.genres
      }
      .observe(on: kUIScheduler)
      .on(event: { [unowned self] event in
        switch event {
          case .value(let value):
            self._modelData.value[.movieGenre] = [(1, value as [TMDBEntityProtocol])]
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }
  
  public func getRatings() {
    guard let ratings = modelData.value[.rating] else { return }
    guard ratings.isEmpty else { return }
    client.searchUSRatings()
      .take(first: 1)
      .map { response in
          return response
      }
      .observe(on: kUIScheduler)
      .on(event: { [unowned self] event in
        switch event {
          case .value(let value):
            self._modelData.value[.rating]?.append((1, value.certifications as [TMDBEntityProtocol]))
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }
}
