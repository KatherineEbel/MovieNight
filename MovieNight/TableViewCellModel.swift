//
//  TableViewCellMode.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

public protocol SearchResultsTableViewCellModeling {
  var title: String { get }
}

public final class SearchResultsTableViewCellModel: SearchResultsTableViewCellModeling {
  public var title: String
  
  internal init(title: String ) {
    self.title = title
  }
}
