//
//  MovieNightNetworking.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/29/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation
import ReactiveSwift
import Alamofire

public protocol MovieNightNetworkProtocol {
  func requestJSON(search: TMDBEndpoint) -> SignalProducer<Any, TMDBEndpointError>
  func requestImage(search: TMDBEndpoint) -> SignalProducer<UIImage, TMDBEndpointError>
}

public final class MovieNightNetwork: MovieNightNetworkProtocol {
  public func requestImage(search: TMDBEndpoint) -> SignalProducer<UIImage, TMDBEndpointError> {
    return SignalProducer { observer, disposable in
      Alamofire.request(search).validate().responseData { response in
        switch response.result {
          case .success(let data):
            if let image = UIImage(data: data) {
              observer.send(value: image)
              observer.sendCompleted()
            } else {
              let defaultImage = UIImage(named: "mov-clapper")!
              observer.send(value: defaultImage)
              observer.sendCompleted()
            }
          case .failure(let dataError):
            observer.send(error: .createPhotoError(dataError))
        }
      }
    }.take(first: 1)
  }

  private let queue = DispatchQueue(label: "MovieNight.MovieNightNetworking.Queue")
  static let networking = MovieNightNetwork()
  public init() {}
  public func requestJSON(search: TMDBEndpoint) -> SignalProducer<Any, TMDBEndpointError> {
    return SignalProducer {  observer, disposable in
      Alamofire.request(search)
        .validate()
        .responseJSON(queue: self.queue, options: JSONSerialization.ReadingOptions.mutableContainers) { response in
        switch response.result {
          case .success(let value):
              observer.send(value: value)
              observer.sendCompleted()
          case .failure(let error):
            observer.send(error: TMDBEndpointError.incorrectURLString(error))
            observer.sendCompleted()
        }
      }
    }.take(first: 1)
  }
  
  deinit {
    print("Networking deinit")
  }
}
