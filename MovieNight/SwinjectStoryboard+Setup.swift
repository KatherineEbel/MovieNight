//
//  SwinjectStoryBoardExtension.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import SwinjectStoryboard

extension SwinjectStoryboard {
  class func setup() {
    // Models
    defaultContainer.register(MovieNightNetworking.self) { _ in MovieNightNetworking() }
    defaultContainer.register(TMDBSearchController.self) { r in
      TMDBSearchController(network: r.resolve(MovieNightNetworking.self)!)
    }
    // View models
    defaultContainer.register(SearchTableViewModeling.self) { r in
      MovieNightTableViewModel(searchController: r.resolve(TMDBSearchController.self)!)
    }
    
    // Views
    defaultContainer.storyboardInitCompleted(UINavigationController.self) { _,_ in }
    defaultContainer.storyboardInitCompleted(HomeViewController.self) { _, _ in }
    defaultContainer.storyboardInitCompleted(SearchTableViewController.self) { r, c in
      c.viewModel = r.resolve(SearchTableViewModeling.self)!
    }
  }
}
