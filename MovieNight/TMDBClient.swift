//
//  TMDBClient.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/11/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation

import ReactiveSwift
import Result
import Argo

enum TMDBColor {
  case green
  case blue
}

extension TMDBColor {
  static func ColorFromRGB(color: TMDBColor, withAlpha alpha: CGFloat) -> UIColor {
    switch color {
    case .green:
      return UIColor(red: 1/255.0, green: 210/255.0, blue: 119/255.0, alpha: alpha)
    case .blue:
      return UIColor(red: 8/255.0, green: 28/255.0, blue: 36/255.0, alpha: alpha)
    }
  
  }
}
enum TMDBClientError: Error {
  case invalidJson(Error)
}

extension TMDBClientError: LocalizedError {
  var errorDescription: String? {
    switch self {
      case .invalidJson(let error): return error.localizedDescription
    }
  }
}


public protocol TMDBClientPrototcol {
  func searchPopularPeople(pageNumber: Int) -> SignalProducer<TMDBResponseEntity.PopularPeople, TMDBEndpointError>
  func searchMovieGenres() -> SignalProducer<TMDBResponseEntity.MovieGenreResponse, TMDBEndpointError>
  func searchUSRatings() -> SignalProducer<TMDBResponseEntity.USCertifications, TMDBEndpointError>
  func searchMovieDiscover(page: Int, discover: MovieDiscoverProtocol) -> SignalProducer<TMDBResponseEntity.MovieDiscover, TMDBEndpointError>
}



public final class TMDBClient: TMDBClientPrototcol {
  private let network: MovieNightNetworkProtocol
  public init(network: MovieNightNetworkProtocol) {
    print("Client init")
    self.network = network
  }
  
  public func searchPopularPeople(pageNumber: Int) -> SignalProducer<TMDBResponseEntity.PopularPeople, TMDBEndpointError> {
    return network.requestJSON(search: .popularPeople(page: pageNumber))
      .retry(upTo: 2)
      .attemptMap { json in
          let result: Decoded<TMDBResponseEntity.PopularPeople> = decode(json)
          switch result {
            case .success(let value):
              return Result(value: value)
            case .failure(let error):
              return Result(error: .parsingError(error))
          }
      }.take(first: 1)
  }
  
  public func searchMovieGenres() -> SignalProducer<TMDBResponseEntity.MovieGenreResponse, TMDBEndpointError> {
    return network.requestJSON(search: .movieGenres)
      .retry(upTo: 2)
      .attemptMap { json in
        let result: Decoded<TMDBResponseEntity.MovieGenreResponse> = decode(json)
        switch result {
          case .success(let value): return Result(value: value)
          case .failure(let error): return Result(error: .parsingError(error))
        }
    }.take(first: 1)
  }
  
  public func searchUSRatings() -> SignalProducer<TMDBResponseEntity.USCertifications, TMDBEndpointError> {
    return network.requestJSON(search: .ratings)
      .attemptMap { json in
        let result: Decoded<TMDBResponseEntity.USCertifications> = decode(json)
        switch result {
          case .success(let value): return Result(value: value)
          case .failure(let error): return Result(error: .parsingError(error))
        }
    }.take(first: 1)
  }
  
  public func searchMovieDiscover(page: Int, discover: MovieDiscoverProtocol) -> SignalProducer<TMDBResponseEntity.MovieDiscover, TMDBEndpointError> {
    return network.requestJSON(search: .movieDiscover(page: page, discover: discover))
      .attemptMap { json in
        let result: Decoded<TMDBResponseEntity.MovieDiscover> = decode(json)
        switch result {
          case .success(let value): return Result(value: value)
          case .failure(let error): return Result(error: .parsingError(error))
        }
      }.take(first: 1)
  }
}
