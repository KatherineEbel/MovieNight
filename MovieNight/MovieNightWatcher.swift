//
//  MovieNightWatcher.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation

protocol MovieWatcherType {
  var name: String { get }
  var moviePreference: MovieNightPreference? { get }
}
struct MovieNightWatcher: MovieWatcherType {
  var name: String
  let moviePreference: MovieNightPreference?
}
