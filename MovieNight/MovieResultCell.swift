//
//  MovieResultCell.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/24/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit
import ReactiveSwift

class MovieResultCell: UITableViewCell {

  @IBOutlet weak var posterImageView: UIImageView!
//  @IBOutlet weak var movieTitleLabel: UILabel!
//  @IBOutlet weak var infoButtonPressed: UIButton!
  
  var viewModel: SearchResultsTableViewCellModeling? {
    didSet {
      viewModel!.getThumbnailImage()?
        .take(until: self.reactive.prepareForReuse)
        .on { image in
          self.posterImageView.image = image.resizedImage(withBounds: self.contentView.bounds.size)
          self.layoutIfNeeded()
      }.observe(on: UIScheduler()).start()
    }
  }
  
  override func awakeFromNib() {
      super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
  }
    
}
