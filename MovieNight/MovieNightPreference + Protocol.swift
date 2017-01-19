//
//  KMNMoviePreference.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/10/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//


import ReactiveSwift
import Argo

fileprivate let MAX_ACTOR_PREFERENCES = 5
fileprivate let MAX_GENRE_PREFERENCES = 5
fileprivate let MAX_RATING_PREFERENCES = 1

public protocol MoviePreferenceProtocol: class {
  var choices: Property<[TMDBEntity:[TMDBEntityProtocol]]> { get }
  var maxActorPreferences: Int { get }
  var maxGenrePreferences: Int { get }
  var maxRatingPreferences: Int { get }
  var isSet: Property<Bool> { get }
  func add(choice: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool
  func remove(choice: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool
  func clearAll()
}

public class MovieNightPreference: MoviePreferenceProtocol {
  public let _choices: MutableProperty<[TMDBEntity:[TMDBEntityProtocol]]> =
    MutableProperty([.actor: [], .movieGenre: [], .rating: []])
  public var choices: Property<[TMDBEntity : [TMDBEntityProtocol]]> {
    return Property(_choices)
  }
  
  // must include at least 1 actor choice/genre choice, and max 1 rating preference
  public var isSet: Property<Bool> {
    return choices.map { [unowned self] choices in
      choices[.actor]!.count > 0 &&
      choices[.movieGenre]!.count > 0 &&
      choices[.rating]!.count == self.maxRatingPreferences
    }
  }
  public var maxActorPreferences = MAX_ACTOR_PREFERENCES
  public var maxGenrePreferences = MAX_GENRE_PREFERENCES
  public var maxRatingPreferences = MAX_RATING_PREFERENCES
  
  public init() {}
  // adds choice if not already present
  public func add(choice: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool {
    if let entities = _choices.value[entityType] {
      let shouldAdd = !entities.contains(where: {$0.id == choice.id})
      switch entityType {
        case .actor:
          guard entities.count < maxActorPreferences else { return false }
          if shouldAdd {
            _choices.value[.actor]?.append(choice)
          }
        case .movieGenre:
          guard entities.count < maxGenrePreferences else { return false }
          if shouldAdd {
            _choices.value[.movieGenre]?.append(choice)
          }
        case .rating:
          guard entities.count < maxRatingPreferences else { return false }
          if shouldAdd {
            _choices.value[.rating]?.append(choice)
          }
        default: break
      }
      return true
    } else {
      return false
    }
  }
  
  // removes choice if  present
  public func remove(choice: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool {
    guard let entities = _choices.value[entityType] else { return false }
    if let index = entities.index(where: {$0.id == choice.id}) {
      _choices.value[entityType]?.remove(at: index)
      return true
    } else {
      return false
    }
  }
  
  // clears all of the watchers choices
  public func clearAll() {
    _choices.value[.actor]?.removeAll()
    _choices.value[.movieGenre]?.removeAll()
    _choices.value[.rating]?.removeAll()
  }
}
