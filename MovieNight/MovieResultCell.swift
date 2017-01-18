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
  
  var viewModel: SearchResultsTableViewCellModeling? {
    didSet {
      viewModel!.getThumbnailImage()?
        .take(until: self.reactive.prepareForReuse)
        .on { [weak self] image in
          guard let strongSelf = self else { return }
          strongSelf.posterImageView.image = image.resizedImage(withBounds: strongSelf.contentView.bounds.size)
          strongSelf.layoutIfNeeded()
      }.observe(on: UIScheduler()).start()
    }
  }
}
