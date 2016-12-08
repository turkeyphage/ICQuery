//
//  DetailViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/8.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var datasheetButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var company_label: UILabel!
    
    @IBOutlet weak var model_label: UILabel!
    
    @IBOutlet weak var detail_label: UILabel!
    
    @IBOutlet weak var product_imageview: UIImageView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let placeholderStr = NSAttributedString(string: "請輸入查詢資料", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
        searchTextField.attributedPlaceholder = placeholderStr
    
        
        //datasheet button outline
        datasheetButton.backgroundColor = .clear
        
        datasheetButton.layer.cornerRadius = 5
        
        datasheetButton.layer.borderWidth = 1
        
        datasheetButton.layer.borderColor = UIColor.lightGray.cgColor
        
        

        //fake data
        product_imageview.image = UIImage(named: "logo_120_120")
        company_label.text = "Texas Instruments"
        model_label.text =  "LM555"
        detail_label.text = "Output Can Source or Sink 200 mA, Temperature Stability Better than 0.005% per °C"

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidLayoutSubviews() {
        view.layoutIfNeeded()
        searchTextField.useUnderline()
    }
    
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    

}
