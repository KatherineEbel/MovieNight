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

public protocol TMDBEntityProtocol {
  var title: String { get }
  var details: String? { get }
  var imagePath: String? { get }
}

// Defines types of the responses from TMDB
public struct TMDBEntity {
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
    let known_for: [Media]
    let adult: Bool
  }
  
  // combines movie and tv results when searching popular people
  public struct Media: Decodable, TMDBEntityProtocol {
    let poster_path: String?
    let overview: String
    let id: Int
    let _title: String?
    let name: String?
  }
}

extension TMDBEntity.Media {
  // popular people response comes back with known_for value of either
  // tv credits or movie which have different schemas. Either name or title respectively
  public var title: String {
    return _title != nil ? _title! : name!
  }
  
  public var details: String? {
    return overview
  }
  
  public var imagePath: String? {
    return poster_path
  }
  
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.Media> {
    return curry(TMDBEntity.Media.init)
      <^> json <|? "poster_path"
      <*> json <| "overview"
      <*> json <| "id"
      <*> json <|? "title"
      <*> json <|? "name"
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
  
  public var title: String {
    return self.name
  }
  
  public var details: String? {
    return "Known For:\n\n\(known_for.map { $0.title }.joined(separator: ",\n"))"
  }
  
  public var imagePath: String? {
    return profile_path
  }
}

extension TMDBEntity.MovieGenre {
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.MovieGenre> {
    return curry(TMDBEntity.MovieGenre.init)
      <^> json <| "id"
      <*> json <| "name"
  }
  
  public var title: String {
    return self.name
  }
  
  public var details: String? {
    return nil
  }
  
  public var imagePath: String? {
    return nil
  }
}



extension TMDBEntity.Rating {
  public static func decode(_ json: JSON) -> Decoded<TMDBEntity.Rating> {
    return curry(TMDBEntity.Rating.init)
      <^> json <| "certification"
      <*> json <| "meaning"
      <*> json <| "order"
  }
  
  
  public var title: String {
    return certification
  }
  
  public var details: String? {
    return meaning
  }
  
  public var imagePath: String? {
    return nil
  }
  
}
