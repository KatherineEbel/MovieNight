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
//    defaultContainer.register(MovieNightConfigurationProtocol.self) { _ in MovieNightConfiguration(configuration: nil) }
//      .initCompleted { _, config in
//        var copy = config
//        TMDB.getConfig().producer.on { value in
//          copy.configuration = value
//        }.observe(on: UIScheduler()).start()
//      }.inObjectScope(.container)
    defaultContainer.register(TMDBSearching.self) { resolver in
      TMDBClient(network: resolver.resolve(MovieNightNetworkProtocol.self)!)
      }.inObjectScope(.container)
    
    defaultContainer.register(MoviePreferenceProtocol.self) { resolver in MovieNightPreference() }
    defaultContainer.register(MovieWatcherProtocol.self) { resolver, name in
      MovieNightWatcher(name: name)
    }
    
    
       // page: Int, actorIDs: [Int], genreIDs: [Int], rating: String
    // View model dependencies
    defaultContainer.register(SearchResultsTableViewModeling.self) { resolver in
      SearchResultsTableViewModel(client: resolver.resolve(TMDBSearching.self)!)
    }.inObjectScope(.container)
//    defaultContainer.register(SearchResultsTableViewCellModeling.self) { resolver, title, path in
//      SearchResultsTableViewCellModel(title: title, imagePath: path)
//    }
    // set watchers property for WatcherViewModel
    defaultContainer.register(WatcherViewModelProtocol.self) { resolver in
      let name1: String = "Watcher 1"
      let name2: String = "Watcher 2"
      guard let watcher1 = resolver.resolve(MovieWatcherProtocol.self, argument: name1),
      let watcher2 = resolver.resolve(MovieWatcherProtocol.self, argument: name2) else {
        print("No watchers")
        fatalError("Couldn't complete!")
      }
      return WatcherViewModel(watchers: [watcher1, watcher2])
      }.inObjectScope(.container)
    // registers all of the controllers
    defaultContainer.storyboardInitCompleted(UINavigationController.self){ _, _ in }
    defaultContainer.storyboardInitCompleted(HomeViewController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    
    defaultContainer.storyboardInitCompleted(ViewResultsController.self) { resolver, controller in
        controller.tableViewModel = resolver.resolve(SearchResultsTableViewModeling.self)
        controller.watcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)
    }
    
    defaultContainer.storyboardInitCompleted(UITabBarController.self){ _, _ in }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "RatingNav"){ _, _ in
    }
    defaultContainer.storyboardInitCompleted(RatingPickerController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "GenreNav"){ _, _ in
    }
    defaultContainer.storyboardInitCompleted(GenrePickerController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "ActorNav"){ _, _ in
    }
    defaultContainer.storyboardInitCompleted(PeoplePickerController.self) { resolver, controller in
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
  }
}
