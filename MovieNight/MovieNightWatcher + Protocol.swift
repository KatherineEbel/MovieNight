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
  var isReady: Bool { get }
  var nameValid: MutableProperty<Bool> { get }
  func setName(value: String) -> Bool
}

public struct MovieNightWatcher: MovieWatcherProtocol {
  private var _moviePreference = MovieNightPreference()
  internal var _name: MutableProperty<String>
  private var _nameValid: Bool  {
    return name.value.characters.count >= 2
  }
  
  public var isReady: Bool {
    let ready = nameValid.value && moviePreference.isSet.value
    return ready
  }
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
    _name.swap(value.capitalized)
    return true
  }
  
}

// MARK: init(:name)
extension MovieNightWatcher {
  public init(name: String) {
    self._name = MutableProperty(name)
  }
  
}

