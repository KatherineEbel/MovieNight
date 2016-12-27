//
//  DetailViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/26/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

protocol DetailViewModelProtocol {
  var entity: TMDBEntity { get }
}

public final class DetailViewModel {
  private let _entity: TMDBEntity
  public var entity: TMDBEntity {
    return _entity
  }
  public init(entity: TMDBEntity) {
    self._entity = entity
  }
}
