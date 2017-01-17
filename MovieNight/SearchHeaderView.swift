//
//  SearchHeaderView.swift
//  MovieNight
//
//  Created by Katherine Ebel on 1/17/17.
//  Copyright © 2017 Katherine Ebel. All rights reserved.
//

import UIKit

class SearchHeaderView: UIView {

  @IBOutlet weak var searchHeaderStackView: UIStackView!
  @IBOutlet weak var SearchPagesButton: UIButton!
  @IBOutlet weak var searchTextField: UITextField!
  var entityType: TMDBEntity!
  weak var viewModel: SearchResultsTableViewModeling! {
    didSet {
      setupSearchTextField()
      viewModel!.peoplePageCountTracker().map { (numPages, _) in
        return "Go to (?) of \(numPages) Result Pages"
        }.signal.observeValues { [weak self] text in
          guard let strongSelf = self else { return }
          strongSelf.searchTextField.placeholder = text
        }
    }
  }
  
  public func setupSearchTextField() {
    // map user input to search viewmodels people result pages
    searchTextField.reactive.textValues.take(during: searchTextField.reactive.lifetime).observeValues { [weak self] text in
      guard let strongSelf = self else { return }
      guard let pageNumber = Int(text!) else { return }
      strongSelf.handleSearch(pageNumber: pageNumber)
    }
    searchHeaderStackView.removeArrangedSubview(searchTextField)
    searchTextField.isHidden = true
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
    viewModel!.getPopularPeoplePage(pageNumber: pageNumber)
  }
  
  @IBAction func searchPagesButtonPressed(_ sender: UIButton) {
    toggleTextField()
  }

}

extension SearchHeaderView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    textField.resignFirstResponder()
    searchTextField.text = ""
  }
  
  func toggleTextField() {
      UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseInOut], animations: {
        [weak self] in
        guard let strongSelf = self else { return }
        if strongSelf.searchTextField.isHidden {
          strongSelf.searchHeaderStackView.addArrangedSubview(strongSelf.searchTextField)
          strongSelf.searchTextField.isHidden = false
          strongSelf.searchTextField.becomeFirstResponder()
        } else {
          strongSelf.searchHeaderStackView.removeArrangedSubview(strongSelf.searchTextField)
          strongSelf.searchTextField.isHidden = true
        }
      }, completion: nil)
  }
}
