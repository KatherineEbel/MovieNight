//
//  TMDBClient.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/11/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation

import Argo
import Runes
import Curry

struct PopularPeopleResult: Decodable {
  let page: Int
  let results: [JSON]
  let totalResults: Int
  let total_pages: Int
}

extension PopularPeopleResult {
  static func decode(_ json: JSON) -> Decoded<PopularPeopleResult> {
    return curry(PopularPeopleResult.init)
      <^> json <| "page"
      <*> json <|| "results"
      <*> json <| "total_results"
      <*> json <| "total_pages"
  }
}

struct GenresResponse {
  let genres: [JSON]
}

