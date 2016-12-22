//
//  TMDBClient.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/11/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation

import Argo
import Runes
import Curry
import Alamofire
import Keys
import ReactiveSwift
import Result


public enum TMDBEndpointError: Error {
  case incorrectURLString(Error)
  case parsingError(Error)
  case none
}
enum TMDBEndpoint: URLRequestConvertible {
  case popularPeople(page: Int)
  case movieGenres
  case movieDiscover(page: Int, actorIDs: Set<Int>, genreIDs: Set<Int>, rating: String)
  case ratings
  
  static let baseURLString = "https://api.themoviedb.org/3/"
  static let api_key = MovienightKeys().api_key()!
  static let sortPreference = "popularity.desc"
  
  enum ParamKeys:String {
    case api_key
    case language
    case page
    case sort_by
    case certification_country
    case certificationlte = "certification.lte"
    case with_cast
    case with_genres
  }
  
  var params: [String: Any] {
    switch self {
      case .popularPeople(page: let page):
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key,
                ParamKeys.page.rawValue: page]
      case .movieGenres:
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key]
      case .ratings:
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key]
      case .movieDiscover(page: let page, actorIDs: let actors, genreIDs: let genres, rating: let rating):
        let actorsValue = actors.map { String($0) }.joined(separator: "|")
        let genresValue = genres.map { String($0) }.joined(separator: "|")
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key,
                ParamKeys.sort_by.rawValue: TMDBEndpoint.sortPreference,
                ParamKeys.certification_country.rawValue: "US",
                ParamKeys.certificationlte.rawValue: rating,
                ParamKeys.page.rawValue: page,
                ParamKeys.with_genres.rawValue: genresValue,
                ParamKeys.with_cast.rawValue: actorsValue]
    }
  }
  
  public func asURLRequest() throws -> URLRequest {
    let result: (path: String, parameters: Parameters) = {
      switch self {
        case .popularPeople: return ("person/popular", params)
        case .movieGenres: return ("genre/movie/list", params)
        case .ratings: return ("certification/movie/list", params)
        case .movieDiscover: return ("discover/movie", params)
      }
    }()
    let url = try TMDBEndpoint.baseURLString.asURL()
    let urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    return try URLEncoding.default.encode(urlRequest, with: result.parameters)
  }
  
}


public final class MovieNightNetworking {
  private let queue = DispatchQueue(label: "MovieNight.MovieNightNetworking.Queue")
  public init() { }
   func requestJSON(search: TMDBEndpoint) -> SignalProducer<Any, TMDBEndpointError> {
    return SignalProducer { observer, disposable in
      Alamofire.request(search).responseJSON(queue: self.queue, options: JSONSerialization.ReadingOptions.mutableContainers) { response in
        switch response.result {
          case .success(let value):
              observer.send(value: value)
              observer.sendCompleted()
          case .failure(let error):
            observer.send(error: TMDBEndpointError.incorrectURLString(error))
        }
      }
    }
  }
}

enum TMDBClientError: Error {
  case invalidJson(Error)
}


public protocol TMDBSearching {
  func searchPopularPeople(pageNumber: Int) -> SignalProducer<TMDBResponseEntity.PopularPeople, TMDBEndpointError>
  func searchMovieGenres() -> SignalProducer<TMDBResponseEntity.MovieGenreResponse, TMDBEndpointError>
  func searchUSRatings() -> SignalProducer<TMDBResponseEntity.USCertifications, TMDBEndpointError>
  func searchMovieDiscover(page: Int, actorIDs: Set<Int>, genreIDs: Set<Int>, rating: String) -> SignalProducer<TMDBResponseEntity.MovieDiscover, TMDBEndpointError>
}

public final class TMDBClient: TMDBSearching {
  private let network: MovieNightNetworking
  public let language: String
  public init(network: MovieNightNetworking) {
    self.network = network
    self.language = "en-US"
  }
  public func searchPopularPeople(pageNumber: Int) -> SignalProducer<TMDBResponseEntity.PopularPeople, TMDBEndpointError> {
    return network.requestJSON(search: .popularPeople(page: pageNumber))
      .attemptMap { json in
          let result: Decoded<TMDBResponseEntity.PopularPeople> = decode(json)
          switch result {
            case .success(let value):
              return Result(value: value)
            case .failure(let error):
              return Result(error: .parsingError(error))
          }
      }
  }
  
  public func searchMovieGenres() -> SignalProducer<TMDBResponseEntity.MovieGenreResponse, TMDBEndpointError> {
    return network.requestJSON(search: .movieGenres)
      .attemptMap { json in
        let result: Decoded<TMDBResponseEntity.MovieGenreResponse> = decode(json)
        switch result {
          case .success(let value): return Result(value: value)
          case .failure(let error): return Result(error: .parsingError(error))
        }
    }
  }
  
  public func searchUSRatings() -> SignalProducer<TMDBResponseEntity.USCertifications, TMDBEndpointError> {
    return network.requestJSON(search: .ratings)
      .attemptMap { json in
        let result: Decoded<TMDBResponseEntity.USCertifications> = decode(json)
        switch result {
          case .success(let value): return Result(value: value)
          case .failure(let error): return Result(error: .parsingError(error))
        }
    }
  }
  
  public func searchMovieDiscover(page: Int, actorIDs: Set<Int>, genreIDs: Set<Int>, rating: String) -> SignalProducer<TMDBResponseEntity.MovieDiscover, TMDBEndpointError> {
    return network.requestJSON(search: .movieDiscover(page: page, actorIDs: actorIDs, genreIDs: genreIDs, rating: rating))
      .attemptMap { json in
        let result: Decoded<TMDBResponseEntity.MovieDiscover> = decode(json)
        switch result {
          case .success(let value): return Result(value: value)
          case .failure(let error): return Result(error: .parsingError(error))
        }
      }
  }
}
