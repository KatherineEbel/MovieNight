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
  func getNextMovieResultPage(pageNumber: Int, discover: MovieDiscoverProtocol)
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
  private var _currentMovieResultPage = MutableProperty(0)
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
    self.client = client
  }
  
  // gets the total number of actor result pages and a string to display for user
  public func peoplePageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)> {
    return currentPeopleResultPage.map { [unowned self] pageNumber in
      let result = NSAttributedString(string: "Fetching \(pageNumber) out of \(self.peoplePageCount) result pages")
      return (self.peoplePageCount, result)
    }
  }
  
  // gets the total number of media(movie discover) result pages and a string to display for user
  public func resultPageCountTracker() -> Property<(page: Int, tracker: NSAttributedString)> {
    return currentMovieResultPage.map { [unowned self] pageNumber in
      let result = NSAttributedString(string: "Fetching \(pageNumber) out of \(self.movieResultPageCount) result pages")
      return (self.movieResultPageCount, result)
    }
  }
  
  // returns true if page already exists for given entity in model data so page
  // won't be reloaded
  public func isPageCached(pageNumber: Int, entityType: TMDBEntity) -> Bool {
    guard let data = modelData.value[entityType] else { return false }
    return data.contains { $0.page == pageNumber }
  }
  
  // if returns true if page is in range of total pages available to search, and page is not already cached.
  public func validatePageSearch(pageNumber: Int, entityType: TMDBEntity) -> Bool {
    let (actorCount, movieCount) = (peoplePageCountTracker().value.page, resultPageCountTracker().value.page)
    let pageInRange: Bool = {
      switch entityType {
        // if count and page number are 0 and 1 respectively, this is the first search, so they are valid. If not go by total number of pages available from api
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
  
  // gets the corresponding index from model data for the given titles. all titles should be unique
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
  
  
  // gets the next movie result page for the passed in page number and movie discover
  public func getNextMovieResultPage(pageNumber: Int, discover: MovieDiscoverProtocol) {
    guard validatePageSearch(pageNumber: pageNumber, entityType: .media) else { return }
    client.searchMovieDiscover(page: pageNumber, discover: discover)
      .take(first: 1)
      .map { $0 }
      .observe(on: kUIScheduler)
      .on(event: { [unowned self] event in
        switch event {
          case .value(let value):
            self._modelData.value[.media]?.append((pageNumber, value.results))
            self.movieResultPageCount = value.totalPages
            self._currentMovieResultPage.value = pageNumber + 1
          case .failed(let error): self._errorMessage.value = error.localizedDescription
          default: break
        }
      }).start()
  }

  // gets the next actor result page for the passed in page number
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
  
  // gets the genres if they haven't already been loaded
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
  
  // gets ratings if they haven't already been loaded
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
  
  // empties all media data, so user can start with a clean slate for new movie discover
  public func clearMediaData() {
    _modelData.value[.media]!.removeAll()
    _currentMovieResultPage.value = 0
  }
}
