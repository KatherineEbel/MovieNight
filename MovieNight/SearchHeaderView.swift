//
//  SearchHeaderView.swift
//  MovieNight
//
//  Created by Katherine Ebel on 1/17/17.
//  Copyright © 2017 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift

// used for searchable endpoints to go to a specific page of the results
class SearchHeaderView: UITableViewHeaderFooterView {
  @IBOutlet weak var searchTextField: UITextField!
  var entityType: TMDBEntity!
  var movieDiscover: MovieDiscoverProtocol?
  weak var viewModel: SearchResultsTableViewModeling! {
    didSet {
      setupSearchTextField()
      configurePlaceHolderText()
    }
  }
  
  private func configurePlaceHolderText() {
    if let _ = movieDiscover {
      searchTextField.attributedPlaceholder = viewModel!.resultPageCountTracker().map { (numPages, _) in
        return NSAttributedString(string:"Go to (?) of \(numPages) Result Pages")
      }.value
    } else {
      searchTextField.attributedPlaceholder = viewModel!.peoplePageCountTracker().map { (numPages, _) in
        return NSAttributedString(string: "Go to (?) of \(numPages) Result Pages")
      }.value
    }
  }
  
  public func setupSearchTextField() {
    // map user input to search viewmodels people result pages
    searchTextField.reactive.textValues.take(during: searchTextField.reactive.lifetime).observeValues { [weak self] text in
      guard let strongSelf = self else { return }
      guard let pageNumber = Int(text!) else { return }
      strongSelf.handleSearch(pageNumber: pageNumber)
    }
  }
    
  private func handleSearch(pageNumber: Int) {
    searchTextField.layer.cornerRadius = 8.0
    searchTextField.layer.borderWidth = 2.0
    // check to make sure user submitted pageNumber is valid
    guard viewModel!.validatePageSearch(pageNumber: pageNumber, entityType: entityType) else {
      searchTextField.layer.borderColor = UIColor.red.cgColor
      return
    }
    searchTextField.layer.borderColor = TMDBColor.ColorFromRGB(color: .green, withAlpha: 1.0).cgColor
    if let movieDiscover = movieDiscover {
      viewModel.getNextMovieResultPage(pageNumber: pageNumber, discover: movieDiscover)
    } else {
      viewModel.getPopularPeoplePage(pageNumber: pageNumber)
    }
  }
  
  deinit {
    searchTextField.attributedPlaceholder = NSAttributedString(string: "Go to Page")
  }
}

extension SearchHeaderView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    searchTextField.layer.borderColor = UIColor.clear.cgColor
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    textField.resignFirstResponder()
    searchTextField.text = ""
  }
}
