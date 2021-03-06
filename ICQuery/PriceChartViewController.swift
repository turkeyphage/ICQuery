//
//  PriceChartViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/29.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit
import SwiftHTTP
import SafariServices



class PriceChartViewController: UIViewController {

    //登入帳號：
    var account : String?
    var favorStatus : Bool!
    
    
    @IBOutlet weak var supplier_label: UILabel!
    
    @IBOutlet weak var titleTable: UITableView!
    
    @IBOutlet weak var priceTable: UITableView!
    var supplier : SupplierDetail!
    
    
    //@IBOutlet weak var backgroundScrollView: UIScrollView!
    @IBOutlet weak var price_trend_label: UILabel!
    @IBOutlet weak var price_trend_background: UIView!
    
    @IBOutlet weak var quantity_trend_label: UILabel!
    @IBOutlet weak var quantity_trend_background: UIView!
    

    @IBOutlet weak var manuButton: UIButton!
    //@IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var favorButton: UIButton!
    
    @IBOutlet weak var loadingActivity: UIActivityIndicatorView!
    
    @IBOutlet weak var loadingSign: UILabel!
    
    
    
    var units = [String]()
    var currency = ""
    var prices = [String]()
    
    
    var priceView :ScrollableGraphView!
    var quantityView : ScrollableGraphView!
    
    var priceDots:[Double] = []
    var datesDots:[String] = []
    var quantityDots:[Double] = []
    
    
    deinit {
        print("deinit of PriceChartViewController")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.buyButton.isHidden = true
        self.favorButton.isHidden = true


        supplier_label.text = "\(supplier.pn) (\(supplier.sup))"
        //print("\(supplier)")
        //print("id = \(supplier.id)")
        
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
            
            for eachUnit in units{
                prices.append(supplier.price[eachUnit]!)
            }
            
        }
        
        
        if supplier.cur.isEmpty || supplier.price.isEmpty{
            self.currency = "N/A"
        } else {
            self.currency = supplier.cur
        }
        
        
        self.loadingActivity.isHidden = true
        self.loadingSign.isHidden = true
        
        
        self.price_trend_background.isHidden = true
        self.price_trend_label.isHidden = true
        self.quantity_trend_background.isHidden = true
        self.quantity_trend_label.isHidden = true
        
        
        
        
        updatePrice(pn: supplier.pn, urlAdd: supplier.url)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //連接圖表API
        get_price_data()
        
        
        if self.account == nil{
            
            self.favorButton.setBackgroundImage(UIImage(named: "gray_circle"), for: UIControlState.normal)
            self.favorButton.setImage(UIImage(named: "favor_0"), for: UIControlState.normal)
            //self.favorButton.setImage(UIImage(named: "favor_0"), for: UIControlState.selected)
            
        } else {
            
            if favorStatus == true{
                self.favorButton.setBackgroundImage(UIImage(named: "blue_circle"), for: UIControlState.normal)
                
                //self.favorButton.imageView?.image = UIImage(named: "favor_1")
                self.favorButton.setImage(UIImage(named: "favor_1"), for: UIControlState.normal)
            } else {
                self.favorButton.setBackgroundImage(UIImage(named: "gray_circle"), for: UIControlState.normal)
                //self.favorButton.imageView?.image = UIImage(named: "favor_0")
                self.favorButton.setImage(UIImage(named: "favor_0"), for: UIControlState.normal)
            }
        }

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    
    
