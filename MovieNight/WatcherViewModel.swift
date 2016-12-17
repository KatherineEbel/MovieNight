//
//  WatcherViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift
import Result

enum WatcherViewModelError: Error {
  case nameUpdateFailed(message: String)
  case notReadyToUpdate(message: String)
}

protocol WatcherViewModeling {
  var isReadyForResults: MutableProperty<Bool> { get }
  var watchers: Property<[MovieWatcherType]> { get }
  func updateWatcher(at index: Int, with name: String) -> Bool
  func watcher1Ready() -> Bool
  func watcher2Ready() -> Bool
}

public class WatcherViewModel: WatcherViewModeling {
  private let _watchers: MutableProperty<[MovieWatcherType]>
  var isReadyForResults: MutableProperty<Bool> {
    return MutableProperty(watchersReady())
  }
  
  var watchers: Property<[MovieWatcherType]> {
    return Property(_watchers)
  }

  
  init() {
    let watcher1 = MovieNightWatcher(name: "watcher1", moviePreference: nil)
    let watcher2 = MovieNightWatcher(name: "watcher2", moviePreference: nil)
    self._watchers = MutableProperty([watcher1, watcher2])
  }
  
  func watchersReady() -> Bool {
    return self.watchers.value.reduce(false) { isReady, watcher in
      return watcher.moviePreference != nil && !watcher.name.isEmpty
    }
  }
  
  func watcher1Ready() -> Bool {
    let watcher1 = watchers.value[0]
    return watcher1.moviePreference != nil && !watcher1.name.isEmpty
  }
  
  func watcher2Ready() -> Bool {
    let watcher2 = watchers.value[1]
    return watcher2.moviePreference != nil && !watcher2.name.isEmpty
  }
  
  func isReady(_ watcher: MovieWatcherType) -> Bool {
    return watcher.moviePreference != nil
  }
  
  func updateWatcher(at index: Int, with name: String) -> Bool {
    guard index >= 0 && index <= 1 && name.characters.count >= 2 else {
      return false
    }
    _watchers.value[index].name = name
    return watchers.value[index].name == name
  }
  
}
  
