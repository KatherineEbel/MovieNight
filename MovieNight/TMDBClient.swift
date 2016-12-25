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

// MARK: Configuration
public struct TMDBConfiguration: Decodable {
  let images: TMDBImageConfiguration
  let change_keys: [String]
  
  public static func decode(_ json: JSON) -> Decoded<TMDBConfiguration> {
    return curry(TMDBConfiguration.init)
      <^> json <| "images"
      <*> json <|| "change_keys"
  }
}


public struct TMDBImageConfiguration: Decodable {
  let base_url: String
  let secure_base_url: String
  let backdrop_sizes: [String]
  let logo_sizes: [String]
  let poster_sizes: [String]
  let profile_sizes: [String]
  let still_sizes: [String]
  
  public static func decode(_ json: JSON) -> Decoded<TMDBImageConfiguration> {
    return curry(TMDBImageConfiguration.init)
      <^> json <| "base_url"
      <*> json <| "secure_base_url"
      <*> json <|| "backdrop_sizes"
      <*> json <|| "logo_sizes"
      <*> json <|| "poster_sizes"
      <*> json <|| "profile_sizes"
      <*> json <|| "still_sizes"
  }
}

public protocol MovieNightConfigurationProtocol {
  var configuration: TMDBConfiguration! { get set }
}

public struct MovieNightConfiguration: MovieNightConfigurationProtocol {
  public var configuration: TMDBConfiguration!
}


// MARK: TMDBEndpoint
public enum TMDBEndpointError: Error {
  case incorrectURLString(Error)
  case parsingError(Error)
  case createPhotoError(Error)
  case none
}
public enum TMDB: URLRequestConvertible {
  case configuration
  case popularPeople(page: Int)
  case movieGenres
  case movieDiscover(page: Int, actorIDs: Set<Int>, genreIDs: Set<Int>, rating: String)
  case ratings
  case image(size: String, imagePath: String)
//  To build an image URL, you will need 3 pieces of data. The base_url, size and file_path. Simply combine them all and you will have a fully qualified URL. Here’s an example URL:
//  
//  https://image.tmdb.org/t/p/w500/8uO0gUM8aNqYLs1OsTBQiXu0fEv.jpg
  
  static let baseURLString = "https://api.themoviedb.org/3/"
  static let api_key = MovienightKeys().api_key()!
  static let sortPreference = "popularity.desc"
  static let imageURLString = TMDB.movieNightConfig?.images.secure_base_url
  static var posterThumbNailSize: String? {
    return (TMDB.movieNightConfig?.images.poster_sizes)?.first ?? nil
    
  }
  static var actorThumbNailSize: String? {
    return (TMDB.movieNightConfig?.images.profile_sizes)?.first ?? nil
  }
  
  var urlString: String? {
    switch self {
    case .image:
      print(TMDB.imageURLString!)
      return TMDB.imageURLString
    default:
      return TMDB.baseURLString
    }
  }
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
  
  var params: [String: Any]? {
    switch self {
    case .configuration:
      return [ParamKeys.api_key.rawValue: TMDB.api_key]
      case .popularPeople(page: let page):
        return [ParamKeys.api_key.rawValue: TMDB.api_key,
                ParamKeys.page.rawValue: page]
      case .movieGenres:
        return [ParamKeys.api_key.rawValue: TMDB.api_key]
      case .ratings:
        return [ParamKeys.api_key.rawValue: TMDB.api_key]
      case .movieDiscover(page: let page, actorIDs: let actors, genreIDs: let genres, rating: let rating):
        let actorsValue = actors.map { String($0) }.joined(separator: "|")
        let genresValue = genres.map { String($0) }.joined(separator: "|")
        return [ParamKeys.api_key.rawValue: TMDB.api_key,
                ParamKeys.sort_by.rawValue: TMDB.sortPreference,
                ParamKeys.certification_country.rawValue: "US",
                ParamKeys.certificationlte.rawValue: rating,
                ParamKeys.page.rawValue: page,
                ParamKeys.with_genres.rawValue: genresValue,
                ParamKeys.with_cast.rawValue: actorsValue]
      case .image: return nil
    }
  }
  
  public func asURLRequest() throws -> URLRequest {
    let result: (path: String, parameters: Parameters?) = {
      switch self {
        case .configuration: return ("configuration", params)
        case .popularPeople: return ("person/popular", params)
        case .movieGenres: return ("genre/movie/list", params)
        case .ratings: return ("certification/movie/list", params)
        case .movieDiscover: return ("discover/movie", params)
        case .image(size: let size, imagePath: let path):
          let components = ("\(size)/\(path)", params)
          print(components)
          return components
      }
    }()
    let url = try urlString!.asURL()
    let urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    let encoded = try URLEncoding.default.encode(urlRequest, with: result.parameters)
    return encoded
  }
  
}

extension TMDB {
  public static var movieNightConfig: TMDBConfiguration? {
    let configuration = UserDefaults.standard.object(forKey: "configuration")
    if let configuration = configuration,
      let tmdbConfig: TMDBConfiguration = decode(configuration) {
      return tmdbConfig
    } else {
      return setConfig()
    }
  }
  public static func setConfig() -> TMDBConfiguration? {
    let json = getConfigJSON()
    if let json = json {
      UserDefaults.standard.setValue(json, forKey: "configuration")
      let config: TMDBConfiguration? = decode(json)
      return config
    } else {
      print("no config")
      return nil
    }
  }
  
  public static func getConfigJSON() -> Any? {
    let network = MovieNightNetwork()
    let result = network.requestJSON(search: .configuration).single()
    switch result?.value {
      case .some(let json): return json
      case .none: return nil
    }
  }
}

public protocol MovieNightNetworkProtocol {
  func requestJSON(search: TMDB) -> SignalProducer<Any, TMDBEndpointError>
  func requestImage(search: TMDB) -> SignalProducer<UIImage, TMDBEndpointError>
}

public final class MovieNightNetwork: MovieNightNetworkProtocol {
  public func requestImage(search: TMDB) -> SignalProducer<UIImage, TMDBEndpointError> {
    return SignalProducer { observer, disposable in
      Alamofire.request(search).responseData { response in
        switch response.result {
          case .success(let data):
            if let image = UIImage(data: data) {
              observer.send(value: image)
            } else {
              let defaultImage = UIImage(named: "mov-clapper")!
              observer.send(value: defaultImage)
            }
          case .failure(let dataError):
            observer.send(error: .createPhotoError(dataError))
        }
      }
    }
  }

  private let queue = DispatchQueue(label: "MovieNight.MovieNightNetworking.Queue")
  public init() { }
   public func requestJSON(search: TMDB) -> SignalProducer<Any, TMDBEndpointError> {
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
  private let network: MovieNightNetworkProtocol
  public init(network: MovieNightNetworkProtocol) {
    self.network = network
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

extension TMDBClient {
}
