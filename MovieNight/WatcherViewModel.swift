//
//  WatcherViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift
import Result
import Argo

enum WatcherViewModelError: Error {
  case nameUpdateFailed(message: String)
  case notReadyToUpdate(message: String)
}

protocol WatcherViewModelProtocol {
  var watchers: Property<[MovieWatcherProtocol]?> { get }
  var activeWatcher: Int { get }
  func setNameForWatcher(at index: Int, with name: String) -> Bool
  func addWalker(watcher: MovieWatcherProtocol) -> Bool
  func add<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool
  func remove<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool
  func combineWatchersChoices() -> MovieDiscoverProtocol?
  func clearWatcherChoices()
  func updateActiveWatcher()
  func watcher1Ready() -> Bool
  func watcher2Ready() -> Bool
}

public class WatcherViewModel: WatcherViewModelProtocol {
  private var _watchers: MutableProperty<[MovieWatcherProtocol]?>
  var resultValues: SignalProducer<(actorIDs: Set<Int>, genreIDs: Set<Int>, rating: String)?, NoError>!
  var watchers: Property<[MovieWatcherProtocol]?> {
    return Property(_watchers)
  }
  var activeWatcher: Int = 0
  
  init(watchers: [MovieWatcherProtocol]?) {
    self._watchers = MutableProperty(watchers)
  }
  
  func watcher1Ready() -> Bool {
    guard let watcher1 = watchers.value?[0] else {
      return false
    }
    return watcher1.isReady
  }
  
  func watcher2Ready() -> Bool {
    guard let watcher2 = watchers.value?[1] else {
      return false
    }
    return watcher2.isReady
  }
  
  func setNameForWatcher(at index: Int, with name: String) -> Bool {
    guard index >= 0 && index <= 1 && name.characters.count >= 2 else {
      return false
    }
    _watchers.value?[index].name = name.capitalized
    return watchers.value?[index].nameValid ?? false
  }
  
  func addWalker(watcher: MovieWatcherProtocol) -> Bool {
    guard let count = watchers.value?.count, count < 2 else {
      return false
    }
    _watchers.value?.append(watcher)
    return true
  }
  
  func add<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool {
    switch preference {
      case let actor as TMDBEntity.Actor:
        // makes sure same choice isn't accidentally added again
        if let watcher = watchers.value?[index] {
          let exists = watcher.actorChoices.contains { $0.name == actor.name }
          guard !exists else { return false }
        }
        return _watchers.value![index].addActor(choice: actor)
      case let genre as TMDBEntity.MovieGenre:
        if let watcher = watchers.value?[index] {
          let exists = watcher.genreChoices.contains { $0.name == genre.name }
          guard  !exists else { return false }
        }
        return _watchers.value![index].addGenre(choice: genre)
      case let rating as TMDBEntity.Rating: return _watchers.value![index].setMaxRating(choice: rating)
      default: return false
    }
  }
  
  func remove<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool{
    switch preference {
      case let actor as TMDBEntity.Actor: return _watchers.value![index].removeActor(choice: actor)
      case let genre as TMDBEntity.MovieGenre: return _watchers.value![index].removeGenre(choice: genre)
      case let rating as TMDBEntity.Rating: return _watchers.value![index].setMaxRating(choice: rating)
      default: return false
    }
  }
  
  func updateActiveWatcher() {
    activeWatcher = activeWatcher == 0 ? 1 : 0
  }
  
  func combineWatchersChoices() -> MovieDiscoverProtocol? {
    guard watcher1Ready() && watcher2Ready() else {
      return nil
    }
    let watcher1 = watchers.value?[0]
    let watcher2 = watchers.value?[1]
    var actors = watcher1!.actorChoices.map { $0.id }
    actors.append(contentsOf: watcher2!.actorChoices.map { $0.id })
    var genres = watcher1!.genreChoices.map { $0.id }
    genres.append(contentsOf: watcher2!.genreChoices.map { $0.id })
    let rating = watcher1!.maxRatingChoice!.order > watcher2!.maxRatingChoice!.order ?
      watcher2!.maxRatingChoice : watcher1!.maxRatingChoice
    return MovieDiscover(actorIDs: Set(actors), genreIDs: Set(genres), maxRating: rating!.title)
  }
  
  func clearWatcherChoices() {
    _watchers.value = _watchers.value?.enumerated().map { (index,watcher) in
      var copy = watcher
      copy.clearPreferences()
      copy.name = "Watcher \(index + 1)"
      return copy
    }
  }
}
  
