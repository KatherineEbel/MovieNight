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
  var title: String { get }
  func getThumbnailImage() -> SignalProducer<UIImage,NoError>
}

public final class SearchResultsTableViewCellModel: SearchResultsTableViewCellModeling {
  public var title: String
  private var imagePath: String?
  private let network: MovieNightNetworkProtocol! = MovieNightNetwork()
  init(title: String, imagePath: String?) {
    self.title = title
    self.imagePath = imagePath
  }
  
  public func getThumbnailImage() -> SignalProducer<UIImage, NoError> {
    return network.requestImage(search: .image(size: TMDB.posterThumbNailSize!, imagePath: imagePath!))
      .flatMapError { _ in SignalProducer<UIImage, NoError>.empty }
  }
}
