//
//  PeopleSearchCell.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/13/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class DefaultSearchCell: UITableViewCell {
  internal var viewModel: SearchResultsTableViewCellModeling? {
    didSet {
      nameLabel.text = viewModel?.title
    }
  }
  @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
