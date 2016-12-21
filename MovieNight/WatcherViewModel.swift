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
  var activeWatcher: Int { get }
  func setNameForWatcher(at index: Int, with name: String) -> Bool
  func addWalker(watcher: MovieWatcherProtocol) -> Bool
  func add<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool
  func remove<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool
  func watcher1Ready() -> Bool
  func watcher2Ready() -> Bool
}

public class WatcherViewModel: WatcherViewModelProtocol {
  private var _watchers: MutableProperty<[MovieWatcherProtocol]?> {
    didSet {
      print("Set watchers")
      watchersReady = SignalProducer<Bool, NoError> { observer, disposable in
        observer.send(value: self.watcher1Ready() && self.watcher2Ready())
      }
    }
  }
  var watchers: Property<[MovieWatcherProtocol]?> {
    return Property(_watchers)
  }
  var watchersReady: SignalProducer<Bool, NoError>?
  var activeWatcher: Int = 0
  
  init(watchers: [MovieWatcherProtocol]?) {
    self._watchers = MutableProperty(watchers)
  }
  
  func watcher1Ready() -> Bool {
    guard let watcher1 = watchers.value?[0] else {
      return false
    }
    if watcher1.isReady {
      activeWatcher = 1
      return true
    } else {
      return false
    }
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
  
  func add<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool {
    return _watchers.value?[activeWatcher].moviePreference.add(preference) ?? false
  }
  
  func remove<T: Decodable>(preference: T, watcherAtIndex index: Int) -> Bool{
    return _watchers.value?[activeWatcher].moviePreference.remove(preference) ?? false
  }
  
}
  
