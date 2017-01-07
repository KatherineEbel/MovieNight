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
import Result

class PreferenceCell: UITableViewCell {
  internal var viewModel: SearchResultsTableViewCellModeling? {
    didSet {
      nameLabel.reactive.text <~ viewModel!.data.map { $0.title }
      self.accessoryType = viewModel!.data.value.details != nil ? .detailButton : .none
    }
  }
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var selectionImage: UIImageView!
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    let selectedImage = UIImage(named: ImageAssetName.cellSelected.rawValue)!
    let unselectedImage = UIImage(named: ImageAssetName.cellUnselected.rawValue)!
    selectionImage.image = selected ? selectedImage : unselectedImage
    self.layoutIfNeeded()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  
}
