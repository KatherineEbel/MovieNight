//
//  SwinjectStoryboard+Setup.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/17/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import SwinjectStoryboard
import ReactiveSwift

extension SwinjectStoryboard {
  class func setup() {
    // Register Models
    defaultContainer.register(MovieNightNetworking.self) { _ in MovieNightNetworking() }
    defaultContainer.register(TMDBSearching.self) { resolver in
      TMDBClient(network: resolver.resolve(MovieNightNetworking.self)!)
    }
    defaultContainer.register(MoviePreferenceProtocol.self) { resolver in MovieNightPreference() }
    defaultContainer.register(MovieWatcherProtocol.self) { resolver, name in
      MovieNightWatcher(name: name)
    }
    
    // View model dependencies
    defaultContainer.register(SearchResultsTableViewModeling.self) { resolver in
      SearchResultsTableViewModel(client: resolver.resolve(TMDBSearching.self)!)
    }.inObjectScope(.container)
    
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
    defaultContainer.storyboardInitCompleted(UINavigationController.self){ _, _ in
      // FIXME: Remove debug statements
      print("Home Nav")
    }
    defaultContainer.storyboardInitCompleted(HomeViewController.self) { resolver, controller in
      print("Home Controller")
      controller.viewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(UITabBarController.self){ _, _ in }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "RatingNav"){ _, _ in
      print("Rating Nav")
    }
    defaultContainer.storyboardInitCompleted(RatingPickerController.self) { resolver, controller in
      print("Rating controller")
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "GenreNav"){ _, _ in
      print("Genre Nav")
    }
    defaultContainer.storyboardInitCompleted(GenrePickerController.self) { resolver, controller in
      print("Genre Picker")
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
    defaultContainer.storyboardInitCompleted(UINavigationController.self, name: "ActorNav"){ _, _ in
      print("Actor Nav")
    }
    defaultContainer.storyboardInitCompleted(PeoplePickerController.self) { resolver, controller in
      print("People Picker")
      controller.viewModel = resolver.resolve(SearchResultsTableViewModeling.self)!
      controller.movieWatcherViewModel = resolver.resolve(WatcherViewModelProtocol.self)!
    }
  }
}
