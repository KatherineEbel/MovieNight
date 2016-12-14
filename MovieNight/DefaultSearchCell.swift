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
  internal var viewModel: SearchTableViewCellModeling? {
    didSet {
      nameLabel.text? = viewModel!.name
    }
  }
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var selectNameButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let image = UIImage(named: "bubble-selected")
        self.selectNameButton.setImage(image, for: .normal)
        // Configure the view for the selected state
    }

}
