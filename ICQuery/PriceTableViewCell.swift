//
//  PriceTableViewCell.swift
//  ICQuery
//
//  Created by Roger on 2016/12/30.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class PriceTableViewCell: UITableViewCell {

    @IBOutlet weak var left_label: UILabel!
    
    @IBOutlet weak var center_label: UILabel!
    
    @IBOutlet weak var right_label: UILabel!
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
