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
// uncomment line below if using cocoa-pods keys to store api_key
//import Keys

public enum TMDBEndpointError: Error {
  case incorrectURLString(Error)
  case parsingError(Error)
  case createPhotoError(Error)
  case none
}

extension TMDBEndpointError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case .incorrectURLString(let error): return error.localizedDescription
      case .parsingError(let error):
        if let error = error as? DecodeError {
          return "Unable to parse data due to: \(error.description)"
        } else {
          return "Unknown data parsing error."
        }
      case .createPhotoError(let error): return error.localizedDescription
      case .none: return "Error fetching TMDB configuration"
    }
  }
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
// uncomment line below if using cocoa-pods keys to store api_key
//  static let api_key = MovienightKeys().api_key()!
  static let api_key = ""
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
  
  var path: String {
    switch self {
      case .configuration: return "configuration"
      case .popularPeople: return "person/popular"
      case .movieGenres: return "genre/movie/list"
      case .ratings: return "certification/movie/list"
      case .movieDiscover: return "discover/movie"
      case .image(size: let size, imagePath: let path): return "\(size)\(path)"
    }
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
  
  // encodes the url request with given parameters for each endpoint
  public func asURLRequest() throws -> URLRequest {
    let result: (path: String, parameters: Parameters?) = (path, params)
    let url = try urlString!.asURL()
    let urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    let encoded = try URLEncoding.default.encode(urlRequest, with: result.parameters)
    return encoded
  }
  
}

extension TMDBEndpoint {
  // if config hasn't already been fetched and saved to user defaults, then fetch, else just
  // decode the config in user defaults
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
    let result = MovieNightNetwork.networking.requestJSON(search: .configuration).single()
    switch result?.value {
      case .some(let json): return json
      case .none: return nil
    }
  }
}
