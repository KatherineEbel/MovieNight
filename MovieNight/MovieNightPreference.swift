//
//  KMNMoviePreference.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/10/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation
import Argo
import Runes
import Curry


public struct MovieNightPreference {
  var actorChoices: [TMDBEntity.Actor]
  var genreChoices: [TMDBEntity.MovieGenre]
  var maxRating: TMDBEntity.Certification
}
