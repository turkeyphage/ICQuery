//
//  PriceChartViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/29.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit
//import ScrollableGraphView


class PriceChartViewController: UIViewController {
    
    
    
    @IBOutlet weak var supplier_label: UILabel!
    
    @IBOutlet weak var titleTable: UITableView!
    
    @IBOutlet weak var priceTable: UITableView!
    var supplier : SupplierDetail!
    
    
    @IBOutlet weak var price_trend_background: UIView!
    @IBOutlet weak var quantity_trend_background: UIView!
    
    
    var units = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        supplier_label.text = "\(supplier.pn) (\(supplier.sup))"
        print("\(supplier)")
        print("id = \(supplier.id)")
        
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
            var quanityArray = [Int]()
            for quanity in supplier.price.keys{
                quanityArray.append(Int(quanity)!)
            }
            
            let quanityArraySorted = quanityArray.sorted()
            for each in quanityArraySorted{
                units.append(String(each))
            }
        }
        
        // test add graphView
        let graphView = ScrollableGraphView(frame: self.price_trend_background.frame)
        let data: [Double] = [4, 8, 15, 16, 23, 42]
        let labels = ["one", "two", "three", "four", "five", "six"]
        graphView.set(data: data, withLabels: labels)
        
        price_trend_background.addSubview(graphView)
        
        let horizonalContraints = NSLayoutConstraint(item: graphView, attribute:
            .leadingMargin, relatedBy: .equal, toItem: price_trend_background,
                            attribute: .leading, multiplier: 1.0,
                            constant: 0)
        
        let verticalContraints = NSLayoutConstraint(item: graphView, attribute:.trailingMargin, relatedBy: .equal, toItem: price_trend_background,
                                                    attribute: .trailing, multiplier: 1.0, constant: 0)
        
        
        let pinTop = NSLayoutConstraint(item: graphView, attribute: .top, relatedBy: .equal, toItem: price_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
        
        let pinBottom = NSLayoutConstraint(item: graphView, attribute: .bottom, relatedBy: .equal, toItem: price_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
        
        
        graphView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
        
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    
    //MARK: 
    
    
    
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





