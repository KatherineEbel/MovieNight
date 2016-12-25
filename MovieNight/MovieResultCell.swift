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
  @IBOutlet weak var movieTitleLabel: UILabel!
  var viewModel: SearchResultsTableViewCellModeling? {
    didSet {
      movieTitleLabel.text? = viewModel!.title
      viewModel!.getThumbnailImage()
        .take(until: self.reactive.prepareForReuse)
        .on { image in
        self.posterImageView.image = image
        self.setNeedsDisplay()
      }.observe(on: UIScheduler()).start()
    }
  }
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
