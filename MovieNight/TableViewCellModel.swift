//
//  TableViewCellMode.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift
import Result

public protocol SearchResultsTableViewCellModeling {
  var data: Property<TMDBEntityProtocol> { get }
  var imageUpdated: MutableProperty<Bool> { get }
  func getThumbnailImage() -> SignalProducer<UIImage, NoError>
}

public final class SearchResultsTableViewCellModel: SearchResultsTableViewCellModeling {
  public var _data: MutableProperty<TMDBEntityProtocol>
  private let network: MovieNightNetworkProtocol! = MovieNightNetwork()
  public var imageUpdated = MutableProperty<Bool>(false)
  public var data: Property<TMDBEntityProtocol> {
    return Property(_data)
  }
  init(model: TMDBEntityProtocol) {
    self._data = MutableProperty(model)
  }
  
  public func getThumbnailImage() -> SignalProducer<UIImage, NoError> {
    return network.requestImage(search: .image(size: TMDBEndpoint.posterThumbNailSize!, imagePath: data.value.imagePath!))
      .flatMapError { _ in SignalProducer<UIImage, NoError>.empty }
  }
}
