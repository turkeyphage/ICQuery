//
//  SpecCell.swift
//  ICQuery
//
//  Created by Roger on 2016/12/28.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class SpecCell: UITableViewCell {

    @IBOutlet weak var keyLabel: UILabel!
    
    @IBOutlet weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
