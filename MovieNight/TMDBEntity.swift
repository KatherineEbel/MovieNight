//
//  TMDBEntity.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/18/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Argo
import Runes
import Curry
import Result


// Defines types of the responses from TMDB
public struct TMDBEntity {
  public struct MovieGenre: Decodable {
    let id: Int
    let name: String
  }
  
  public struct Rating: Decodable {
    let certification: String
    let meaning: String
    let order: Int
  }
  
   public struct Actor: Decodable {
    let name: String
    let popularity: Double
    let profile_path: String
    let id: Int
    let known_for: [JSON]
    let adult: Bool
  }
  
}

// MARK: Conform to Decodable Protocol
extension TMDBEntity.Actor {
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.Actor> {
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
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.MovieGenre> {
    return curry(TMDBEntity.MovieGenre.init)
      <^> json <| "id"
      <*> json <| "name"
  }
}



extension TMDBEntity.Rating {
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.Rating> {
    return curry(TMDBEntity.Rating.init)
      <^> json <| "certification"
      <*> json <| "meaning"
      <*> json <| "order"
  }
}
