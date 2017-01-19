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
import Foundation

enum WatcherViewModelError: Error {
  case nameUpdateFailed(message: String)
  case notReadyToUpdate(message: String)
}

protocol WatcherViewModelProtocol: class {
  var watchers: Property<[MovieWatcherProtocol]?> { get }
  var activeWatcherIndex: Property<Int> { get }
  var activeWatcher: Property<MovieWatcherProtocol> { get }
  var activeWatcherReady: Property<Bool> { get }
  var movieDiscovery: Property<MovieDiscoverProtocol> { get }
  func setActiveWatcherName(name: String) -> Bool
  func addWatcher(watcher: MovieWatcherProtocol) -> Bool
  func getChoicesForActiveWatcher(choiceType: TMDBEntity) -> Property<[TMDBEntityProtocol]?>
 func getStatusForActiveWatcherChoice(choiceType: TMDBEntity) -> Property<(statusMessage: String, statusColor: UIColor)>
  func activeWatcherAdd(choice: TMDBEntityProtocol, with type: TMDBEntity) -> Bool
  func activeWatcherRemove(choice: TMDBEntityProtocol, with type: TMDBEntity) -> Bool
  func clearAllChoices()
  func updateActiveWatcher(index: Int)
  func watcher1Ready() -> Property<Bool>
  func watcher2Ready() -> Property<Bool>
}

public class WatcherViewModel: WatcherViewModelProtocol {
  private var _watchers: MutableProperty<[MovieWatcherProtocol]?>
  var resultValues: SignalProducer<(actorIDs: Set<Int>, genreIDs: Set<Int>, rating: String)?, NoError>!
  var watchers: Property<[MovieWatcherProtocol]?> {
    return Property(_watchers)
  }
  // tracks which watcher is active
  private let _activeWatcherIndex = MutableProperty(0)
  var activeWatcherIndex: Property<Int> {
    return Property(_activeWatcherIndex)
  }
  var activeWatcher: Property<MovieWatcherProtocol> {
    return watchers.map {
      [weak self] in
      guard let strongSelf = self else { return $0!.first! }
      return $0![strongSelf.activeWatcherIndex.value]
    }
  }
  var activeWatcherReady: Property<Bool> {
    return activeWatcher
      .map { $0.isReady.map { $0.0 && $0.1 }}
      .flatten(.latest)
  }
  var movieDiscovery: Property<MovieDiscoverProtocol> {
    // combined unique values for watcher 1 and watcher 2, to make a movieDiscover request.
    let watcher1Preferences = watchers.value?[0].moviePreference.choices
    let watcher2Preferences = watchers.value?[1].moviePreference.choices
    return watcher1Preferences!.combineLatest(with: watcher2Preferences!).map { preference1, preference2  -> MovieDiscoverProtocol in
      let actorsIDs = Set([preference1[.actor]!.map { $0.id }, preference2[.actor]!.map { $0.id }].flatMap {$0})
      let genreIDs = Set([preference1[.movieGenre]!.map { $0.id }, preference2[.movieGenre]!.map { $0.id }].flatMap {$0})
      let maxRating = preference1[.rating]!.first!.id > preference2[.rating]!.first!.id ?
        preference2[.rating]!.first!.title : preference1[.rating]!.first!.title
      let title = self.watchers.map { "Picks for \($0!.first!.name) & \($0!.last!.name)" }.value
      return MovieDiscover(title: title, actorIDs: actorsIDs, genreIDs: genreIDs, maxRating: maxRating)
    }
  }
  
  init(watchers: [MovieWatcherProtocol]?) {
    self._watchers = MutableProperty(watchers)
  }
  
  // watchers are ready if their name is valid and their preferences are set.
  func watcher1Ready() -> Property<Bool> {
    return watchers.value!.first!.isReady.map { $0.0 && $0.1 }
  }
  
  func watcher2Ready() -> Property<Bool> {
    return watchers.value!.last!.isReady.map { $0.0 && $0.1 }
  }
  
  func getChoicesForActiveWatcher(choiceType: TMDBEntity) -> Property<[TMDBEntityProtocol]?> {
    switch choiceType {
      case .movieGenre: return activeWatcher.value.moviePreference.choices.map { $0[.movieGenre] }
      case .rating: return activeWatcher.value.moviePreference.choices.map { $0[.rating] }
      default: return activeWatcher.value.moviePreference.choices.map { $0[.actor] }
    }
  }
  
  // given an entity type will return tuple of ready/not ready color and a message with current count for preference
  func getStatusForActiveWatcherChoice(choiceType: TMDBEntity) -> Property<(statusMessage: String, statusColor: UIColor)> {
    let readyColor = TMDBColor.ColorFromRGB(color: .green, withAlpha: 1.0)
    let notReadyColor = UIColor.red
    var statusText: String = ""
    var statusColor = notReadyColor
    let currentCount = activeWatcher.value.moviePreference.choices.map { $0[choiceType]!.count }
    return currentCount.map { count -> (String, UIColor) in
      switch choiceType {
        case .rating:
          statusText = "\(count)/1"
          statusColor = count == 1 ? readyColor : notReadyColor
          return (statusText, statusColor)
        default:
          // should trigger for .actor and .genre
          statusText = "\(count)/5"
          statusColor = count >= 1 && count <= 5 ? readyColor : notReadyColor
          return (statusText, statusColor)
      }
    }
  }
  
  func setActiveWatcherName(name: String) -> Bool {
    return activeWatcher.value.setName(value: name)
  }
  
  func addWatcher(watcher: MovieWatcherProtocol) -> Bool {
    guard let count = watchers.value?.count, count < 2 else {
      return false
    }
    _watchers.value?.append(watcher)
    return true
  }
  
  func activeWatcherAdd(choice: TMDBEntityProtocol, with type: TMDBEntity) -> Bool {
    return activeWatcher.value.moviePreference.add(choice: choice, with: type)
  }
  
  func activeWatcherRemove(choice: TMDBEntityProtocol, with type: TMDBEntity) -> Bool {
    return activeWatcher.value.moviePreference.remove(choice: choice, with: type)
  }
  
  func updateActiveWatcher(index: Int) {
    _activeWatcherIndex.swap(index)
  }
  
  func clearAllChoices() {
    // enumerate through both watchers and reset back to initial settings
    _watchers.value = _watchers.value?.enumerated().map { (index,watcher) in
      let copy = watcher
      copy.moviePreference.clearAll()
      _ = copy.setName(value: "Watcher \(index + 1)")
      return copy
    }
  } 
}
  
