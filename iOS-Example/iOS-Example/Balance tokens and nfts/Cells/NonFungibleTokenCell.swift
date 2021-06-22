//
//  NonFungibleTokenCell.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 11/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit

class NonFungibleTokenCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var desc: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
