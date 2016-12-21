//
//  MovieNightTableViewModel.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import ReactiveSwift
import Argo
import Result

public protocol SearchResultsTableViewModeling {
  var genreModelData: MutableProperty<[TMDBEntity.MovieGenre]> { get }
  var actorModelData: MutableProperty<[TMDBEntity.Actor]> { get }
  var ratingModelData: MutableProperty<[TMDBEntity.Rating]> { get }
  func getNextPage()
  func getGenres()
  func getRatings()
}

public final class SearchResultsTableViewModel: SearchResultsTableViewModeling {
  public var genreModelData = MutableProperty<[TMDBEntity.MovieGenre]>([])
  public var actorModelData = MutableProperty<[TMDBEntity.Actor]>([])
  public var ratingModelData = MutableProperty<[TMDBEntity.Rating]>([])
  private let client: TMDBSearching
  private var nextPage: Int
  private let maxPages = 5
  
  public init(client: TMDBSearching) {
    nextPage = 1
    self.client = client
  }

  public func getNextPage() {
    client.searchPopularPeople(pageNumber: nextPage)
     .map { response in
        return response.results
      }
    .observe(on: UIScheduler())
    .on { actors in
      self.actorModelData.value.append(contentsOf: actors)
    }
    .start()
    nextPage += 1
  }
  
  public func getGenres() {
    client.searchMovieGenres()
      .map { response in
        return response.genres
      }
      .observe(on: UIScheduler())
      .on { genres in
        self.genreModelData.value = genres
      }
    .start()
  }
  
  public func getRatings() {
    client.searchUSRatings()
      .map { response in
          return response
      }
      .observe(on: UIScheduler())
      .on { ratings in
        self.ratingModelData.value = ratings.certifications
      }
      .start()
  }
}
