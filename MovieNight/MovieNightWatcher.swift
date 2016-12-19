//
//  MovieNightWatcher.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift

public protocol MovieWatcherProtocol {
  var name: String { get set }
  var moviePreference: MoviePreferenceProtocol { get set }
  var isReady: Bool { get }
  var nameValid: Bool { get }
}

public struct MovieNightWatcher: MovieWatcherProtocol {
  public var name: String
  public var moviePreference: MoviePreferenceProtocol = MovieNightPreference()
  public var nameValid: Bool {
    return name.characters.count > 2
  }
  public var isReady: Bool {
    return nameValid && moviePreference.isSet
  }
}

// MARK: init(:name)
extension MovieNightWatcher {
  init(name: String) {
    self.name = name
  }
}