    // 獲得圖表的資料：
    func get_price_data(){

        
        //weak var weakSelf = self
        let searchAPI = API_Manager.shared.SEARCH_API_PATH
        
        //組裝url-string
        let combinedStr = String(format: "%@?t=c&q=%@", arguments: [searchAPI!, supplier.id])
        let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //print("\(escapedStr)")
        
        //放request
        let url = URL(string: escapedStr)
        let request = URLRequest(url: url!)
        //request.httpMethod = "GET"
        let session = URLSession.shared
        
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil{
                print(error.debugDescription)
                
                //alert -- 連線錯誤
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "連線錯誤", message: "請稍後再試", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                    self.present(alert, animated: true, completion:nil)
                }
                
            } else {
                
                if let data = data, let jsonDictionary = self.parse(json: data) {
                    
                    if let result = jsonDictionary["result"] as? [String:Any]{
                        
                        if let supplierDistribute = result["supplierDistribute"] as? [String:Any]{
                            if let supplierPriceDetail = supplierDistribute[self.supplier.sup] as? [String:Any]{
                                //print("\(supplierPriceDetail)")
                                
                                if !supplierPriceDetail.isEmpty{
                                    
                                    //日期
                                    let dates = supplierPriceDetail.keys.sorted()
                                    //print("\(dates)")
                                    
                                    for dateHistory in dates{
                                        //print("\(supplierPriceDetail[dateHistory])")
                                        // 取得mfs名稱
                                        if let mfsContent = supplierPriceDetail[dateHistory] as? [String:Any] {

                                            if !mfsContent.isEmpty{
                                                // 取得mfs的名稱
                                                //if let mfs = mfsContent.keys.first{
                                                if let insideDetail = mfsContent["mfs"] as? [String:Any]{
                                                    if let mfsName = insideDetail.keys.first{
                                                        
                                                        if let filterResult = insideDetail[mfsName] as? [String:Any]{
                                                            if let price = filterResult["price"] as? Double {
                                                                //print ("Date:\(dateHistory) Price:\(price)")
                                                                self.priceDots.append(price)
                                                                //priceData.append([dateHistory:price])
                                                            } else{
                                                                self.priceDots.append(0)
                                                            }
                                                            
                                                            if let inventory = filterResult["inventory"] as? Double {
                                                                //print ("Date:\(dateHistory) Inventory:\(inventory)")
                                                                self.quantityDots.append(inventory)
                                                                //quantityData.append([dateHistory:inventory])
                                                            } else {
                                                                self.quantityDots.append(0)
                                                            }
                                                            
                                                            self.datesDots.append(dateHistory)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    //print("\(self.priceDots)")
                                    //print("\(self.datesDots)")
                                    //print("\(self.quantityDots)")
                                    
                                }
                            }
                        }
                    }
                } else {
                
                
                }
                
                
                if !self.priceDots.isEmpty, !self.quantityDots.isEmpty{
                    
                    DispatchQueue.main.async {
                        
                        
                        
                        // price chart:
                        self.priceView = ScrollableGraphView(frame: self.price_trend_background.frame)
                        self.priceView.backgroundFillColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
                        self.priceView.lineWidth = 1
                        self.priceView.lineColor = UIColor(red: 119/255, green: 119/255, blue: 119/255, alpha: 1)
                        self.priceView.lineStyle = ScrollableGraphViewLineStyle.smooth
                        
                        self.priceView.shouldFill = true
                        self.priceView.fillType = ScrollableGraphViewFillType.gradient
                        
                        self.priceView.fillColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
                        self.priceView.fillGradientType = ScrollableGraphViewGradientType.linear
                        self.priceView.fillGradientStartColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
                        self.priceView.fillGradientEndColor = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 1)
                        
                        self.priceView.dataPointSpacing = 80
                        self.priceView.dataPointSize = 2
                        self.priceView.dataPointFillColor = UIColor.white
                        
                        self.priceView.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
                        self.priceView.referenceLineColor = UIColor.white.withAlphaComponent(0.2)
                        self.priceView.referenceLineLabelColor = UIColor.white
                        self.priceView.referenceLineNumberOfDecimalPlaces = 6
                        self.priceView.dataPointLabelColor = UIColor.white.withAlphaComponent(0.5)
                        self.priceView.shouldAutomaticallyDetectRange = true
                        
                        
                        
                        //如果資料為空：則設為0
                        //if !self.priceDots.isEmpty{
                        //priceView:
                        self.priceView.set(data: self.priceDots, withLabels: self.datesDots)
                        
                        self.price_trend_background.addSubview(self.priceView)
                        
                        let price_trend_horizonalContraints = NSLayoutConstraint(item: self.priceView, attribute:
                            .leadingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                                            attribute: .leading, multiplier: 1.0,
                                            constant: 0)
                        
                        let price_trend_verticalContraints = NSLayoutConstraint(item: self.priceView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                                                                                attribute: .trailing, multiplier: 1.0, constant: 0)
                        
                        let price_trend_pinTop = NSLayoutConstraint(item: self.priceView, attribute: .top, relatedBy: .equal, toItem: self.price_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                        
                        let price_trend_pinBottom = NSLayoutConstraint(item: self.priceView, attribute: .bottom, relatedBy: .equal, toItem: self.price_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                        
                        self.priceView.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([price_trend_horizonalContraints, price_trend_verticalContraints,price_trend_pinTop, price_trend_pinBottom])
                        //}
                        //                } else {
                        //                    let data: [Double] = [0]
                        //
                        //                    //date:
                        //                    let date = Date()
                        //                    let calendar = Calendar.current
                        //                    let components = calendar.dateComponents([.year,.month,.day], from: date)
                        //                    let currentDate = "\(components.year!)/\(components.month!)/\(components.day!)"
                        //                    let labels = [currentDate]
                        //
                        //                    self.priceView.set(data: data, withLabels: labels)
                        //                    self.price_trend_background.addSubview(self.priceView)
                        //
                        //                    let horizonalContraints = NSLayoutConstraint(item: self.priceView, attribute:
                        //                        .leadingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                        //                                        attribute: .leading, multiplier: 1.0,
                        //                                        constant: 0)
                        //                    let verticalContraints = NSLayoutConstraint(item: self.priceView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                        //                                                                attribute: .trailing, multiplier: 1.0, constant: 0)
                        //                    let pinTop = NSLayoutConstraint(item: self.priceView, attribute: .top, relatedBy: .equal, toItem: self.price_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                        //
                        //                    let pinBottom = NSLayoutConstraint(item: self.priceView, attribute: .bottom, relatedBy: .equal, toItem: self.price_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                        //
                        //                    self.priceView.translatesAutoresizingMaskIntoConstraints = false
                        //                    NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
                        //
                        //                }
                        
                        
                        //quantity chart
                        
                        self.quantityView = ScrollableGraphView(frame: self.quantity_trend_background.frame)
                        
                        // Disable the lines and data points.
                        self.quantityView.shouldDrawDataPoint = false
                        self.quantityView.lineColor = UIColor.clear
                        
                        // Tell the graph it should draw the bar layer instead.
                        self.quantityView.shouldDrawBarLayer = true
                        
                        self.quantityView.dataPointSpacing = 80
                        self.quantityView.dataPointSize = 2
                        
                        // Customise the bar.
                        self.quantityView.barWidth = 25
                        self.quantityView.barLineWidth = 1
                        self.quantityView.barLineColor = UIColor(red: 119/255, green: 119/255, blue: 119/255, alpha: 1)
                        self.quantityView.barColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
                        self.quantityView.backgroundFillColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
                        
                        self.quantityView.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
                        self.quantityView.referenceLineColor = UIColor.white.withAlphaComponent(0.2)
                        self.quantityView.referenceLineLabelColor = UIColor.white
                        self.quantityView.numberOfIntermediateReferenceLines = 5
                        self.quantityView.dataPointLabelColor = UIColor.white.withAlphaComponent(0.5)
                        
                        self.quantityView.shouldAnimateOnStartup = true
                        //self.quantityView.shouldAdaptRange = true
                        self.quantityView.shouldAutomaticallyDetectRange = true
                        self.quantityView.adaptAnimationType = ScrollableGraphViewAnimationType.elastic
                        self.quantityView.animationDuration = 1.5
                        self.quantityView.rangeMax = 10
                        self.quantityView.shouldRangeAlwaysStartAtZero = true
                        
                        
                        
                        //如果資料為空：則設為0
                        //if !self.quantityDots.isEmpty{
                        //quantityView:
                        self.quantityView.set(data: self.quantityDots, withLabels: self.datesDots)
                        
                        self.quantity_trend_background.addSubview(self.quantityView)
                        
                        let quantity_trend_horizonalContraints = NSLayoutConstraint(item: self.quantityView, attribute:
                            .leadingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                                            attribute: .leading, multiplier: 1.0,
                                            constant: 0)
                        
                        let quantity_trend_verticalContraints = NSLayoutConstraint(item: self.quantityView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                                                                                   attribute: .trailing, multiplier: 1.0, constant: 0)
                        
                        let quantity_trend_pinTop = NSLayoutConstraint(item: self.quantityView, attribute: .top, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                        
                        let quantity_trend_pinBottom = NSLayoutConstraint(item: self.quantityView, attribute: .bottom, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                        
                        self.quantityView.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([quantity_trend_horizonalContraints, quantity_trend_verticalContraints, quantity_trend_pinTop, quantity_trend_pinBottom])
                        
                        //}
                        //                else {
                        //                    let data: [Double] = [0]
                        //
                        //                    //date:
                        //                    let date = Date()
                        //                    let calendar = Calendar.current
                        //                    let components = calendar.dateComponents([.year,.month,.day], from: date)
                        //                    let currentDate = "\(components.year!)/\(components.month!)/\(components.day!)"
                        //                    let labels = [currentDate]
                        //                    
                        //                    self.quantityView.set(data: data, withLabels: labels)
                        //                    self.quantity_trend_background.addSubview(self.quantityView)
                        //                    
                        //                    let horizonalContraints = NSLayoutConstraint(item: self.quantityView, attribute:
                        //                        .leadingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                        //                                        attribute: .leading, multiplier: 1.0,
                        //                                        constant: 0)
                        //                    
                        //                    let verticalContraints = NSLayoutConstraint(item: self.quantityView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                        //                                                                attribute: .trailing, multiplier: 1.0, constant: 0)
                        //                    
                        //                    let pinTop = NSLayoutConstraint(item: self.quantityView, attribute: .top, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                        //                    
                        //                    let pinBottom = NSLayoutConstraint(item: self.quantityView, attribute: .bottom, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                        //                    
                        //                    self.quantityView.translatesAutoresizingMaskIntoConstraints = false
                        //                    NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
                        //                    
                        //                }
                        
                        
                        self.price_trend_label.isHidden = false
                        self.price_trend_background.isHidden = false
                        self.quantity_trend_label.isHidden = false
                        self.quantity_trend_background.isHidden = false
                        
                    }
                } else {
                    DispatchQueue.main.async {
                        
                       
                        
                        
                        self.quantity_trend_background.removeFromSuperview()
                        self.quantity_trend_label.removeFromSuperview()
                        self.price_trend_background.removeFromSuperview()
                        self.price_trend_label.removeFromSuperview()
                    }
                
                }
            }

            
            
            
            
            // 更新圖表資料：
            
        }
        task.resume()
    }
    
    
    func parse(json data:Data) -> [String : Any]? {
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch{
            print("JSON Error:\(error)")
            
            return nil
        }
        
        
    }
    
    @IBAction func manuButton_pressed(_ sender: Any) {
        
        if self.favorButton.isHidden {
            favorButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            favorButton.isHidden = false
            favorButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            
            UIView.animate(withDuration: 0.08, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.favorButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
            
            
        } else {
            
            favorButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            UIView.animate(withDuration: 0.08, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.favorButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }, completion: { (animated) in
                self.favorButton.isHidden = true
            })
            
        }

        
    }
    
//    @IBAction func manuButtonPressed(_ sender: Any) {
////
////        if self.buyButton.isHidden {
////            buyButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
////            buyButton.isHidden = false
////            buyButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
////            
////            UIView.animate(withDuration: 0.08, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
////                self.buyButton.transform = CGAffineTransform(scaleX: 1, y: 1)
////            }, completion: nil)
////            
////           
////        } else {
////            
////            buyButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
////            
////            UIView.animate(withDuration: 0.08, delay: 0.05, options: UIViewAnimationOptions.curveLinear, animations: {
////                self.buyButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
////            }, completion: { (animated) in
////                self.buyButton.isHidden = true
////            })
////
////        }
////        
//        
//        
//    }
    
    
    @IBAction func buyButtonPressed(_ sender: Any) {
        //print("\(self.supplier)")
        
        if self.supplier.url.isEmpty || self.supplier.url == " " {
           
            let alert = UIAlertController(title: "目前無法連線至購買網頁", message: "請稍後再試", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
            self.present(alert, animated: true, completion:nil)
            
        } else {
            //print("url: \(self.supplier.url)")
            let svc = SFSafariViewController(url: URL(string: self.supplier.url)!)
            self.present(svc, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func favorButtonPressed(_ sender: Any) {
    
    
        if self.account == nil{
            
            let alert = UIAlertController(title: "無法加入價錢追蹤清單", message:"請先登入帳號以開啟此功能", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
            self.present(alert, animated: true, completion: nil)

            
        } else {
            
            if favorStatus == true{
                let alert = UIAlertController(title: "確定將此產品移出追蹤清單？", message:nil, preferredStyle: .alert)
                let okAction = UIAlertAction(
                    title: "確認",
                    style: .default,
                    handler: {
                        (action: UIAlertAction!) -> Void in
                        
                        //呼叫setPriceAlert
                        //print("\(self.supplier.price)")
                        
                        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                        hud.label.text = "連線中"
                        let queue = DispatchQueue.global()
                        
                        queue.async {
                            // 呼叫API
                            //"latitude", "longitude", pid
                            let pid = self.supplier.id
                            let name = DBManager.shared.systemInfo.deviceUUID
                            let latitude = DBManager.shared.get_device_position()["latitude"]!
                            let longitude = DBManager.shared.get_device_position()["longitude"]!
                            let userid = self.account
                            let action = "d"
                            let stock = "0"
                            let price = "\(self.supplier.price)"
                            let purl = self.supplier.url
                            
                            let combinedStr = String(format: "%@/setPriceAlert?pid=%@&deviceid=%@&latitude=%@&longtitude=%@&user_id=%@&action=%@&stock=%@&price=%@&url=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, pid, name, latitude, longitude, userid!, action, stock, price, purl])
                            
                            
                            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                            //print("\(escapedStr)")
                            
                            let url = URL(string:escapedStr)!
                            
                            var request = URLRequest(url: url)
                            request.httpMethod = "POST"
                            
                            let session = URLSession.shared
                            
                            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                                
                                
                                if error != nil{
                                    
                                    print(error.debugDescription)
                                } else {
                                    if let serverTalkBack = String(data: data!, encoding: String.Encoding.utf8){
                                        if serverTalkBack == "1"{
                                            
                                            //print("成功移除")
                                            
                                            DispatchQueue.main.async {
                                                hud.hide(animated: true)
                                                self.favorStatus = false
                                                self.favorButton.setBackgroundImage(UIImage(named: "gray_circle"), for: UIControlState.normal)
                                                //self.favorButton.imageView?.image = UIImage(named: "favor_0")
                                                self.favorButton.setImage(UIImage(named: "favor_0"), for: UIControlState.normal)
                                                hud.removeFromSuperview()
                                            }
                                        }
                                        
                                    }
                                }
                            }
                            task.resume()
                        }
                        
                    })
                
                alert.addAction(okAction)
                
                let cancelAction = UIAlertAction(
                    title: "取消",
                    style: .default,
                    handler: nil)
                alert.addAction(cancelAction)

                self.present(alert, animated: true, completion: nil)
                
            } else {
                
                let alert = UIAlertController(title: "確定將此產品加入追蹤清單？", message:nil, preferredStyle: .alert)
                
                let okAction = UIAlertAction(
                    title: "確認",
                    style: .default,
                    handler: {
                        (action: UIAlertAction!) -> Void in
                        
                        //呼叫setPriceAlert
                        //print("\(self.supplier.price)")
                        
                        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                        hud.label.text = "連線中"
                        let queue = DispatchQueue.global()
                        
                        queue.async {
                            // 呼叫API
                            //"latitude", "longitude", pid
                            let pid = self.supplier.id
                            let name = DBManager.shared.systemInfo.deviceUUID
                            let latitude = DBManager.shared.get_device_position()["latitude"]!
                            let longitude = DBManager.shared.get_device_position()["longitude"]!
                            let userid = self.account
                            let action = "a"
                            let stock = "0"
                            let price = "\(self.supplier.price)"
                            let purl = self.supplier.url
                            
                            let combinedStr = String(format: "%@/setPriceAlert?pid=%@&deviceid=%@&latitude=%@&longtitude=%@&user_id=%@&action=%@&stock=%@&price=%@&url=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, pid, name, latitude, longitude, userid!, action, stock, price, purl])
                            
                            
                            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                            //print("\(escapedStr)")
                            
                            let url = URL(string:escapedStr)!
                            
                            var request = URLRequest(url: url)
                            request.httpMethod = "POST"
                            
                            let session = URLSession.shared
                            
                            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                                
                                
                                if error != nil{
                                    
                                    print(error.debugDescription)
                                } else {
                                    if let serverTalkBack = String(data: data!, encoding: String.Encoding.utf8){
                                        if serverTalkBack == "1"{
                                            
                                            //print("成功加入")
                                            
                                            DispatchQueue.main.async {
                                                hud.hide(animated: true)
                                                self.favorStatus = true
                                                self.favorButton.setBackgroundImage(UIImage(named: "blue_circle"), for: UIControlState.normal)
                                                //self.favorButton.imageView?.image = UIImage(named: "favor_1")
                                                self.favorButton.setImage(UIImage(named: "favor_1"), for: UIControlState.normal)
                                                hud.removeFromSuperview()
                                            }
                                        }
                                        
                                    }
                                }
                            }
                            task.resume()
                        }
                })
                alert.addAction(okAction)
                
                let cancelAction = UIAlertAction(
                    title: "取消",
                    style: .default,
                    handler: nil)
                alert.addAction(cancelAction)
  
                self.present(alert, animated: true, completion: nil)
            }
        }
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
//            if !supplier.price.keys.isEmpty{
//                return supplier.price.keys.count
//            } else {
//                return 1
//            }
            
            if self.prices.isEmpty {
                return 1
            } else {
                return self.prices.count
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
            
            if self.currency == "N/A"{
                cell.center_label.textColor = UIColor.darkGray
            } else {
                cell.center_label.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
            }
            
            cell.center_label.text = self.currency
            
            
           
            
            
            
//            if supplier.cur.isEmpty{
//                cell.center_label.textColor = UIColor.darkGray
//                cell.center_label.text = "N/A"
//                
//            } else {
//                if supplier.price.isEmpty{
//                    cell.center_label.textColor = UIColor.darkGray
//                    cell.center_label.text = "N/A"
//                } else {
//                    cell.center_label.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
//                    cell.center_label.text = supplier.cur
//                }
//                
//            }
            
            if self.prices.isEmpty{
                cell.left_label.textColor = UIColor.darkGray
                cell.left_label.text = "N/A"
                cell.right_label.textColor = UIColor.darkGray
                cell.right_label.text = "N/A"
                
            } else {
                cell.left_label.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
                cell.left_label.text = units[indexPath.row]
                cell.right_label.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
                cell.right_label.text = prices[indexPath.row]
                
            }
            
            return cell
        }
    }

}




// MARK: 價格即時更新
extension PriceChartViewController{

    func updatePrice(pn:String, urlAdd:String){
        
        
        self.loadingSign.isHidden = false
        self.loadingActivity.isHidden = false
        self.loadingActivity.startAnimating()
        
        // 1.取得HTML
        let url = URL(string:urlAdd)!
        let request = URLRequest(url: url)
        //request.httpMethod = "POST"
        let session = URLSession.shared

        weak var weakSelf = self
  
        let task1 = session.dataTask(with: request as URLRequest) { data, response, error in
          
            if error != nil{
                print("error: \(error)")
                DispatchQueue.main.async {
                    weakSelf?.loadingActivity.stopAnimating()
                    weakSelf?.loadingSign.isHidden = true
                    weakSelf?.loadingActivity.isHidden = true
                }
            } else {
                if let serverTalkBack1 = String(data: data!, encoding: String.Encoding.utf8){
                    let webData = serverTalkBack1.data(using: String.Encoding.utf8)
                    
                    let web64Encode = webData?.base64EncodedString() // HTML with base64Encode
                    if DBManager.shared.getIFAddresses().isEmpty{
                        //沒有連線功能
                        print("no-connection")
                        DispatchQueue.main.async {
                            weakSelf?.loadingActivity.stopAnimating()
                            weakSelf?.loadingSign.isHidden = true
                            weakSelf?.loadingActivity.isHidden = true
                        }
                    } else {
                        //包成一個 json
                        let ip = DBManager.shared.getIFAddresses().first
                        let dic = ["html":web64Encode, "ip":ip, "productId":pn, "url":urlAdd, "uuid": DBManager.shared.systemInfo.deviceUUID]
//
//                        //print("\(dic)")
//                        
                        let escapedStr = String(format: "%@parsers", arguments: [API_Manager.shared.PARSER_API_PATH]).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
//
//                        
                        do {
                            let opt = try HTTP.POST(escapedStr, parameters: dic)
                            opt.start { response in
//                                //do things...
                                if let err = response.error {
                                    print("error: \(err.localizedDescription)")
                                    DispatchQueue.main.async {
                                        weakSelf?.loadingActivity.stopAnimating()
                                        weakSelf?.loadingSign.isHidden = true
                                        weakSelf?.loadingActivity.isHidden = true
                                    }
                                    return //also notify app of failure as needed
                                }
                                //print("opt finished: \(response.description)")
//
                                if let jsonDictionary = weakSelf?.parse(json: response.data) {
                                    //print("\(jsonDictionary)")
                                    if let success = jsonDictionary["success"] as? Bool{
                                        if success == true {
//
//                                            
                                            //print("supplier = \(weakSelf?.supplier)")
                                            let value = "\(weakSelf?.supplier.pn)+\(weakSelf?.supplier.mfs)+\(weakSelf?.supplier.sup)+1)"
                                            //print("\(value)")
                                            weakSelf?.searchLogSend(searchStr: value, key: "refresh")
//                                            
//                                            
//                                            
//                                            
                                            if let results = jsonDictionary["results"] as? [Any]{
                                                //print("\(results)")
                                                if let contents = results.first as? [String:Any]{
//
//                                                    
//                                                    
                                                    if let newPrice = contents["priceStores"] as? [[String:Any]]{
                                                        var updatePrice = [String]()
                                                        var updateAmount = [String]()
                                                        for item in newPrice{
                                                            //print("\(item)")
                                                            if let unitPrice = item["unitPrice"] as? String, let amount = item["amount"] as? Int{
                                                                updatePrice.append(unitPrice)
                                                                updateAmount.append(String(amount))
                                                            }
                                                        }
                                                        weakSelf?.prices = updatePrice
                                                        weakSelf?.units = updateAmount
                                                        
                                                    }
//
                                                    if let currency = contents["currency"] as? String{
                                                        //print("currency = \(currency)")
                                                        weakSelf?.currency = currency
                                                    }
//
                                                    if (weakSelf?.prices.isEmpty)! {
                                                        weakSelf?.currency = "N/A"
                                                    }
//
//                                                    
                                                    DispatchQueue.main.async {
                                                        weakSelf?.priceTable.reloadData()
                                                        weakSelf?.loadingActivity.stopAnimating()
                                                        weakSelf?.loadingSign.isHidden = true
                                                        weakSelf?.loadingActivity.isHidden = true
 
                                                    }
//
                                                }else{
                                                    DispatchQueue.main.async {
                                                        weakSelf?.loadingActivity.stopAnimating()
                                                        weakSelf?.loadingSign.isHidden = true
                                                        weakSelf?.loadingActivity.isHidden = true
                                                    }
                                                }
                                            } else {
                                                DispatchQueue.main.async {
                                                    weakSelf?.loadingActivity.stopAnimating()
                                                    weakSelf?.loadingSign.isHidden = true
                                                    weakSelf?.loadingActivity.isHidden = true
                                                }
                                            }
                                        } else {
                                            //print("supplier = \(weakSelf?.supplier)")
                                            let value = "\(weakSelf?.supplier.pn)+\(weakSelf?.supplier.mfs)+\(weakSelf?.supplier.sup)+0)"
                                            weakSelf?.searchLogSend(searchStr: value, key: "refresh")
                                            
                                            DispatchQueue.main.async {
                                                weakSelf?.loadingActivity.stopAnimating()
                                                weakSelf?.loadingSign.isHidden = true
                                                weakSelf?.loadingActivity.isHidden = true
                                            }
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            weakSelf?.loadingActivity.stopAnimating()
                                            weakSelf?.loadingSign.isHidden = true
                                            weakSelf?.loadingActivity.isHidden = true
                                        }
                                    }
//
                                } else {
                                    DispatchQueue.main.async {
                                        weakSelf?.loadingActivity.stopAnimating()
                                        weakSelf?.loadingSign.isHidden = true
                                        weakSelf?.loadingActivity.isHidden = true
                                    }
                                }
//
                            }
                        } catch let error {
                            print("got an error creating the request: \(error)")
                            
                            DispatchQueue.main.async {
                                weakSelf?.loadingActivity.stopAnimating()
                                weakSelf?.loadingSign.isHidden = true
                                weakSelf?.loadingActivity.isHidden = true
                            }
                        }
//
                    }
                } else {
                    DispatchQueue.main.async {
                        weakSelf?.loadingActivity.stopAnimating()
                        weakSelf?.loadingSign.isHidden = true
                        weakSelf?.loadingActivity.isHidden = true
                    }
                
                }
//
            }
        }
        task1.resume()
    }


}


