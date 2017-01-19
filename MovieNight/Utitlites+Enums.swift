//
//  Utitlites.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/12/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift

// MovieNightSearchController constant
let kTableHeaderViewHeight: CGFloat = 60.0
let kUIScheduler = UIScheduler()

public enum ImageAssetName: String {
  case undecided = "bubble-empty-1"
  case ready = "bubble-filled"
  case cellSelected = "circle-checked"
  case cellUnselected = "circle-empty"
}
  enum SelectionImage: String {
    case selected = "circle-checked"
    case unselected = "circle-empty"
  }

public enum Identifiers: String {
  case networkActivityKey = "isNetworkActivityIndicatorVisible"
  case preferenceCellNibName = "PreferenceCell"
  case movieResultCellNibName = "MovieResultCell"
  case searchHeaderView = "SearchHeaderView"
  case showDetailsSegue = "showDetails"
  case choosePreferencesSegue = "choosePreferences"
}

enum MovieNightControllerAlert: String {
  case preferencesNotComplete = "Please make at least one selection from each preference type"
  case propertyInjectionFailure = "Property injection failure. Fatal Error. Please report to app developer"
  case somethingWentWrong = "Sorry! Something went wrong."
  case somethingNotRight = "Sorry! Something's not quite right."
  case updateName = "Update Name"
  case updateNameMessage = "Update your name?"
  case keepDefaultName = "Keep current name"
  case clearSelectionsMessage = "Proceeding, will clear all selected preferences"
  case clearSelectionsConfirmation = "Are you sure you want to continue?"
  case ready = "Ready"
  case undecided = "Undecided"
  case ok = "OK"
  case reset = "Reset"
  case cancel = "Cancel"
}

// created this function as possible option for creating MovieDiscover
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
