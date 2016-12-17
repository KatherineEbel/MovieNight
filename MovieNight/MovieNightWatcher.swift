//
//  MovieNightWatcher.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation

public protocol MovieWatcherType {
  var name: String { get set }
  var moviePreference: MovieNightPreference? { get }
}
public struct MovieNightWatcher: MovieWatcherType {
  public var name: String
  public let moviePreference: MovieNightPreference?
}
