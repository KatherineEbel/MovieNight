//
//  TableViewCellMode.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift
import Result

public protocol SearchResultsTableViewCellModeling: class {
  var data: Property<TMDBEntityProtocol> { get }
  func getThumbnailImage() -> SignalProducer<UIImage, NoError>?
}

public final class SearchResultsTableViewCellModel: SearchResultsTableViewCellModeling {
  public var _data: MutableProperty<TMDBEntityProtocol>
  private var network: MovieNightNetworkProtocol = MovieNightNetwork.networking
  public var data: Property<TMDBEntityProtocol> {
    return Property(_data)
  }
  init(model: TMDBEntityProtocol) {
    self._data = MutableProperty(model)
  }
  
  public func getThumbnailImage() -> SignalProducer<UIImage, NoError>? {
    guard let size = TMDBEndpoint.posterThumbNailSize, let path = data.value.imagePath
    else {
      return nil
    }
    return network.requestImage(search: .image(size: size, imagePath: path))
      .flatMapError { _ in SignalProducer<UIImage, NoError>.empty }.take(first: 1)
  }
  
  deinit {
    print("Cell model deinit")
  }
}
