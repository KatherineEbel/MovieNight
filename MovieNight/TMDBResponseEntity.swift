//
//  TMDBWrapper.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/14/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Argo
import Runes
import Curry
import Result

public protocol PagedResponseProtocol: Decodable {
  associatedtype TMDB
  var page: Int { get }
  var results: [TMDBEntity] { get }
  var totalResults: Int { get }
  var totalPages: Int { get }
}

// Defines a response from TMDB
public enum TMDBResponseEntity {
  case popularPeople(PopularPeople)
  case movieGenre(MovieGenreResponse)
  case certification(USCertifications)
  case movieDiscover(MovieDiscover)
  
  public struct PopularPeople: Decodable {
    let page: Int
    let results: [TMDBEntity.Actor]
    let totalResults: Int
    let totalPages: Int
  }
  
  public struct MovieGenreResponse: Decodable {
    let genres: [TMDBEntity.MovieGenre]
  }
  
  public struct USCertifications: Decodable {
    let certifications: [TMDBEntity.Rating]
  }
  
  public struct MovieDiscover: Decodable {
    let page: Int
    let results: [TMDBEntity.Movie]
    let totalResults: Int
    let totalPages: Int
  }
}

// MARK: Adopt Decodable
extension TMDBResponseEntity.USCertifications {
  public static func decode(_ json: JSON) -> Decoded<TMDBResponseEntity.USCertifications> {
    return curry(TMDBResponseEntity.USCertifications.init)
      <^> json <|| ["certifications", "US"]
  }
}

extension TMDBResponseEntity.PopularPeople {
  public static func decode(_ json: JSON) -> Decoded<TMDBResponseEntity.PopularPeople> {
    return curry(TMDBResponseEntity.PopularPeople.init)
      <^> json <| "page"
      <*> json <|| "results"
      <*> json <| "total_results"
      <*> json <| "total_pages"
  }
}

extension TMDBResponseEntity.MovieDiscover {
  public static func decode(_ json: JSON) -> Decoded<TMDBResponseEntity.MovieDiscover> {
    return curry(TMDBResponseEntity.MovieDiscover.init)
      <^> json <| "page"
      <*> json <|| "results"
      <*> json <| "total_results"
      <*> json <| "total_pages"
  }
}

extension TMDBResponseEntity.MovieGenreResponse {
  public static func decode(_ json: JSON) -> Decoded<TMDBResponseEntity.MovieGenreResponse> {
    return curry(TMDBResponseEntity.MovieGenreResponse.init)
      <^> json <|| "genres"
  }
}

