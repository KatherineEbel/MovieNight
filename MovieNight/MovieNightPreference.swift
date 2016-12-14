//
//  KMNMoviePreference.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/10/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation
import Argo
import Runes
import Curry


struct TMDBEntity {
  let entity: Entity
  enum Entity {
    case actor
    case genre
    case classification
  }
  
  
  struct MovieGenre: IDType {
    let id: Int
    let name: String
  }
  
  struct Certification: Decodable {
    let certification: String
    let meaning: String
    let order: Int
  }
  
  struct Actor: IDType {
    let name: String
    let popularity: Double
    let profile_path: String
    let id: Int
    let known_for: [JSON]
    let adult: Bool
  }
}
protocol IDType: Decodable {
  var id: Int { get }
  var name: String { get }
}


struct PopularPeopleResponseEntity: Decodable {
  let page: Int
  let results: [TMDBEntity.Actor]
  let totalResults: Int
  let total_pages: Int
}

extension PopularPeopleResponseEntity {
  static func decode(_ json: JSON) -> Decoded<PopularPeopleResponseEntity> {
    return curry(PopularPeopleResponseEntity.init)
      <^> json <| "page"
      <*> json <|| "results"
      <*> json <| "total_results"
      <*> json <| "total_pages"
  }
}


extension TMDBEntity.Actor {
  static func decode(_ json: JSON) -> Decoded<TMDBEntity.Actor> {
    return curry(TMDBEntity.Actor.init)
      <^> json <| "name"
      <*> json <| "popularity"
      <*> json <| "profile_path"
      <*> json <| "id"
      <*> json <|| "known_for"
      <*> json <| "adult"
  }
}

extension TMDBEntity.MovieGenre {
  static func decode(_ json: JSON) -> Decoded<TMDBEntity.MovieGenre> {
    return curry(TMDBEntity.MovieGenre.init)
      <^> json <| "id"
      <*> json <| "name"
  }
}


extension TMDBEntity.Certification {
  static func decode(_ json: JSON) -> Decoded<TMDBEntity.Certification> {
    return curry(TMDBEntity.Certification.init)
      <^> json <| "certification"
      <*> json <| "meaning"
      <*> json <| "order"
  }
}
struct MovieNightPreference {
  var actorChoices: [TMDBEntity.Actor]
  var genreChoices: [TMDBEntity.MovieGenre]
  var maxRating: TMDBEntity.Certification
}
