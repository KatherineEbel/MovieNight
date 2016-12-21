//
//  KMNMoviePreference.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/10/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//


import ReactiveSwift
import Argo

public protocol MoviePreferenceProtocol {
  var actorChoices: [TMDBEntity.Actor] { get set }
  var genreChoices: [TMDBEntity.MovieGenre] { get set }
  var maxRating: TMDBEntity.Rating? { get set }
  mutating func add<T: Decodable>(_ preference: T) -> Bool
  mutating func remove<T:Decodable>(_ preference: T) -> Bool
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
  
  mutating public func remove<T:Decodable>(_ preference: T) -> Bool {
    switch preference {
      case _ where preference is TMDBEntity.Rating:
        maxRating = nil
      case _ where preference is TMDBEntity.Actor:
        let actor = preference as! TMDBEntity.Actor
        if let index =
          actorChoices.index(where: { (prospectiveMatch) -> Bool in
            actor.name == prospectiveMatch.name
           })
        {
          actorChoices.remove(at: index)
          return true
        }
      case _ where preference is TMDBEntity.MovieGenre:
        let genre = preference as! TMDBEntity.MovieGenre
        let index = genreChoices.index(where: { (prospectiveMatch) -> Bool in
            genre.name == prospectiveMatch.name
        })
        if let index = index {
          genreChoices.remove(at: index)
          return true
        }
      default:
        print("Unknown preference")
        return false
    }
    return false
  }
  
  mutating public func add<T: Decodable>(_ preference: T) -> Bool {
    switch preference {
      case let actor where preference is TMDBEntity.Actor:
        guard actorChoices.count < 5 else {
          return false
        }
        if let actor = actor as? TMDBEntity.Actor {
          actorChoices.append(actor)
          return true
        }
      case _ where preference is TMDBEntity.MovieGenre:
        guard genreChoices.count < 5 else {
          return false
        }
        if let genre = preference as? TMDBEntity.MovieGenre {
          genreChoices.append(genre)
          return true
        }
      case _ where preference is TMDBEntity.Rating:
        if let rating = preference as? TMDBEntity.Rating {
          maxRating = rating
          return true
        }
      default: break
    }
    return false
  }
}
