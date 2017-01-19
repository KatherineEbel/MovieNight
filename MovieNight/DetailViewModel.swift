//
//  DetailViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/26/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

// Detail viewmodel only needs an entity type so it can display a name/title and a description of that entity.
public protocol DetailViewModelProtocol {
  var entity: TMDBEntityProtocol? { get set }
}

public final class DetailViewModel: DetailViewModelProtocol {
  public var entity: TMDBEntityProtocol? = nil
}
