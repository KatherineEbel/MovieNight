//
//  PreferenceCell.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/19/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class PreferenceCell: UITableViewCell {
  internal var viewModel: SearchResultsTableViewCellModeling? {
    didSet {
      nameLabel.text = viewModel?.title
    }
  }
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var selectionImage: UIImageView!

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    let backgroundView = UIView()
    backgroundView.backgroundColor = UIColor.clear
    self.selectedBackgroundView = backgroundView
    
  }
}
