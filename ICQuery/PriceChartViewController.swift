//
//  PriceChartViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/29.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class PriceChartViewController: UIViewController {

    
    
    @IBOutlet weak var supplier_label: UILabel!
    
    @IBOutlet weak var priceTitle_tableview: UITableView!
    
    
    
    var supplierName :String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        supplier_label.text = supplierName
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func backButtonPressed(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}






