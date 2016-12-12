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

protocol Queryable: Decodable {
  var id: Int { get }
  var name: String { get }
}

struct TMDBActor: Queryable {
  let id: Int
  let name: String
}

extension TMDBActor {
  static func decode(_ json: JSON) -> Decoded<TMDBActor> {
    return curry(TMDBActor.init)
      <^> json <| "id"
      <*> json <| "name"
  }
}
struct TMDBMovieGenre: Queryable {
  let id: Int
  let name: String
}

extension TMDBMovieGenre {
  static func decode(_ json: JSON) -> Decoded<TMDBMovieGenre> {
    return curry(TMDBMovieGenre.init)
      <^> json <| "id"
      <*> json <| "name"
  }
}

struct TMDBCertification: Decodable {
  let certification: String
  let meaning: String
  let order: Int
}

extension TMDBCertification {
  static func decode(_ json: JSON) -> Decoded<TMDBCertification> {
    return curry(TMDBCertification.init)
      <^> json <| "certification"
      <*> json <| "meaning"
      <*> json <| "order"
  }
}
struct MovieNightPreference {
  var actorChoices: [TMDBActor]
  var genreChoices: [TMDBMovieGenre]
  var maxRating: TMDBCertification
}
