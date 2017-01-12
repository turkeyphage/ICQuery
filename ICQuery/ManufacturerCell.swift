//
//  ManufacturerCell.swift
//  ICQuery
//
//  Created by Roger on 2016/12/28.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class ManufacturerCell: UITableViewCell {

    
    //@IBOutlet weak var favorImageView: UIImageView!
    
    
    
    //sup name
    @IBOutlet weak var keyLabel: UILabel!
    
    //price
    @IBOutlet weak var valueLabel: UILabel!
    
    //currancy sign
    @IBOutlet weak var curLabel: UILabel!
    
    //favor star imageview
    @IBOutlet weak var favorStar: UIImageView!
    
    
    @IBOutlet weak var stockLabel: UILabel!
    
    @IBOutlet weak var buyButton: UIButton!
    
    var favorStatus : Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5)
        selectedBackgroundView = selectedView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
