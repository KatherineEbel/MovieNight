//
//  SwinjectStoryboard+Setup.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import SwinjectStoryboard

extension SwinjectStoryboard {
  class func setup() {
    defaultContainer.register(MovieNightNetworking.self) { _ in MovieNightNetworking() }
    defaultContainer.register(TMDBSearching.self) { resolver in
      TMDBClient(network: resolver.resolve(MovieNightNetworking.self)!)
    }
    // View model dependencies
    defaultContainer.register(SearchResultsTableViewModeling.self) { resolver in
      SearchResultsTableViewModel(client: resolver.resolve(TMDBSearching.self)!)
    }
    defaultContainer.register(WatcherViewModeling.self) { _ in WatcherViewModel() }
    // registers all of the controllers
    defaultContainer.storyboardInitCompleted(HomeViewController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(WatcherViewModeling.self)!
    }
    defaultContainer.storyboardInitCompleted(PeoplePickerController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
    }
  }
}
