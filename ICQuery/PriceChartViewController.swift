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

    @IBOutlet weak var titleTable: UITableView!
    
    @IBOutlet weak var priceTable: UITableView!
    var supplier : SupplierDetail!
    //var supplierName :String!
    
    
    var units = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        supplier_label.text = supplier.sup
        print("\(supplier)")

        titleTable.dataSource = self
        priceTable.dataSource = self

        titleTable.allowsSelection = false
        priceTable.allowsSelection = false
        
        let titleNib = UINib(nibName: CellID.price_cell, bundle: nil)
        titleTable.register(titleNib, forCellReuseIdentifier: CellID.price_cell)
        
        
        let valueNib = UINib(nibName: CellID.value_cell, bundle: nil)
        priceTable.register(valueNib, forCellReuseIdentifier: CellID.value_cell)
        
        
        // 將價格排序：
        if !supplier.price.keys.isEmpty{
            units = supplier.price.keys.sorted()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func backButtonPressed(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)

    }

}




extension PriceChartViewController:UITableViewDelegate,UITableViewDataSource{

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.titleTable{
            return 1
        } else {
            if !supplier.price.keys.isEmpty{
                return supplier.price.keys.count
            } else {
                return 1
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if tableView == self.titleTable{
            let cell =  tableView.dequeueReusableCell(withIdentifier: "PriceTitleCell", for: indexPath) as! PriceTableViewCell
            
            cell.left_label.text = "數量"
            cell.center_label.text = "幣別"
            cell.right_label.text = "單價"
            return cell
        } else {
            let cell =  tableView.dequeueReusableCell(withIdentifier: "PriceValueCell", for: indexPath) as! ValueTableViewCell
            
            if supplier.cur.isEmpty{
                cell.center_label.textColor = UIColor.darkGray
                cell.center_label.text = "N/A"
            } else {
                if supplier.price.isEmpty{
                    cell.center_label.textColor = UIColor.darkGray
                    cell.center_label.text = "N/A"
                } else {
                    cell.center_label.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
                    cell.center_label.text = supplier.cur
                }
                
            }
            
            if supplier.price.isEmpty{
                cell.left_label.textColor = UIColor.darkGray
                cell.left_label.text = "N/A"
                cell.right_label.textColor = UIColor.darkGray
                cell.right_label.text = "N/A"
            
            } else {
                cell.left_label.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
                cell.left_label.text = units[indexPath.row]
                cell.right_label.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
                cell.right_label.text = supplier.price[units[indexPath.row]]
            
            }
            
            return cell
        }
    }

}





