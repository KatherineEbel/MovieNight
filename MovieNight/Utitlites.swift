//
//  Utitlites.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/12/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import Foundation

func allPairs<T>(inSet set: Set<T>) -> [Array<T>] {
  let arrayFromSet: [T] = Array(set)
    var result = [[T]]()
      for i in 0..<arrayFromSet.count {
        for j in i + 1..<arrayFromSet.count {
          result.append([arrayFromSet[i], arrayFromSet[j]])
        }
      }
    return result
}
