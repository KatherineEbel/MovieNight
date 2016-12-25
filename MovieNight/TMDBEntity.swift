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

public protocol TMDBEntityProtocol: CustomStringConvertible {
  var description: String { get }
  var thumbnailPath: String { get }
}

// Defines types of the responses from TMDB
public struct TMDBEntity {
  enum Category {
    case actor
    case genre
    case rating
  }
  public struct MovieGenre: Decodable, TMDBEntityProtocol {
    let id: Int
    let name: String
  }
  
  public struct Rating: Decodable, TMDBEntityProtocol {
    let certification: String
    let meaning: String
    let order: Int
  }
  
   public struct Actor: Decodable, TMDBEntityProtocol {
    let name: String
    let popularity: Double
    let profile_path: String
    let id: Int
    let known_for: [JSON]
    let adult: Bool
  }
  
  public struct Movie: Decodable, TMDBEntityProtocol {
    let poster_path: String
    let adult: Bool
    let overview: String
    let release_date: String
    let genre_ids: [Int]
    let id: Int
    let original_title: String
    let original_language: String
    let title: String
    let backdrop_path: String
    let popularity: Double
    let vote_count: Int
    let video: Bool
    let voteAverage: Double
  }
}

extension TMDBEntity.Movie {
  public var description: String {
    return title
  }
  
  public var thumbnailPath: String {
    return poster_path
  }
  
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.Movie> {
    return curry(TMDBEntity.Movie.init)
      <^> json <| "poster_path"
      <*> json <| "adult"
      <*> json <| "overview"
      <*> json <| "release_date"
      <*> json <|| "genre_ids"
      <*> json <| "id"
      <*> json <| "original_title"
      <*> json <| "original_language"
      <*> json <| "title"
      <*> json <| "backdrop_path"
      <*> json <| "popularity"
      <*> json <| "vote_count"
      <*> json <| "video"
      <*> json <| "vote_average"
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
  
  public var description: String {
    return self.name
  }
  
  public var thumbnailPath: String {
    return profile_path
  }
}

extension TMDBEntity.MovieGenre {
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.MovieGenre> {
    return curry(TMDBEntity.MovieGenre.init)
      <^> json <| "id"
      <*> json <| "name"
  }
  
  public var description: String {
    return self.name
  }
  
  public var thumbnailPath: String {
    return ""
  }
}



extension TMDBEntity.Rating {
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.Rating> {
    return curry(TMDBEntity.Rating.init)
      <^> json <| "certification"
      <*> json <| "meaning"
      <*> json <| "order"
  }
  
  
  public var description: String {
    return self.certification
  }
  
  public var thumbnailPath: String {
    return ""
  }
}
