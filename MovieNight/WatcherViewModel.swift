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

enum Preference {
  case actors
  case genres
  case maxRating
}

protocol WatcherViewModelProtocol {
  var watchers: Property<[MovieWatcherProtocol]?> { get }
  var watchersReady: SignalProducer<Bool,NoError>? { get }
  func setNameForWatcher(at index: Int, with name: String) -> Bool
  func addWalker(watcher: MovieWatcherProtocol) -> Bool
  func add<T: Decodable>(movie preference: T, toWatcher index: Int) -> Bool
  func watcher1Ready() -> Bool
  func watcher2Ready() -> Bool
}

public class WatcherViewModel: WatcherViewModelProtocol {
  private var _watchers: MutableProperty<[MovieWatcherProtocol]?> {
    didSet {
      watchersReady = SignalProducer<Bool, NoError> { observer, disposable in
        observer.send(value: self.watcher1Ready() && self.watcher2Ready())
      }
    }
  }
  var watchers: Property<[MovieWatcherProtocol]?> {
    return Property(_watchers)
  }
  var watchersReady: SignalProducer<Bool, NoError>?
  
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
    _watchers.value?[index].name = name
    return watchers.value?[index].nameValid ?? false
  }
  
  func addWalker(watcher: MovieWatcherProtocol) -> Bool {
    guard let count = watchers.value?.count, count < 2 else {
      return false
    }
    _watchers.value?.append(watcher)
    return true
  }
  
  func add<T: Decodable>(movie preference: T, toWatcher index: Int) -> Bool {
    guard (watchers.value != nil) else {
      return false
    }
    switch preference {
      case let actor where preference is TMDBEntity.Actor:
        guard _watchers.value![index].moviePreference.actorChoices.count < 5 else {
          return false
        }
        if let actor = actor as? TMDBEntity.Actor {
          _watchers.value![index].moviePreference.actorChoices.append(actor)
          return true
        }
      case _ where preference is TMDBEntity.MovieGenre:
        guard _watchers.value![index].moviePreference.genreChoices.count < 5 else {
          return false
        }
        if let genre = preference as? TMDBEntity.MovieGenre {
          _watchers.value![index].moviePreference.genreChoices.append(genre)
          return true
        }
      case _ where preference is TMDBEntity.Rating:
        if let rating = preference as? TMDBEntity.Rating {
          _watchers.value![index].moviePreference.maxRating = rating
          return true
        }
      default: break
    }
    return false
  }
  
}
  
