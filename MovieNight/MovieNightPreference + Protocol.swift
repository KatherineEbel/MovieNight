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

public protocol MoviePreferenceProtocol {
  var preferences: Property<[TMDBEntity:[TMDBEntityProtocol]]> { get }
  var maxActorPreferences: Int { get }
  var maxGenrePreferences: Int { get }
  var maxRatingPreferences: Int { get }
  var isSet: Property<Bool> { get }
  func add(preference: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool
  func remove(preference: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool
  func clearAll()
}

public struct MovieNightPreference: MoviePreferenceProtocol {
  public let _preferences: MutableProperty<[TMDBEntity:[TMDBEntityProtocol]]> =
    MutableProperty([.actor: [], .movieGenre: [], .rating: []])
  public var preferences: Property<[TMDBEntity : [TMDBEntityProtocol]]> {
    return Property(_preferences)
  }
  
  public var isSet: Property<Bool> {
    return preferences.map { preferences in
      preferences[.actor]!.count > 0 &&
      preferences[.movieGenre]!.count > 0 &&
      preferences[.rating]!.count == self.maxRatingPreferences
    }
  }
  public var maxActorPreferences = MAX_ACTOR_PREFERENCES
  public var maxGenrePreferences = MAX_GENRE_PREFERENCES
  public var maxRatingPreferences = MAX_RATING_PREFERENCES
  
  public init() { print("Movie preference init") }
  public func add(preference: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool {
    if let entities = _preferences.value[entityType] {
      let shouldAdd = !entities.contains(where: {$0.id == preference.id})
      switch entityType {
        case .actor:
          guard entities.count < maxActorPreferences else { return false }
          if shouldAdd {
            _preferences.value[.actor]?.append(preference)
          }
        case .movieGenre:
          guard entities.count < maxGenrePreferences else { return false }
          if shouldAdd {
            _preferences.value[.movieGenre]?.append(preference)
          }
        case .rating:
          guard entities.count < maxRatingPreferences else { return false }
          if shouldAdd {
            _preferences.value[.rating]?.append(preference)
          }
        default: break
      }
      return true
    } else {
      return false
    }
  }
  
  public func remove(preference: TMDBEntityProtocol, with entityType: TMDBEntity) -> Bool {
    guard let entities = _preferences.value[entityType] else { return false }
    if let index = entities.index(where: {$0.id == preference.id}) {
      _preferences.value[entityType]?.remove(at: index)
      return true
    } else {
      return false
    }
  }
  
  public func clearAll() {
    _preferences.value[.actor]?.removeAll()
    _preferences.value[.movieGenre]?.removeAll()
    _preferences.value[.rating]?.removeAll()
  }
}
