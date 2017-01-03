//
//  TMDBEndpoint.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/29/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation
import Alamofire
import Argo
import Keys

public enum TMDBEndpointError: Error {
  case incorrectURLString(Error)
  case parsingError(Error)
  case createPhotoError(Error)
  case none
}
public enum TMDBEndpoint: URLRequestConvertible {
  case configuration
  case popularPeople(page: Int)
  case movieGenres
  case movieDiscover(page: Int, discover: MovieDiscoverProtocol)
  case ratings
  case image(size: String, imagePath: String)
//  To build an image URL, you will need 3 pieces of data. The base_url, size and file_path. Simply combine them all and you will have a fully qualified URL. Here’s an example URL:
//  
//  https://image.tmdb.org/t/p/w500/8uO0gUM8aNqYLs1OsTBQiXu0fEv.jpg
  
  static let baseURLString = "https://api.themoviedb.org/3/"
  static let api_key = MovienightKeys().api_key()!
  static let sortPreference = "popularity.desc"
  static let imageURLString = TMDBEndpoint.movieNightConfig?.images.secure_base_url
  static var posterThumbNailSize: String? {
    return (TMDBEndpoint.movieNightConfig?.images.poster_sizes)?[3] ?? nil
    
  }
  static var actorThumbNailSize: String? {
    return (TMDBEndpoint.movieNightConfig?.images.profile_sizes)?.first ?? nil
  }
  
  var urlString: String? {
    switch self {
    case .image:
      return TMDBEndpoint.imageURLString
    default:
      return TMDBEndpoint.baseURLString
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
      return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key]
      case .popularPeople(page: let page):
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key,
                ParamKeys.page.rawValue: page]
      case .movieGenres:
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key]
      case .ratings:
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key]
      case .movieDiscover(page: let page, discover: let movieDiscover):
        let actorsValue = movieDiscover.actorIDs.map { String($0) }.joined(separator: "|")
        let genresValue = movieDiscover.genreIDs.map { String($0) }.joined(separator: "|")
        return [ParamKeys.api_key.rawValue: TMDBEndpoint.api_key,
                ParamKeys.sort_by.rawValue: TMDBEndpoint.sortPreference,
                ParamKeys.certification_country.rawValue: "US",
                ParamKeys.certificationlte.rawValue: movieDiscover.maxRating,
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
        case .image(size: let size, imagePath: let path): return  ("\(size)\(path)", params)
      }
    }()
    let url = try urlString!.asURL()
    let urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    let encoded = try URLEncoding.default.encode(urlRequest, with: result.parameters)
    return encoded
  }
  
}

extension TMDBEndpoint {
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