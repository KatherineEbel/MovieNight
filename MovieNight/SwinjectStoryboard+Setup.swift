//
//  SwinjectStoryBoardExtension.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import SwinjectStoryboard

// register all dependencies for injection
extension SwinjectStoryboard {
  class func setup() {
    // Models
    defaultContainer.register(MovieNightNetworking.self) { _ in MovieNightNetworking() }
    defaultContainer.register(TMDBClient.self) { resolver in
      TMDBClient(network: resolver.resolve(MovieNightNetworking.self)!)
    }
    // View model dependencies
    defaultContainer.register(SearchResultsTableViewModeling.self) { resolver in
      SearchResultsTableViewModel(client: resolver.resolve(TMDBClient.self)!)
    }
    
    // registers all of the controllers
    defaultContainer.storyboardInitCompleted(UINavigationController.self) { _,_ in }
    defaultContainer.storyboardInitCompleted(HomeViewController.self) { _, _ in }
    defaultContainer.storyboardInitCompleted(SearchResultsController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
    }
  }
}
