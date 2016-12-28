//
//  DetailViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/26/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

public protocol DetailViewModelProtocol {
  var entity: TMDBEntityProtocol? { get set }
}

public final class DetailViewModel: DetailViewModelProtocol {
  public var entity: TMDBEntityProtocol? = nil
}
