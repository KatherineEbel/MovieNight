//
//  TMDBMovieDiscover.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/29/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

// this is used for TMDBEndpoint in creating a search for watcher results
import Foundation
public protocol MovieDiscoverProtocol {
  var title: String { get }
  var actorIDs: Set<Int> { get }
  var genreIDs: Set<Int> { get }
  var maxRating: String { get }
}

public struct MovieDiscover: MovieDiscoverProtocol {
  public let title: String 
  public let actorIDs: Set<Int>
  public let genreIDs: Set<Int>
  public let maxRating: String
}
