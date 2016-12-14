//
//  TableViewCellMode.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveCocoa


public protocol SearchResultsTableViewCellModeling {
  var id: Int { get }
  var name: String { get }
}

public final class SearchResultsTableViewCellModel: SearchResultsTableViewCellModeling {
  public let id: Int
  public let name: String
  
  internal init(actor: TMDBEntity.Actor) {
    id = actor.id
    name = actor.name
  }
}