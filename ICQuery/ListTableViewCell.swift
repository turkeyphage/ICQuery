//
//  ListTableViewCell.swift
//  ICQuery
//
//  Created by Roger on 2016/12/8.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class ListTableViewCell: UITableViewCell {

    
    @IBOutlet weak var itemImageView: UIImageView!
    
    @IBOutlet weak var companyNameLabel: UILabel!
    
    @IBOutlet weak var modelNameLabel: UILabel!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var detailLabel: UILabel!
    
    var downloadTask: URLSessionDownloadTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5)
        //selectedView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 0.5)
        
        
        selectedBackgroundView = selectedView
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(for productDetail:ProductDetail){
    
        if productDetail.mfs.isEmpty{
            companyNameLabel.text = "N/A"
        } else {
            companyNameLabel.text = productDetail.mfs
        }
        
        if productDetail.pn.isEmpty{
            modelNameLabel.text = "N/A"
        } else {
            modelNameLabel.text = productDetail.pn
        }
        
        if productDetail.catagory.isEmpty{
            typeLabel.text = "N/A"
        } else {
            typeLabel.text = productDetail.catagory
        }
        
        if productDetail.desc.isEmpty{
            detailLabel.text = "N/A"
        } else {
            detailLabel.text = productDetail.desc
        }
        
        
        itemImageView.image = UIImage(named: "logo_120_120")
    
        if let smallURL = URL(string: productDetail.picurl) {
            downloadTask = itemImageView.loadImage(url: smallURL)
        }
    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        downloadTask?.cancel()
        downloadTask = nil
    }
    
}
