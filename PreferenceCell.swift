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
    let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    backgroundView.backgroundColor = UIColor(red: 255/255.0, green: 142/255.0, blue: 138/255.0, alpha: 0.2)
    self.selectedBackgroundView = backgroundView
  }
}
