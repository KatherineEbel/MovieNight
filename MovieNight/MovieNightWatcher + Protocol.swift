//
//  MovieNightWatcher.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift

public protocol MovieWatcherProtocol: class {
  var name: String { get }
  var moviePreference: MoviePreferenceProtocol { get }
  var isReady: Property<(Bool, Bool)> { get }
  var nameValid: Property<Bool> { get }
  func setName(value: String) -> Bool
}

public class MovieNightWatcher: MovieWatcherProtocol {
  private var _moviePreference = MovieNightPreference()
  internal var _name: MutableProperty<String>
  private var _nameValid: Property<Bool>  {
    return _name.map { $0.characters.count >= 2 }
  }
  
  public var isReady: Property<(Bool, Bool)> {
    return nameValid.combineLatest(with: moviePreference.isSet)
  }
  
  public var name: String {
    return _name.value
  }
  public var moviePreference: MoviePreferenceProtocol {
    return _moviePreference
  }
  
  public var nameValid: Property<Bool> {
    return Property(_nameValid)
  }
  
  public init(name: String) {
    self._name = MutableProperty(name)
  }
  
  public func setName(value: String) -> Bool {
    guard value.characters.count >= 2 else { return false }
    _name.swap(value.capitalized)
    return true
  }
  
}
