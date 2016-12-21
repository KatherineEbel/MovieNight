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
  var actorChoices: [TMDBEntity.Actor] { get }
  var genreChoices: [TMDBEntity.MovieGenre] { get }
  var maxRatingChoice: TMDBEntity.Rating? { get }
  var isReady: Bool { get }
  var nameValid: Bool { get }
  
  mutating func addActor(choice: TMDBEntity.Actor) -> Bool
  mutating func addGenre(choice: TMDBEntity.MovieGenre) -> Bool
  mutating func removeActor(choice: TMDBEntity.Actor) -> Bool
  mutating func removeGenre(choice: TMDBEntity.MovieGenre) -> Bool
  mutating func setMaxRating(choice: TMDBEntity.Rating) -> Bool
}

public struct MovieNightWatcher: MovieWatcherProtocol {
  public var name: String
  internal var moviePreference: MoviePreferenceProtocol = MovieNightPreference()
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
  
  public var actorChoices: [TMDBEntity.Actor] {
    return moviePreference.actorChoices
  }
  
  public var genreChoices: [TMDBEntity.MovieGenre] {
    return moviePreference.genreChoices
  }
  
  public var maxRatingChoice: TMDBEntity.Rating? {
    return moviePreference.maxRating
  }
  
  public mutating func setMaxRating(choice: TMDBEntity.Rating) -> Bool {
    moviePreference.maxRating = choice
    return true
  }
  
  public mutating func addActor(choice: TMDBEntity.Actor) -> Bool {
    guard actorChoices.count < 5 else {
      return false
    }
    moviePreference.actorChoices.append(choice)
    return true
  }
  
  public mutating func addGenre(choice: TMDBEntity.MovieGenre) -> Bool {
    guard genreChoices.count < 5 else {
      return false
    }
    moviePreference.genreChoices.append(choice)
    return true
  }
  
  public mutating func removeActor(choice: TMDBEntity.Actor) -> Bool {
    if let index = actorChoices.index(where: { (actor) -> Bool in
      actor.name == choice.name
    }) {
      moviePreference.actorChoices.remove(at: index)
      return true
    } else {
      return false
    }
  }
  
  public mutating func removeGenre(choice: TMDBEntity.MovieGenre) -> Bool {
    if let index = genreChoices.index(where: { (genre) -> Bool in
      genre.name == choice.name
    }) {
      moviePreference.genreChoices.remove(at: index)
      return true
    } else {
      return false
    }
  }
}

