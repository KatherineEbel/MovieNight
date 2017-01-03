//
//  TMDBMovieDiscover.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/29/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation
//actorIDs: Set<Int>, genreIDs: Set<Int>, rating: String
public protocol MovieDiscoverProtocol {
  var actorIDs: Set<Int> { get }
  var genreIDs: Set<Int> { get }
  var maxRating: String { get }
}

public struct MovieDiscover: MovieDiscoverProtocol {
  public let actorIDs: Set<Int>
  public let genreIDs: Set<Int>
  public let maxRating: String
}
