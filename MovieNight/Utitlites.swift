//
//  Utitlites.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/12/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
public func allPairs<T>(inSet set: Set<T>) -> [Array<T>] {
  let arrayFromSet: [T] = Array(set)
    var result = [[T]]()
      for i in 0..<arrayFromSet.count {
        for j in i + 1..<arrayFromSet.count {
          result.append([arrayFromSet[i], arrayFromSet[j]])
        }
      }
    return result
}

extension UIImage {
  func resizedImage(withBounds bounds: CGSize) -> UIImage {
    let horizontalRatio = bounds.width / size.width
    let verticalRatio = bounds.height / size.height
    let ratio = min(horizontalRatio, verticalRatio)
    let newSize = CGSize(width: size.width * ratio,
                         height: size.height * ratio)
    UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
    draw(in: CGRect(origin: CGPoint.zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
  }
}
