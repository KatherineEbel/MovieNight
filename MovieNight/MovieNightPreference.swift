//
//  KMNMoviePreference.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/10/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//


import ReactiveSwift

public protocol MoviePreferenceProtocol {
  var actorChoices: [TMDBEntity.Actor] { get set }
  var genreChoices: [TMDBEntity.MovieGenre] { get set }
  var maxRating: TMDBEntity.Rating? { get set }
  var isSet: Bool { get }
}

public struct MovieNightPreference: MoviePreferenceProtocol {
  public var actorChoices: [TMDBEntity.Actor] = []
  public var genreChoices: [TMDBEntity.MovieGenre] = []
  public var maxRating: TMDBEntity.Rating?
  public var isSet: Bool {
    guard let _ = maxRating else {
      return false
    }
    return actorChoices.count > 0 && genreChoices.count > 0
  }
}

extension MovieNightPreference {
}
