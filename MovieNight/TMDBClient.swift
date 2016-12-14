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

protocol Searching {
  func searchPopularPeople(pageNumber: Int) -> SignalProducer<PopularPeopleResponseEntity, TMDBRouterError>
}

enum TMDBRouterError: Error {
  case incorrectURLString(Error)
  case parsingError(Error)
  case none
}
enum TMDBRouter: URLRequestConvertible {
  case popularPeople(language: String, page: Int)
  
  static let baseURLString = "https://api.themoviedb.org/3/"
  static let api_key = MovienightKeys().api_key()!
  
  enum ParamKeys:String {
    case api_key
    case language
    case page
  }
  
  var params: [String: Any] {
    switch self {
    case .popularPeople(language: let language, page: let page):
      return [ParamKeys.api_key.rawValue: TMDBRouter.api_key,
              ParamKeys.language.rawValue: language,
              ParamKeys.page.rawValue: page]
    }
  }
  
  func asURLRequest() throws -> URLRequest {
    let result: (path: String, parameters: Parameters) = {
      switch self {
        case .popularPeople:
          return ("person/popular", params)
      }
    }()
    let url = try TMDBRouter.baseURLString.asURL()
    let urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    return try URLEncoding.default.encode(urlRequest, with: result.parameters)
  }
  
}

struct GenresResponseEntity {
  let genres: [JSON]
}

public final class MovieNightNetworking {
  private let queue = DispatchQueue(label: "MovieNight.MovieNightNetworking.Queue")
  func requestJSON(search: TMDBRouter) -> SignalProducer<Any, TMDBRouterError> {
    return SignalProducer { observer, disposable in
      Alamofire.request(search).responseJSON(queue: self.queue, options: JSONSerialization.ReadingOptions.mutableContainers) { response in
        switch response.result {
          case .success(let value):
              observer.send(value: value)
              observer.sendCompleted()
          case .failure(let error):
            observer.send(error: TMDBRouterError.incorrectURLString(error))
        }
      }
    }
  }
}

enum TMDBSearchClientError: Error {
  case invalidJson(Error)
}

public final class TMDBSearchController: Searching {
  private let network: MovieNightNetworking
  private let language: String
  public init(network: MovieNightNetworking) {
    self.network = network
    self.language = "en-US"
  }
  func searchPopularPeople(pageNumber: Int) -> SignalProducer<PopularPeopleResponseEntity, TMDBRouterError> {
    return network.requestJSON(search: .popularPeople(language: language, page: pageNumber))
      .attemptMap { json in
          let result: Decoded<PopularPeopleResponseEntity> = decode(json)
          switch result {
            case .success(let value):
              return Result(value: value)
            case .failure(let error):
              return Result(error: .parsingError(error))
          }
      }
  }
}
