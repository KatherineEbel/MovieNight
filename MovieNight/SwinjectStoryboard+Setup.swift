//
//  SwinjectStoryboard+Setup.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import SwinjectStoryboard
import ReactiveSwift
import Result

extension SwinjectStoryboard {
  class func setup() {
    // Register Models
    defaultContainer.register(MovieNightNetworkProtocol.self) { _ in MovieNightNetwork() }
    defaultContainer.register(TMDBClientPrototcol.self) { resolver in
      TMDBClient(network: resolver.resolve(MovieNightNetworkProtocol.self)!)
      }.inObjectScope(.container)
    
    defaultContainer.register(MoviePreferenceProtocol.self) { resolver in MovieNightPreference() }
    defaultContainer.register(MovieWatcherProtocol.self) { resolver, name in
      MovieNightWatcher(name: name)
    }
       // page: Int, actorIDs: [Int], genreIDs: [Int], rating: String
    // View model dependencies
    defaultContainer.register(SearchResultsTableViewModeling.self) { resolver in
      SearchResultsTableViewModel(client: resolver.resolve(TMDBClientPrototcol.self)!)
    }.inObjectScope(.container)
    // set watchers property for WatcherViewModel
    defaultContainer.register(WatcherViewModelProtocol.self) { resolver in
      let watcher1 = MovieNightWatcher(name: "Watcher 1")
      let watcher2 = MovieNightWatcher(name: "Watcher 2")
      return WatcherViewModel(watchers: [watcher1, watcher2])
    }.inObjectScope(.container)
    defaultContainer.register(DetailViewModelProtocol.self) { _ in DetailViewModel() }
    
    // registers all of the controllers
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "HomeNav"){ _, _ in }
    defaultContainer.storyboardInitCompleted(HomeViewController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    
    defaultContainer.storyboardInitCompleted(ViewResultsController.self) { resolver, controller in
      controller._entityType = .media
      controller.tableViewModel = resolver.resolve(SearchResultsTableViewModeling.self)
      controller.watcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)
    }
    
    defaultContainer.storyboardInitCompleted(UITabBarController.self){ _, _ in }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "RatingNav"){ _, _ in
    }
    defaultContainer.storyboardInitCompleted(MovieNightSearchController.self, name: "actors") { resolver, controller in
      controller._entityType = .actor
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "GenreNav"){ _, _ in
    }
    defaultContainer.storyboardInitCompleted(MovieNightSearchController.self, name: "genres") { resolver, controller in
      controller._entityType = .movieGenre
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "ActorNav"){ _, _ in
    }
    defaultContainer.storyboardInitCompleted(MovieNightSearchController.self, name: "ratings") { resolver, controller in
      controller._entityType = .rating
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(DetailController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(DetailViewModelProtocol.self)!
    }
  }
}
