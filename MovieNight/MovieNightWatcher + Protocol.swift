//
//  MovieNightWatcher.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift

public protocol MovieWatcherProtocol {
  var name: MutableProperty<String> { get }
  var moviePreference: MoviePreferenceProtocol { get }
  var isReady: MutableProperty<Bool> { get }
  var nameValid: MutableProperty<Bool> { get }
  func setName(value: String) -> Bool
}

public struct MovieNightWatcher: MovieWatcherProtocol {
  private var _moviePreference = MovieNightPreference()
  internal var _name: MutableProperty<String> {
    didSet {
      // combine moviePreference isSet with nameValid to make one bool property
      let isSet = moviePreference.isSet.combineLatest(with: nameValid)
      // bind isReady to isSet
      isReady <~ isSet.map { $0.0 && $0.1 }
    }
  }
  private var _nameValid: Bool  {
    return name.value.characters.count >= 2
  }
  
  public let isReady = MutableProperty(false)
  public var name: MutableProperty<String> {
    return _name
  }
  public var moviePreference: MoviePreferenceProtocol {
    return _moviePreference
  }
  
  public var nameValid: MutableProperty<Bool> {
    return MutableProperty(_nameValid)
  }
  
  public func setName(value: String) -> Bool {
    guard value.characters.count >= 2 else { return false }
    _name.swap(value)
    return true
  }
  
}

// MARK: init(:name)
extension MovieNightWatcher {
  public init(name: String) {
    self._name = MutableProperty(name)
  }
  
}

