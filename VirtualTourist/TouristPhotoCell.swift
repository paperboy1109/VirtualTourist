//
//  TouristPhotoCell.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 8/7/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import UIKit

class TouristPhotoCell: UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet var touristPhotoCellImageView: UIImageView!
    @IBOutlet var touristPhotoCellActivityIndicator: UIActivityIndicatorView!
    
    
    override func awakeFromNib() {
        // Configure the cell
        layer.borderWidth = 0.8
        layer.cornerRadius = 5
        layer.borderColor = UIColor.grayColor().CGColor
    }
    
}
