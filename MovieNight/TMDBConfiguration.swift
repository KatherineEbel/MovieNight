//
//  TMDBConfiguration.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/29/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Argo
import Runes
import Curry

public struct TMDBConfiguration: Decodable {
  let images: TMDBImageConfiguration
  let change_keys: [String]
  
  public static func decode(_ json: JSON) -> Decoded<TMDBConfiguration> {
    return curry(TMDBConfiguration.init)
      <^> json <| "images"
      <*> json <|| "change_keys"
  }
}


public struct TMDBImageConfiguration: Decodable {
  let base_url: String
  let secure_base_url: String
  let backdrop_sizes: [String]
  let logo_sizes: [String]
  let poster_sizes: [String]
  let profile_sizes: [String]
  let still_sizes: [String]
  
  public static func decode(_ json: JSON) -> Decoded<TMDBImageConfiguration> {
    return curry(TMDBImageConfiguration.init)
      <^> json <| "base_url"
      <*> json <| "secure_base_url"
      <*> json <|| "backdrop_sizes"
      <*> json <|| "logo_sizes"
      <*> json <|| "poster_sizes"
      <*> json <|| "profile_sizes"
      <*> json <|| "still_sizes"
  }
}
