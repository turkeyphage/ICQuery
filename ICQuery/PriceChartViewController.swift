//
//  PriceChartViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/29.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit
import SafariServices



class PriceChartViewController: UIViewController {

    //登入帳號：
    var account : String?
    var favorStatus : Bool!
    
    
    @IBOutlet weak var supplier_label: UILabel!
    
    @IBOutlet weak var titleTable: UITableView!
    
    @IBOutlet weak var priceTable: UITableView!
    var supplier : SupplierDetail!
    
    
    @IBOutlet weak var price_trend_background: UIView!
    @IBOutlet weak var quantity_trend_background: UIView!
    

    @IBOutlet weak var manuButton: UIButton!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var favorButton: UIButton!
    
    
    
    var units = [String]()
    
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
        
        self.buyButton.isHidden = true
        self.favorButton.isHidden = true


        supplier_label.text = "\(supplier.pn) (\(supplier.sup))"
        //print("\(supplier)")
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
        
        //連接圖表API
        get_price_data()
        
        updatePrice(pn: supplier.pn, urlAdd: supplier.url)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
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

        let searchAPI = API_Manager.shared.SEARCH_API_PATH
        
        //組裝url-string
        let combinedStr = String(format: "%@?t=c&q=%@", arguments: [searchAPI!, supplier.id])
        let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        print("\(escapedStr)")
        
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
                }
            }

            // 更新圖表資料：
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
                if !self.priceDots.isEmpty{
                    //priceView:
                    self.priceView.set(data: self.priceDots, withLabels: self.datesDots)
                    
                    self.price_trend_background.addSubview(self.priceView)
                    
                    let horizonalContraints = NSLayoutConstraint(item: self.priceView, attribute:
                        .leadingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                                        attribute: .leading, multiplier: 1.0,
                                        constant: 0)
                    
                    let verticalContraints = NSLayoutConstraint(item: self.priceView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                                                                attribute: .trailing, multiplier: 1.0, constant: 0)
                    
                    let pinTop = NSLayoutConstraint(item: self.priceView, attribute: .top, relatedBy: .equal, toItem: self.price_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                    
                    let pinBottom = NSLayoutConstraint(item: self.priceView, attribute: .bottom, relatedBy: .equal, toItem: self.price_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                    
                    self.priceView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
                    
                } else {
                    let data: [Double] = [0]
                    
                    //date:
                    let date = Date()
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year,.month,.day], from: date)
                    let currentDate = "\(components.year!)/\(components.month!)/\(components.day!)"
                    let labels = [currentDate]
                    
                    self.priceView.set(data: data, withLabels: labels)
                    self.price_trend_background.addSubview(self.priceView)
                    
                    let horizonalContraints = NSLayoutConstraint(item: self.priceView, attribute:
                        .leadingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                                        attribute: .leading, multiplier: 1.0,
                                        constant: 0)
                    let verticalContraints = NSLayoutConstraint(item: self.priceView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.price_trend_background,
                                                                attribute: .trailing, multiplier: 1.0, constant: 0)
                    let pinTop = NSLayoutConstraint(item: self.priceView, attribute: .top, relatedBy: .equal, toItem: self.price_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                    
                    let pinBottom = NSLayoutConstraint(item: self.priceView, attribute: .bottom, relatedBy: .equal, toItem: self.price_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                    
                    self.priceView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
                    
                }
                
                
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
                if !self.quantityDots.isEmpty{
                    //quantityView:
                    self.quantityView.set(data: self.quantityDots, withLabels: self.datesDots)
                    
                    self.quantity_trend_background.addSubview(self.quantityView)
                    
                    let horizonalContraints = NSLayoutConstraint(item: self.quantityView, attribute:
                        .leadingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                                        attribute: .leading, multiplier: 1.0,
                                        constant: 0)
                    
                    let verticalContraints = NSLayoutConstraint(item: self.quantityView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                                                                attribute: .trailing, multiplier: 1.0, constant: 0)
                    
                    let pinTop = NSLayoutConstraint(item: self.quantityView, attribute: .top, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                    
                    let pinBottom = NSLayoutConstraint(item: self.quantityView, attribute: .bottom, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                    
                    self.quantityView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
                    
                } else {
                    let data: [Double] = [0]
                    
                    //date:
                    let date = Date()
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year,.month,.day], from: date)
                    let currentDate = "\(components.year!)/\(components.month!)/\(components.day!)"
                    let labels = [currentDate]
                    
                    self.quantityView.set(data: data, withLabels: labels)
                    self.quantity_trend_background.addSubview(self.quantityView)
                    
                    let horizonalContraints = NSLayoutConstraint(item: self.quantityView, attribute:
                        .leadingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                                        attribute: .leading, multiplier: 1.0,
                                        constant: 0)
                    
                    let verticalContraints = NSLayoutConstraint(item: self.quantityView, attribute:.trailingMargin, relatedBy: .equal, toItem: self.quantity_trend_background,
                                                                attribute: .trailing, multiplier: 1.0, constant: 0)
                    
                    let pinTop = NSLayoutConstraint(item: self.quantityView, attribute: .top, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .top, multiplier: 1.0, constant: 0)
                    
                    let pinBottom = NSLayoutConstraint(item: self.quantityView, attribute: .bottom, relatedBy: .equal, toItem: self.quantity_trend_background, attribute: .bottom, multiplier: 1.0, constant: 0)
                    
                    self.quantityView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
                    
                }
            }
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
    
    
    @IBAction func manuButtonPressed(_ sender: Any) {

        if self.buyButton.isHidden {
            buyButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            buyButton.isHidden = false
            buyButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            
            UIView.animate(withDuration: 0.08, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.buyButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
            
           
        } else {
            
            buyButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            UIView.animate(withDuration: 0.08, delay: 0.05, options: UIViewAnimationOptions.curveLinear, animations: {
                self.buyButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }, completion: { (animated) in
                self.buyButton.isHidden = true
            })

        }
        
        if self.favorButton.isHidden {
            favorButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            favorButton.isHidden = false
            favorButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            
            UIView.animate(withDuration: 0.08, delay: 0.05, options: UIViewAnimationOptions.curveLinear, animations: {
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
    
    
    @IBAction func buyButtonPressed(_ sender: Any) {
        print("\(self.supplier)")
        
        if self.supplier.url.isEmpty || self.supplier.url == " " {
           
            let alert = UIAlertController(title: "目前無法連線至購買網頁", message: "請稍後再試", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
            self.present(alert, animated: true, completion:nil)
            
        } else {
            print("url: \(self.supplier.url)")
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
                        print("\(self.supplier.price)")
                        
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
                            print("\(escapedStr)")
                            
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
                                            
                                            print("成功移除")
                                            
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
                        print("\(self.supplier.price)")
                        
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
                            print("\(escapedStr)")
                            
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
                                            
                                            print("成功加入")
                                            
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




// MARK: 價格即時更新
extension PriceChartViewController{

    func updatePrice(pn:String, urlAdd:String){
        // 1.取得HTML
        let url = URL(string:urlAdd)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let session = URLSession.shared

        let task1 = session.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil{
                print("error: \(error)")
            } else {
                if let serverTalkBack1 = String(data: data!, encoding: String.Encoding.utf8){
                    let webData = serverTalkBack1.data(using: String.Encoding.utf8)
                    
                    let web64Encode = webData?.base64EncodedString() // HTML with base64Encode
                    //let web64Encode = webData?.base64EncodedData()
                    
                    if DBManager.shared.getIFAddresses().isEmpty{
                        //沒有連線功能
                        print("no-connection")
                    } else {
                        //包成一個 json
                        let ip = DBManager.shared.getIFAddresses().first
                        let dic = ["html":web64Encode, "ip":ip, "productId":pn, "url":urlAdd, "uuid": DBManager.shared.systemInfo.deviceUUID]
                        
                        let fakehtml = "PCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFsLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL1RSL3hodG1sMS9EVEQveGh0bWwxLXRyYW5zaXRpb25hbC5kdGQiPgoKPCEtLSBTdGFydCAtIEpTUEYgRmlsZSBOYW1lOiBKU1RMRW52aXJvbm1lbnRTZXR1cC5qc3BmIC0tPjwhLS0gV0FTX05BTUUgQ0hJTkFfUFJPRF9TRVJWRVIxICAtLT4KPCEtLSBFbmQgLSBKU1BGIEZpbGUgTmFtZTogSlNUTEVudmlyb25tZW50U2V0dXAuanNwZiAtLT4NCg0KPCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFsLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL1RSL3hodG1sMS9EVEQveGh0bWwxLXRyYW5zaXRpb25hbC5kdGQiPg0KPGh0bWw+DQo8aGVhZD4NCg0KDQo8bWV0YSBodHRwLWVxdWl2PSJDb250ZW50LVR5cGUiIGNvbnRlbnQ9InRleHQvaHRtbDsgY2hhcnNldD1VVEYtOCIvPg0KPG1ldGEgaHR0cC1lcXVpdj0iQ29udGVudC1MYW5ndWFnZSIgY29udGVudD0iemgtQ04iLz4NCjxtZXRhIG5hbWU9IkdFTkVSQVRPUiIgY29udGVudD0iSUJNIFNvZnR3YXJlIERldmVsb3BtZW50IFBsYXRmb3JtIi8+DQoNCjxtZXRhIG5hbWU9ZGVzY3JpcHRpb24gY29udGVudD0i5ZyoIGRpZ2lrZXkuY29tLmNuIOi0reS5sCAxNjMuNzAxMC4wMTAyIExpdHRlbGZ1c2UgSW5jLiAxNjMuNzAxMC4wMTAyLU5E44CCIOe9keW6lyBkaWdpa2V5LiYjMzAwMDU7JiMzODQ1OTsmIzIyMTIwOyDkuLrmgqjnmoQgJiMxOTk4NzsmIzI5OTkyOyYjMjI0MTE7JiMzMDAwNTsmIzM4NDU5OyYjMjIxMjA7IHs2fSDpnIDopoHjgIIgRGlnaUtleSDmi6XmnInmnIDlub/ms5vnmoTnlLXlrZDlhYPku7bjgIHpm7bku7blkozkvpvlupTllYbpgInmi6njgIIiLz4NCg0KPG1ldGEgbmFtZT1rZXl3b3JkcyBjb250ZW50PSIxNjMuNzAxMC4wMTAyLDE2My43MDEwLjAxMDItTkQsRGlnaS1LZXkgRWxlY3Ryb25pY3Ms55S15a2Q6Zu25Lu2LCDlhYPku7YsIOe7j+mUgOWVhiIvPg0KPHRpdGxlPjE2My43MDEwLjAxMDIgTGl0dGVsZnVzZSBJbmMuIHwgMTYzLjcwMTAuMDEwMi1ORCB8IOW+l+aNt+eUteWtkDwvdGl0bGU+DQo8IS0tIGhlbHAgZGlhbG9nIGNvbnRlbnQgLS0+DQoNCjxkaXYgaWQ9Im5vblN0b2NrSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IuaXoOW6k+WtmOmhueebriIgPg0KPHA+IuWPr+S+m+W6lOaVsOmHjyLmoI/kuK3moIforrDkuLrml6DlupPlrZjnmoTkuqflk4HpgJrluLjml6DotKfjgILmnKzkuqflk4Hlj6/ku6XotK3kubDvvIzkvYblm6DkuLrlhbblrqLmiLfnvqTmnInpmZDvvIzmiYDku6XlhbbmnIDkvY7otbfotK3mlbDph4/pgJrluLjopoHmsYLovoPpq5jjgIJEaWdpLUtleSDmj5DkvpvpnZ7lupPlrZjkuqflk4HnmoTln7rmnKzljp/liJnlpoLkuIvvvJo8L3A+PHA+RGlnaS1LZXnnm67liY0gIDxiPuW6k+WtmDwvYj7mlbDku6XljYHkuIforqHnmoTnlLXlrZDlhYPku7bvvIzlubbmr4/ml6Xlop7liqDmlrDkuqflk4HjgIIg5Y+v5Lul6K+B5piO77yM6L+Z5piv5Lia55WMIDxiPuW6k+WtmOaUr+aMgTwvYj7nmoTmnIDlub/ms5vnmoTkuqflk4HkvpvlupTjgII8L1A+PHA+5L2G6L+Y5pyJ5o6l6L+R5pWw5LiH56eN5YW25a6D5YWD5Lu25Y+v5LuO5oiR5Lus55qE5L6b5bqU5ZWG6YKj6YeM6I635b6X44CC5bC9566h5Zug6L+Z5Lqb5Lqn5ZOB55qE6ZSA6Lev5pyJ6ZmQ6ICM5peg5rOV5YWF5YiG5L+d6K+B5a6D5Lus55qE5bqT5a2Y6YeP77yM5L2G5oiR5Lus55u45L+h6K6p5LqG6Kej5a6D5Lus5piv5ZCm5pyJ5bqT5a2Y5a+55oiR5Lus55qE5a6i5oi35piv5pyJ5Yip55qE44CC5oiR5Lus55qE55uu5qCH5piv5Li65oiR5Lus55qE5a6i5oi35o+Q5L6b5pyA5aSn5pWw6YeP55qE5Lqn5ZOB6YCJ5oup55qE5L+h5oGv77yM5bm26K6p5LuW5Lus5qC55o2u6KeE5qC844CB5Lu35qC844CB5L6b5bqU6YeP5ZKM5pyA5L2O6LSt5Lmw6YeP6L+b6KGM6YCJ5oup44CCPC9QPjxwPuazqOaEj++8jOmAieaLqSLlhbPplK7lrZci5LiL6Z2i55qEIuWcqOW6k+WVhuWTgSLlj7PovrnnmoTlpI3pgInmoYbvvIzkvJrlsIbmgqjpmZDliLbkuLrlj6rmn6XnnIvlj6/njrDotKfkvpvlupTnmoTkuqflk4HjgII8L3A+DQo8L2Rpdj4NCjxkaXYgaWQ9InZhbHVlQWRkSXRlbUhlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiIHRpdGxlPSLlop7lgLznianku7YiPg0KPFA+6L+Z5piv5oiR5Lus5a6a5Yi26KOF6YWN5oiW5YyF6KOF55qE5LiA5Liq5aKe5YC85ZWG5ZOB44CC5Zyo5aSn5aSa5pWw5oOF5Ya15LiL77yM5oiR5Lus5Y+v5Lul5qC55o2u5oKo55qE6K6i5Y2V5LiT6Zeo6KOF6YWN5oiW5YyF6KOF6L+Z56eN5ZWG5ZOB77yM5bm25Y+v5Zyo5b2T5aSp5Y+R6LSn44CC5aaC5p6c5oKo5bCG6L+Z56eN5ZWG5ZOB5pS+5Yiw6K6i5Y2V5LiK77yM5Lya5pi+56S657y66LSn77yM5aaC5p6c5peg5rOV5bGl6KGM6K6i5Y2V77yM5oiR5Lus5Lya5LiO5oKo6IGU57O744CCPC9QPg0KPC9kaXY+DQoNCjxkaXYgaWQ9Iml0ZW1OdW1iZXJIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7IiB0aXRsZT0i5ZWG5ZOB5Y+3IiA+DQoJPFA+5L2/55So5LiL5ouJ6I+c5Y2V6YCJ5oup5Zyo6K6i5Y2V5LiK5pi+56S655qEIOW+l+aNt+eUteWtkCDmiJbliLbpgKDllYbpm7bku7bnvJblj7fjgII8L1A+DQo8L2Rpdj4NCg0KPGRpdiBpZD0ic3RhbmRhcmRQYWNrYWdlSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9Iuagh+WHhuWMheijhSIgPg0KCTxQPuagh+WHhuWMheijheaYr+aMh+WOguWutuWQkeW+l+aNt+eUteWtkOaPkOS+m+eahOacgOWwj+WwuuWvuOWMheijheOAgiDnlLHkuo7lvpfmjbfnlLXlrZDmj5Dkvpvlop7lgLzmnI3liqHvvIzlm6DmraTmnIDkvY7orqLotK3mlbDph4/lj6/og73kvJrmr5TliLbpgKDllYbnmoTmoIflh4bljIXoo4XmlbDph4/lsJHjgILlvZPkuqflk4HliIbmiJDlsI/lsIHoo4Xph4/lh7rllK7ml7bvvIzlsIHoo4XnsbvlnovvvIjljbPljbfovbTjgIHnrqHoo4XjgIHmiZjnm5joo4XnrYnvvInlj6/og73kvJrmnInmiYDmlLnlj5jjgII8L1A+DQo8L2Rpdj4NCg0KPGxpbmsgaHJlZj0iLy9ka2MzLmRpZ2lrZXkuY29tL2Nzcy9wcmludC5jc3MiIHJlbD0ic3R5bGVzaGVldCIgdHlwZT0idGV4dC9jc3MiIG1lZGlhPSJwcmludCIvPg0KPGxpbmsgaHJlZj0iL3djc3N0b3JlL0NOL2Nzcy9zZWFyY2hfc3R5bGVzLmNzcyIgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIvPg0KPGxpbmsgaHJlZj0iL3djc3N0b3JlL0NOL2Nzcy9zdHlsZXNfb3ZlcnJpZGUuY3NzIiByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIi8+DQo8bGluayBpZD0idGhpY2tCb3hDc3MiIGhyZWY9Ii93Y3NzdG9yZS9DTi9jc3MvdGhpY2tib3guY3NzIiByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIiAvPg0KDQo8bGluayByZWw9ImNhbm9uaWNhbCIgaHJlZj0iaHR0cDovL3d3dy5kaWdpa2V5LmNvbS5jbi9zZWFyY2gvemgvMTYzLTcwMTAtMDEwMi8xNjMtNzAxMC0wMTAyLU5EP3JlY29yZElkPTM0MjY2NTciLz4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9kb2pvMTMxL2Rvam8vZG9qby5qcyIgZGpDb25maWc9InBhcnNlT25Mb2FkOiBmYWxzZSwgaXNEZWJ1ZzogZmFsc2UsIHVzZUNvbW1lbnRlZEpzb246IHRydWUsbG9jYWxlOiAnemgtY24nICI+PC9zY3JpcHQ+DQo8L2hlYWQ+DQoNCjxib2R5IHN0eWxlPSdwYWRkaW5nLWxlZnQ6IDBweDsgcGFkZGluZy1yaWdodDogMHB4Oycgb25VbmxvYWQ9J2VuYWJsZVN1Ym1pdCgpJz4NCg0KPHNjcmlwdCB0eXBlPSd0ZXh0L2phdmFzY3JpcHQnPg0KZnVuY3Rpb24gZGVsUXVhbnRpdHkoKQ0Kew0KDQpkZWxldGVRdWFudGl0eSgpDQp9DQoJLy92YXIgdXJsID0gbmV3IFN0cmluZyh3aW5kb3cubG9jYXRpb24pOw0KCS8vaWYgKHVybC5pbmRleE9mKCJodHRwczovLyIpICE9IC0xKSB7DQoJLy8Jd2luZG93LmxvY2F0aW9uID0gdXJsLnJlcGxhY2UoImh0dHBzOi8vIiwgImh0dHA6Ly8iKTsNCgkvL30JDQo8L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0ndGV4dC9qYXZhc2NyaXB0Jz4NCiB2YXIgYnRuVmlld0Zhdm9yaXRlVHh0ID0gJ+afpeeci+aUtuiXj+WkuSc7DQogdmFyIGJ0bkNvbnRpbnVlU2hvcHBpbmdUeHQgPSAn57un57ut6LSt5LmwJzsNCg0KIGZ1bmN0aW9uIGFkZFBhcnRUb0Zhdm9yaXRlKGRpZ2lrZXlQYXJ0TnVtYmVyKSB7DQoJCWlmKCdHJyA9PSAnRycpew0KCQkgJCggZG9jdW1lbnQgKS5yZWFkeShmdW5jdGlvbigpIHsNCiAJCQkJc2hvd0hlbHBEaWFsb2coJyNsb2dpbkRpYWxvZycsJ2F1dG8nLCczMDBweCcsZmFsc2UsdHJ1ZSx7fSk7DQoJCSB9KTsNCgkgIH0gZWxzZSB7DQoJCW9wZW5Qcm9ncmVzc01vZGFsV2luZG93KCk7DQoJCXZhciBwYXJhbXMgPSBbXTsNCgkJcGFyYW1zLmRrY1BhcnROdW1iZXIgPSBkaWdpa2V5UGFydE51bWJlcjsNCgkJZG9qby54aHJQb3N0KHsNCiAgICAJCXVybDogIi9teWRpZ2lrZXkvQWpheEludGVyZXN0SXRlbUFkZCIsCQ0KICAgIAkJaGFuZGxlQXM6ICJqc29uLWNvbW1lbnQtZmlsdGVyZWQiLAkJCQ0KICAgIAkJY29udGVudDogcGFyYW1zLA0KICAgIAkJc2VydmljZTogdGhpcywNCiAgICAJCWxvYWQ6IGZ1bmN0aW9uKHNlcnZpY2VSZXNwb25zZSwgaW9BcmdzKSB7DQogICAgCQlpZiAoc2VydmljZVJlc3BvbnNlLmVycm9yTWVzc2FnZUtleSAhPSBudWxsKSB7DQogICAgCQkJZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2Zhdm9yaXRlQWRkRXJyb3JNb2RlbFdpbmRvdycpLmlubmVySFRNTCA9IHNlcnZpY2VSZXNwb25zZS5lcnJvck1lc3NhZ2U7DQogICAgCQkJJCgnI2Zhdm9yaXRlQWRkRXJyb3JNb2RlbFdpbmRvdycpLmRpYWxvZygnb3BlbicpOw0KICAgIAkJfSBlbHNlIHsNCiAgICAJCQl2YXIgYnV0dG9uT3B0cyA9IHt9Ow0KCQkJCWJ1dHRvbk9wdHNbYnRuQ29udGludWVTaG9wcGluZ1R4dF0gPSBmdW5jdGlvbiAoKSB7DQoJCQkJICAgICQodGhpcykuZGlhbG9nKCJjbG9zZSIpOw0KCQkJCX07DQoJCQkJYnV0dG9uT3B0c1tidG5WaWV3RmF2b3JpdGVUeHRdID0gZnVuY3Rpb24gKCkgew0KCQkJCQkgd2luZG93LmxvY2F0aW9uLmhyZWYgPSAnaHR0cHM6Ly93d3cuZGlnaWtleS5jb20uY24vbXlkaWdpa2V5L015RmF2b3JpdGVQYXJ0c0NtZCc7DQoJCQkJfTsNCgkJCQkkKCcjZmF2b3JpdGVBZGRNb2RlbFdpbmRvdycpLmRpYWxvZygib3B0aW9uIiwgImJ1dHRvbnMiLCBidXR0b25PcHRzKTsNCgkJCQkkKCcjZmF2b3JpdGVBZGRNb2RlbFdpbmRvdycpLmRpYWxvZygnb3BlbicpOw0KCQkJCX0NCgkJCQljbG9zZVByb2dyZXNzTW9kYWxXaW5kb3coKTsNCgkJCX0sDQogICAgCQllcnJvcjogZnVuY3Rpb24oZXJyT2JqLCBpb0FyZ3MpIHsNCiAgICAJCQljbG9zZVByb2dyZXNzTW9kYWxXaW5kb3coKTsNCiAgICAJCQljb25zb2xlLmxvZygiRXJyb3Igd2hpbGUgc2F2aW5nIHBhcnQgdG8gZmF2b3JpdGUuIik7DQoJICAgIAl9DQogCQkgfSk7DQogCQkgfQ0KCQl9DQo8L3NjcmlwdD4NCjwhLS0gSW5jbHVkZSBIZWFkZXIgLS0+Cgo8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCI+CiAgIAkgICB2YXIgc3RvcmVJbWFnZXNEaXI9Ii93Y3NzdG9yZS9DTi8iOwogICAJICAgdmFyIGRlZmF1bHRDdXJyZW5jeSA9ICdDTlknOwoJICAgdmFyIG9rQnV0dG9uVGV4dD0gJ+ehruWumic7Cjwvc2NyaXB0PgoKCQk8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCI+CgkJICAgdmFyIGRpbWVuc2lvblNlYXJjaFVybCA9ICcvL3d3dy5kaWdpa2V5LmNvbS5jbi93ZWJhcHAvd2NzL3N0b3Jlcy9zZXJ2bGV0L0RpbWVuc2lvblZpZXcnOwoJICAgPC9zY3JpcHQ+CgkJPHN0eWxlIHR5cGU9InRleHQvY3NzIj4gCgkJPCEtLQoJCSNzaG9wcGluZ0NhcnQge3dpZHRoOjE3NXB4O30KCQkjY2FydHtkaXNwbGF5OmJsb2NrOyBoZWlnaHQ6NTFweDsgd2lkdGg6MTc1cHg7IGJhY2tncm91bmQtaW1hZ2U6dXJsKC8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2ltYWdlcy9kaWdpa2V5L2hlYWRlci9jYXJ0LXpocy5qcGcpOyBwb3NpdGlvbjpyZWxhdGl2ZTsgdGV4dC1kZWNvcmF0aW9uOm5vbmU7fQoJCSNjYXJ0IHNwYW4ge2N1cnNvcjpwb2ludGVyfQoJCSNxdHlJZCB7IHBvc2l0aW9uOmFic29sdXRlOyB0b3A6MzJweDsgbGVmdDoxMHB4OyBmb250LXNpemU6MTBweDsgZm9udC13ZWlnaHQ6Ym9sZDsgY29sb3I6I2M1MDAxZjsgfQoJCSNzdWJUb3RhbElkIHtwb3NpdGlvbjphYnNvbHV0ZTsgdG9wOjI5cHg7IHJpZ2h0OjEwcHg7ICBjb2xvcjojMDAwOyBmb250LXdlaWdodDpib2xkOyBmb250LXNpemU6MTRweDt9CgkJI2hlYWRlclRhYmxlIHRkIHt3aGl0ZS1zcGFjZTpub3dyYXA7fQoJCSNxdWlja0xpbmtzIHt3aWR0aDphdXRvOyB3aWR0aDoxMDAlXDk7fQoJCSNoZWFkZXIgYSBpbWcge2JvcmRlcjogbm9uZSAhaW1wb3J0YW50O30KCQkjY3VyX3RhYiB7Zm9udC1zaXplOjEycHg7IGNvbG9yOiNiYmI7IGZvbnQtd2VpZ2h0OmJvbGQ7fSAKCQktLT4KCQk8L3N0eWxlPgoJCTxsaW5rIHJlbD0ic3R5bGVzaGVldCIgdHlwZT0idGV4dC9jc3MiIGhyZWY9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvRGVzaWduZXIvR2xvYmFsL0NTUy9qcXVlcnktdWkuMS4xMS40LmNzcyI+CgkJCgkJPGxpbmsgcmVsPSJzdHlsZXNoZWV0IiBocmVmPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9jc3MvanF1ZXJ5LmF1dG9jb21wbGV0ZS5jc3MiIHR5cGU9InRleHQvY3NzIj48L2xpbms+CgkJPGxpbmsgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vY3NzL2RpZ2lrZXkvSGVhZGVyRm9vdGVyLmNzcyIvPgoJCTxsaW5rIHJlbD0ic3R5bGVzaGVldCIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vY3NzL2Ryb3B6b25lLmNzcyIvPgoJCQoJCTxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvRGVzaWduZXIvR2xvYmFsL0pTL2pxdWVyeS0xLjExLjMubWluLmpzIj48L3NjcmlwdD4KCQk8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0Rlc2lnbmVyL0dsb2JhbC9KUy9qcXVlcnktdWkuMS4xMS40Lm1pbi5qcyI+PC9zY3JpcHQ+CgkJPCEtLSA8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L2RpZ2lrZXkvY3VycmVuY3lTZXR0ZXIuanMiPjwvc2NyaXB0PiAgCgkJPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9kaWdpa2V5L2N1cnJlbmN5VG9nZ2xlLmpzIj48L3NjcmlwdD4gLS0+CgkJPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9kaWdpa2V5L2pzb24yLmpzIj48L3NjcmlwdD4KCQk8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L2RpZ2lrZXkvaGVhZGVyX3NlYXJjaF9jb29raWUuanMiPjwvc2NyaXB0PgoJCTxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2phdmFzY3JpcHQvanF1ZXJ5LmF1dG9jb21wbGV0ZS5qcyI+PC9zY3JpcHQ+CgkJPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9jb21tb25VdGlsLmpzIj48L3NjcmlwdD4gIAoJCTxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2phdmFzY3JpcHQvZHJvcHpvbmUuanMiLz4iPjwvc2NyaXB0PgoJCQoJCTwhLS1TVEFSVCBPRiBTaXRlQ29yZUhlYWRlci5qc3AgLS0+DQo8bGluayByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIiBocmVmPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0Rlc2lnbmVyL0hlYWRlci9NZXJrbGUvQ1NTL2hlYWRlci5jc3M/bGE9emgtQ04tUk1CJmFtcDt0cz1mY2VmMGQ3ZC05NTdhLTRiY2UtYjIwMi1mYTI4MjkwOTZkMzUiIC8+PGxpbmsgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9STUIgUVEgQ2hhdC9DU1MvanF1ZXJ5LXVpLmNzcz9sYT16aC1DTi1STUImYW1wO3RzPTliYjY3MWUwLWE5YjctNDBiOS1hOTQxLTBjM2JhZTkyZjY2YiIgLz48bGluayByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIiBocmVmPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0Rlc2lnbmVyL1JNQiBRUSBDaGF0L0NTUy9ybWJoZWFkZXIuY3NzP2xhPXpoLUNOLVJNQiZhbXA7dHM9OTVhNTgwODctZDc2Yy00YjdjLWI5OTQtNGEyNmZkMzZhYjY2IiAvPg0KPGRpdiBpZD0iaGVhZGVyIiBzY3NfZXhjbHVkZT0idHJ1ZSIgY29va2llLXRyYWNraW5nPSJXVC56X2hlYWRlcj1saW5rO2hlYWRlcl9mbGFnPWxpbmsiPgoJCiAgICA8ZGl2IGlkPSJoZWFkZXItbGVmdCI+CiAgICAgICAgPGEgaHJlZj0iaHR0cDovL3d3dy5kaWdpa2V5LmNvbS5jbiI+PGltZyBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9sb2dvX2RrLnBuZz9sYT16aC1DTi1STUImdHM9NWI2YjgxZGMtNzRiMy00MjhkLTgyNTEtYzk2ZWZiZWJlYzg5IiBhbHQ9IkRpZ2ktS2V5IEVsZWN0cm9uaWNzIC0gRWxlY3Ryb25pYyBDb21wb25lbnRzIERpc3RyaWJ1dG9yIiAvPjwvYT4KICAgIDwvZGl2PgogICAgPGRpdiBpZD0iaGVhZGVyLXJpZ2h0Ij4KICAgICAgICA8ZGl2IGlkPSJoZWFkZXItbG9jYWxlIj4KICAgICAgICAgICAgPGRpdiBjbGFzcz0iaGVhZGVyLWxvY2FsZS1yb3ciPgogICAgICAgICAgICAgICAgPHNwYW4+5Lit5Zu9PC9zcGFuPgogICAgICAgICAgICAgICAgPHNwYW4gY2xhc3M9ImhlYWRlci1zZXAiPjwvc3Bhbj4KICAgICAgICAgICAgICAgIDxzcGFuPjQwMCA5MjAgMTE5OTwvc3Bhbj4KICAgICAgICAgICAgPC9kaXY+CiAgICAgICAgICAgIDxkaXYgY2xhc3M9ImhlYWRlci1sb2NhbGUtcm93Ij4KICAgICAgICAgICAgICAgIDxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbCIgY2xhc3M9ImhlYWRlci1jaGFuZ2UtY291bnRyeSI+5pS55Y+Y5Zu95a62PC9hPgogICAgICAgICAgICAgICAgPGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsIj48aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvR2xvYmFsL0ZsYWdzL0NOX0ZsYWcucG5nP3RzPTVjOTU5NTIwLThiNWEtNDBiNy04NzU0LWQyOTZhY2VkNjEzOSIgY2xhc3M9ImhlYWRlci1mbGFnIiBhbHQ9IkNOIiAvPjwvYT4KICAgICAgICAgICAgICAgIDxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbCIgY2xhc3M9ImhlYWRlci1sYW5nIj48L2E+CiAgICAgICAgICAgICAgICA8c3BhbiBjbGFzcz0iaGVhZGVyLXNlcCI+PC9zcGFuPgogICAgICAgICAgICAgICAgPGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsIiBjbGFzcz0iaGVhZGVyLWN1cnJlbmN5Ij5DTlk8L2E+CiAgICAgICAgICAgIDwvZGl2PgogICAgICAgIDwvZGl2PgogICAgICAgIDxkaXY+PGRpdiBpZD0iaGVhZGVyLWNhcnQiIGNsYXNzPSJoZWFkZXItZHJvcGRvd24iPjxzcGFuIGNsYXNzPSJoZWFkZXItZHJvcGRvd24tdGl0bGUgaGVhZGVyLXJlc291cmNlIj48aW1nIGNsYXNzPSJoZWFkZXItaWNvbiIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9IZWFkZXIvY2FydC13aGl0ZS5wbmc/bGE9emgtQ04tUk1CJnRzPWUwMjIyNTYzLWQwNDgtNDZlMC04ZTUwLWNiZTAzOWY1MzIxMCIgYWx0PSJjYXJ0IHdoaXRlIiAvPiDmgqjnmoTpobnnm64gPGltZyBjbGFzcz0iaGVhZGVyLWljb24iIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvSGVhZGVyL3RyaWFuZ2xlLXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9M2EyY2NjZWItMzAzNC00NGRkLWEwNTYtYjM1ODI4Y2RmYjgxIiBhbHQ9InRyaWFuZ2xlIHdoaXRlIiAvPjwvc3Bhbj48ZGl2IGNsYXNzPSJoZWFkZXItZHJvcGRvd24tY29udGVudCI+PGEgaHJlZj0iaHR0cHM6Ly93d3cuZGlnaWtleS5jb20uY24vb3JkZXJpbmcvU2hvcHBpbmdDYXJ0Vmlldz9XVC56X2hlYWRlcj1saW5rIiBjbGFzcz0iaGVhZGVyLXZpZXctY2FydCBoZWFkZXItYnV0dG9uIj7mn6XnnIvotK3nianovaY8L2E+PC9kaXY+PC9kaXY+PHNwYW4gY2xhc3M9ImhlYWRlci1yZXNvdXJjZS1zZXAiPiZuYnNwOzwvc3Bhbj48ZGl2IGlkPSJoZWFkZXItbG9naW4iIGNsYXNzPSJoZWFkZXItZHJvcGRvd24iPjxkaXYgaWQ9ImhlYWRlci1sb2dpbi10aXRsZSIgY2xhc3M9ImhlYWRlci1kcm9wZG93bi10aXRsZSBoZWFkZXItcmVzb3VyY2UiPjxwIGNsYXNzPSJoZWFkZXItaGVsbG8iPueZu+W9leaIljwvcD48cD7ms6jlhowgPGltZyBjbGFzcz0iaGVhZGVyLWljb24iIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvSGVhZGVyL3RyaWFuZ2xlLXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9M2EyY2NjZWItMzAzNC00NGRkLWEwNTYtYjM1ODI4Y2RmYjgxIiBhbHQ9InRyaWFuZ2xlIHdoaXRlIiAvPjwvcD48L2Rpdj48ZGl2IGNsYXNzPSJoZWFkZXItZHJvcGRvd24tY29udGVudCI+PGEgaHJlZj0iaHR0cHM6Ly93d3cuZGlnaWtleS5jb20uY24vbXlkaWdpa2V5L0xvZ29uRm9ybSIgY2xhc3M9ImhlYWRlci1idXR0b24iPueZu+W9lTwvYT48YSBocmVmPSIvbXlkaWdpa2V5L1VzZXJSZWdpc3RyYXRpb25BZGRGb3JtVmlldyIgY2xhc3M9ImhlYWRlci1idXR0b24iPuazqOWGjDwvYT48YSBocmVmPSIvemgvaGVscC93aHktcmVnaXN0ZXIiIGNsYXNzPSJoZWFkZXItYnV0dG9uIj7kuLrkvZXms6jlhow8L2E+PC9kaXY+PC9kaXY+PC9kaXY+CiAgICA8L2Rpdj4KICAgIDxkaXYgaWQ9ImhlYWRlci1taWRkbGUiPgogICAgICAgIDxkaXYgaWQ9ImhlYWRlci1zZWFyY2gtd3JhcHBlciI+CiAgICAgICAgICAgIDxkaXYgaWQ9ImhlYWRlci1zZWFyY2gtc2VsZWN0LXdyYXBwZXIiPgogICAgICAgICAgICAgICAgPHNlbGVjdCBpZD0iaGVhZGVyLXNlYXJjaC10eXBlIj4KICAgICAgICAgICAgICAgICAgICA8b3B0aW9uIHNlbGVjdGVkPSJzZWxlY3RlZCIgdmFsdWU9Ii9zZWFyY2gvemg/V1Quel9oZWFkZXI9c2VhcmNoX2dvJmFtcDtrZXl3b3Jkcz17MH0iIGRhdGEtbmFtZT0ia2V5d29yZHMiPumbtuS7tjwvb3B0aW9uPjxvcHRpb24gdmFsdWU9Ii96aC9jb250ZW50LXNlYXJjaD90PXswfSZhbXA7V1Quel9oZWFkZXI9c2VhcmNoX2dvIiBkYXRhLW5hbWU9Ik50dCI+5YaF5a65PC9vcHRpb24+CiAgICAgICAgICAgICAgICA8L3NlbGVjdD4KICAgICAgICAgICAgPC9kaXY+CiAgICAgICAgICAgIDxidXR0b24gaWQ9ImhlYWRlci1zZWFyY2gtYnV0dG9uIiB0eXBlPSJidXR0b24iPjwvYnV0dG9uPgogICAgICAgICAgICA8c3BhbiBpZD0iaGVhZGVyLXNlYXJjaC1ob2xkZXIiPjxpbnB1dCBpZD0iaGVhZGVyLXNlYXJjaCIgdHlwZT0idGV4dCIgY2xhc3M9ImRrZGlyY2hhbmdlciIgLz48L3NwYW4+CiAgICAgICAgPC9kaXY+CiAgICAgICAgPGRpdj48YSBocmVmPSIvc2VhcmNoL3poIiBjbGFzcz0iaGVhZGVyLXJlc291cmNlIj7kuqflk4E8L2E+PHNwYW4gY2xhc3M9ImhlYWRlci1yZXNvdXJjZS1zZXAiPiZuYnNwOzwvc3Bhbj48YSBocmVmPSIvemgvc3VwcGxpZXItY2VudGVycyIgY2xhc3M9ImhlYWRlci1yZXNvdXJjZSI+5Yi26YCg5ZWGPC9hPjxzcGFuIGNsYXNzPSJoZWFkZXItcmVzb3VyY2Utc2VwIj4mbmJzcDs8L3NwYW4+PGRpdiBjbGFzcz0iaGVhZGVyLWRyb3Bkb3duIj48c3BhbiBjbGFzcz0iaGVhZGVyLWRyb3Bkb3duLXRpdGxlIGhlYWRlci1yZXNvdXJjZSI+6LWE5rqQIDxpbWcgY2xhc3M9ImhlYWRlci1pY29uIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci90cmlhbmdsZS13aGl0ZS5wbmc/bGE9emgtQ04tUk1CJnRzPTNhMmNjY2ViLTMwMzQtNDRkZC1hMDU2LWIzNTgyOGNkZmI4MSIgYWx0PSJ0cmlhbmdsZSB3aGl0ZSIgLz48L3NwYW4+PGRpdiBjbGFzcz0iaGVhZGVyLXJlc291cmNlLWNvbnRlbnQgaGVhZGVyLWRyb3Bkb3duLWNvbnRlbnQiPjxwIGNsYXNzPSJoZWFkZXItZGFyayI+5Y+C6ICDPC9wPjx1bD48bGk+PGEgaHJlZj0iL3poL2FydGljbGVzL3RlY2h6b25lLyI+5paH5bqTPC9hPjwvbGk+PGxpPjxhIGhyZWY9Ii96aC9jb250ZW50LXNlYXJjaCI+5YaF5a655bqTCjwvYT48L2xpPjxsaT48YSBocmVmPSIvemgvcHJvZHVjdC1oaWdobGlnaHQiPuacgOaWsOS6p+WTgQo8L2E+PC9saT48bGk+PGEgaHJlZj0iL3poL3B0bSI+5Lqn5ZOB5Z+56K6t5qih5Z2XIChQVE0pPC9hPjwvbGk+PGxpPjxhIGhyZWY9Ii92aWRlb3MvemgiPuinhumikeW6kzwvYT48L2xpPjwvdWw+PGhyIGNsYXNzPSJoZWFkZXItZHJvcGRvd24tc2VwIj48L2hyPjxwIGNsYXNzPSJoZWFkZXItZGFyayI+6K6+6K6hPC9wPjx1bD48bGk+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9vbmxpbmUtY29udmVyc2lvbi1jYWxjdWxhdG9ycyI+5Zyo57q/5o2i566X5ZmoPC9hPjwvbGk+PGxpPjxhIGhyZWY9Ii9yZWZlcmVuY2UtZGVzaWducy96aCI+5Y+C6ICD6K6+6K6hCjwvYT48L2xpPjxsaT48YSBocmVmPSIvemgvdGVjaHpvbmVzIj5UZWNoWm9uZXPihKA8L2E+PC9saT48L3VsPjxociBjbGFzcz0iaGVhZGVyLWRyb3Bkb3duLXNlcCI+PC9ocj48cCBjbGFzcz0iaGVhZGVyLWRhcmsiPuaQnOe0oi/mjpLluo88L3A+PHVsPjxsaT48YSBocmVmPSIvb3JkZXJpbmcvQm9tTWFuYWdlciI+54mp5paZ5riF5Y2V566h55CG5ZmoIDwvYT48L2xpPjxsaT48YSBocmVmPSIvemgvcmVzb3VyY2VzL2Jyb3dzZXItcmVzb3VyY2VzIj7mtY/op4jlmajotYTmupA8L2E+PC9saT48bGk+PGEgaHJlZj0iL29yZGVyaW5nL09yZGVyU3RhdHVzRW50cnlWaWV3Ij7orqLljZXnirbmgIE8L2E+PC9saT48bGk+PGEgaHJlZj0iL29yZGVyaW5nL1Nob3BwaW5nQ2FydFZpZXciPui0reeJqei9pgo8L2E+PC9saT48L3VsPjwvZGl2PjwvZGl2PjxzcGFuIGNsYXNzPSJoZWFkZXItcmVzb3VyY2Utc2VwIj4mbmJzcDs8L3NwYW4+PGEgaHJlZj0iamF2YXNjcmlwdDo7IiBpZD0icXFvbmxpbmVfZmxvYXQiIGNsYXNzPSJoZWFkZXItcmVzb3VyY2UiPjxpbWcgY2xhc3M9ImhlYWRlci1pY29uIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9jaGF0LXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9ZjIyOWYxMDQtOGQ3OC00NzkwLWIyYjgtMjZkYzM2ZDk5NDkyIiBhbHQ9ImNoYXQgd2hpdGUiIC8+IFFR5Zyo57q/5ZKo6K+iPC9hPjwvZGl2PgogICAgPC9kaXY+Cgo8L2Rpdj4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij5fX2hlYWRlckRhdGEgPSB7ImNhcnRUaXRsZSI6IiZjYXJ0OyB7MH0g6aG5ICZkcm9wZG93bjsiLCJ2aWV3Q2FydCI6Iuafpeeci+i0reeJqei9piAoezB9IOmhueebrikiLCJ1c2VyTGluZTEiOiLmgqjlpb0gezB9IiwidXNlckxpbmUyIjoi5oiR55qEIERpZ2ktS2V5ICZkcm9wZG93bjsiLCJub0ltYWdlIjoiaHR0cDovL21lZGlhLmRpZ2lrZXkuY29tL1Bob3Rvcy9Ob1Bob3RvL3BuYV9lbl90bWIuanBnIiwiZW50aXRpZXMiOnsiY2FydCI6IjxpbWcgY2xhc3M9XCJoZWFkZXItaWNvblwiIHNyYz1cIi8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9jYXJ0LXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9ZTAyMjI1NjMtZDA0OC00NmUwLThlNTAtY2JlMDM5ZjUzMjEwXCIgYWx0PVwiY2FydCB3aGl0ZVwiIC8+IiwiZHJvcGRvd24iOiI8aW1nIGNsYXNzPVwiaGVhZGVyLWljb25cIiBzcmM9XCIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9IZWFkZXIvdHJpYW5nbGUtd2hpdGUucG5nP2xhPXpoLUNOLVJNQiZ0cz0zYTJjY2NlYi0zMDM0LTQ0ZGQtYTA1Ni1iMzU4MjhjZGZiODFcIiBhbHQ9XCJ0cmlhbmdsZSB3aGl0ZVwiIC8+IiwiY2hhdCI6IjxpbWcgY2xhc3M9XCJoZWFkZXItaWNvblwiIHNyYz1cIi8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9jaGF0LXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9ZjIyOWYxMDQtOGQ3OC00NzkwLWIyYjgtMjZkYzM2ZDk5NDkyXCIgYWx0PVwiY2hhdCB3aGl0ZVwiIC8+In0sInNpdGUiOiJDTiIsImxhbmciOiJ6aCIsImN1ciI6IkNOWSIsImVuYWJsZVRvZ2dsZSI6dHJ1ZSwiZW5hYmxlQ3VyVG9nZ2xlIjp0cnVlLCJsYW5ncyI6W3sibmFtZSI6bnVsbCwiY29kZSI6InpoIn1dLCJvcmRlclNpdGUiOiJjbiIsIm9yZGVyTGFuZyI6InpoIiwiY3VycyI6WyJDTlkiLCJVU0QiXSwibGlua3MiOlt7InRpdGxlIjoi5oiR55qEIERpZ2ktS2V5IiwibGluayI6Imh0dHBzOi8vd3d3LmRpZ2lrZXkuY29tLmNuL215ZGlnaWtleS9Mb2dvbkZvcm0gIn0seyJ0aXRsZSI6IumAgOWHuiIsImxpbmsiOiIvbXlkaWdpa2V5L0xvZ29mZiJ9XX07PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9IZWFkZXIvTWVya2xlL0phdmFzY3JpcHQvaGVhZGVyLmpzP3RzPTAxYWFiMjExLWE0NDMtNGIwYy1hYjBiLTA3YWM3Y2QyY2IwZCI+PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9STUIgUVEgQ2hhdC9KYXZhc2NyaXB0L3JtYmhlYWRlci5qcz9sYT16aC1DTi1STUImYW1wO3RzPWY3YzI1NmViLTcwNDItNDNkNC05MDQwLTI0ZjM5MjVlYmYwMyI+PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9STUIgUVEgQ2hhdC9KYXZhc2NyaXB0L3N1Ym1pdF9jb250ZW50X3RvX2JhaWR1LmpzP2xhPXpoLUNOLVJNQiZhbXA7dHM9Mzc4MTE5NTgtMGU3NS00MjBjLTg4ZmMtY2Y1MWYyZDgzNGM4Ij48L3NjcmlwdD48c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCI+PC9zY3JpcHQ+DQoNCg0KPCEtLUVORCBPRiBTaXRlQ29yZUhlYWRlci5qc3AgLS0+DQo8ZGl2IGlkPSJjb250ZW50Ij4gPCEtLSBTdGFydCBvZiBkaXYgY29udGVudCAtLT48IS0tIFN0YXJ0IEhlYWRlciBDb250ZW50IC0tPgo8ZGl2IGlkPSJqc3BTdG9yZUltZ0RpciIgc3R5bGU9ImRpc3BsYXk6bm9uZSI+L3djc3N0b3JlL0NOLzwvZGl2Pgo8IS0tIEhlYWRlciBDb250ZW50IEVuZHMtLT48IS0tIGhlbHAgZGlhbG9nIGNvbnRlbnQgLS0+DQoNCjxkaXYgaWQ9IlRBUEVSRUVMX1BhY2thZ2luZ0hlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCeWNt+W4puaYr+aMh+S7juWItumAoOWVhuaOpeaUtueahOeOsOaIkOi/nue7reWMheijheW4puWNt+OAguS9jeS6juWni+err+WSjOacq+err+eahOepuueZveW4pu+8jOS6puWIhuWIq+ensOW8leW4puWSjOWwvuW4pu+8jOacieWKqeS6juS9v+eUqOiHquWKqOijhemFjeiuvuWkh+OAguWNt+W4puaYr+agueaNrueUteWtkOW3peS4muWQjOebnyAoRUlBKSDmoIflh4bnvKDnu5XmiJDloZHmlpnnm5jljbfjgILnm5jljbflsLrlr7jjgIHpl7Tot53jgIHmlbDph4/lkozmlrnlkJHlj4rlhbbku5bor6bnu4bkv6Hmga/lnYfkvY3kuo7pm7bku7bop4TmoLzkuabnu5PlsL7lpITjgILljbfluKbkvJrmoLnmja7liLbpgKDllYbop4TlrprnmoQgRVNE77yI6Z2Z55S15pS+55S177yJ5ZKMIE1TTO+8iOa5v+W6puaVj+aEn+etiee6p++8ieS/neaKpOimgeaxgui/m+ihjOWMheijheOAgg0KPC9kaXY+DQoNCjxkaXYgaWQ9IkNVVFRBUEVfUGFja2FnaW5nSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyI+DQoJ5YiH5bim5oyH5LuO5bim5Y2377yI6KeB5LiK5paH5LuL57uN77yJ5LiK5YiH5LiL55qE5LiA5q6177yM5ZCr5pyJ6K6i6LSt5pWw6YeP55qE6Zu25Lu244CC5YiH5bim5rKh5pyJ5byV5bim5ZKM5bC+5bim77yM5Zug5q2k5LiN6YCC55So5LqO6K645aSa6Ieq5Yqo6KOF6YWN6K6+5aSH44CC5YiH5bim54S25ZCO5Lya5oyJ54Wn5Yi26YCg5ZWG6KeE5a6a55qEIEVTRO+8iOmdmeeUteaUvueUte+8ieWSjCBNU0zvvIjmub/luqbmlY/mhJ/nrYnnuqfvvInkv53miqTopoHmsYLov5vooYzljIXoo4XjgIINCjwvZGl2Pg0KDQo8ZGl2IGlkPSJCVUxLX1BhY2thZ2luZ0hlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCeaVo+ijheaYr+eUqOS6juadguS5seOAgeadvuaVo+mbtuS7tueahOWMheijheW9ouW8j++8iOmAmuW4uOS4uuiii+WtkO+8ie+8jOS4lOS4gOiIrOaDheWGteS4i+S4jemAgueUqOS6juiHquWKqOijhemFjeiuvuWkh+OAguaVo+ijhembtuS7tuS8muagueaNruWItumAoOWVhuinhOWumueahCBFU0TvvIjpnZnnlLXmlL7nlLXvvInlkowgTVNM77yI5rm/5bqm5pWP5oSf562J57qn77yJ5L+d5oqk6KaB5rGC6L+b6KGM5YyF6KOF44CCDQo8L2Rpdj4NCg0KPGRpdiBpZD0iVEFQRUFOREJPWF9QYWNrYWdpbmdIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7Ij4NCgnnm5LluKbmmK/kuIDmrrXluKbmnInpm7bku7bnmoTluKblrZDvvIzmnaXlm57mipjlj6DmiJbogIXljbfmiJDonrrml4vnirblkI7mlL7lhaXnm5LlrZDkuK3jgIIg5bim5a2Q5LiA6Iis5LuO55uS5a2Q55qE6aG26YOo5byA5a2U5aSE5ouJ5Ye644CCIOW4puWtkOinhOagvOOAgemXtOi3neOAgeaVsOmHj+OAgeaWueWQkeS7peWPiuWFtuWug+ivpue7huS/oeaBr+mAmuW4uOS9jeS6jumbtuS7tuinhOagvOS5pueahOe7k+WwvumDqOWIhuOAgiDnm5LluKbmoLnmja7liLbpgKDllYbop4TlrprnmoQgIEVTRO+8iOmdmeeUteaUvueUte+8ieWSjCBNU0zvvIjmub/luqbmlY/mhJ/nrYnnuqfvvInkv53miqTopoHmsYLljIXoo4XjgIINCjwvZGl2Pg0KDQo8ZGl2IGlkPSJUVUJFX1BhY2thZ2luZ0hlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCeeuoeijheaYr+S4gOenjeehrOi0qOaMpOWOi+WhkeaWmeeuoeW9ouWMheijhe+8jOiDveWkn+mAguWQiOmbtuS7tuWkluW9ou+8jOS/neaKpOW8leiEmuOAgueuoeijheWPkei0p+aXtuWGheWQq+S4juiuoui0reaVsOmHj+S4gOiHtOeahOmbtuS7tu+8jOS4lOS4pOerr+Wdh+acieS4gOS4quapoeearuWhnuaIluiAheWhkeaWmeapm++8jOS7pemYsumbtuS7tuS7jueuoeS4rea7keiQveOAgueuoeijheS8muagueaNruWItumAoOWVhuinhOWumueahCBFU0TvvIjpnZnnlLXmlL7nlLXvvInlkowgTVNM77yI5rm/5bqm5pWP5oSf562J57qn77yJ5L+d5oqk6KaB5rGC6L+b6KGM5YyF6KOF44CCDQo8L2Rpdj4NCg0KPGRpdiBpZD0iVFJBWV9QYWNrYWdpbmdIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7Ij4NCgnmiZjnm5jpgJrluLjmjIfop4TmoLzkuLogMTIuN3g1LjN4MC4yNe+8iOmrmO+8ieiLseWvuOaIluiAhSAxMi43eDUuM3gwLjQw77yI6auY77yJ6Iux5a+455qEIEpFREVDIOagh+WHhuefqemYteaJmOebmOOAgiDmiZjnm5jpgJrluLjnlLHloZHmlpnliLbmiJDvvIzkuZ/lhYHorrjph4fnlKjpk53jgIIgSkVERUMg5omY55uY5LiK5pyJ6IO95L2/56m65rCU5Z6C55u06YCa6L+H55qE5qe957yd77yM5bm25LiU6Iez5bCR6IO95om/5Y+XIDE0MMKwQyDpq5jmuKnvvIzku6Xkvr/lnKjlt6XkuJrng5jngonkuK3lubLnh6Xpm7bku7bjgIIg5omY55uY5Y+v5Lul5aCG5Y+g77yM55So5LiA5Liq5YCS6KeS5oyH56S66Zu25Lu255qE5LiA5Y+35byV6ISa55qE5pa55ZCR44CCIOaJmOebmOagueaNruWItumAoOWVhuinhOWumueahCAgRVNE77yI6Z2Z55S15pS+55S177yJ5ZKMIE1TTO+8iOa5v+W6puaVj+aEn+etiee6p++8ieS/neaKpOimgeaxguWMheijheOAgg0KPC9kaXY+DQoNCjxkaXYgaWQ9IkRJR0ktUkVFTF9QYWNrYWdpbmdIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7Ij4NCgk8cD5EaWdpLVJlZWzCriDmmK/kuIDnp43luKbljbfovbTvvIzmoLnmja7lrqLmiLfoh6rlrprmlbDph4/ku47nlJ/kuqfllYbnmoTluKbljbfovbTkuIrlsIbnu53nvJjluKbov57nu63nvKDnu5XlnKjov5nkuKrluKbljbfovbTkuIrjgIIg5bim5pyJNDYgY23lpLTlsL7lvJXluKbvvIzog73kvb/pk77ova7pvb/lrZTmiJDkuIDnur/lr7nnm7TvvIzlubbnoa7kv53ljbfluKbnrJTnm7TkuJTmr6vml6DlgY/lt67lnLDpgIHlhaXoh6rliqjljJbmnb/oo4Xnva7orr7lpIfvvJvnhLblkI7moLnmja7nlLXlrZDlt6XkuJrlkIznm58oRUlBKeeahOagh+WHhuaKiuWNt+W4pumHjeaWsOWNt+e7leWcqOS4gOS4quWhkeaWmeW4puWNt+i9tOS4iuOAgiDlnKjlpKflpJrmlbDmg4XlhrXkuIvvvIzmiJHku6zlj6/kvp3lrqLmiLforqLljZXkuJPpl6jnu4Too4Xov5nnp43luKbljbfovbTvvIzlubblnKjlvZPml6Xlj5HotKfjgIIg5Zyo5peg5rOV5ruh6Laz5oKo55qE6K6i5Y2V6KaB5rGC55qE5oOF5Ya15LiL77yM5oiR5Lus5Lya5LiO5oKo6IGU57O744CCPC9wPjxwPuWvueavj+S4gOS4quW4puWNt+i9tOaIkeS7rOWwhuaUtuS4gOeslOOAjOWNt+e7lei0ueOAje+8jOW5tuaKiuWug+WMheaLrOWcqOaCqOeahOaAu+i0ueeUqOS4reOAgjwvcD48cD5EaWdpLVJlZWzCriDlvpfmjbflrprliLbljbfluKbmmK/kuIDnp43mjInnhaflrqLmiLfoh6rlrprnmoTljbfluKbvvIwg5LiN5Y+v5Y+W5raI77yM5LiN5Y+v6YCA6LSn44CCPC9wPg0KPC9kaXY+DQo8IS0tIEZvciBXZWJUcmVuZHMgVHJhY2tpbmcgcHVycG9zZSAtIHN0YXJ0IC0tPjxNRVRBIG5hbWU9IldULnpfcGFnZV90eXBlIiBjb250ZW50PSJQUyIgLz48TUVUQSBuYW1lPSJXVC56X3BhZ2Vfc3ViX3R5cGUiIGNvbnRlbnQ9IlBEIiAvPjwhLS0gRm9yIFdlYlRyZW5kcyBUcmFja2luZyBwdXJwb3NlIC0gZW5kIC0tPg0KDQo8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9tYWluLmpzIj48L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L1V0aWwuanMiPjwvc2NyaXB0Pg0KPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iL3djc3N0b3JlL0NOL2phdmFzY3JpcHQvc2hvd3RoaWNrYm94LmpzIj48L3NjcmlwdD4gDQoNCjwhRE9DVFlQRSBodG1sIFBVQkxJQyAiLS8vVzNDLy9EVEQgWEhUTUwgMS4wIFRyYW5zaXRpb25hbC8vRU4iICJodHRwOi8vd3d3LnczLm9yZy9UUi94aHRtbDEvRFREL3hodG1sMS10cmFuc2l0aW9uYWwuZHRkIj4KCjwhLS0gU3RhcnQgLSBKU1BGIEZpbGUgTmFtZTogSlNUTEVudmlyb25tZW50U2V0dXAuanNwZiAtLT48IS0tIFdBU19OQU1FIENISU5BX1BST0RfU0VSVkVSMSAgLS0+CjwhLS0gRW5kIC0gSlNQRiBGaWxlIE5hbWU6IEpTVExFbnZpcm9ubWVudFNldHVwLmpzcGYgLS0+DQoNCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L1NlYXJjaEFyZWEvc2hvcnR1cmwuanMiPjwvc2NyaXB0Pg0KDQo8ZGl2IGlkPSJzaG9ydFVSTERpYWxvZyIgc3R5bGU9ImRpc3BsYXk6IG5vbmU7IiB0aXRsZT0i5b+r5o23IFVSTCI+DQoJ5aSN5Yi25Lul5LiL6ZO+5o6l5bm257KY6LS06Iez5oKo5biM5pyb55qE5Lu75L2V5L2N572u77yM5YiG5Lqr5b2T5YmN572R6aG144CCPGJyIC8+PGJyIC8+DQo8L2Rpdj4NCjxkaXYgaWQ9InNob3J0VVJMRXJyb3JEaWFsb2ciIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IuW/q+aNtyBVUkwiPg0KCeivpeWKn+iDveebruWJjeS4jeWPr+eUqO+8jOaIkeS7rOato+WKquWKm+S/ruWkjeOAguiwouiwouaCqOeahOiAkOW/g+etieW+heOAgiA8YnIgLz48YnIgLz4NCjwvZGl2Pg0KPGRpdiBhbGlnbj0icmlnaHQiPg0KCTxkaXYgaWQ9ImRrLXNoYXJlbGluayIgc3R5bGU9IndpZHRoOiAxNDBweDtjdXJzb3I6cG9pbnRlcjsiIG9uY2xpY2s9InNob3J0SW5pdCgnc2hvcnRVUkxEaWFsb2cnICwnc2hvcnRVUkxFcnJvckRpYWxvZycpIj4NCgnliIbkuqvmnKzpobXlhoXlrrkgDQoJPGEgaWQ9ImRrLXNoYXJlaW1hZ2VsaW5rIiBzdHlsZT0iY3Vyc29yOnBvaW50ZXI7Ij4NCgk8aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vaW1hZ2VzL2RpZ2lrZXkvbGluay5wbmciIHRpdGxlPSLnn63pk77mjqUiIGJvcmRlcj0iMCIgYWxpZ249InRvcCI+DQoJPC9hPg0KCTwvZGl2Pg0KCTxkaXYgaWQ9InNob3J0eS1oZWxwZXJzIiBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCTxpbnB1dCB0eXBlPSJoaWRkZW4iIGlkPSJpcFBIIiB2YWx1ZT0iMjIwLjEzMy4yNi43NCIvPg0KCTxpbnB1dCB0eXBlPSJoaWRkZW4iIGlkPSJtZXRob2RQSCIgdmFsdWU9IjAiLz4NCgk8aW5wdXQgdHlwZT0iaGlkZGVuIiBpZD0iYm9keVBIIiB2YWx1ZT0iIi8+DQoJPGlucHV0IHR5cGU9ImhpZGRlbiIgaWQ9InNob3J0VXJsVmFsdWUiLz4NCgk8L2Rpdj4NCg0KPC9kaXY+CQkJCQ0KCQ0KPHN0eWxlIHR5cGU9InRleHQvY3NzIj4NCgkjRmlsdGVyVGFibGV7DQoJICAgIHdpZHRoOjk5JTsNCgkgICAgaGVpZ2h0OjIxMHB4Ow0KCSAgICBvdmVyZmxvdy14OiBzY3JvbGw7DQoJICAgIG92ZXJmbG93LXk6IGhpZGRlbjsNCgkgICAgd2hpdGUtc3BhY2U6IG5vd3JhcDsNCgl9DQoNCjwvc3R5bGU+CQkJDQo8Zm9ybSBuYW1lPSJLZXl3b3JkU2VhcmNoIiBpZD0iS2V5d29yZFNlYXJjaCIgYWN0aW9uPSIvc2VhcmNoL3poIiBtZXRob2Q9J2dldCcgYXV0b2NvbXBsZXRlPSJvZmYiIGVuY3R5cGU9ImFwcGxpY2F0aW9uL3gtd3d3LWZvcm0tdXJsZW5jb2RlZCI+DQoNCjxiPuWFs+mUruWtlzo8L2I+Jm5ic3A7DQo8YSBocmVmPSJqYXZhc2NyaXB0OiBzaG93SGVscERpYWxvZygnI2tleXdvcmRTZWFyY2hIZWxwRGlhbG9nJywnYXV0bycsJzI1MHB4JyxmYWxzZSx0cnVlKSI+PGltZyBpZD0iU2VhcmNoSGVscEltYWdlIiBib3JkZXI9IjAiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vaW1hZ2VzL2hlbHAucG5nIj48L2E+DQoNCiZuYnNwOyZuYnNwOw0KDQoNCiANCg0KDQo8aW5wdXQgdHlwZT0ndGV4dCcgaWQ9J2tleXdvcmRzJyBuYW1lPSdrZXl3b3Jkcycgc2l6ZT0nMzUnIG1heGxlbmd0aD0nMjUwJyB2YWx1ZT0nJyBjbGFzcz0iYWNfaW5wdXQiIGF1dG9jb21wbGV0ZT0ib2ZmIi8+DQoNCjxpbnB1dCB0eXBlPSdoaWRkZW4nIGlkPSdpc1JtYlNlYXJjaCcgbmFtZT0naXNSbWJTZWFyY2gnIHZhbHVlPSd0cnVlJy8+DQombmJzcDsmbmJzcDsNCg0KPGlucHV0IHR5cGU9ImhpZGRlbiIgbmFtZT0icmVmUElkIiB2YWx1ZT0iMyIgLz4NCjxpbnB1dCB0eXBlPSdjaGVja2JveCcgaWQ9J3N0b2NrJyBuYW1lPSdzdG9jaycgdmFsdWU9JzEnIG9uY2hhbmdlPSdqYXZhc2NyaXB0OnVwZENvdW50QmFzZWRPbkZpbHRlcnMoKTsnLz48bGFiZWwgZm9yPSdzdG9jayc+546w6LSnPC9sYWJlbD4mbmJzcDsmbmJzcDs8aW5wdXQgdHlwZT0nY2hlY2tib3gnIGlkPSdwYmZyZWUnIG5hbWU9J3BiZnJlZScgdmFsdWU9JzEnIG9uY2hhbmdlPSdqYXZhc2NyaXB0OnVwZENvdW50QmFzZWRPbkZpbHRlcnMoKTsnLz48bGFiZWwgZm9yPSdwYmZyZWUnPuaXoOmThTwvbGFiZWw+Jm5ic3A7Jm5ic3A7PGlucHV0IHR5cGU9J2NoZWNrYm94JyBpZD0ncm9ocycgbmFtZT0ncm9ocycgdmFsdWU9JzEnIG9uY2hhbmdlPSdqYXZhc2NyaXB0OnVwZENvdW50QmFzZWRPbkZpbHRlcnMoKTsnLz48bGFiZWwgZm9yPSdyb2hzJz7nrKblkIjpmZDliLbmnInlrrPnianotKjmjIfku6QoUm9IUynop4TojIPopoHmsYI8L2xhYmVsPiZuYnNwOyZuYnNwOw0KPGJyLz4NCjxici8+DQo8aW5wdXQgdHlwZT1zdWJtaXQgdmFsdWU9J+mHjeaWsOaQnOe0oicgaWQ9InNlYXJjaEFnYWluU3VibWl0QnV0dG9uIi8+DQo8aHIgLz4NCjwvZm9ybT4NCg0KDQo8ZGl2IGlkPSJrZXl3b3JkU2VhcmNoSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IuWFs+mUruWtlyIgPg0KPHA+5YWz6ZSu5a2X5YyF5ousIOW+l+aNt+eUteWtkCDpm7bku7bnvJblj7fjgIHliLbpgKDllYbpm7bku7bnvJblj7fjgIHliLbpgKDllYblkI3np7DmiJbkuI7mgqjmkJzntKLnmoTkuqflk4HmnInlhbPnmoTku7vkvZXmj4/ov7DmgKfmlofmnKzjgILmgqjlj6/ku6Xkvb/nlKjmlbTkuKrljZXor43jgIHliY3nvIDjgIHlkI7nvIDmiJbnlJroh7PlrZDlrZfnrKbkuLLkvZzlhbPplK7lrZfjgII8L3A+PHA+6YCa5bi45L2/55So56m65qC85bCG5YWz6ZSu5a2X6ZqU5byA77yM5Zug5q2k5LiN6ZyA6KaB5byV5Y+344CC5Y+q5pyJ6KaB5Zyo5YWz6ZSu5a2X5Lit5bWM5YWl56m65qC85pe25omN6ZyA6KaB55So5byV5Y+35bCG5YWz6ZSu5a2X5ous6LW35p2l44CCPC9wPjxwPum7mOiupOaDheWGteS4i++8jOaQnOe0ouaTjeS9nOWPquS8mui/lOWbnuWMheWQq+aJgOacieWFs+mUruWtl+eahOiusOW9leOAguWIhumalOWFs+mUruWtl+eahOepuuagvOmakOWQq+WcsOi1t+WIsOmAu+i+kSBBTkQg6L+Q566X56ym55qE5L2c55So44CC5L2G5piv77yM5oKo5Lmf5Y+v5Zyo5oKo55qE5YWz6ZSu5a2X5YiX6KGo5Lit5piO5pi+5Zyw5L2/55So6YC76L6R6L+Q566X56ymICIuYW5kLiLjgIEiLm9yLiIg5ZKMICIubm90LiLjgILmiJbkuLrkuoboioLnnIHmjInplK7mrKHmlbDvvIzmgqjlj6/ku6XnlKggInwiIOabv+S7oyAiLm9yLiLvvIznlKggIn4iIOabv+S7oyAiLm5vdC4iPC9wPg0KPC9kaXY+PCEtLSBCcmVhZGNydW1iIC0tPg0KPGRpdiBzdHlsZT0ncGFkZGluZy1ib3R0b206IDIwcHg7IHBhZGRpbmctdG9wOiAyMHB4Oyc+DQoJDQoJDQoJPGgyIGNsYXNzID0gInNlb2h0YWciPiANCgkJPGEgaHJlZj0naHR0cDovL3d3dy5kaWdpa2V5LmNvbS5jbi9zZWFyY2gvemg/Y2F0YWxvZ0lkPSc+5Lqn5ZOB57Si5byVPC9hPiZuYnNwOyZndDsmbmJzcDsNCgkJPGEgaHJlZj0nL3NlYXJjaC96aC/nlLXpmLvlmagvNjgxJz4mIzMwMDA1OyYjMzg0NTk7JiMyMjEyMDs8L2E+Jm5ic3A7Jmd0OyZuYnNwOw0KCQk8YSBocmVmPScvc2VhcmNoL3poL+eUtemYu+WZqC/kuJPnlKjlnovnlLXpmLvlmagvNjg2Jz4mIzE5OTg3OyYjMjk5OTI7JiMyMjQxMTsmIzMwMDA1OyYjMzg0NTk7JiMyMjEyMDs8L2E+Jm5ic3A7Jmd0OyZuYnNwOzE2My43MDEwLjAxMDINCgk8L2gyPg0KPC9kaXY+DQoNCg0KPGRpdiBzdHlsZT0iZGlzcGxheTpub25lIj4NCjxoMj5MaXR0ZWxmdXNlIEluYy48L2gyPg0KPC9kaXY+DQo8ZGl2IGlkPSJlcnJvck1lc3NhZ2VCbG9jayIgc3R5bGU9J2NvbG9yOiByZWQ7Jz4NCjwhLS0gU3RhcnQgLSBKU1AgRmlsZSBOYW1lOiAgRXJyb3JNZXNzYWdlU2V0dXAuanNwZiAtLT48IS0tIEVuZCAtIEpTUCBGaWxlIE5hbWU6ICBFcnJvck1lc3NhZ2VTZXR1cC5qc3BmIC0tPg0KPC9kaXY+DQoNCjwhLS0gSGVyZSBpcyB3aGVyZSB0aGUgQ2hpcCBPdXRwb3N0IGltYWdlIC8gbGluayB3aWxsIGdvIGlmIG9uZSBpcyBuZWVkZWQgLS0+DQo8dGFibGUgY2xhc3M9InByb2R1Y3QtZGV0YWlscy10YWJsZSIgY2VsbHNwYWNpbmc9JzEnIGJvcmRlcj0nMCc+DQo8IS0tIENvZGUgY2hhbmdlIGZvciBQcm9kdWN0IEJhY2tsb2cgSXRlbSA1NDY2OTpWZW5kb3IgMTAzNCBObyBXYXJyYW50eSAtLT48IS0tIEFkZGVkIG5ldyBzdG9yZXRleHQgcHJvcGVydHkgRElPREVfSU5DX1dBUlJBTlRZX01TRyBpbiBzdG9yZXRleHRfemhfQ04ucHJvcGVydGllcyAtLT48IS0tIEVuZCBjaGFuZ2UgLS0+DQoJCTx0cj4NCgkJCTx0ZCBjbGFzcz0iYmVhYmxvY2stbm90aWNlIiBjb2xzcGFuPSIyIiB2YWxpZ249InRvcCI+DQoJCQkJPHA+ICA8c3BhbiAgc3R5bGU9ImZvbnQtd2VpZ2h0OiBib2xkOyI+DQoJCQkJCQ0KCQkJCQkJPHNwYW4gIHN0eWxlPSJmb250LXdlaWdodDogYm9sZDsiPg0KCQkJCQkJIOmdnuW6k+WtmOi0pyZuYnNwOyA8YSBocmVmPSJqYXZhc2NyaXB0OiBzaG93SGVscERpYWxvZygnI25vblN0b2NrSGVscERpYWxvZycsJ2F1dG8nLDMwMCxmYWxzZSx0cnVlKSI+PGltZyBpZD0iU2VhcmNoSGVscEltYWdlIiBib3JkZXI9IjAiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vaW1hZ2VzL2hlbHAucG5nIj48L2E+DQoJCQkJCQk8L3NwYW4NCgkJCQkJCTxiciAvPjxiciAvPg0KCQkJCQkNCgkJCQkJCQkJPHNwYW4+5LiN5YaN55Sf5Lqn55qE54mI5pysIOivt+WPgumYheKAnOabv+S7o+WwgeijheKAneaIluKAnOabv+S7o+WTgeKAnemAiemhueOAgjwvc3Bhbj4NCgkJCQkJCQkJPGJyIC8+PGJyIC8+DQoJCQkJCQkJDQoJCQkJPC9wPg0KCQkJPC90ZD4NCgkJPC90cj4NCgkJDQoJPHRyPiAgDQoJCTx0ZCB2YWxpZ249J3RvcCc+DQoJCQk8dGFibGUgY2xhc3M9cHJvZHVjdC1kZXRhaWxzIGJvcmRlcj0nMScgY2VsbHNwYWNpbmc9JzEnIGNlbGxwYWRkaW5nPScyJyBpZD0icHJpY2luZ1RhYmxlIj4NCgkJCQk8dHIgY2xhc3M9InByb2R1Y3QtZGV0YWlscy10b3AiPjx0ZCBjbGFzcz0icHJpY2luZy1kZXNjcmlwdGlvbiIgY29sc3Bhbj0zIGFsaWduPXJpZ2h0Pg0KDQo8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9VdGlsLmpzIj48L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L05ld0N1cnJlbmN5U2V0dGVyLmpzIj48L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij4NCm5ld0N1cnJlbmN5U2V0dGVyLnByZXZpb3VzQ3VycmVuY3kgPSAiQ05ZIjsNCm5ld0N1cnJlbmN5U2V0dGVyLmNvdW50cnkgPSAiIjsNCi8vYWxlcnQoIkN1cnJlbmN5U2V0dGVyLmNvdW50cnkgVksiK25ld0N1cnJlbmN5U2V0dGVyLmNvdW50cnkpOw0KPC9zY3JpcHQ+DQoNCuS6uuawkeW4geS7t+agvO+8iOWQq+WinuWAvOeoju+8iTwvdGQ+PC90cj4NCgkJCQk8dHI+IA0KCQkJCQk8dGggYWxpZ249J3JpZ2h0Jz7lvpfmjbfnlLXlrZAg6Zu25Lu257yW5Y+3PC90aD4NCgkJCQkJDQoJCQkJCTx0ZCBpZD0iUGFydE51bWJlciI+PG1ldGEgaXRlbXByb3A9InByb2R1Y3RJRCIgY29udGVudD0ic2t1OjE2My43MDEwLjAxMDItTkQiIC8+MTYzLjcwMTAuMDEwMi1ORDwvdGQ+DQoJCQkJCQ0KCQkJCQkJCQk8dGQgY2xhc3M9ImNhdGFsb2ctcHJpY2luZyIgcm93c3Bhbj0nNycgYWxpZ249J2NlbnRlcicgdmFsaWduPSd0b3AnPg0KCQkJCQkJCQ0KCQkJCQkJPHRhYmxlIGlkPSJwcmljaW5nIiBmcmFtZT0ndm9pZCcgcnVsZXM9J2FsbCcgYm9yZGVyPScxJyBjZWxsc3BhY2luZz0nMCcgY2VsbHBhZGRpbmc9JzEnPg0KCQkJCQkJCTx0cj4NCgkJCQkJCQkgICA8dGg+5Lu35qC85YiG5q61PC90aD4NCgkJCQkJCQkgICA8dGg+5Y2V5Lu3PC90aD4NCgkJCQkJCQkgICA8dGg+5oC75Lu3PC90aD4NCgkJCQkJCQkgICANCgkJCQkJCQk8L3RyPg0KDQoJCQkJCQkJDQoJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJPHRkIGFsaWduPSdjZW50ZXInPueUteivojwvdGQ+DQoJCQkJCQkJCQkJPHRkIGFsaWduPSdjZW50ZXInPueUteivojwvdGQ+DQoJCQkJCQkJCQkJPHRkIGFsaWduPSdjZW50ZXInPueUteivojwvdGQ+DQoJCQkJCQkJCQkJDQoJCQkJCQkJCQk8L3RyPg0KCQkJCQkJCQkNCgkJCQkJCTwvdGFibGU+DQoJCQkJCQkNCgkJCQkJPC90ZD4NCgkJCQk8L3RyPg0KDQoJCQkJDQoJCQkJPHRyPg0KCQkJCQk8dGggYWxpZ249cmlnaHQ+546w5pyJ5pWw6YePPC90aD4NCgkJCQkJPHRkIGFsaWduPWxlZnQgbm93cmFwPSJub3dyYXAiPg0KCQkJCQk8c3BhbiBpZD0iaGlkZGVuUXR5QXZhaWxhYmxlIiBzdHlsZT0iZGlzcGxheTpub25lOyI+MDwvc3Bhbj4NCgkJCQkJPCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFsLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL1RSL3hodG1sMS9EVEQveGh0bWwxLXRyYW5zaXRpb25hbC5kdGQiPgoKPCEtLSBTdGFydCAtIEpTUEYgRmlsZSBOYW1lOiBKU1RMRW52aXJvbm1lbnRTZXR1cC5qc3BmIC0tPjwhLS0gV0FTX05BTUUgQ0hJTkFfUFJPRF9TRVJWRVIxICAtLT4KPCEtLSBFbmQgLSBKU1BGIEZpbGUgTmFtZTogSlNUTEVudmlyb25tZW50U2V0dXAuanNwZiAtLT4NCg0KPHNjcmlwdD4NCmZ1bmN0aW9uIGdldExlYWRUaW1lTW9kYWwodXJsLCBkaWFsb2dEaXYsIGxlYWRUaW1lRXN0aW1hdGVUaXRsZSl7DQoJCXZhciBib3F1YW50eSA9ICQoIiNib1F0eSIpLnZhbCgpOw0KCQl2YXIgbmV3VXJsID0gdXJsLnJlcGxhY2UoLyZib1F0eT0vaSwgJyZib1F0eT0nK2JvcXVhbnR5KTsNCgkJDQoJCW5ld1VybCA9IG5ld1VybCArICImcGFydElkPSIrJzM0MjY2NTcnOw0KCQljb25zb2xlLmxvZyhuZXdVcmwpOw0KCQkkLmFqYXhTZXR1cCh7Y2FjaGU6IGZhbHNlfSk7DQoJCSQuZ2V0KG5ld1VybCwgZnVuY3Rpb24oZGF0YSkgew0KCQkkKCcjJytkaWFsb2dEaXYpLmh0bWwoZGF0YSk7DQoJCXZhciB0aXRsZVRleHQgPSBsZWFkVGltZUVzdGltYXRlVGl0bGU7DQoJCQkkKCcjJytkaWFsb2dEaXYpLmRpYWxvZyh7aGVpZ2h0OiAyMTAsIHdpZHRoOiA0MDAsIHRpdGxlOiB0aXRsZVRleHQsIG1vZGFsOiB0cnVlfSk7IA0KCX0pOw0KfQ0KZnVuY3Rpb24gb25LZXlQcmVzc0V2ZW50SGFuZGxlcihlLCB1cmwsIGRpYWxvZ0RpdiwgbGVhZFRpbWVFc3RpbWF0ZVRpdGxlKXsNCgl2YXIga2V5PWUua2V5Q29kZSB8fCBlLndoaWNoOw0KCWlmKGtleT09MTMpew0KCQlnZXRMZWFkVGltZU1vZGFsKHVybCwgZGlhbG9nRGl2LCBsZWFkVGltZUVzdGltYXRlVGl0bGUpOw0KCX0NCn0NCjwvc2NyaXB0Pg0KPGRpdiBpZD0ibGVhZFRpbWVEaWFsb2ciPiA8L2Rpdj4NCg0KCQkJIDANCgkJCSA8YnIvPg0KCQkJDQoJCQkJCTwvdGQ+DQoJCQkJPC90cj4NCgkJCQkNCgkJCQkNCgkJCQk8dHI+DQoJCQkJPHRoIGFsaWduPXJpZ2h0PuWItumAoOWVhjwvdGg+DQoJCQkJDQoJCQkJCQk8dGQ+PGgyIGNsYXNzPXNlb2h0YWcgaXRlbXByb3A9Im1hbnVmYWN0dXJlciI+PHNwYW4gaXRlbXNjb3BlIGl0ZW10eXBlPSJodHRwOi8vc2NoZW1hLm9yZy9Pcmdhbml6YXRpb24iPjxhICBpdGVtcHJvcD0idXJsIiBocmVmPScvemgvc3VwcGxpZXItY2VudGVycy9sL2xpdHRlbGZ1c2UnPjxzcGFuIGl0ZW1wcm9wPSJuYW1lIj5MaXR0ZWxmdXNlIEluYy48L3NwYW4+PC9zcGFuPjwvaDI+PC9hPjwvdGQ+PC90cj4NCgkJCQkJDQoJCQkJPHRyPjx0aCBhbGlnbj1yaWdodD7liLbpgKDllYbpm7bku7bnvJblj7c8L3RoPg0KCQkJCTx0ZD4NCgkJCQkJDQoJCQkJCQk8bWV0YSBpdGVtcHJvcD0ibmFtZSIgY29udGVudD0iMTYzLjcwMTAuMDEwMiIgLz48aDEgY2xhc3M9c2VvaHRhZyBpdGVtcHJvcD0ibW9kZWwiPg0KCQkJCQkJCTE2My43MDEwLjAxMDINCgkJCQkJPC9oMT4NCgkJCQk8L3RkPg0KCQkJCTwvdHI+DQoNCgkJCQkNCgkJCQk8dHI+PHRoIGFsaWduPXJpZ2h0PuaPj+i/sDwvdGg+PHRkIGl0ZW1wcm9wPSJkZXNjcmlwdGlvbiI+UkVTIEJMQURFIEFUTyAxMTAgT0hNIDElIDAuNFc8L3RkPjwvdHI+DQoJCQkJDQoJCQkJDQoJCQkJCTx0cj4NCgkJCQkJCTx0aCBhbGlnbj1yaWdodD4NCgkJCQkJCQnlr7nml6Dpk4XopoHmsYLnmoTovr7moIfmg4XlhrUv5a+56ZmQ5Yi25pyJ5a6z54mp6LSo5oyH5LukKFJvSFMp6KeE6IyD55qE6L6+5qCH5oOF5Ya1DQoJCQkJCQk8L3RoPg0KCQkJCQkJPHRkPg0KCQkJCQkJCeWQq+mThS/kuI3nrKblkIjpmZDliLbmnInlrrPnianotKjmjIfku6QoUm9IUynop4TojIPopoHmsYINCgkJCQkJCTwvdGQ+DQoJCQkJCTwvdHI+DQoJCQkJDQoJCQkJCTx0cj4NCgkJCQkJCTx0aCBhbGlnbj1yaWdodD7vu7/mub/msJTmlY/mhJ/mgKfnrYnnuqcg77yITVNM77yJPC90aD4NCgkJCQkJCTx0ZCBpdGVtcHJvcD0iTVNMIj4x77yI5peg6ZmQ77yJPC90ZD4NCgkJCQkJPC90cj4NCgkJCQkNCgkJCTwvdGFibGU+DQoJCQkNCgkJCQ0KDQoJCTwvdGQ+DQoJCTx0ZCBjbGFzcz0iaW1hZ2UtdGFibGUiIHZhbGlnbj0ndG9wJyBib3JkZXI9MT4NCgkJCTxkaXYgY2xhc3M9ImJlYWJsb2NrLWltYWdlIiBjb29raWUtdHJhY2tpbmc9InJlZl9wYWdlX2V2ZW50PUV4cGFuZCBJbWFnZTtyZWZfcGFnZV90eXBlPVBTO3JlZl9wYWdlX3N1Yl90eXBlPVBEO3JlZl9wYWdlX2lkPVBEO3JlZl9zdXBwbGllcl9pZD0xODtyZWZfcGFnZV9ldmVudD1BZGQlMjB0byUyMENhcnQ7cmVmX3BuX3NrdT0xNjMuNzAxMC4wMTAyLU5EO3JlZl9wYXJ0X2lkPTM0MjY2NTciPg0KCQkJCQ0KCQkJCQk8aW1nIGJvcmRlcj0wIHdpZHRoPTIwMCBzcmM9Ii93Y3NzdG9yZS9DTi9pbWFnZXMvcG5hLXpoLWNuLmpwZyIgdGl0bGU9JzE2My43MDEwLjAxMDIgTGl0dGVsZnVzZSBJbmMuIHwgMTYzLjcwMTAuMDEwMi1ORCB8IERpZ2ktS2V5IEVsZWN0cm9uaWNzJy8+DQoJCQkJDQoJCQk8L2Rpdj4NCgkJPC90ZD4NCgk8L3RyPg0KPC90YWJsZT4NCg0KDQo8dGFibGUgY2xhc3M9InByb2R1Y3QtYWRkaXRpb25hbC1pbmZvIiBpZD0iRGF0YXNoZWV0c1RhYmxlIj4NCjx0cj48dGQgdmFsaWduPSJ0b3AiIHN0eWxlPSJwYWRkaW5nLXRvcDo0cHg7IHdpZHRoOjI1JSI+DQoNCgkNCgk8Yj7kuIDoiKzkv6Hmga88L2I+DQoJPHRhYmxlIGJvcmRlcj0nMCcgaWQ9IkdlbmVyYWxJbmZvcm1hdGlvblRhYmxlIj4NCgkJPHRyPg0KCQkJPHRkIHZhbGlnbj0ndG9wJz4NCgkJCQk8dGFibGUgY2xhc3M9InByb2R1Y3QtZGV0YWlscyIgc3R5bGU9J3dpZHRoOiA1MDBweDsnaWQ9IkRhdGFzaGVldHNUYWJsZTEiPg0KCQkJCQkNCgkJCQkJCTx0cj4NCgkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+DQoJCQkJCQkJ5pWw5o2u5YiX6KGoPC90aD4NCgkJCQkJCQk8dGQ+IA0KCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJDQoJCQkJCQkJCQk8YSBjbGFzcz0ibG5rRGF0YXNoZWV0IiBocmVmPSdodHRwOi8vd3d3LmxpdHRlbGZ1c2UuY29tL34vbWVkaWEvYXV0b21vdGl2ZS9kYXRhc2hlZXRzL2Z1c2VzL2F1dG9tb3RpdmUtZnVzZXMvbGl0dGVsZnVzZV9hdG8lMjBibGFkZSUyMHR5cGUlMjByZXNpc3Rvcl9ma3MucGRmJyB0YXJnZXQ9J19ibGFuaycgdHJhY2stZGF0YT0icHJvZHVjdF9za3U9MTYzLjcwMTAuMDEwMi1ORDtwYXJ0X2lkPTM0MjY2NTc7cmVmX3N1cHBsaWVyX2lkPTE4O3JlZl9wYWdlX2V2ZW50PURpc3BsYXkgRGF0YXNoZWV0czthc3NldF90eXBlPURhdGFzaGVldHMiPjE2MyBTZXJpZXMsIEZLUyBSZXMgQVRPJiMxNzQ7IERhdGFzaGVldDs8L2E+PGJyLz4NCgkJCQkJCQkJDQoJCQkJCQkJPC90ZD4NCgkJCQkJCTwvdHI+DQoJCQkJCQ0KCQkJCQk8dHI+DQoJCQkJCQk8dGggYWxpZ249J3JpZ2h0JyB2YWxpZ249J3RvcCcgc3R5bGU9J3dpZHRoOiAyMDBweDsnPuagh+WHhuWMheijhSZuYnNwOyA8YSBocmVmPSJqYXZhc2NyaXB0OiBzaG93SGVscERpYWxvZygnI3N0YW5kYXJkUGFja2FnZUhlbHBEaWFsb2cnLCdhdXRvJywzMDAsZmFsc2UsdHJ1ZSkiPjxpbWcgaWQ9IlNlYXJjaEhlbHBJbWFnZSIgYm9yZGVyPSIwIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2ltYWdlcy9oZWxwLnBuZyIgdHJhY2stZGF0YT0icHJvZHVjdF9za3U9MTYzLjcwMTAuMDEwMi1ORDtwYXJ0X2lkPTM0MjY2NTc7cmVmX3N1cHBsaWVyX2lkPTE4O3JlZl9wYWdlX2V2ZW50PVN0YW5kYXJkIFBhY2thZ2luZyI+PC9hPjwvdGg+DQoJCQkJCQk8dGQ+MSwwMDA8L3RkPg0KCQkJCQk8L3RyPg0KCQkJCQkNCgkJCQkJDQoJCQkJCQk8dHI+DQoJCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7ljIXoo4UmbmJzcDsgPGEgaHJlZj0iamF2YXNjcmlwdDogc2hvd0hlbHBEaWFsb2coJyNzdGFuZGFyZFBhY2thZ2VIZWxwRGlhbG9nJywnYXV0bycsMzAwLGZhbHNlLHRydWUpIj48aW1nIGlkPSJTZWFyY2hIZWxwSW1hZ2UiIGJvcmRlcj0iMCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9pbWFnZXMvaGVscC5wbmciPjwvYT48L3RoPg0KCQkJCQkJCTx0ZD4NCgkJCQkJCQkJJiMyNTk1NTsmIzM1MDEzOw0KCQkJCQkJCQkNCgkJPGEgaHJlZj0iamF2YXNjcmlwdDogc2hvd0hlbHBNb2RlbERpYWxvZygnI0JVTEtfUGFja2FnaW5nSGVscERpYWxvZycsJyYjMjU5NTU7JiMzNTAxMzsnLCdhdXRvJywzMDAsZmFsc2UsdHJ1ZSkiPjxpbWcgYm9yZGVyPSIwIiBhbGlnbj0iY2VudGVyIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2ltYWdlcy9oZWxwLnBuZyI+PC9hPg0KCQ0KCQkJCQkJCTwvdGQ+DQoJCQkJCQk8L3RyPg0KCQkJCQkNCgkNCgkJCQkJPHRyPg0KCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7nsbvliKs8L3RoPg0KCQkJCQkJPHRkPjxhIGhyZWY9Ii9zZWFyY2gvemgv55S16Zi75ZmoLzY4MSIgaWQ9ImNhdGVnb3J5TG5rIj4mIzMwMDA1OyYjMzg0NTk7JiMyMjEyMDs8L2E+PC90ZD4NCgkJCQkJPC90cj4NCgkJCQkJPHRyPg0KCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7kuqflk4Hml488L3RoPg0KCQkJCQkJPHRkPjxhIGhyZWY9Ii9zZWFyY2gvemgv55S16Zi75ZmoL+S4k+eUqOWei+eUtemYu+WZqC82ODYiIGlkPSJmYW1pbHlMbmsiPiYjMTk5ODc7JiMyOTk5MjsmIzIyNDExOyYjMzAwMDU7JiMzODQ1OTsmIzIyMTIwOzwvYT48L3RkPg0KCQkJCQk8L3RyPg0KCQkJCQkNCgkJCQkJPHRyPg0KCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7ns7vliJc8L3RoPg0KCQkJCQk8dGQ+DQoJCQkJCSAJICAgDQoJCQkgCQkJCQk8YSBocmVmPSJodHRwOi8vd3d3LmRpZ2lrZXkuY29tLmNuL3NlYXJjaC96aD9zZXJpZXNpZD00Mjg4MDQyNDczJnB2PTY4MSU3QzQyODgwNDI0NzMiIGlkPSJzZXJpZXNMbmsiPkZLUyBBVE8mIzE3NDs8L2E+DQoJCQkgCQkJCSAgIA0KCQkJCQk8L3RkPiAgDQoJCQkJCTwvdHI+DQoJCQkJCQ0KDQoJCQkJPC90YWJsZT4NCgkJCTwvdGQ+DQoJCTwvdHI+DQoJPC90YWJsZT4NCgk8YnIvPg0KDQoJDQoJCQk8Yj7op4TmoLw8L2I+DQoJCQk8dGFibGUgYm9yZGVyPScwJyBpZD0iU3BlY2lmaWNhdGlvblRhYmxlIj4NCgkJCQk8dHI+DQoJCQkJCTx0ZCB2YWxpZ249J3RvcCc+DQoJCQkJCQk8dGFibGUgY2xhc3M9InByb2R1Y3QtZGV0YWlscyIgc3R5bGU9J3dpZHRoOiA1MDBweDsnIGlkPSJTcGVjaWZpY2F0aW9uVGFibGUxIj4NCgkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMzMTg2NzsmIzIyNDExOzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPiYjMjA5OTI7JiMyOTI1NTsmIzY1MjkyO0FUTzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyNDIxMjsmIzI5OTkyOzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPiYjMjc3NzM7JiMzNjcxMDsmIzMyNDIzOzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyNTEwNDsmIzIwOTk4OzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPiYjMzczMjk7JiMyMzY0NjsmIzIwODAzOyYjMzIwMzI7PC90ZD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJPC90cj4NCgkJCQkJCQkJCQ0KCQkJCQkJCQkJCTx0cj4NCgkJCQkJCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz4mIzMwMDA1OyYjMzg0NTk7JiM2NTI4ODsmIzI3NDMxOyYjMjI5ODI7JiM2NTI4OTs8L3RoPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQkJCTx0ZD4xMTA8L3RkPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQk8L3RyPg0KCQkJCQkJCQkJDQoJCQkJCQkJCQkJPHRyPg0KCQkJCQkJCQkJCQk8dGggYWxpZ249J3JpZ2h0JyB2YWxpZ249J3RvcCcgc3R5bGU9J3dpZHRoOiAyMDBweDsnPiYjMjM0ODE7JiMyNDA0Njs8L3RoPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQkJCTx0ZD4mIzE3NzsxJTwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyMTE1MTsmIzI5NTc1OyYjNjUyODg7VyYjNjUyODk7PC90aD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJCQk8dGQ+MC40VzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyODIwMTsmIzI0MjMwOyYjMzE5OTU7JiMyNTk2ODs8L3RoPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQkJCTx0ZD4tPC90ZD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJPC90cj4NCgkJCQkJCQkJCQ0KCQkJCQkJCQkJCTx0cj4NCgkJCQkJCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz4mIzI0MDM3OyYjMjAzMTY7JiMyODIwMTsmIzI0MjMwOzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPi08L3RkPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQk8L3RyPg0KCQkJCQkJCQkJDQoJCQkJCQkJCQkJPHRyPg0KCQkJCQkJCQkJCQk8dGggYWxpZ249J3JpZ2h0JyB2YWxpZ249J3RvcCcgc3R5bGU9J3dpZHRoOiAyMDBweDsnPiYjMjM0MzM7JiMzNTAxMzsmIzMxODY3OyYjMjI0MTE7PC90aD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJCQk8dGQ+JiMyNTkwMzsmIzI0MjMxOzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCTwvdGFibGU+DQoJCQkJCTwvdGQ+DQoJCQkJPC90cj4NCgkJCTwvdGFibGU+DQoJCQk8YnIvPg0KCQkNCg0KPC90ZD4NCjx0ZCB2YWxpZ249InRvcCIgc3R5bGU9J3BhZGRpbmctdG9wOiAyMHB4OyB3aWR0aDo2MCUnPgkNCgk8IS0tIFN0YXJ0IC0gSlNQIEZpbGUgTmFtZTogIEFsdGVybmF0aXZlUGFja2FnaW5nLmpzcGYgLS0+PCEtLSBFbmQgLSBKU1AgRmlsZSBOYW1lOiAgQWx0ZXJuYXRpdmVQYWNrYWdpbmcuanNwZiAtLT4gDQo8L3RkPg0KPHRkPjwvdGQ+DQo8L3RyPg0KPHRyPg0KCTx0ZCBhbGlnbj0icmlnaHQiPg0KCQkNCgkJPGlucHV0IGlkPSJidG5SZXBvcnRFcnJvciIgdHlwZT0iYnV0dG9uIiBuYW1lPSJyZXBvcnRFcnJvciIgDQoJCQkJdmFsdWU9J+aKpeWRiuS4gOS4qumUmeivrycgDQoJCQkJdGl0bGU9J+aKpeWRiuS4gOS4qumUmeivrycNCgkJCQlvbmNsaWNrPSJqYXZhc2NyaXB0OndpbmRvdy5vcGVuKCcvb3JkZXJpbmcvUmVwb3J0RXJyb3JGZWVkYmFja1ZpZXc/bGFuZ0lkPS03JnBhcnROdW1iZXI9MTYzLjcwMTAuMDEwMi1ORCZtYW51ZmFjdHVyZXJOYW1lPUxpdHRlbGZ1c2UrSW5jLiZzdG9yZUlkPTEwMDAxJywgJ19ibGFuaycpOyIvPg0KCQkNCgk8L3RkPg0KCTx0ZD48IS0tIExlYXZlIGVtcHR5IC0tPjwvdGQ+DQoJPHRkPjwhLS0gTGVhdmUgZW1wdHkgLS0+PC90ZD4NCjwvdHI+DQo8L3RhYmxlPg0KDQo8ZGl2IHN0eWxlPSdjbGVhcjogYm90aDsnPg0KCTxwPg0KCQkyMDE3LTAxLTA1IDE0OjMxOjMwICjljJfkuqzml7bpl7QpIA0KCTwvcD4NCjwvZGl2Pg0KPGRpdiBpZD0iZmF2b3JpdGVBZGRNb2RlbFdpbmRvdyIgc3R5bGU9ImRpc3BsYXk6IG5vbmU7IiB0aXRsZT0i5pS26JeP5aS5Ij4NCjx0YWJsZSBpZD0iZmF2b3JpdGVQYXJ0QWRkZWQiIGNlbGxzcGFjaW5nPSIwIiBjZWxscGFkZGluZz0iMCIgYm9yZGVyPSIwIiBzdHlsZT0id2lkdGg6MTAwJTsiPg0KCTx0cj4NCgk8dGQ+Jm5ic3A7PC90ZD4NCgk8L3RyPg0KCTx0cj4NCgk8dGQ+PGI+6K+l5Lqn5ZOB5bey5oiQ5Yqf5Yqg5YWl5pS26JeP5aS5PC9iPjwvdGQ+DQoJPC90cj4NCgk8dHI+DQoJPHRkPiZuYnNwOzwvdGQ+DQoJPC90cj4NCgk8dHI+IA0KCSA8dGQ+MTYzLjcwMTAuMDEwMjwvdGQ+DQoJPC90cj4NCgk8dHI+IA0KCSA8dGQ+UkVTIEJMQURFIEFUTyAxMTAgT0hNIDElIDAuNFc8L3RkPg0KCTwvdHI+DQoJPHRyPiANCgkgPHRkPkxpdHRlbGZ1c2UgSW5jLjwvdGQ+DQoJPC90cj4JDQo8L3RhYmxlPg0KPC9kaXY+DQo8ZGl2IGlkPSJmYXZvcml0ZUFkZEVycm9yTW9kZWxXaW5kb3ciIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IumUmeivryI+DQo8L2Rpdj4NCjxkaXYgaWQ9ImxvZ2luRGlhbG9nIiBzdHlsZT0iZGlzcGxheTpub25lOyIgdGl0bGU9IuaUtuiXj+WkuSI+DQoJPHA+5Y+q6YCC55So5LqO5rOo5YaM55So5oi344CC6K+3PGEgaWQ9Im90aGVyU3JjTG9naW4iIGhyZWY9Imh0dHBzOi8vd3d3LmRpZ2lrZXkuY29tLmNuL215ZGlnaWtleS9Mb2dvbkZvcm0/ZnJvbVBhZ2U9cGFydERldGFpbCZVUkw9JTJGc2VhcmNoJTJGemglMkYxNjMtNzAxMC0wMTAyJTJGMTYzLTcwMTAtMDEwMi1ORCUzRnJlY29yZElkJTNEMzQyNjY1NyI+55m75b2VPC9hPuaIljxhIGhyZWY9Imh0dHBzOi8vd3d3LmRpZ2lrZXkuY29tLmNuL215ZGlnaWtleS9Vc2VyUmVnaXN0cmF0aW9uQWRkRm9ybVZpZXciPuazqOWGjDwvYT7jgII8L3A+DQo8L2Rpdj4NCg0KPCEtLSBJbmNsdWRlIEZvb3RlciAtLT48IS0tIERvdWJsZUNsaWNrIFRhZ2dpbmcgLS0+PCEtLSBCRUdJTiBGb290ZXIuanNwIC0tPjwvZGl2PjwhLS0gRU5ESU5HIERJViBDb250ZW50IC0tPjwhLS1TVEFSVCBPRiBTaXRlQ29yZUZvb3Rlci5qc3AgLS0+DQoNCg0KPGxpbmsgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9Gb290ZXIvTWVya2xlL0NTUy9mb290ZXIuY3NzP2xhPXpoLUNOLVJNQiZhbXA7dHM9YjRkZWI1OTctYmQxYi00M2VhLWJjYzktMGVlZjk2ZDVkYWU3IiAvPg0KPGRpdiBpZD0iZm9vdGVyIj4gIAogICAgPHRhYmxlIGNsYXNzPSJmb290ZXItY29udGFpbmVyIj4KICAgICAgPHRyPgogICAgICAgIDx0ZD4KICAgICAgICAgICAgPGRpdiBjbGFzcz0iZm9vdGVyLWluZm9ybWF0aW9uIj4KICAgICAgICAgICAgICAgIDxwIGNsYXNzPSJmb290ZXItYm9sZCI+5L+h5oGvPC9wPgogICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC90ZXJtcy1hbmQtY29uZGl0aW9ucyI+5p2h5qy+5ZKM5p2h5Lu2PC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvYWJvdXQtZGlnaWtleSI+5YWz5LqO5b6X5o2355S15a2QPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9oZWxwL2NvbnRhY3QtdXMiPuiBlOezu+aIkeS7rDwvYT48L3A+PHAgY2xhc3M9ImZvb3Rlci1saW5rIj48YSBocmVmPSIvemgvbmV3cyI+5paw6Ze757yW6L6R5a6kPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9oZWxwL3NpdGUtbWFwIj7nq5nngrnlnLDlm748L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL2hlbHAvYnJvd3Nlci1zdXBwb3J0Ij7mlK/mjIHnmoTmtY/op4jlmag8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL2hlbHAvUHJpdmFjeSI+6ZqQ56eB5aOw5piOPC9hPjwvcD48L2Rpdj4KICAgICAgICAgICAgPGRpdiBjbGFzcz0iZm9vdGVyLWNvdW50cnkiIHN0eWxlPSJiYWNrZ3JvdW5kLWltYWdlOiB1cmwoLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvRm9vdGVyL0NvdW50cmllcy9jbi5wbmc/bGE9emgtQ04tUk1CJmFtcDt0cz1mMWEyZWJhZS0yNTc4LTRmODUtYjMwNS04MzQ5MmM1ZWQxNGQpOyI+CiAgICAgICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWJvbGQiPuS4reWbvTwvcD4KICAgICAgICAgICAgICAgIDxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0ibWFpbHRvOnNlcnZpY2Uuc2hAZGlnaWtleS5jb20gIj5zZXJ2aWNlLnNoQGRpZ2lrZXkuY29tIDwvYT48L3A+CiAgICAgICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWJvbGQiPueUteivnTogNDAwIDkyMCAxMTk5PGJyIC8+5Lyg55yfOiAoMDIxKSA1MjQyOTI2OTxiciAvPjxiciAvPuayqklDUOWkhzE0MDI0NTE05Y+3LTMgPC9wPgogICAgICAgICAgICAgICAgPHAgY2xhc3M9ImZvb3Rlci1saW5rIGxpdmUtY2hhdCBjaGF0bGluayI+CiAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgPGEgaHJlZj0iamF2YXNjcmlwdDo7Ij48aW1nIGNsYXNzPSJmb290ZXItaWNvbiIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9IZWFkZXIvY2hhdC13aGl0ZS5wbmc/bGE9emgtQ04tUk1CJnRzPWYyMjlmMTA0LThkNzgtNDc5MC1iMmI4LTI2ZGMzNmQ5OTQ5MiIgLz4gUVHlnKjnur/lkqjor6I8L2E+CiAgICAgICAgICAgICAgICA8L3A+CiAgICAgICAgICAgIDxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9IiI+PC9zY3JpcHQ+PC9kaXY+CiAgICAgICAgICAgIDxkaXYgY2xhc3M9ImZvb3Rlci1pbnRlcm5hdGlvbmFsIj4KICAgICAgICAgICAgICAgIDxwIGNsYXNzPSJmb290ZXItYm9sZCI+546v55CD5Lia5YqhPC9wPgogICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbD9yZWdpb249YWZyaWNhIj7pnZ7mtLI8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsP3JlZ2lvbj1hc2lhIj7kuprmtLI8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsP3JlZ2lvbj1hdXN0cmFsaWEiPua+s+Wkp+WIqeS6mjwvYT48L3A+PHAgY2xhc3M9ImZvb3Rlci1saW5rIj48YSBocmVmPSIvemgvcmVzb3VyY2VzL2ludGVybmF0aW9uYWw/cmVnaW9uPWV1cm9wZSI+5qyn5rSyPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbD9yZWdpb249bWlkZGxlZWFzdCI+5Lit5LicPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbD9yZWdpb249bm9ydGhhbWVyaWNhIj7ljJfnvo7mtLI8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsP3JlZ2lvbj1zb3V0aGFtZXJpY2EiPuWNl+e+jua0sjwvYT48L3A+PC9kaXY+CiAgICAgICAgPC90ZD4KICAgICAgICA8dGQ+CiAgICAgICAgICAgIDxkaXYgY2xhc3M9ImZvb3Rlci1jb3B5cmlnaHQiPgogICAgICAgICAgICAgICAgPGRpdiBjbGFzcz0ic29jaWFsLWljb25zIj48YSBocmVmPSIvemgvcmVzb3VyY2VzL21vYmlsZS1hcHBsaWNhdGlvbnMiPjxpbWcgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9HbG9iYWwvSWNvbnMvbW9iaWxlYXBwXzMyLnBuZz9oPTMyJmxhPXpoLUNOLVJNQiZ3PTMyJnRzPWQyOTZhZTQwLTg2MDgtNDFiYy04MGQ5LTEyM2RiYjhjMTEzYiIgYWx0PSJEaWdpLUtleSBNb2JpbGUgQXBwcyIgLz48L2E+PGEgaHJlZj0iaHR0cDovL2kueW91a3UuY29tL2RpZ2lrZXkiIHRhcmdldD0iX2JsYW5rIj48aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvR2xvYmFsL0ljb25zL3lvdWt1XzMyLnBuZz9oPTMyJmxhPXpoLUNOLVJNQiZ3PTMyJnRzPThlNTU2NjU3LTgwNGItNGNkMS1hNGM1LWI0MGZiNWFlZjc2MSIgYWx0PSJ5b3VrdSIgLz48L2E+PGEgaHJlZj0iaHR0cDovL3d3dy53ZWliby5jb20vZGlnaWtleWVsZWN0cm9uaWNzIiB0YXJnZXQ9Il9ibGFuayI+PGltZyBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0dsb2JhbC9JY29ucy9XZWlib18zMi5wbmc/aD0zMiZsYT16aC1DTi1STUImdz0zMiZ0cz04ZDlkZTU4NS0yMjgxLTQwMzYtOTE3NS00M2I5YWM2MTMwNWIiIGFsdD0id2VpYm8iIC8+PC9hPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvd2VjaGF0Ij48aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvR2xvYmFsL0ljb25zL1dlY2hhdF8zMi5wbmc/aD0zMiZsYT16aC1DTi1STUImdz0zMiZ0cz04OGVjOWMyNy03Mzc5LTRhNTktYjFiNi1kNzBkMzBmNWEwMTciIGFsdD0iV2VjaGF0IiAvPjwvYT48YSBocmVmPSJodHRwczovL3d3dy5saW5rZWRpbi5jb20vY29tcGFueS9kaWdpLWtleS1jb3Jwb3JhdGlvbiIgdGFyZ2V0PSJfc2NOZXdUYWIiPjxpbWcgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9HbG9iYWwvSWNvbnMvbGlua2VkaW5fMzIucG5nP2g9MzImbGE9emgtQ04tUk1CJnc9MzImdHM9MGRkOTg5MzAtY2Q2Mi00ZGExLWE5N2UtZDA4MDBmZGMxOTlkIiBhbHQ9IkxpbmtlZEluIiAvPjwvYT48L2Rpdj4KICAgICAgICAgICAgICAgIDxwPkNvcHlyaWdodCAmY29weTsgMTk5NS0yMDE3PGJyIC8+5b6X5o2355S15a2Q77yI5LiK5rW377yJ5pyJ6ZmQ5YWs5Y+444CC5L+d55WZ5YWo6YOo54mI5p2D44CCPGJyIC8+5LiK5rW35a6i5pyN5Lit5b+D77yaIOS4iua1t+S4reWxseilv+i3rzEwNTXlj7c8YnIgLz5TT0hP5Lit5bGx5bm/5Zy6QeW6pzUwNOWupCDpgq7nvJYgMjAwMDUxPC9wPgogICAgICAgICAgICAgICAgPGEgaHJlZj0iL3poL2hlbHAvYXV0aG9yaXplZC1kaXN0cmlidXRvciI+PGltZyBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hvbWVwYWdlL2hvbWVwYWdlLWFzc29jaWF0aW9ucy5wbmc/aD00NiZsYT16aC1DTi1STUImdz0yMjUmdHM9NjAwNmZiZWItZTY4Ny00MWE4LWIzNGYtYmNkYzgzMDY4NDJjIiBhbHQ9IkVDSUEvQ0VEQS9FQ1NOIE1lbWJlciIgLz48L2E+CiAgICAgICAgICAgIDwvZGl2PgogICAgICAgIDwvdGQ+CiAgICAgIDwvdHI+CiAgICA8L3RhYmxlPgo8L2Rpdj4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij4oZnVuY3Rpb24oYSxiLGMsZCl7YT0nLy90YWdzLnRpcWNkbi5jb20vdXRhZy9kaWdpa2V5L21haW4vcHJvZC91dGFnLmpzJztiPWRvY3VtZW50O2M9J3NjcmlwdCc7ZD1iLmNyZWF0ZUVsZW1lbnQoYyk7ZC5zcmM9YTtkLnR5cGU9J3RleHQvamF2YScrYztkLmFzeW5jPXRydWU7YT1iLmdldEVsZW1lbnRzQnlUYWdOYW1lKGMpWzBdO2EucGFyZW50Tm9kZS5pbnNlcnRCZWZvcmUoZCxhKTt9KSgpOzwvc2NyaXB0PjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvRGVzaWduZXIvRm9vdGVyL1JNQi9KUy9mb290ZXJxcWNoYXQuanM/bGE9emgtQ04tUk1CJmFtcDt0cz1mZmQ3YjgxYS1lNTQ4LTRkZTQtYTA0YS0wMTg5ZGVjZTkwNDAiPjwvc2NyaXB0PjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij5pZiAodHlwZW9mIHV0YWdfZGF0YSA9PT0gJ3VuZGVmaW5lZCcpIHsgdXRhZ19kYXRhID0geyB3dF91c2VfdWRvIDogImZhbHNlIiB9OyB9PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9XZWIgQW5hbHl0aWNzL0Nvb2tpZSBUcmFja2luZy9KUy9kaWdpa2V5LXdlYnRyZW5kcy5qcz90cz00NWFlZTk3ZC1hMmJhLTQxY2MtOTI2OS00YTY1Y2JjYTkyN2EiPjwvc2NyaXB0Pg0KDQo8IS0tIEVORCBGb290ZXIuanNwZiAtLT4NCg0KPHNjcmlwdCB0eXBlPSd0ZXh0L2phdmFzY3JpcHQnPg0KDQogICAgaWYgKGxvY2F0aW9uLmhhc2gubGVuZ3RoID4gMCkgew0KICAgIAl2YXIgX3BhcnROdW1iZXIgPSBsb2NhdGlvbi5oYXNoOw0KICAgIAlpZiAobmF2aWdhdG9yLmFwcE5hbWUgPT0gIk1pY3Jvc29mdCBJbnRlcm5ldCBFeHBsb3JlciIpIHsNCgkgICAgCWlmIChfcGFydE51bWJlci5jaGFyQXQoMCkgPT0gJyMnKSB7DQoJICAgIAkJX3BhcnROdW1iZXIgPSBfcGFydE51bWJlci5zbGljZSgxKTsNCgkgICAgCX0NCiAgICAJfQ0KICAgIAlkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnaXRlbW51bWJlcnNlbGVjdCcpLnZhbHVlID0gX3BhcnROdW1iZXI7DQogICAgfSANCiAgICAgIA0KJChkb2N1bWVudCkucmVhZHkoZnVuY3Rpb24gKCkgew0KICAgIGluaXREaWFsb2coJyNmYXZvcml0ZUFkZE1vZGVsV2luZG93JywgNTAwKTsNCiAgICBpbml0RGlhbG9nKCcjZmF2b3JpdGVBZGRFcnJvck1vZGVsV2luZG93JywgNTAwKTsNCn0pOw0KDQo8L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij4NCgkJdmFyIHV0YWdfZGF0YSA9IHsNCgkJCXBhZ2VfdGl0bGU6ICdQYXJ0IERldGFpbCcsDQoJCSAgICBwYWdlX3R5cGU6ICJQUyIsDQoJCSAgICBwYWdlX3N1Yl90eXBlOiAnUEQnLA0KCQkgICAgcGFnZV9pZDogIlBEIiwNCgkJICAgIHBhcnRfaWQ6ICIzNDI2NjU3IiwNCgkJICAgIHBhcnRfc2VhcmNoX3Rlcm06ICIiLA0KCQkgICAgcGFydF9hdmFpbGFibGU6ICIwIiwNCgkJCXBhZ2VfbGFuZ3VhZ2U6ICJ6aCIsDQoJCQlwbl9za3U6ICIxNjMuNzAxMC4wMTAyLU5EIiwNCgkJCXd0X3VzZV91ZG86ICJ0cnVlIiwNCgkJCXBhZ2VfY29udGVudF9ncm91cDogIlBhcnQgU2VhcmNoIiwNCgkJCXBhcnRfc2VhcmNoX3Jlc3VsdHNfY291bnQ6ICIxIiwNCgkJCXRyYW5zYWN0aW9uX3R5cGU6ICJ2IiwNCgkJCXRyYW5zYWN0aW9uX3F1YW50aXR5OiAiMSIsDQoJCQlzdXBwbGllcl9pZDogIjE4IiwNCgkJCXZpZGVvX3NvdXJjZTogJ1BhcnQgRGV0YWlsJywNCgkJICAgIHBhZ2VfY29udGVudF9zdWJfZ3JvdXA6ICdQYXJ0IERldGFpbCcNCgkJfQ0KPC9zY3JpcHQ+DQo8L2JvZHk+DQo8L2h0bWw+DQo=272C217-03F8-43E4-8962-F82D0FD47536&html=PCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFsLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL1RSL3hodG1sMS9EVEQveGh0bWwxLXRyYW5zaXRpb25hbC5kdGQiPgoKPCEtLSBTdGFydCAtIEpTUEYgRmlsZSBOYW1lOiBKU1RMRW52aXJvbm1lbnRTZXR1cC5qc3BmIC0tPjwhLS0gV0FTX05BTUUgQ0hJTkFfUFJPRF9TRVJWRVIxICAtLT4KPCEtLSBFbmQgLSBKU1BGIEZpbGUgTmFtZTogSlNUTEVudmlyb25tZW50U2V0dXAuanNwZiAtLT4NCg0KPCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFsLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL1RSL3hodG1sMS9EVEQveGh0bWwxLXRyYW5zaXRpb25hbC5kdGQiPg0KPGh0bWw+DQo8aGVhZD4NCg0KDQo8bWV0YSBodHRwLWVxdWl2PSJDb250ZW50LVR5cGUiIGNvbnRlbnQ9InRleHQvaHRtbDsgY2hhcnNldD1VVEYtOCIvPg0KPG1ldGEgaHR0cC1lcXVpdj0iQ29udGVudC1MYW5ndWFnZSIgY29udGVudD0iemgtQ04iLz4NCjxtZXRhIG5hbWU9IkdFTkVSQVRPUiIgY29udGVudD0iSUJNIFNvZnR3YXJlIERldmVsb3BtZW50IFBsYXRmb3JtIi8+DQoNCjxtZXRhIG5hbWU9ZGVzY3JpcHRpb24gY29udGVudD0i5ZyoIGRpZ2lrZXkuY29tLmNuIOi0reS5sCAxNjMuNzAxMC4wMTAyIExpdHRlbGZ1c2UgSW5jLiAxNjMuNzAxMC4wMTAyLU5E44CCIOe9keW6lyBkaWdpa2V5LiYjMzAwMDU7JiMzODQ1OTsmIzIyMTIwOyDkuLrmgqjnmoQgJiMxOTk4NzsmIzI5OTkyOyYjMjI0MTE7JiMzMDAwNTsmIzM4NDU5OyYjMjIxMjA7IHs2fSDpnIDopoHjgIIgRGlnaUtleSDmi6XmnInmnIDlub/ms5vnmoTnlLXlrZDlhYPku7bjgIHpm7bku7blkozkvpvlupTllYbpgInmi6njgIIiLz4NCg0KPG1ldGEgbmFtZT1rZXl3b3JkcyBjb250ZW50PSIxNjMuNzAxMC4wMTAyLDE2My43MDEwLjAxMDItTkQsRGlnaS1LZXkgRWxlY3Ryb25pY3Ms55S15a2Q6Zu25Lu2LCDlhYPku7YsIOe7j+mUgOWVhiIvPg0KPHRpdGxlPjE2My43MDEwLjAxMDIgTGl0dGVsZnVzZSBJbmMuIHwgMTYzLjcwMTAuMDEwMi1ORCB8IOW+l+aNt+eUteWtkDwvdGl0bGU+DQo8IS0tIGhlbHAgZGlhbG9nIGNvbnRlbnQgLS0+DQoNCjxkaXYgaWQ9Im5vblN0b2NrSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IuaXoOW6k+WtmOmhueebriIgPg0KPHA+IuWPr+S+m+W6lOaVsOmHjyLmoI/kuK3moIforrDkuLrml6DlupPlrZjnmoTkuqflk4HpgJrluLjml6DotKfjgILmnKzkuqflk4Hlj6/ku6XotK3kubDvvIzkvYblm6DkuLrlhbblrqLmiLfnvqTmnInpmZDvvIzmiYDku6XlhbbmnIDkvY7otbfotK3mlbDph4/pgJrluLjopoHmsYLovoPpq5jjgIJEaWdpLUtleSDmj5DkvpvpnZ7lupPlrZjkuqflk4HnmoTln7rmnKzljp/liJnlpoLkuIvvvJo8L3A+PHA+RGlnaS1LZXnnm67liY0gIDxiPuW6k+WtmDwvYj7mlbDku6XljYHkuIforqHnmoTnlLXlrZDlhYPku7bvvIzlubbmr4/ml6Xlop7liqDmlrDkuqflk4HjgIIg5Y+v5Lul6K+B5piO77yM6L+Z5piv5Lia55WMIDxiPuW6k+WtmOaUr+aMgTwvYj7nmoTmnIDlub/ms5vnmoTkuqflk4HkvpvlupTjgII8L1A+PHA+5L2G6L+Y5pyJ5o6l6L+R5pWw5LiH56eN5YW25a6D5YWD5Lu25Y+v5LuO5oiR5Lus55qE5L6b5bqU5ZWG6YKj6YeM6I635b6X44CC5bC9566h5Zug6L+Z5Lqb5Lqn5ZOB55qE6ZSA6Lev5pyJ6ZmQ6ICM5peg5rOV5YWF5YiG5L+d6K+B5a6D5Lus55qE5bqT5a2Y6YeP77yM5L2G5oiR5Lus55u45L+h6K6p5LqG6Kej5a6D5Lus5piv5ZCm5pyJ5bqT5a2Y5a+55oiR5Lus55qE5a6i5oi35piv5pyJ5Yip55qE44CC5oiR5Lus55qE55uu5qCH5piv5Li65oiR5Lus55qE5a6i5oi35o+Q5L6b5pyA5aSn5pWw6YeP55qE5Lqn5ZOB6YCJ5oup55qE5L+h5oGv77yM5bm26K6p5LuW5Lus5qC55o2u6KeE5qC844CB5Lu35qC844CB5L6b5bqU6YeP5ZKM5pyA5L2O6LSt5Lmw6YeP6L+b6KGM6YCJ5oup44CCPC9QPjxwPuazqOaEj++8jOmAieaLqSLlhbPplK7lrZci5LiL6Z2i55qEIuWcqOW6k+WVhuWTgSLlj7PovrnnmoTlpI3pgInmoYbvvIzkvJrlsIbmgqjpmZDliLbkuLrlj6rmn6XnnIvlj6/njrDotKfkvpvlupTnmoTkuqflk4HjgII8L3A+DQo8L2Rpdj4NCjxkaXYgaWQ9InZhbHVlQWRkSXRlbUhlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiIHRpdGxlPSLlop7lgLznianku7YiPg0KPFA+6L+Z5piv5oiR5Lus5a6a5Yi26KOF6YWN5oiW5YyF6KOF55qE5LiA5Liq5aKe5YC85ZWG5ZOB44CC5Zyo5aSn5aSa5pWw5oOF5Ya15LiL77yM5oiR5Lus5Y+v5Lul5qC55o2u5oKo55qE6K6i5Y2V5LiT6Zeo6KOF6YWN5oiW5YyF6KOF6L+Z56eN5ZWG5ZOB77yM5bm25Y+v5Zyo5b2T5aSp5Y+R6LSn44CC5aaC5p6c5oKo5bCG6L+Z56eN5ZWG5ZOB5pS+5Yiw6K6i5Y2V5LiK77yM5Lya5pi+56S657y66LSn77yM5aaC5p6c5peg5rOV5bGl6KGM6K6i5Y2V77yM5oiR5Lus5Lya5LiO5oKo6IGU57O744CCPC9QPg0KPC9kaXY+DQoNCjxkaXYgaWQ9Iml0ZW1OdW1iZXJIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7IiB0aXRsZT0i5ZWG5ZOB5Y+3IiA+DQoJPFA+5L2/55So5LiL5ouJ6I+c5Y2V6YCJ5oup5Zyo6K6i5Y2V5LiK5pi+56S655qEIOW+l+aNt+eUteWtkCDmiJbliLbpgKDllYbpm7bku7bnvJblj7fjgII8L1A+DQo8L2Rpdj4NCg0KPGRpdiBpZD0ic3RhbmRhcmRQYWNrYWdlSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9Iuagh+WHhuWMheijhSIgPg0KCTxQPuagh+WHhuWMheijheaYr+aMh+WOguWutuWQkeW+l+aNt+eUteWtkOaPkOS+m+eahOacgOWwj+WwuuWvuOWMheijheOAgiDnlLHkuo7lvpfmjbfnlLXlrZDmj5Dkvpvlop7lgLzmnI3liqHvvIzlm6DmraTmnIDkvY7orqLotK3mlbDph4/lj6/og73kvJrmr5TliLbpgKDllYbnmoTmoIflh4bljIXoo4XmlbDph4/lsJHjgILlvZPkuqflk4HliIbmiJDlsI/lsIHoo4Xph4/lh7rllK7ml7bvvIzlsIHoo4XnsbvlnovvvIjljbPljbfovbTjgIHnrqHoo4XjgIHmiZjnm5joo4XnrYnvvInlj6/og73kvJrmnInmiYDmlLnlj5jjgII8L1A+DQo8L2Rpdj4NCg0KPGxpbmsgaHJlZj0iLy9ka2MzLmRpZ2lrZXkuY29tL2Nzcy9wcmludC5jc3MiIHJlbD0ic3R5bGVzaGVldCIgdHlwZT0idGV4dC9jc3MiIG1lZGlhPSJwcmludCIvPg0KPGxpbmsgaHJlZj0iL3djc3N0b3JlL0NOL2Nzcy9zZWFyY2hfc3R5bGVzLmNzcyIgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIvPg0KPGxpbmsgaHJlZj0iL3djc3N0b3JlL0NOL2Nzcy9zdHlsZXNfb3ZlcnJpZGUuY3NzIiByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIi8+DQo8bGluayBpZD0idGhpY2tCb3hDc3MiIGhyZWY9Ii93Y3NzdG9yZS9DTi9jc3MvdGhpY2tib3guY3NzIiByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIiAvPg0KDQo8bGluayByZWw9ImNhbm9uaWNhbCIgaHJlZj0iaHR0cDovL3d3dy5kaWdpa2V5LmNvbS5jbi9zZWFyY2gvemgvMTYzLTcwMTAtMDEwMi8xNjMtNzAxMC0wMTAyLU5EP3JlY29yZElkPTM0MjY2NTciLz4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9kb2pvMTMxL2Rvam8vZG9qby5qcyIgZGpDb25maWc9InBhcnNlT25Mb2FkOiBmYWxzZSwgaXNEZWJ1ZzogZmFsc2UsIHVzZUNvbW1lbnRlZEpzb246IHRydWUsbG9jYWxlOiAnemgtY24nICI+PC9zY3JpcHQ+DQo8L2hlYWQ+DQoNCjxib2R5IHN0eWxlPSdwYWRkaW5nLWxlZnQ6IDBweDsgcGFkZGluZy1yaWdodDogMHB4Oycgb25VbmxvYWQ9J2VuYWJsZVN1Ym1pdCgpJz4NCg0KPHNjcmlwdCB0eXBlPSd0ZXh0L2phdmFzY3JpcHQnPg0KZnVuY3Rpb24gZGVsUXVhbnRpdHkoKQ0Kew0KDQpkZWxldGVRdWFudGl0eSgpDQp9DQoJLy92YXIgdXJsID0gbmV3IFN0cmluZyh3aW5kb3cubG9jYXRpb24pOw0KCS8vaWYgKHVybC5pbmRleE9mKCJodHRwczovLyIpICE9IC0xKSB7DQoJLy8Jd2luZG93LmxvY2F0aW9uID0gdXJsLnJlcGxhY2UoImh0dHBzOi8vIiwgImh0dHA6Ly8iKTsNCgkvL30JDQo8L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0ndGV4dC9qYXZhc2NyaXB0Jz4NCiB2YXIgYnRuVmlld0Zhdm9yaXRlVHh0ID0gJ+afpeeci+aUtuiXj+WkuSc7DQogdmFyIGJ0bkNvbnRpbnVlU2hvcHBpbmdUeHQgPSAn57un57ut6LSt5LmwJzsNCg0KIGZ1bmN0aW9uIGFkZFBhcnRUb0Zhdm9yaXRlKGRpZ2lrZXlQYXJ0TnVtYmVyKSB7DQoJCWlmKCdHJyA9PSAnRycpew0KCQkgJCggZG9jdW1lbnQgKS5yZWFkeShmdW5jdGlvbigpIHsNCiAJCQkJc2hvd0hlbHBEaWFsb2coJyNsb2dpbkRpYWxvZycsJ2F1dG8nLCczMDBweCcsZmFsc2UsdHJ1ZSx7fSk7DQoJCSB9KTsNCgkgIH0gZWxzZSB7DQoJCW9wZW5Qcm9ncmVzc01vZGFsV2luZG93KCk7DQoJCXZhciBwYXJhbXMgPSBbXTsNCgkJcGFyYW1zLmRrY1BhcnROdW1iZXIgPSBkaWdpa2V5UGFydE51bWJlcjsNCgkJZG9qby54aHJQb3N0KHsNCiAgICAJCXVybDogIi9teWRpZ2lrZXkvQWpheEludGVyZXN0SXRlbUFkZCIsCQ0KICAgIAkJaGFuZGxlQXM6ICJqc29uLWNvbW1lbnQtZmlsdGVyZWQiLAkJCQ0KICAgIAkJY29udGVudDogcGFyYW1zLA0KICAgIAkJc2VydmljZTogdGhpcywNCiAgICAJCWxvYWQ6IGZ1bmN0aW9uKHNlcnZpY2VSZXNwb25zZSwgaW9BcmdzKSB7DQogICAgCQlpZiAoc2VydmljZVJlc3BvbnNlLmVycm9yTWVzc2FnZUtleSAhPSBudWxsKSB7DQogICAgCQkJZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2Zhdm9yaXRlQWRkRXJyb3JNb2RlbFdpbmRvdycpLmlubmVySFRNTCA9IHNlcnZpY2VSZXNwb25zZS5lcnJvck1lc3NhZ2U7DQogICAgCQkJJCgnI2Zhdm9yaXRlQWRkRXJyb3JNb2RlbFdpbmRvdycpLmRpYWxvZygnb3BlbicpOw0KICAgIAkJfSBlbHNlIHsNCiAgICAJCQl2YXIgYnV0dG9uT3B0cyA9IHt9Ow0KCQkJCWJ1dHRvbk9wdHNbYnRuQ29udGludWVTaG9wcGluZ1R4dF0gPSBmdW5jdGlvbiAoKSB7DQoJCQkJICAgICQodGhpcykuZGlhbG9nKCJjbG9zZSIpOw0KCQkJCX07DQoJCQkJYnV0dG9uT3B0c1tidG5WaWV3RmF2b3JpdGVUeHRdID0gZnVuY3Rpb24gKCkgew0KCQkJCQkgd2luZG93LmxvY2F0aW9uLmhyZWYgPSAnaHR0cHM6Ly93d3cuZGlnaWtleS5jb20uY24vbXlkaWdpa2V5L015RmF2b3JpdGVQYXJ0c0NtZCc7DQoJCQkJfTsNCgkJCQkkKCcjZmF2b3JpdGVBZGRNb2RlbFdpbmRvdycpLmRpYWxvZygib3B0aW9uIiwgImJ1dHRvbnMiLCBidXR0b25PcHRzKTsNCgkJCQkkKCcjZmF2b3JpdGVBZGRNb2RlbFdpbmRvdycpLmRpYWxvZygnb3BlbicpOw0KCQkJCX0NCgkJCQljbG9zZVByb2dyZXNzTW9kYWxXaW5kb3coKTsNCgkJCX0sDQogICAgCQllcnJvcjogZnVuY3Rpb24oZXJyT2JqLCBpb0FyZ3MpIHsNCiAgICAJCQljbG9zZVByb2dyZXNzTW9kYWxXaW5kb3coKTsNCiAgICAJCQljb25zb2xlLmxvZygiRXJyb3Igd2hpbGUgc2F2aW5nIHBhcnQgdG8gZmF2b3JpdGUuIik7DQoJICAgIAl9DQogCQkgfSk7DQogCQkgfQ0KCQl9DQo8L3NjcmlwdD4NCjwhLS0gSW5jbHVkZSBIZWFkZXIgLS0+Cgo8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCI+CiAgIAkgICB2YXIgc3RvcmVJbWFnZXNEaXI9Ii93Y3NzdG9yZS9DTi8iOwogICAJICAgdmFyIGRlZmF1bHRDdXJyZW5jeSA9ICdDTlknOwoJICAgdmFyIG9rQnV0dG9uVGV4dD0gJ+ehruWumic7Cjwvc2NyaXB0PgoKCQk8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCI+CgkJICAgdmFyIGRpbWVuc2lvblNlYXJjaFVybCA9ICcvL3d3dy5kaWdpa2V5LmNvbS5jbi93ZWJhcHAvd2NzL3N0b3Jlcy9zZXJ2bGV0L0RpbWVuc2lvblZpZXcnOwoJICAgPC9zY3JpcHQ+CgkJPHN0eWxlIHR5cGU9InRleHQvY3NzIj4gCgkJPCEtLQoJCSNzaG9wcGluZ0NhcnQge3dpZHRoOjE3NXB4O30KCQkjY2FydHtkaXNwbGF5OmJsb2NrOyBoZWlnaHQ6NTFweDsgd2lkdGg6MTc1cHg7IGJhY2tncm91bmQtaW1hZ2U6dXJsKC8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2ltYWdlcy9kaWdpa2V5L2hlYWRlci9jYXJ0LXpocy5qcGcpOyBwb3NpdGlvbjpyZWxhdGl2ZTsgdGV4dC1kZWNvcmF0aW9uOm5vbmU7fQoJCSNjYXJ0IHNwYW4ge2N1cnNvcjpwb2ludGVyfQoJCSNxdHlJZCB7IHBvc2l0aW9uOmFic29sdXRlOyB0b3A6MzJweDsgbGVmdDoxMHB4OyBmb250LXNpemU6MTBweDsgZm9udC13ZWlnaHQ6Ym9sZDsgY29sb3I6I2M1MDAxZjsgfQoJCSNzdWJUb3RhbElkIHtwb3NpdGlvbjphYnNvbHV0ZTsgdG9wOjI5cHg7IHJpZ2h0OjEwcHg7ICBjb2xvcjojMDAwOyBmb250LXdlaWdodDpib2xkOyBmb250LXNpemU6MTRweDt9CgkJI2hlYWRlclRhYmxlIHRkIHt3aGl0ZS1zcGFjZTpub3dyYXA7fQoJCSNxdWlja0xpbmtzIHt3aWR0aDphdXRvOyB3aWR0aDoxMDAlXDk7fQoJCSNoZWFkZXIgYSBpbWcge2JvcmRlcjogbm9uZSAhaW1wb3J0YW50O30KCQkjY3VyX3RhYiB7Zm9udC1zaXplOjEycHg7IGNvbG9yOiNiYmI7IGZvbnQtd2VpZ2h0OmJvbGQ7fSAKCQktLT4KCQk8L3N0eWxlPgoJCTxsaW5rIHJlbD0ic3R5bGVzaGVldCIgdHlwZT0idGV4dC9jc3MiIGhyZWY9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvRGVzaWduZXIvR2xvYmFsL0NTUy9qcXVlcnktdWkuMS4xMS40LmNzcyI+CgkJCgkJPGxpbmsgcmVsPSJzdHlsZXNoZWV0IiBocmVmPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9jc3MvanF1ZXJ5LmF1dG9jb21wbGV0ZS5jc3MiIHR5cGU9InRleHQvY3NzIj48L2xpbms+CgkJPGxpbmsgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vY3NzL2RpZ2lrZXkvSGVhZGVyRm9vdGVyLmNzcyIvPgoJCTxsaW5rIHJlbD0ic3R5bGVzaGVldCIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vY3NzL2Ryb3B6b25lLmNzcyIvPgoJCQoJCTxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvRGVzaWduZXIvR2xvYmFsL0pTL2pxdWVyeS0xLjExLjMubWluLmpzIj48L3NjcmlwdD4KCQk8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0Rlc2lnbmVyL0dsb2JhbC9KUy9qcXVlcnktdWkuMS4xMS40Lm1pbi5qcyI+PC9zY3JpcHQ+CgkJPCEtLSA8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L2RpZ2lrZXkvY3VycmVuY3lTZXR0ZXIuanMiPjwvc2NyaXB0PiAgCgkJPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9kaWdpa2V5L2N1cnJlbmN5VG9nZ2xlLmpzIj48L3NjcmlwdD4gLS0+CgkJPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9kaWdpa2V5L2pzb24yLmpzIj48L3NjcmlwdD4KCQk8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L2RpZ2lrZXkvaGVhZGVyX3NlYXJjaF9jb29raWUuanMiPjwvc2NyaXB0PgoJCTxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2phdmFzY3JpcHQvanF1ZXJ5LmF1dG9jb21wbGV0ZS5qcyI+PC9zY3JpcHQ+CgkJPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9jb21tb25VdGlsLmpzIj48L3NjcmlwdD4gIAoJCTxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2phdmFzY3JpcHQvZHJvcHpvbmUuanMiLz4iPjwvc2NyaXB0PgoJCQoJCTwhLS1TVEFSVCBPRiBTaXRlQ29yZUhlYWRlci5qc3AgLS0+DQo8bGluayByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIiBocmVmPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0Rlc2lnbmVyL0hlYWRlci9NZXJrbGUvQ1NTL2hlYWRlci5jc3M/bGE9emgtQ04tUk1CJmFtcDt0cz1mY2VmMGQ3ZC05NTdhLTRiY2UtYjIwMi1mYTI4MjkwOTZkMzUiIC8+PGxpbmsgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9STUIgUVEgQ2hhdC9DU1MvanF1ZXJ5LXVpLmNzcz9sYT16aC1DTi1STUImYW1wO3RzPTliYjY3MWUwLWE5YjctNDBiOS1hOTQxLTBjM2JhZTkyZjY2YiIgLz48bGluayByZWw9InN0eWxlc2hlZXQiIHR5cGU9InRleHQvY3NzIiBocmVmPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0Rlc2lnbmVyL1JNQiBRUSBDaGF0L0NTUy9ybWJoZWFkZXIuY3NzP2xhPXpoLUNOLVJNQiZhbXA7dHM9OTVhNTgwODctZDc2Yy00YjdjLWI5OTQtNGEyNmZkMzZhYjY2IiAvPg0KPGRpdiBpZD0iaGVhZGVyIiBzY3NfZXhjbHVkZT0idHJ1ZSIgY29va2llLXRyYWNraW5nPSJXVC56X2hlYWRlcj1saW5rO2hlYWRlcl9mbGFnPWxpbmsiPgoJCiAgICA8ZGl2IGlkPSJoZWFkZXItbGVmdCI+CiAgICAgICAgPGEgaHJlZj0iaHR0cDovL3d3dy5kaWdpa2V5LmNvbS5jbiI+PGltZyBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9sb2dvX2RrLnBuZz9sYT16aC1DTi1STUImdHM9NWI2YjgxZGMtNzRiMy00MjhkLTgyNTEtYzk2ZWZiZWJlYzg5IiBhbHQ9IkRpZ2ktS2V5IEVsZWN0cm9uaWNzIC0gRWxlY3Ryb25pYyBDb21wb25lbnRzIERpc3RyaWJ1dG9yIiAvPjwvYT4KICAgIDwvZGl2PgogICAgPGRpdiBpZD0iaGVhZGVyLXJpZ2h0Ij4KICAgICAgICA8ZGl2IGlkPSJoZWFkZXItbG9jYWxlIj4KICAgICAgICAgICAgPGRpdiBjbGFzcz0iaGVhZGVyLWxvY2FsZS1yb3ciPgogICAgICAgICAgICAgICAgPHNwYW4+5Lit5Zu9PC9zcGFuPgogICAgICAgICAgICAgICAgPHNwYW4gY2xhc3M9ImhlYWRlci1zZXAiPjwvc3Bhbj4KICAgICAgICAgICAgICAgIDxzcGFuPjQwMCA5MjAgMTE5OTwvc3Bhbj4KICAgICAgICAgICAgPC9kaXY+CiAgICAgICAgICAgIDxkaXYgY2xhc3M9ImhlYWRlci1sb2NhbGUtcm93Ij4KICAgICAgICAgICAgICAgIDxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbCIgY2xhc3M9ImhlYWRlci1jaGFuZ2UtY291bnRyeSI+5pS55Y+Y5Zu95a62PC9hPgogICAgICAgICAgICAgICAgPGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsIj48aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvR2xvYmFsL0ZsYWdzL0NOX0ZsYWcucG5nP3RzPTVjOTU5NTIwLThiNWEtNDBiNy04NzU0LWQyOTZhY2VkNjEzOSIgY2xhc3M9ImhlYWRlci1mbGFnIiBhbHQ9IkNOIiAvPjwvYT4KICAgICAgICAgICAgICAgIDxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbCIgY2xhc3M9ImhlYWRlci1sYW5nIj48L2E+CiAgICAgICAgICAgICAgICA8c3BhbiBjbGFzcz0iaGVhZGVyLXNlcCI+PC9zcGFuPgogICAgICAgICAgICAgICAgPGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsIiBjbGFzcz0iaGVhZGVyLWN1cnJlbmN5Ij5DTlk8L2E+CiAgICAgICAgICAgIDwvZGl2PgogICAgICAgIDwvZGl2PgogICAgICAgIDxkaXY+PGRpdiBpZD0iaGVhZGVyLWNhcnQiIGNsYXNzPSJoZWFkZXItZHJvcGRvd24iPjxzcGFuIGNsYXNzPSJoZWFkZXItZHJvcGRvd24tdGl0bGUgaGVhZGVyLXJlc291cmNlIj48aW1nIGNsYXNzPSJoZWFkZXItaWNvbiIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9IZWFkZXIvY2FydC13aGl0ZS5wbmc/bGE9emgtQ04tUk1CJnRzPWUwMjIyNTYzLWQwNDgtNDZlMC04ZTUwLWNiZTAzOWY1MzIxMCIgYWx0PSJjYXJ0IHdoaXRlIiAvPiDmgqjnmoTpobnnm64gPGltZyBjbGFzcz0iaGVhZGVyLWljb24iIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvSGVhZGVyL3RyaWFuZ2xlLXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9M2EyY2NjZWItMzAzNC00NGRkLWEwNTYtYjM1ODI4Y2RmYjgxIiBhbHQ9InRyaWFuZ2xlIHdoaXRlIiAvPjwvc3Bhbj48ZGl2IGNsYXNzPSJoZWFkZXItZHJvcGRvd24tY29udGVudCI+PGEgaHJlZj0iaHR0cHM6Ly93d3cuZGlnaWtleS5jb20uY24vb3JkZXJpbmcvU2hvcHBpbmdDYXJ0Vmlldz9XVC56X2hlYWRlcj1saW5rIiBjbGFzcz0iaGVhZGVyLXZpZXctY2FydCBoZWFkZXItYnV0dG9uIj7mn6XnnIvotK3nianovaY8L2E+PC9kaXY+PC9kaXY+PHNwYW4gY2xhc3M9ImhlYWRlci1yZXNvdXJjZS1zZXAiPiZuYnNwOzwvc3Bhbj48ZGl2IGlkPSJoZWFkZXItbG9naW4iIGNsYXNzPSJoZWFkZXItZHJvcGRvd24iPjxkaXYgaWQ9ImhlYWRlci1sb2dpbi10aXRsZSIgY2xhc3M9ImhlYWRlci1kcm9wZG93bi10aXRsZSBoZWFkZXItcmVzb3VyY2UiPjxwIGNsYXNzPSJoZWFkZXItaGVsbG8iPueZu+W9leaIljwvcD48cD7ms6jlhowgPGltZyBjbGFzcz0iaGVhZGVyLWljb24iIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvSGVhZGVyL3RyaWFuZ2xlLXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9M2EyY2NjZWItMzAzNC00NGRkLWEwNTYtYjM1ODI4Y2RmYjgxIiBhbHQ9InRyaWFuZ2xlIHdoaXRlIiAvPjwvcD48L2Rpdj48ZGl2IGNsYXNzPSJoZWFkZXItZHJvcGRvd24tY29udGVudCI+PGEgaHJlZj0iaHR0cHM6Ly93d3cuZGlnaWtleS5jb20uY24vbXlkaWdpa2V5L0xvZ29uRm9ybSIgY2xhc3M9ImhlYWRlci1idXR0b24iPueZu+W9lTwvYT48YSBocmVmPSIvbXlkaWdpa2V5L1VzZXJSZWdpc3RyYXRpb25BZGRGb3JtVmlldyIgY2xhc3M9ImhlYWRlci1idXR0b24iPuazqOWGjDwvYT48YSBocmVmPSIvemgvaGVscC93aHktcmVnaXN0ZXIiIGNsYXNzPSJoZWFkZXItYnV0dG9uIj7kuLrkvZXms6jlhow8L2E+PC9kaXY+PC9kaXY+PC9kaXY+CiAgICA8L2Rpdj4KICAgIDxkaXYgaWQ9ImhlYWRlci1taWRkbGUiPgogICAgICAgIDxkaXYgaWQ9ImhlYWRlci1zZWFyY2gtd3JhcHBlciI+CiAgICAgICAgICAgIDxkaXYgaWQ9ImhlYWRlci1zZWFyY2gtc2VsZWN0LXdyYXBwZXIiPgogICAgICAgICAgICAgICAgPHNlbGVjdCBpZD0iaGVhZGVyLXNlYXJjaC10eXBlIj4KICAgICAgICAgICAgICAgICAgICA8b3B0aW9uIHNlbGVjdGVkPSJzZWxlY3RlZCIgdmFsdWU9Ii9zZWFyY2gvemg/V1Quel9oZWFkZXI9c2VhcmNoX2dvJmFtcDtrZXl3b3Jkcz17MH0iIGRhdGEtbmFtZT0ia2V5d29yZHMiPumbtuS7tjwvb3B0aW9uPjxvcHRpb24gdmFsdWU9Ii96aC9jb250ZW50LXNlYXJjaD90PXswfSZhbXA7V1Quel9oZWFkZXI9c2VhcmNoX2dvIiBkYXRhLW5hbWU9Ik50dCI+5YaF5a65PC9vcHRpb24+CiAgICAgICAgICAgICAgICA8L3NlbGVjdD4KICAgICAgICAgICAgPC9kaXY+CiAgICAgICAgICAgIDxidXR0b24gaWQ9ImhlYWRlci1zZWFyY2gtYnV0dG9uIiB0eXBlPSJidXR0b24iPjwvYnV0dG9uPgogICAgICAgICAgICA8c3BhbiBpZD0iaGVhZGVyLXNlYXJjaC1ob2xkZXIiPjxpbnB1dCBpZD0iaGVhZGVyLXNlYXJjaCIgdHlwZT0idGV4dCIgY2xhc3M9ImRrZGlyY2hhbmdlciIgLz48L3NwYW4+CiAgICAgICAgPC9kaXY+CiAgICAgICAgPGRpdj48YSBocmVmPSIvc2VhcmNoL3poIiBjbGFzcz0iaGVhZGVyLXJlc291cmNlIj7kuqflk4E8L2E+PHNwYW4gY2xhc3M9ImhlYWRlci1yZXNvdXJjZS1zZXAiPiZuYnNwOzwvc3Bhbj48YSBocmVmPSIvemgvc3VwcGxpZXItY2VudGVycyIgY2xhc3M9ImhlYWRlci1yZXNvdXJjZSI+5Yi26YCg5ZWGPC9hPjxzcGFuIGNsYXNzPSJoZWFkZXItcmVzb3VyY2Utc2VwIj4mbmJzcDs8L3NwYW4+PGRpdiBjbGFzcz0iaGVhZGVyLWRyb3Bkb3duIj48c3BhbiBjbGFzcz0iaGVhZGVyLWRyb3Bkb3duLXRpdGxlIGhlYWRlci1yZXNvdXJjZSI+6LWE5rqQIDxpbWcgY2xhc3M9ImhlYWRlci1pY29uIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci90cmlhbmdsZS13aGl0ZS5wbmc/bGE9emgtQ04tUk1CJnRzPTNhMmNjY2ViLTMwMzQtNDRkZC1hMDU2LWIzNTgyOGNkZmI4MSIgYWx0PSJ0cmlhbmdsZSB3aGl0ZSIgLz48L3NwYW4+PGRpdiBjbGFzcz0iaGVhZGVyLXJlc291cmNlLWNvbnRlbnQgaGVhZGVyLWRyb3Bkb3duLWNvbnRlbnQiPjxwIGNsYXNzPSJoZWFkZXItZGFyayI+5Y+C6ICDPC9wPjx1bD48bGk+PGEgaHJlZj0iL3poL2FydGljbGVzL3RlY2h6b25lLyI+5paH5bqTPC9hPjwvbGk+PGxpPjxhIGhyZWY9Ii96aC9jb250ZW50LXNlYXJjaCI+5YaF5a655bqTCjwvYT48L2xpPjxsaT48YSBocmVmPSIvemgvcHJvZHVjdC1oaWdobGlnaHQiPuacgOaWsOS6p+WTgQo8L2E+PC9saT48bGk+PGEgaHJlZj0iL3poL3B0bSI+5Lqn5ZOB5Z+56K6t5qih5Z2XIChQVE0pPC9hPjwvbGk+PGxpPjxhIGhyZWY9Ii92aWRlb3MvemgiPuinhumikeW6kzwvYT48L2xpPjwvdWw+PGhyIGNsYXNzPSJoZWFkZXItZHJvcGRvd24tc2VwIj48L2hyPjxwIGNsYXNzPSJoZWFkZXItZGFyayI+6K6+6K6hPC9wPjx1bD48bGk+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9vbmxpbmUtY29udmVyc2lvbi1jYWxjdWxhdG9ycyI+5Zyo57q/5o2i566X5ZmoPC9hPjwvbGk+PGxpPjxhIGhyZWY9Ii9yZWZlcmVuY2UtZGVzaWducy96aCI+5Y+C6ICD6K6+6K6hCjwvYT48L2xpPjxsaT48YSBocmVmPSIvemgvdGVjaHpvbmVzIj5UZWNoWm9uZXPihKA8L2E+PC9saT48L3VsPjxociBjbGFzcz0iaGVhZGVyLWRyb3Bkb3duLXNlcCI+PC9ocj48cCBjbGFzcz0iaGVhZGVyLWRhcmsiPuaQnOe0oi/mjpLluo88L3A+PHVsPjxsaT48YSBocmVmPSIvb3JkZXJpbmcvQm9tTWFuYWdlciI+54mp5paZ5riF5Y2V566h55CG5ZmoIDwvYT48L2xpPjxsaT48YSBocmVmPSIvemgvcmVzb3VyY2VzL2Jyb3dzZXItcmVzb3VyY2VzIj7mtY/op4jlmajotYTmupA8L2E+PC9saT48bGk+PGEgaHJlZj0iL29yZGVyaW5nL09yZGVyU3RhdHVzRW50cnlWaWV3Ij7orqLljZXnirbmgIE8L2E+PC9saT48bGk+PGEgaHJlZj0iL29yZGVyaW5nL1Nob3BwaW5nQ2FydFZpZXciPui0reeJqei9pgo8L2E+PC9saT48L3VsPjwvZGl2PjwvZGl2PjxzcGFuIGNsYXNzPSJoZWFkZXItcmVzb3VyY2Utc2VwIj4mbmJzcDs8L3NwYW4+PGEgaHJlZj0iamF2YXNjcmlwdDo7IiBpZD0icXFvbmxpbmVfZmxvYXQiIGNsYXNzPSJoZWFkZXItcmVzb3VyY2UiPjxpbWcgY2xhc3M9ImhlYWRlci1pY29uIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9jaGF0LXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9ZjIyOWYxMDQtOGQ3OC00NzkwLWIyYjgtMjZkYzM2ZDk5NDkyIiBhbHQ9ImNoYXQgd2hpdGUiIC8+IFFR5Zyo57q/5ZKo6K+iPC9hPjwvZGl2PgogICAgPC9kaXY+Cgo8L2Rpdj4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij5fX2hlYWRlckRhdGEgPSB7ImNhcnRUaXRsZSI6IiZjYXJ0OyB7MH0g6aG5ICZkcm9wZG93bjsiLCJ2aWV3Q2FydCI6Iuafpeeci+i0reeJqei9piAoezB9IOmhueebrikiLCJ1c2VyTGluZTEiOiLmgqjlpb0gezB9IiwidXNlckxpbmUyIjoi5oiR55qEIERpZ2ktS2V5ICZkcm9wZG93bjsiLCJub0ltYWdlIjoiaHR0cDovL21lZGlhLmRpZ2lrZXkuY29tL1Bob3Rvcy9Ob1Bob3RvL3BuYV9lbl90bWIuanBnIiwiZW50aXRpZXMiOnsiY2FydCI6IjxpbWcgY2xhc3M9XCJoZWFkZXItaWNvblwiIHNyYz1cIi8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9jYXJ0LXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9ZTAyMjI1NjMtZDA0OC00NmUwLThlNTAtY2JlMDM5ZjUzMjEwXCIgYWx0PVwiY2FydCB3aGl0ZVwiIC8+IiwiZHJvcGRvd24iOiI8aW1nIGNsYXNzPVwiaGVhZGVyLWljb25cIiBzcmM9XCIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9IZWFkZXIvdHJpYW5nbGUtd2hpdGUucG5nP2xhPXpoLUNOLVJNQiZ0cz0zYTJjY2NlYi0zMDM0LTQ0ZGQtYTA1Ni1iMzU4MjhjZGZiODFcIiBhbHQ9XCJ0cmlhbmdsZSB3aGl0ZVwiIC8+IiwiY2hhdCI6IjxpbWcgY2xhc3M9XCJoZWFkZXItaWNvblwiIHNyYz1cIi8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hlYWRlci9jaGF0LXdoaXRlLnBuZz9sYT16aC1DTi1STUImdHM9ZjIyOWYxMDQtOGQ3OC00NzkwLWIyYjgtMjZkYzM2ZDk5NDkyXCIgYWx0PVwiY2hhdCB3aGl0ZVwiIC8+In0sInNpdGUiOiJDTiIsImxhbmciOiJ6aCIsImN1ciI6IkNOWSIsImVuYWJsZVRvZ2dsZSI6dHJ1ZSwiZW5hYmxlQ3VyVG9nZ2xlIjp0cnVlLCJsYW5ncyI6W3sibmFtZSI6bnVsbCwiY29kZSI6InpoIn1dLCJvcmRlclNpdGUiOiJjbiIsIm9yZGVyTGFuZyI6InpoIiwiY3VycyI6WyJDTlkiLCJVU0QiXSwibGlua3MiOlt7InRpdGxlIjoi5oiR55qEIERpZ2ktS2V5IiwibGluayI6Imh0dHBzOi8vd3d3LmRpZ2lrZXkuY29tLmNuL215ZGlnaWtleS9Mb2dvbkZvcm0gIn0seyJ0aXRsZSI6IumAgOWHuiIsImxpbmsiOiIvbXlkaWdpa2V5L0xvZ29mZiJ9XX07PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9IZWFkZXIvTWVya2xlL0phdmFzY3JpcHQvaGVhZGVyLmpzP3RzPTAxYWFiMjExLWE0NDMtNGIwYy1hYjBiLTA3YWM3Y2QyY2IwZCI+PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9STUIgUVEgQ2hhdC9KYXZhc2NyaXB0L3JtYmhlYWRlci5qcz9sYT16aC1DTi1STUImYW1wO3RzPWY3YzI1NmViLTcwNDItNDNkNC05MDQwLTI0ZjM5MjVlYmYwMyI+PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9STUIgUVEgQ2hhdC9KYXZhc2NyaXB0L3N1Ym1pdF9jb250ZW50X3RvX2JhaWR1LmpzP2xhPXpoLUNOLVJNQiZhbXA7dHM9Mzc4MTE5NTgtMGU3NS00MjBjLTg4ZmMtY2Y1MWYyZDgzNGM4Ij48L3NjcmlwdD48c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCI+PC9zY3JpcHQ+DQoNCg0KPCEtLUVORCBPRiBTaXRlQ29yZUhlYWRlci5qc3AgLS0+DQo8ZGl2IGlkPSJjb250ZW50Ij4gPCEtLSBTdGFydCBvZiBkaXYgY29udGVudCAtLT48IS0tIFN0YXJ0IEhlYWRlciBDb250ZW50IC0tPgo8ZGl2IGlkPSJqc3BTdG9yZUltZ0RpciIgc3R5bGU9ImRpc3BsYXk6bm9uZSI+L3djc3N0b3JlL0NOLzwvZGl2Pgo8IS0tIEhlYWRlciBDb250ZW50IEVuZHMtLT48IS0tIGhlbHAgZGlhbG9nIGNvbnRlbnQgLS0+DQoNCjxkaXYgaWQ9IlRBUEVSRUVMX1BhY2thZ2luZ0hlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCeWNt+W4puaYr+aMh+S7juWItumAoOWVhuaOpeaUtueahOeOsOaIkOi/nue7reWMheijheW4puWNt+OAguS9jeS6juWni+err+WSjOacq+err+eahOepuueZveW4pu+8jOS6puWIhuWIq+ensOW8leW4puWSjOWwvuW4pu+8jOacieWKqeS6juS9v+eUqOiHquWKqOijhemFjeiuvuWkh+OAguWNt+W4puaYr+agueaNrueUteWtkOW3peS4muWQjOebnyAoRUlBKSDmoIflh4bnvKDnu5XmiJDloZHmlpnnm5jljbfjgILnm5jljbflsLrlr7jjgIHpl7Tot53jgIHmlbDph4/lkozmlrnlkJHlj4rlhbbku5bor6bnu4bkv6Hmga/lnYfkvY3kuo7pm7bku7bop4TmoLzkuabnu5PlsL7lpITjgILljbfluKbkvJrmoLnmja7liLbpgKDllYbop4TlrprnmoQgRVNE77yI6Z2Z55S15pS+55S177yJ5ZKMIE1TTO+8iOa5v+W6puaVj+aEn+etiee6p++8ieS/neaKpOimgeaxgui/m+ihjOWMheijheOAgg0KPC9kaXY+DQoNCjxkaXYgaWQ9IkNVVFRBUEVfUGFja2FnaW5nSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyI+DQoJ5YiH5bim5oyH5LuO5bim5Y2377yI6KeB5LiK5paH5LuL57uN77yJ5LiK5YiH5LiL55qE5LiA5q6177yM5ZCr5pyJ6K6i6LSt5pWw6YeP55qE6Zu25Lu244CC5YiH5bim5rKh5pyJ5byV5bim5ZKM5bC+5bim77yM5Zug5q2k5LiN6YCC55So5LqO6K645aSa6Ieq5Yqo6KOF6YWN6K6+5aSH44CC5YiH5bim54S25ZCO5Lya5oyJ54Wn5Yi26YCg5ZWG6KeE5a6a55qEIEVTRO+8iOmdmeeUteaUvueUte+8ieWSjCBNU0zvvIjmub/luqbmlY/mhJ/nrYnnuqfvvInkv53miqTopoHmsYLov5vooYzljIXoo4XjgIINCjwvZGl2Pg0KDQo8ZGl2IGlkPSJCVUxLX1BhY2thZ2luZ0hlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCeaVo+ijheaYr+eUqOS6juadguS5seOAgeadvuaVo+mbtuS7tueahOWMheijheW9ouW8j++8iOmAmuW4uOS4uuiii+WtkO+8ie+8jOS4lOS4gOiIrOaDheWGteS4i+S4jemAgueUqOS6juiHquWKqOijhemFjeiuvuWkh+OAguaVo+ijhembtuS7tuS8muagueaNruWItumAoOWVhuinhOWumueahCBFU0TvvIjpnZnnlLXmlL7nlLXvvInlkowgTVNM77yI5rm/5bqm5pWP5oSf562J57qn77yJ5L+d5oqk6KaB5rGC6L+b6KGM5YyF6KOF44CCDQo8L2Rpdj4NCg0KPGRpdiBpZD0iVEFQRUFOREJPWF9QYWNrYWdpbmdIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7Ij4NCgnnm5LluKbmmK/kuIDmrrXluKbmnInpm7bku7bnmoTluKblrZDvvIzmnaXlm57mipjlj6DmiJbogIXljbfmiJDonrrml4vnirblkI7mlL7lhaXnm5LlrZDkuK3jgIIg5bim5a2Q5LiA6Iis5LuO55uS5a2Q55qE6aG26YOo5byA5a2U5aSE5ouJ5Ye644CCIOW4puWtkOinhOagvOOAgemXtOi3neOAgeaVsOmHj+OAgeaWueWQkeS7peWPiuWFtuWug+ivpue7huS/oeaBr+mAmuW4uOS9jeS6jumbtuS7tuinhOagvOS5pueahOe7k+WwvumDqOWIhuOAgiDnm5LluKbmoLnmja7liLbpgKDllYbop4TlrprnmoQgIEVTRO+8iOmdmeeUteaUvueUte+8ieWSjCBNU0zvvIjmub/luqbmlY/mhJ/nrYnnuqfvvInkv53miqTopoHmsYLljIXoo4XjgIINCjwvZGl2Pg0KDQo8ZGl2IGlkPSJUVUJFX1BhY2thZ2luZ0hlbHBEaWFsb2ciICBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCeeuoeijheaYr+S4gOenjeehrOi0qOaMpOWOi+WhkeaWmeeuoeW9ouWMheijhe+8jOiDveWkn+mAguWQiOmbtuS7tuWkluW9ou+8jOS/neaKpOW8leiEmuOAgueuoeijheWPkei0p+aXtuWGheWQq+S4juiuoui0reaVsOmHj+S4gOiHtOeahOmbtuS7tu+8jOS4lOS4pOerr+Wdh+acieS4gOS4quapoeearuWhnuaIluiAheWhkeaWmeapm++8jOS7pemYsumbtuS7tuS7jueuoeS4rea7keiQveOAgueuoeijheS8muagueaNruWItumAoOWVhuinhOWumueahCBFU0TvvIjpnZnnlLXmlL7nlLXvvInlkowgTVNM77yI5rm/5bqm5pWP5oSf562J57qn77yJ5L+d5oqk6KaB5rGC6L+b6KGM5YyF6KOF44CCDQo8L2Rpdj4NCg0KPGRpdiBpZD0iVFJBWV9QYWNrYWdpbmdIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7Ij4NCgnmiZjnm5jpgJrluLjmjIfop4TmoLzkuLogMTIuN3g1LjN4MC4yNe+8iOmrmO+8ieiLseWvuOaIluiAhSAxMi43eDUuM3gwLjQw77yI6auY77yJ6Iux5a+455qEIEpFREVDIOagh+WHhuefqemYteaJmOebmOOAgiDmiZjnm5jpgJrluLjnlLHloZHmlpnliLbmiJDvvIzkuZ/lhYHorrjph4fnlKjpk53jgIIgSkVERUMg5omY55uY5LiK5pyJ6IO95L2/56m65rCU5Z6C55u06YCa6L+H55qE5qe957yd77yM5bm25LiU6Iez5bCR6IO95om/5Y+XIDE0MMKwQyDpq5jmuKnvvIzku6Xkvr/lnKjlt6XkuJrng5jngonkuK3lubLnh6Xpm7bku7bjgIIg5omY55uY5Y+v5Lul5aCG5Y+g77yM55So5LiA5Liq5YCS6KeS5oyH56S66Zu25Lu255qE5LiA5Y+35byV6ISa55qE5pa55ZCR44CCIOaJmOebmOagueaNruWItumAoOWVhuinhOWumueahCAgRVNE77yI6Z2Z55S15pS+55S177yJ5ZKMIE1TTO+8iOa5v+W6puaVj+aEn+etiee6p++8ieS/neaKpOimgeaxguWMheijheOAgg0KPC9kaXY+DQoNCjxkaXYgaWQ9IkRJR0ktUkVFTF9QYWNrYWdpbmdIZWxwRGlhbG9nIiAgc3R5bGU9ImRpc3BsYXk6IG5vbmU7Ij4NCgk8cD5EaWdpLVJlZWzCriDmmK/kuIDnp43luKbljbfovbTvvIzmoLnmja7lrqLmiLfoh6rlrprmlbDph4/ku47nlJ/kuqfllYbnmoTluKbljbfovbTkuIrlsIbnu53nvJjluKbov57nu63nvKDnu5XlnKjov5nkuKrluKbljbfovbTkuIrjgIIg5bim5pyJNDYgY23lpLTlsL7lvJXluKbvvIzog73kvb/pk77ova7pvb/lrZTmiJDkuIDnur/lr7nnm7TvvIzlubbnoa7kv53ljbfluKbnrJTnm7TkuJTmr6vml6DlgY/lt67lnLDpgIHlhaXoh6rliqjljJbmnb/oo4Xnva7orr7lpIfvvJvnhLblkI7moLnmja7nlLXlrZDlt6XkuJrlkIznm58oRUlBKeeahOagh+WHhuaKiuWNt+W4pumHjeaWsOWNt+e7leWcqOS4gOS4quWhkeaWmeW4puWNt+i9tOS4iuOAgiDlnKjlpKflpJrmlbDmg4XlhrXkuIvvvIzmiJHku6zlj6/kvp3lrqLmiLforqLljZXkuJPpl6jnu4Too4Xov5nnp43luKbljbfovbTvvIzlubblnKjlvZPml6Xlj5HotKfjgIIg5Zyo5peg5rOV5ruh6Laz5oKo55qE6K6i5Y2V6KaB5rGC55qE5oOF5Ya15LiL77yM5oiR5Lus5Lya5LiO5oKo6IGU57O744CCPC9wPjxwPuWvueavj+S4gOS4quW4puWNt+i9tOaIkeS7rOWwhuaUtuS4gOeslOOAjOWNt+e7lei0ueOAje+8jOW5tuaKiuWug+WMheaLrOWcqOaCqOeahOaAu+i0ueeUqOS4reOAgjwvcD48cD5EaWdpLVJlZWzCriDlvpfmjbflrprliLbljbfluKbmmK/kuIDnp43mjInnhaflrqLmiLfoh6rlrprnmoTljbfluKbvvIwg5LiN5Y+v5Y+W5raI77yM5LiN5Y+v6YCA6LSn44CCPC9wPg0KPC9kaXY+DQo8IS0tIEZvciBXZWJUcmVuZHMgVHJhY2tpbmcgcHVycG9zZSAtIHN0YXJ0IC0tPjxNRVRBIG5hbWU9IldULnpfcGFnZV90eXBlIiBjb250ZW50PSJQUyIgLz48TUVUQSBuYW1lPSJXVC56X3BhZ2Vfc3ViX3R5cGUiIGNvbnRlbnQ9IlBEIiAvPjwhLS0gRm9yIFdlYlRyZW5kcyBUcmFja2luZyBwdXJwb3NlIC0gZW5kIC0tPg0KDQo8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9tYWluLmpzIj48L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L1V0aWwuanMiPjwvc2NyaXB0Pg0KPHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iL3djc3N0b3JlL0NOL2phdmFzY3JpcHQvc2hvd3RoaWNrYm94LmpzIj48L3NjcmlwdD4gDQoNCjwhRE9DVFlQRSBodG1sIFBVQkxJQyAiLS8vVzNDLy9EVEQgWEhUTUwgMS4wIFRyYW5zaXRpb25hbC8vRU4iICJodHRwOi8vd3d3LnczLm9yZy9UUi94aHRtbDEvRFREL3hodG1sMS10cmFuc2l0aW9uYWwuZHRkIj4KCjwhLS0gU3RhcnQgLSBKU1BGIEZpbGUgTmFtZTogSlNUTEVudmlyb25tZW50U2V0dXAuanNwZiAtLT48IS0tIFdBU19OQU1FIENISU5BX1BST0RfU0VSVkVSMSAgLS0+CjwhLS0gRW5kIC0gSlNQRiBGaWxlIE5hbWU6IEpTVExFbnZpcm9ubWVudFNldHVwLmpzcGYgLS0+DQoNCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L1NlYXJjaEFyZWEvc2hvcnR1cmwuanMiPjwvc2NyaXB0Pg0KDQo8ZGl2IGlkPSJzaG9ydFVSTERpYWxvZyIgc3R5bGU9ImRpc3BsYXk6IG5vbmU7IiB0aXRsZT0i5b+r5o23IFVSTCI+DQoJ5aSN5Yi25Lul5LiL6ZO+5o6l5bm257KY6LS06Iez5oKo5biM5pyb55qE5Lu75L2V5L2N572u77yM5YiG5Lqr5b2T5YmN572R6aG144CCPGJyIC8+PGJyIC8+DQo8L2Rpdj4NCjxkaXYgaWQ9InNob3J0VVJMRXJyb3JEaWFsb2ciIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IuW/q+aNtyBVUkwiPg0KCeivpeWKn+iDveebruWJjeS4jeWPr+eUqO+8jOaIkeS7rOato+WKquWKm+S/ruWkjeOAguiwouiwouaCqOeahOiAkOW/g+etieW+heOAgiA8YnIgLz48YnIgLz4NCjwvZGl2Pg0KPGRpdiBhbGlnbj0icmlnaHQiPg0KCTxkaXYgaWQ9ImRrLXNoYXJlbGluayIgc3R5bGU9IndpZHRoOiAxNDBweDtjdXJzb3I6cG9pbnRlcjsiIG9uY2xpY2s9InNob3J0SW5pdCgnc2hvcnRVUkxEaWFsb2cnICwnc2hvcnRVUkxFcnJvckRpYWxvZycpIj4NCgnliIbkuqvmnKzpobXlhoXlrrkgDQoJPGEgaWQ9ImRrLXNoYXJlaW1hZ2VsaW5rIiBzdHlsZT0iY3Vyc29yOnBvaW50ZXI7Ij4NCgk8aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vaW1hZ2VzL2RpZ2lrZXkvbGluay5wbmciIHRpdGxlPSLnn63pk77mjqUiIGJvcmRlcj0iMCIgYWxpZ249InRvcCI+DQoJPC9hPg0KCTwvZGl2Pg0KCTxkaXYgaWQ9InNob3J0eS1oZWxwZXJzIiBzdHlsZT0iZGlzcGxheTogbm9uZTsiPg0KCTxpbnB1dCB0eXBlPSJoaWRkZW4iIGlkPSJpcFBIIiB2YWx1ZT0iMjIwLjEzMy4yNi43NCIvPg0KCTxpbnB1dCB0eXBlPSJoaWRkZW4iIGlkPSJtZXRob2RQSCIgdmFsdWU9IjAiLz4NCgk8aW5wdXQgdHlwZT0iaGlkZGVuIiBpZD0iYm9keVBIIiB2YWx1ZT0iIi8+DQoJPGlucHV0IHR5cGU9ImhpZGRlbiIgaWQ9InNob3J0VXJsVmFsdWUiLz4NCgk8L2Rpdj4NCg0KPC9kaXY+CQkJCQ0KCQ0KPHN0eWxlIHR5cGU9InRleHQvY3NzIj4NCgkjRmlsdGVyVGFibGV7DQoJICAgIHdpZHRoOjk5JTsNCgkgICAgaGVpZ2h0OjIxMHB4Ow0KCSAgICBvdmVyZmxvdy14OiBzY3JvbGw7DQoJICAgIG92ZXJmbG93LXk6IGhpZGRlbjsNCgkgICAgd2hpdGUtc3BhY2U6IG5vd3JhcDsNCgl9DQoNCjwvc3R5bGU+CQkJDQo8Zm9ybSBuYW1lPSJLZXl3b3JkU2VhcmNoIiBpZD0iS2V5d29yZFNlYXJjaCIgYWN0aW9uPSIvc2VhcmNoL3poIiBtZXRob2Q9J2dldCcgYXV0b2NvbXBsZXRlPSJvZmYiIGVuY3R5cGU9ImFwcGxpY2F0aW9uL3gtd3d3LWZvcm0tdXJsZW5jb2RlZCI+DQoNCjxiPuWFs+mUruWtlzo8L2I+Jm5ic3A7DQo8YSBocmVmPSJqYXZhc2NyaXB0OiBzaG93SGVscERpYWxvZygnI2tleXdvcmRTZWFyY2hIZWxwRGlhbG9nJywnYXV0bycsJzI1MHB4JyxmYWxzZSx0cnVlKSI+PGltZyBpZD0iU2VhcmNoSGVscEltYWdlIiBib3JkZXI9IjAiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vaW1hZ2VzL2hlbHAucG5nIj48L2E+DQoNCiZuYnNwOyZuYnNwOw0KDQoNCiANCg0KDQo8aW5wdXQgdHlwZT0ndGV4dCcgaWQ9J2tleXdvcmRzJyBuYW1lPSdrZXl3b3Jkcycgc2l6ZT0nMzUnIG1heGxlbmd0aD0nMjUwJyB2YWx1ZT0nJyBjbGFzcz0iYWNfaW5wdXQiIGF1dG9jb21wbGV0ZT0ib2ZmIi8+DQoNCjxpbnB1dCB0eXBlPSdoaWRkZW4nIGlkPSdpc1JtYlNlYXJjaCcgbmFtZT0naXNSbWJTZWFyY2gnIHZhbHVlPSd0cnVlJy8+DQombmJzcDsmbmJzcDsNCg0KPGlucHV0IHR5cGU9ImhpZGRlbiIgbmFtZT0icmVmUElkIiB2YWx1ZT0iMyIgLz4NCjxpbnB1dCB0eXBlPSdjaGVja2JveCcgaWQ9J3N0b2NrJyBuYW1lPSdzdG9jaycgdmFsdWU9JzEnIG9uY2hhbmdlPSdqYXZhc2NyaXB0OnVwZENvdW50QmFzZWRPbkZpbHRlcnMoKTsnLz48bGFiZWwgZm9yPSdzdG9jayc+546w6LSnPC9sYWJlbD4mbmJzcDsmbmJzcDs8aW5wdXQgdHlwZT0nY2hlY2tib3gnIGlkPSdwYmZyZWUnIG5hbWU9J3BiZnJlZScgdmFsdWU9JzEnIG9uY2hhbmdlPSdqYXZhc2NyaXB0OnVwZENvdW50QmFzZWRPbkZpbHRlcnMoKTsnLz48bGFiZWwgZm9yPSdwYmZyZWUnPuaXoOmThTwvbGFiZWw+Jm5ic3A7Jm5ic3A7PGlucHV0IHR5cGU9J2NoZWNrYm94JyBpZD0ncm9ocycgbmFtZT0ncm9ocycgdmFsdWU9JzEnIG9uY2hhbmdlPSdqYXZhc2NyaXB0OnVwZENvdW50QmFzZWRPbkZpbHRlcnMoKTsnLz48bGFiZWwgZm9yPSdyb2hzJz7nrKblkIjpmZDliLbmnInlrrPnianotKjmjIfku6QoUm9IUynop4TojIPopoHmsYI8L2xhYmVsPiZuYnNwOyZuYnNwOw0KPGJyLz4NCjxici8+DQo8aW5wdXQgdHlwZT1zdWJtaXQgdmFsdWU9J+mHjeaWsOaQnOe0oicgaWQ9InNlYXJjaEFnYWluU3VibWl0QnV0dG9uIi8+DQo8aHIgLz4NCjwvZm9ybT4NCg0KDQo8ZGl2IGlkPSJrZXl3b3JkU2VhcmNoSGVscERpYWxvZyIgIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IuWFs+mUruWtlyIgPg0KPHA+5YWz6ZSu5a2X5YyF5ousIOW+l+aNt+eUteWtkCDpm7bku7bnvJblj7fjgIHliLbpgKDllYbpm7bku7bnvJblj7fjgIHliLbpgKDllYblkI3np7DmiJbkuI7mgqjmkJzntKLnmoTkuqflk4HmnInlhbPnmoTku7vkvZXmj4/ov7DmgKfmlofmnKzjgILmgqjlj6/ku6Xkvb/nlKjmlbTkuKrljZXor43jgIHliY3nvIDjgIHlkI7nvIDmiJbnlJroh7PlrZDlrZfnrKbkuLLkvZzlhbPplK7lrZfjgII8L3A+PHA+6YCa5bi45L2/55So56m65qC85bCG5YWz6ZSu5a2X6ZqU5byA77yM5Zug5q2k5LiN6ZyA6KaB5byV5Y+344CC5Y+q5pyJ6KaB5Zyo5YWz6ZSu5a2X5Lit5bWM5YWl56m65qC85pe25omN6ZyA6KaB55So5byV5Y+35bCG5YWz6ZSu5a2X5ous6LW35p2l44CCPC9wPjxwPum7mOiupOaDheWGteS4i++8jOaQnOe0ouaTjeS9nOWPquS8mui/lOWbnuWMheWQq+aJgOacieWFs+mUruWtl+eahOiusOW9leOAguWIhumalOWFs+mUruWtl+eahOepuuagvOmakOWQq+WcsOi1t+WIsOmAu+i+kSBBTkQg6L+Q566X56ym55qE5L2c55So44CC5L2G5piv77yM5oKo5Lmf5Y+v5Zyo5oKo55qE5YWz6ZSu5a2X5YiX6KGo5Lit5piO5pi+5Zyw5L2/55So6YC76L6R6L+Q566X56ymICIuYW5kLiLjgIEiLm9yLiIg5ZKMICIubm90LiLjgILmiJbkuLrkuoboioLnnIHmjInplK7mrKHmlbDvvIzmgqjlj6/ku6XnlKggInwiIOabv+S7oyAiLm9yLiLvvIznlKggIn4iIOabv+S7oyAiLm5vdC4iPC9wPg0KPC9kaXY+PCEtLSBCcmVhZGNydW1iIC0tPg0KPGRpdiBzdHlsZT0ncGFkZGluZy1ib3R0b206IDIwcHg7IHBhZGRpbmctdG9wOiAyMHB4Oyc+DQoJDQoJDQoJPGgyIGNsYXNzID0gInNlb2h0YWciPiANCgkJPGEgaHJlZj0naHR0cDovL3d3dy5kaWdpa2V5LmNvbS5jbi9zZWFyY2gvemg/Y2F0YWxvZ0lkPSc+5Lqn5ZOB57Si5byVPC9hPiZuYnNwOyZndDsmbmJzcDsNCgkJPGEgaHJlZj0nL3NlYXJjaC96aC/nlLXpmLvlmagvNjgxJz4mIzMwMDA1OyYjMzg0NTk7JiMyMjEyMDs8L2E+Jm5ic3A7Jmd0OyZuYnNwOw0KCQk8YSBocmVmPScvc2VhcmNoL3poL+eUtemYu+WZqC/kuJPnlKjlnovnlLXpmLvlmagvNjg2Jz4mIzE5OTg3OyYjMjk5OTI7JiMyMjQxMTsmIzMwMDA1OyYjMzg0NTk7JiMyMjEyMDs8L2E+Jm5ic3A7Jmd0OyZuYnNwOzE2My43MDEwLjAxMDINCgk8L2gyPg0KPC9kaXY+DQoNCg0KPGRpdiBzdHlsZT0iZGlzcGxheTpub25lIj4NCjxoMj5MaXR0ZWxmdXNlIEluYy48L2gyPg0KPC9kaXY+DQo8ZGl2IGlkPSJlcnJvck1lc3NhZ2VCbG9jayIgc3R5bGU9J2NvbG9yOiByZWQ7Jz4NCjwhLS0gU3RhcnQgLSBKU1AgRmlsZSBOYW1lOiAgRXJyb3JNZXNzYWdlU2V0dXAuanNwZiAtLT48IS0tIEVuZCAtIEpTUCBGaWxlIE5hbWU6ICBFcnJvck1lc3NhZ2VTZXR1cC5qc3BmIC0tPg0KPC9kaXY+DQoNCjwhLS0gSGVyZSBpcyB3aGVyZSB0aGUgQ2hpcCBPdXRwb3N0IGltYWdlIC8gbGluayB3aWxsIGdvIGlmIG9uZSBpcyBuZWVkZWQgLS0+DQo8dGFibGUgY2xhc3M9InByb2R1Y3QtZGV0YWlscy10YWJsZSIgY2VsbHNwYWNpbmc9JzEnIGJvcmRlcj0nMCc+DQo8IS0tIENvZGUgY2hhbmdlIGZvciBQcm9kdWN0IEJhY2tsb2cgSXRlbSA1NDY2OTpWZW5kb3IgMTAzNCBObyBXYXJyYW50eSAtLT48IS0tIEFkZGVkIG5ldyBzdG9yZXRleHQgcHJvcGVydHkgRElPREVfSU5DX1dBUlJBTlRZX01TRyBpbiBzdG9yZXRleHRfemhfQ04ucHJvcGVydGllcyAtLT48IS0tIEVuZCBjaGFuZ2UgLS0+DQoJCTx0cj4NCgkJCTx0ZCBjbGFzcz0iYmVhYmxvY2stbm90aWNlIiBjb2xzcGFuPSIyIiB2YWxpZ249InRvcCI+DQoJCQkJPHA+ICA8c3BhbiAgc3R5bGU9ImZvbnQtd2VpZ2h0OiBib2xkOyI+DQoJCQkJCQ0KCQkJCQkJPHNwYW4gIHN0eWxlPSJmb250LXdlaWdodDogYm9sZDsiPg0KCQkJCQkJIOmdnuW6k+WtmOi0pyZuYnNwOyA8YSBocmVmPSJqYXZhc2NyaXB0OiBzaG93SGVscERpYWxvZygnI25vblN0b2NrSGVscERpYWxvZycsJ2F1dG8nLDMwMCxmYWxzZSx0cnVlKSI+PGltZyBpZD0iU2VhcmNoSGVscEltYWdlIiBib3JkZXI9IjAiIHNyYz0iLy93d3cuZGlnaWtleS5jb20uY24vd2Nzc3RvcmUvQ04vaW1hZ2VzL2hlbHAucG5nIj48L2E+DQoJCQkJCQk8L3NwYW4NCgkJCQkJCTxiciAvPjxiciAvPg0KCQkJCQkNCgkJCQkJCQkJPHNwYW4+5LiN5YaN55Sf5Lqn55qE54mI5pysIOivt+WPgumYheKAnOabv+S7o+WwgeijheKAneaIluKAnOabv+S7o+WTgeKAnemAiemhueOAgjwvc3Bhbj4NCgkJCQkJCQkJPGJyIC8+PGJyIC8+DQoJCQkJCQkJDQoJCQkJPC9wPg0KCQkJPC90ZD4NCgkJPC90cj4NCgkJDQoJPHRyPiAgDQoJCTx0ZCB2YWxpZ249J3RvcCc+DQoJCQk8dGFibGUgY2xhc3M9cHJvZHVjdC1kZXRhaWxzIGJvcmRlcj0nMScgY2VsbHNwYWNpbmc9JzEnIGNlbGxwYWRkaW5nPScyJyBpZD0icHJpY2luZ1RhYmxlIj4NCgkJCQk8dHIgY2xhc3M9InByb2R1Y3QtZGV0YWlscy10b3AiPjx0ZCBjbGFzcz0icHJpY2luZy1kZXNjcmlwdGlvbiIgY29sc3Bhbj0zIGFsaWduPXJpZ2h0Pg0KDQo8c2NyaXB0IHR5cGU9InRleHQvamF2YXNjcmlwdCIgc3JjPSIvd2Nzc3RvcmUvQ04vamF2YXNjcmlwdC9VdGlsLmpzIj48L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii93Y3NzdG9yZS9DTi9qYXZhc2NyaXB0L05ld0N1cnJlbmN5U2V0dGVyLmpzIj48L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij4NCm5ld0N1cnJlbmN5U2V0dGVyLnByZXZpb3VzQ3VycmVuY3kgPSAiQ05ZIjsNCm5ld0N1cnJlbmN5U2V0dGVyLmNvdW50cnkgPSAiIjsNCi8vYWxlcnQoIkN1cnJlbmN5U2V0dGVyLmNvdW50cnkgVksiK25ld0N1cnJlbmN5U2V0dGVyLmNvdW50cnkpOw0KPC9zY3JpcHQ+DQoNCuS6uuawkeW4geS7t+agvO+8iOWQq+WinuWAvOeoju+8iTwvdGQ+PC90cj4NCgkJCQk8dHI+IA0KCQkJCQk8dGggYWxpZ249J3JpZ2h0Jz7lvpfmjbfnlLXlrZAg6Zu25Lu257yW5Y+3PC90aD4NCgkJCQkJDQoJCQkJCTx0ZCBpZD0iUGFydE51bWJlciI+PG1ldGEgaXRlbXByb3A9InByb2R1Y3RJRCIgY29udGVudD0ic2t1OjE2My43MDEwLjAxMDItTkQiIC8+MTYzLjcwMTAuMDEwMi1ORDwvdGQ+DQoJCQkJCQ0KCQkJCQkJCQk8dGQgY2xhc3M9ImNhdGFsb2ctcHJpY2luZyIgcm93c3Bhbj0nNycgYWxpZ249J2NlbnRlcicgdmFsaWduPSd0b3AnPg0KCQkJCQkJCQ0KCQkJCQkJPHRhYmxlIGlkPSJwcmljaW5nIiBmcmFtZT0ndm9pZCcgcnVsZXM9J2FsbCcgYm9yZGVyPScxJyBjZWxsc3BhY2luZz0nMCcgY2VsbHBhZGRpbmc9JzEnPg0KCQkJCQkJCTx0cj4NCgkJCQkJCQkgICA8dGg+5Lu35qC85YiG5q61PC90aD4NCgkJCQkJCQkgICA8dGg+5Y2V5Lu3PC90aD4NCgkJCQkJCQkgICA8dGg+5oC75Lu3PC90aD4NCgkJCQkJCQkgICANCgkJCQkJCQk8L3RyPg0KDQoJCQkJCQkJDQoJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJPHRkIGFsaWduPSdjZW50ZXInPueUteivojwvdGQ+DQoJCQkJCQkJCQkJPHRkIGFsaWduPSdjZW50ZXInPueUteivojwvdGQ+DQoJCQkJCQkJCQkJPHRkIGFsaWduPSdjZW50ZXInPueUteivojwvdGQ+DQoJCQkJCQkJCQkJDQoJCQkJCQkJCQk8L3RyPg0KCQkJCQkJCQkNCgkJCQkJCTwvdGFibGU+DQoJCQkJCQkNCgkJCQkJPC90ZD4NCgkJCQk8L3RyPg0KDQoJCQkJDQoJCQkJPHRyPg0KCQkJCQk8dGggYWxpZ249cmlnaHQ+546w5pyJ5pWw6YePPC90aD4NCgkJCQkJPHRkIGFsaWduPWxlZnQgbm93cmFwPSJub3dyYXAiPg0KCQkJCQk8c3BhbiBpZD0iaGlkZGVuUXR5QXZhaWxhYmxlIiBzdHlsZT0iZGlzcGxheTpub25lOyI+MDwvc3Bhbj4NCgkJCQkJPCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFsLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL1RSL3hodG1sMS9EVEQveGh0bWwxLXRyYW5zaXRpb25hbC5kdGQiPgoKPCEtLSBTdGFydCAtIEpTUEYgRmlsZSBOYW1lOiBKU1RMRW52aXJvbm1lbnRTZXR1cC5qc3BmIC0tPjwhLS0gV0FTX05BTUUgQ0hJTkFfUFJPRF9TRVJWRVIxICAtLT4KPCEtLSBFbmQgLSBKU1BGIEZpbGUgTmFtZTogSlNUTEVudmlyb25tZW50U2V0dXAuanNwZiAtLT4NCg0KPHNjcmlwdD4NCmZ1bmN0aW9uIGdldExlYWRUaW1lTW9kYWwodXJsLCBkaWFsb2dEaXYsIGxlYWRUaW1lRXN0aW1hdGVUaXRsZSl7DQoJCXZhciBib3F1YW50eSA9ICQoIiNib1F0eSIpLnZhbCgpOw0KCQl2YXIgbmV3VXJsID0gdXJsLnJlcGxhY2UoLyZib1F0eT0vaSwgJyZib1F0eT0nK2JvcXVhbnR5KTsNCgkJDQoJCW5ld1VybCA9IG5ld1VybCArICImcGFydElkPSIrJzM0MjY2NTcnOw0KCQljb25zb2xlLmxvZyhuZXdVcmwpOw0KCQkkLmFqYXhTZXR1cCh7Y2FjaGU6IGZhbHNlfSk7DQoJCSQuZ2V0KG5ld1VybCwgZnVuY3Rpb24oZGF0YSkgew0KCQkkKCcjJytkaWFsb2dEaXYpLmh0bWwoZGF0YSk7DQoJCXZhciB0aXRsZVRleHQgPSBsZWFkVGltZUVzdGltYXRlVGl0bGU7DQoJCQkkKCcjJytkaWFsb2dEaXYpLmRpYWxvZyh7aGVpZ2h0OiAyMTAsIHdpZHRoOiA0MDAsIHRpdGxlOiB0aXRsZVRleHQsIG1vZGFsOiB0cnVlfSk7IA0KCX0pOw0KfQ0KZnVuY3Rpb24gb25LZXlQcmVzc0V2ZW50SGFuZGxlcihlLCB1cmwsIGRpYWxvZ0RpdiwgbGVhZFRpbWVFc3RpbWF0ZVRpdGxlKXsNCgl2YXIga2V5PWUua2V5Q29kZSB8fCBlLndoaWNoOw0KCWlmKGtleT09MTMpew0KCQlnZXRMZWFkVGltZU1vZGFsKHVybCwgZGlhbG9nRGl2LCBsZWFkVGltZUVzdGltYXRlVGl0bGUpOw0KCX0NCn0NCjwvc2NyaXB0Pg0KPGRpdiBpZD0ibGVhZFRpbWVEaWFsb2ciPiA8L2Rpdj4NCg0KCQkJIDANCgkJCSA8YnIvPg0KCQkJDQoJCQkJCTwvdGQ+DQoJCQkJPC90cj4NCgkJCQkNCgkJCQkNCgkJCQk8dHI+DQoJCQkJPHRoIGFsaWduPXJpZ2h0PuWItumAoOWVhjwvdGg+DQoJCQkJDQoJCQkJCQk8dGQ+PGgyIGNsYXNzPXNlb2h0YWcgaXRlbXByb3A9Im1hbnVmYWN0dXJlciI+PHNwYW4gaXRlbXNjb3BlIGl0ZW10eXBlPSJodHRwOi8vc2NoZW1hLm9yZy9Pcmdhbml6YXRpb24iPjxhICBpdGVtcHJvcD0idXJsIiBocmVmPScvemgvc3VwcGxpZXItY2VudGVycy9sL2xpdHRlbGZ1c2UnPjxzcGFuIGl0ZW1wcm9wPSJuYW1lIj5MaXR0ZWxmdXNlIEluYy48L3NwYW4+PC9zcGFuPjwvaDI+PC9hPjwvdGQ+PC90cj4NCgkJCQkJDQoJCQkJPHRyPjx0aCBhbGlnbj1yaWdodD7liLbpgKDllYbpm7bku7bnvJblj7c8L3RoPg0KCQkJCTx0ZD4NCgkJCQkJDQoJCQkJCQk8bWV0YSBpdGVtcHJvcD0ibmFtZSIgY29udGVudD0iMTYzLjcwMTAuMDEwMiIgLz48aDEgY2xhc3M9c2VvaHRhZyBpdGVtcHJvcD0ibW9kZWwiPg0KCQkJCQkJCTE2My43MDEwLjAxMDINCgkJCQkJPC9oMT4NCgkJCQk8L3RkPg0KCQkJCTwvdHI+DQoNCgkJCQkNCgkJCQk8dHI+PHRoIGFsaWduPXJpZ2h0PuaPj+i/sDwvdGg+PHRkIGl0ZW1wcm9wPSJkZXNjcmlwdGlvbiI+UkVTIEJMQURFIEFUTyAxMTAgT0hNIDElIDAuNFc8L3RkPjwvdHI+DQoJCQkJDQoJCQkJDQoJCQkJCTx0cj4NCgkJCQkJCTx0aCBhbGlnbj1yaWdodD4NCgkJCQkJCQnlr7nml6Dpk4XopoHmsYLnmoTovr7moIfmg4XlhrUv5a+56ZmQ5Yi25pyJ5a6z54mp6LSo5oyH5LukKFJvSFMp6KeE6IyD55qE6L6+5qCH5oOF5Ya1DQoJCQkJCQk8L3RoPg0KCQkJCQkJPHRkPg0KCQkJCQkJCeWQq+mThS/kuI3nrKblkIjpmZDliLbmnInlrrPnianotKjmjIfku6QoUm9IUynop4TojIPopoHmsYINCgkJCQkJCTwvdGQ+DQoJCQkJCTwvdHI+DQoJCQkJDQoJCQkJCTx0cj4NCgkJCQkJCTx0aCBhbGlnbj1yaWdodD7vu7/mub/msJTmlY/mhJ/mgKfnrYnnuqcg77yITVNM77yJPC90aD4NCgkJCQkJCTx0ZCBpdGVtcHJvcD0iTVNMIj4x77yI5peg6ZmQ77yJPC90ZD4NCgkJCQkJPC90cj4NCgkJCQkNCgkJCTwvdGFibGU+DQoJCQkNCgkJCQ0KDQoJCTwvdGQ+DQoJCTx0ZCBjbGFzcz0iaW1hZ2UtdGFibGUiIHZhbGlnbj0ndG9wJyBib3JkZXI9MT4NCgkJCTxkaXYgY2xhc3M9ImJlYWJsb2NrLWltYWdlIiBjb29raWUtdHJhY2tpbmc9InJlZl9wYWdlX2V2ZW50PUV4cGFuZCBJbWFnZTtyZWZfcGFnZV90eXBlPVBTO3JlZl9wYWdlX3N1Yl90eXBlPVBEO3JlZl9wYWdlX2lkPVBEO3JlZl9zdXBwbGllcl9pZD0xODtyZWZfcGFnZV9ldmVudD1BZGQlMjB0byUyMENhcnQ7cmVmX3BuX3NrdT0xNjMuNzAxMC4wMTAyLU5EO3JlZl9wYXJ0X2lkPTM0MjY2NTciPg0KCQkJCQ0KCQkJCQk8aW1nIGJvcmRlcj0wIHdpZHRoPTIwMCBzcmM9Ii93Y3NzdG9yZS9DTi9pbWFnZXMvcG5hLXpoLWNuLmpwZyIgdGl0bGU9JzE2My43MDEwLjAxMDIgTGl0dGVsZnVzZSBJbmMuIHwgMTYzLjcwMTAuMDEwMi1ORCB8IERpZ2ktS2V5IEVsZWN0cm9uaWNzJy8+DQoJCQkJDQoJCQk8L2Rpdj4NCgkJPC90ZD4NCgk8L3RyPg0KPC90YWJsZT4NCg0KDQo8dGFibGUgY2xhc3M9InByb2R1Y3QtYWRkaXRpb25hbC1pbmZvIiBpZD0iRGF0YXNoZWV0c1RhYmxlIj4NCjx0cj48dGQgdmFsaWduPSJ0b3AiIHN0eWxlPSJwYWRkaW5nLXRvcDo0cHg7IHdpZHRoOjI1JSI+DQoNCgkNCgk8Yj7kuIDoiKzkv6Hmga88L2I+DQoJPHRhYmxlIGJvcmRlcj0nMCcgaWQ9IkdlbmVyYWxJbmZvcm1hdGlvblRhYmxlIj4NCgkJPHRyPg0KCQkJPHRkIHZhbGlnbj0ndG9wJz4NCgkJCQk8dGFibGUgY2xhc3M9InByb2R1Y3QtZGV0YWlscyIgc3R5bGU9J3dpZHRoOiA1MDBweDsnaWQ9IkRhdGFzaGVldHNUYWJsZTEiPg0KCQkJCQkNCgkJCQkJCTx0cj4NCgkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+DQoJCQkJCQkJ5pWw5o2u5YiX6KGoPC90aD4NCgkJCQkJCQk8dGQ+IA0KCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJDQoJCQkJCQkJCQk8YSBjbGFzcz0ibG5rRGF0YXNoZWV0IiBocmVmPSdodHRwOi8vd3d3LmxpdHRlbGZ1c2UuY29tL34vbWVkaWEvYXV0b21vdGl2ZS9kYXRhc2hlZXRzL2Z1c2VzL2F1dG9tb3RpdmUtZnVzZXMvbGl0dGVsZnVzZV9hdG8lMjBibGFkZSUyMHR5cGUlMjByZXNpc3Rvcl9ma3MucGRmJyB0YXJnZXQ9J19ibGFuaycgdHJhY2stZGF0YT0icHJvZHVjdF9za3U9MTYzLjcwMTAuMDEwMi1ORDtwYXJ0X2lkPTM0MjY2NTc7cmVmX3N1cHBsaWVyX2lkPTE4O3JlZl9wYWdlX2V2ZW50PURpc3BsYXkgRGF0YXNoZWV0czthc3NldF90eXBlPURhdGFzaGVldHMiPjE2MyBTZXJpZXMsIEZLUyBSZXMgQVRPJiMxNzQ7IERhdGFzaGVldDs8L2E+PGJyLz4NCgkJCQkJCQkJDQoJCQkJCQkJPC90ZD4NCgkJCQkJCTwvdHI+DQoJCQkJCQ0KCQkJCQk8dHI+DQoJCQkJCQk8dGggYWxpZ249J3JpZ2h0JyB2YWxpZ249J3RvcCcgc3R5bGU9J3dpZHRoOiAyMDBweDsnPuagh+WHhuWMheijhSZuYnNwOyA8YSBocmVmPSJqYXZhc2NyaXB0OiBzaG93SGVscERpYWxvZygnI3N0YW5kYXJkUGFja2FnZUhlbHBEaWFsb2cnLCdhdXRvJywzMDAsZmFsc2UsdHJ1ZSkiPjxpbWcgaWQ9IlNlYXJjaEhlbHBJbWFnZSIgYm9yZGVyPSIwIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2ltYWdlcy9oZWxwLnBuZyIgdHJhY2stZGF0YT0icHJvZHVjdF9za3U9MTYzLjcwMTAuMDEwMi1ORDtwYXJ0X2lkPTM0MjY2NTc7cmVmX3N1cHBsaWVyX2lkPTE4O3JlZl9wYWdlX2V2ZW50PVN0YW5kYXJkIFBhY2thZ2luZyI+PC9hPjwvdGg+DQoJCQkJCQk8dGQ+MSwwMDA8L3RkPg0KCQkJCQk8L3RyPg0KCQkJCQkNCgkJCQkJDQoJCQkJCQk8dHI+DQoJCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7ljIXoo4UmbmJzcDsgPGEgaHJlZj0iamF2YXNjcmlwdDogc2hvd0hlbHBEaWFsb2coJyNzdGFuZGFyZFBhY2thZ2VIZWxwRGlhbG9nJywnYXV0bycsMzAwLGZhbHNlLHRydWUpIj48aW1nIGlkPSJTZWFyY2hIZWxwSW1hZ2UiIGJvcmRlcj0iMCIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS5jbi93Y3NzdG9yZS9DTi9pbWFnZXMvaGVscC5wbmciPjwvYT48L3RoPg0KCQkJCQkJCTx0ZD4NCgkJCQkJCQkJJiMyNTk1NTsmIzM1MDEzOw0KCQkJCQkJCQkNCgkJPGEgaHJlZj0iamF2YXNjcmlwdDogc2hvd0hlbHBNb2RlbERpYWxvZygnI0JVTEtfUGFja2FnaW5nSGVscERpYWxvZycsJyYjMjU5NTU7JiMzNTAxMzsnLCdhdXRvJywzMDAsZmFsc2UsdHJ1ZSkiPjxpbWcgYm9yZGVyPSIwIiBhbGlnbj0iY2VudGVyIiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLmNuL3djc3N0b3JlL0NOL2ltYWdlcy9oZWxwLnBuZyI+PC9hPg0KCQ0KCQkJCQkJCTwvdGQ+DQoJCQkJCQk8L3RyPg0KCQkJCQkNCgkNCgkJCQkJPHRyPg0KCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7nsbvliKs8L3RoPg0KCQkJCQkJPHRkPjxhIGhyZWY9Ii9zZWFyY2gvemgv55S16Zi75ZmoLzY4MSIgaWQ9ImNhdGVnb3J5TG5rIj4mIzMwMDA1OyYjMzg0NTk7JiMyMjEyMDs8L2E+PC90ZD4NCgkJCQkJPC90cj4NCgkJCQkJPHRyPg0KCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7kuqflk4Hml488L3RoPg0KCQkJCQkJPHRkPjxhIGhyZWY9Ii9zZWFyY2gvemgv55S16Zi75ZmoL+S4k+eUqOWei+eUtemYu+WZqC82ODYiIGlkPSJmYW1pbHlMbmsiPiYjMTk5ODc7JiMyOTk5MjsmIzIyNDExOyYjMzAwMDU7JiMzODQ1OTsmIzIyMTIwOzwvYT48L3RkPg0KCQkJCQk8L3RyPg0KCQkJCQkNCgkJCQkJPHRyPg0KCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz7ns7vliJc8L3RoPg0KCQkJCQk8dGQ+DQoJCQkJCSAJICAgDQoJCQkgCQkJCQk8YSBocmVmPSJodHRwOi8vd3d3LmRpZ2lrZXkuY29tLmNuL3NlYXJjaC96aD9zZXJpZXNpZD00Mjg4MDQyNDczJnB2PTY4MSU3QzQyODgwNDI0NzMiIGlkPSJzZXJpZXNMbmsiPkZLUyBBVE8mIzE3NDs8L2E+DQoJCQkgCQkJCSAgIA0KCQkJCQk8L3RkPiAgDQoJCQkJCTwvdHI+DQoJCQkJCQ0KDQoJCQkJPC90YWJsZT4NCgkJCTwvdGQ+DQoJCTwvdHI+DQoJPC90YWJsZT4NCgk8YnIvPg0KDQoJDQoJCQk8Yj7op4TmoLw8L2I+DQoJCQk8dGFibGUgYm9yZGVyPScwJyBpZD0iU3BlY2lmaWNhdGlvblRhYmxlIj4NCgkJCQk8dHI+DQoJCQkJCTx0ZCB2YWxpZ249J3RvcCc+DQoJCQkJCQk8dGFibGUgY2xhc3M9InByb2R1Y3QtZGV0YWlscyIgc3R5bGU9J3dpZHRoOiA1MDBweDsnIGlkPSJTcGVjaWZpY2F0aW9uVGFibGUxIj4NCgkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMzMTg2NzsmIzIyNDExOzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPiYjMjA5OTI7JiMyOTI1NTsmIzY1MjkyO0FUTzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyNDIxMjsmIzI5OTkyOzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPiYjMjc3NzM7JiMzNjcxMDsmIzMyNDIzOzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyNTEwNDsmIzIwOTk4OzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPiYjMzczMjk7JiMyMzY0NjsmIzIwODAzOyYjMzIwMzI7PC90ZD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJPC90cj4NCgkJCQkJCQkJCQ0KCQkJCQkJCQkJCTx0cj4NCgkJCQkJCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz4mIzMwMDA1OyYjMzg0NTk7JiM2NTI4ODsmIzI3NDMxOyYjMjI5ODI7JiM2NTI4OTs8L3RoPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQkJCTx0ZD4xMTA8L3RkPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQk8L3RyPg0KCQkJCQkJCQkJDQoJCQkJCQkJCQkJPHRyPg0KCQkJCQkJCQkJCQk8dGggYWxpZ249J3JpZ2h0JyB2YWxpZ249J3RvcCcgc3R5bGU9J3dpZHRoOiAyMDBweDsnPiYjMjM0ODE7JiMyNDA0Njs8L3RoPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQkJCTx0ZD4mIzE3NzsxJTwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyMTE1MTsmIzI5NTc1OyYjNjUyODg7VyYjNjUyODk7PC90aD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJCQk8dGQ+MC40VzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCQkJCQk8dHI+DQoJCQkJCQkJCQkJCTx0aCBhbGlnbj0ncmlnaHQnIHZhbGlnbj0ndG9wJyBzdHlsZT0nd2lkdGg6IDIwMHB4Oyc+JiMyODIwMTsmIzI0MjMwOyYjMzE5OTU7JiMyNTk2ODs8L3RoPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQkJCTx0ZD4tPC90ZD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJPC90cj4NCgkJCQkJCQkJCQ0KCQkJCQkJCQkJCTx0cj4NCgkJCQkJCQkJCQkJPHRoIGFsaWduPSdyaWdodCcgdmFsaWduPSd0b3AnIHN0eWxlPSd3aWR0aDogMjAwcHg7Jz4mIzI0MDM3OyYjMjAzMTY7JiMyODIwMTsmIzI0MjMwOzwvdGg+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCQkJPHRkPi08L3RkPg0KCQkJCQkJCQkJCQkNCgkJCQkJCQkJCQk8L3RyPg0KCQkJCQkJCQkJDQoJCQkJCQkJCQkJPHRyPg0KCQkJCQkJCQkJCQk8dGggYWxpZ249J3JpZ2h0JyB2YWxpZ249J3RvcCcgc3R5bGU9J3dpZHRoOiAyMDBweDsnPiYjMjM0MzM7JiMzNTAxMzsmIzMxODY3OyYjMjI0MTE7PC90aD4NCgkJCQkJCQkJCQkJDQoJCQkJCQkJCQkJCQk8dGQ+JiMyNTkwMzsmIzI0MjMxOzwvdGQ+DQoJCQkJCQkJCQkJCQ0KCQkJCQkJCQkJCTwvdHI+DQoJCQkJCQkJCQkNCgkJCQkJCTwvdGFibGU+DQoJCQkJCTwvdGQ+DQoJCQkJPC90cj4NCgkJCTwvdGFibGU+DQoJCQk8YnIvPg0KCQkNCg0KPC90ZD4NCjx0ZCB2YWxpZ249InRvcCIgc3R5bGU9J3BhZGRpbmctdG9wOiAyMHB4OyB3aWR0aDo2MCUnPgkNCgk8IS0tIFN0YXJ0IC0gSlNQIEZpbGUgTmFtZTogIEFsdGVybmF0aXZlUGFja2FnaW5nLmpzcGYgLS0+PCEtLSBFbmQgLSBKU1AgRmlsZSBOYW1lOiAgQWx0ZXJuYXRpdmVQYWNrYWdpbmcuanNwZiAtLT4gDQo8L3RkPg0KPHRkPjwvdGQ+DQo8L3RyPg0KPHRyPg0KCTx0ZCBhbGlnbj0icmlnaHQiPg0KCQkNCgkJPGlucHV0IGlkPSJidG5SZXBvcnRFcnJvciIgdHlwZT0iYnV0dG9uIiBuYW1lPSJyZXBvcnRFcnJvciIgDQoJCQkJdmFsdWU9J+aKpeWRiuS4gOS4qumUmeivrycgDQoJCQkJdGl0bGU9J+aKpeWRiuS4gOS4qumUmeivrycNCgkJCQlvbmNsaWNrPSJqYXZhc2NyaXB0OndpbmRvdy5vcGVuKCcvb3JkZXJpbmcvUmVwb3J0RXJyb3JGZWVkYmFja1ZpZXc/bGFuZ0lkPS03JnBhcnROdW1iZXI9MTYzLjcwMTAuMDEwMi1ORCZtYW51ZmFjdHVyZXJOYW1lPUxpdHRlbGZ1c2UrSW5jLiZzdG9yZUlkPTEwMDAxJywgJ19ibGFuaycpOyIvPg0KCQkNCgk8L3RkPg0KCTx0ZD48IS0tIExlYXZlIGVtcHR5IC0tPjwvdGQ+DQoJPHRkPjwhLS0gTGVhdmUgZW1wdHkgLS0+PC90ZD4NCjwvdHI+DQo8L3RhYmxlPg0KDQo8ZGl2IHN0eWxlPSdjbGVhcjogYm90aDsnPg0KCTxwPg0KCQkyMDE3LTAxLTA1IDE0OjMxOjMwICjljJfkuqzml7bpl7QpIA0KCTwvcD4NCjwvZGl2Pg0KPGRpdiBpZD0iZmF2b3JpdGVBZGRNb2RlbFdpbmRvdyIgc3R5bGU9ImRpc3BsYXk6IG5vbmU7IiB0aXRsZT0i5pS26JeP5aS5Ij4NCjx0YWJsZSBpZD0iZmF2b3JpdGVQYXJ0QWRkZWQiIGNlbGxzcGFjaW5nPSIwIiBjZWxscGFkZGluZz0iMCIgYm9yZGVyPSIwIiBzdHlsZT0id2lkdGg6MTAwJTsiPg0KCTx0cj4NCgk8dGQ+Jm5ic3A7PC90ZD4NCgk8L3RyPg0KCTx0cj4NCgk8dGQ+PGI+6K+l5Lqn5ZOB5bey5oiQ5Yqf5Yqg5YWl5pS26JeP5aS5PC9iPjwvdGQ+DQoJPC90cj4NCgk8dHI+DQoJPHRkPiZuYnNwOzwvdGQ+DQoJPC90cj4NCgk8dHI+IA0KCSA8dGQ+MTYzLjcwMTAuMDEwMjwvdGQ+DQoJPC90cj4NCgk8dHI+IA0KCSA8dGQ+UkVTIEJMQURFIEFUTyAxMTAgT0hNIDElIDAuNFc8L3RkPg0KCTwvdHI+DQoJPHRyPiANCgkgPHRkPkxpdHRlbGZ1c2UgSW5jLjwvdGQ+DQoJPC90cj4JDQo8L3RhYmxlPg0KPC9kaXY+DQo8ZGl2IGlkPSJmYXZvcml0ZUFkZEVycm9yTW9kZWxXaW5kb3ciIHN0eWxlPSJkaXNwbGF5OiBub25lOyIgdGl0bGU9IumUmeivryI+DQo8L2Rpdj4NCjxkaXYgaWQ9ImxvZ2luRGlhbG9nIiBzdHlsZT0iZGlzcGxheTpub25lOyIgdGl0bGU9IuaUtuiXj+WkuSI+DQoJPHA+5Y+q6YCC55So5LqO5rOo5YaM55So5oi344CC6K+3PGEgaWQ9Im90aGVyU3JjTG9naW4iIGhyZWY9Imh0dHBzOi8vd3d3LmRpZ2lrZXkuY29tLmNuL215ZGlnaWtleS9Mb2dvbkZvcm0/ZnJvbVBhZ2U9cGFydERldGFpbCZVUkw9JTJGc2VhcmNoJTJGemglMkYxNjMtNzAxMC0wMTAyJTJGMTYzLTcwMTAtMDEwMi1ORCUzRnJlY29yZElkJTNEMzQyNjY1NyI+55m75b2VPC9hPuaIljxhIGhyZWY9Imh0dHBzOi8vd3d3LmRpZ2lrZXkuY29tLmNuL215ZGlnaWtleS9Vc2VyUmVnaXN0cmF0aW9uQWRkRm9ybVZpZXciPuazqOWGjDwvYT7jgII8L3A+DQo8L2Rpdj4NCg0KPCEtLSBJbmNsdWRlIEZvb3RlciAtLT48IS0tIERvdWJsZUNsaWNrIFRhZ2dpbmcgLS0+PCEtLSBCRUdJTiBGb290ZXIuanNwIC0tPjwvZGl2PjwhLS0gRU5ESU5HIERJViBDb250ZW50IC0tPjwhLS1TVEFSVCBPRiBTaXRlQ29yZUZvb3Rlci5qc3AgLS0+DQoNCg0KPGxpbmsgcmVsPSJzdHlsZXNoZWV0IiB0eXBlPSJ0ZXh0L2NzcyIgaHJlZj0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9Gb290ZXIvTWVya2xlL0NTUy9mb290ZXIuY3NzP2xhPXpoLUNOLVJNQiZhbXA7dHM9YjRkZWI1OTctYmQxYi00M2VhLWJjYzktMGVlZjk2ZDVkYWU3IiAvPg0KPGRpdiBpZD0iZm9vdGVyIj4gIAogICAgPHRhYmxlIGNsYXNzPSJmb290ZXItY29udGFpbmVyIj4KICAgICAgPHRyPgogICAgICAgIDx0ZD4KICAgICAgICAgICAgPGRpdiBjbGFzcz0iZm9vdGVyLWluZm9ybWF0aW9uIj4KICAgICAgICAgICAgICAgIDxwIGNsYXNzPSJmb290ZXItYm9sZCI+5L+h5oGvPC9wPgogICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC90ZXJtcy1hbmQtY29uZGl0aW9ucyI+5p2h5qy+5ZKM5p2h5Lu2PC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvYWJvdXQtZGlnaWtleSI+5YWz5LqO5b6X5o2355S15a2QPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9oZWxwL2NvbnRhY3QtdXMiPuiBlOezu+aIkeS7rDwvYT48L3A+PHAgY2xhc3M9ImZvb3Rlci1saW5rIj48YSBocmVmPSIvemgvbmV3cyI+5paw6Ze757yW6L6R5a6kPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9oZWxwL3NpdGUtbWFwIj7nq5nngrnlnLDlm748L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL2hlbHAvYnJvd3Nlci1zdXBwb3J0Ij7mlK/mjIHnmoTmtY/op4jlmag8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL2hlbHAvUHJpdmFjeSI+6ZqQ56eB5aOw5piOPC9hPjwvcD48L2Rpdj4KICAgICAgICAgICAgPGRpdiBjbGFzcz0iZm9vdGVyLWNvdW50cnkiIHN0eWxlPSJiYWNrZ3JvdW5kLWltYWdlOiB1cmwoLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvRm9vdGVyL0NvdW50cmllcy9jbi5wbmc/bGE9emgtQ04tUk1CJmFtcDt0cz1mMWEyZWJhZS0yNTc4LTRmODUtYjMwNS04MzQ5MmM1ZWQxNGQpOyI+CiAgICAgICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWJvbGQiPuS4reWbvTwvcD4KICAgICAgICAgICAgICAgIDxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0ibWFpbHRvOnNlcnZpY2Uuc2hAZGlnaWtleS5jb20gIj5zZXJ2aWNlLnNoQGRpZ2lrZXkuY29tIDwvYT48L3A+CiAgICAgICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWJvbGQiPueUteivnTogNDAwIDkyMCAxMTk5PGJyIC8+5Lyg55yfOiAoMDIxKSA1MjQyOTI2OTxiciAvPjxiciAvPuayqklDUOWkhzE0MDI0NTE05Y+3LTMgPC9wPgogICAgICAgICAgICAgICAgPHAgY2xhc3M9ImZvb3Rlci1saW5rIGxpdmUtY2hhdCBjaGF0bGluayI+CiAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgPGEgaHJlZj0iamF2YXNjcmlwdDo7Ij48aW1nIGNsYXNzPSJmb290ZXItaWNvbiIgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9IZWFkZXIvY2hhdC13aGl0ZS5wbmc/bGE9emgtQ04tUk1CJnRzPWYyMjlmMTA0LThkNzgtNDc5MC1iMmI4LTI2ZGMzNmQ5OTQ5MiIgLz4gUVHlnKjnur/lkqjor6I8L2E+CiAgICAgICAgICAgICAgICA8L3A+CiAgICAgICAgICAgIDxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9IiI+PC9zY3JpcHQ+PC9kaXY+CiAgICAgICAgICAgIDxkaXYgY2xhc3M9ImZvb3Rlci1pbnRlcm5hdGlvbmFsIj4KICAgICAgICAgICAgICAgIDxwIGNsYXNzPSJmb290ZXItYm9sZCI+546v55CD5Lia5YqhPC9wPgogICAgICAgICAgICA8cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbD9yZWdpb249YWZyaWNhIj7pnZ7mtLI8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsP3JlZ2lvbj1hc2lhIj7kuprmtLI8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsP3JlZ2lvbj1hdXN0cmFsaWEiPua+s+Wkp+WIqeS6mjwvYT48L3A+PHAgY2xhc3M9ImZvb3Rlci1saW5rIj48YSBocmVmPSIvemgvcmVzb3VyY2VzL2ludGVybmF0aW9uYWw/cmVnaW9uPWV1cm9wZSI+5qyn5rSyPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbD9yZWdpb249bWlkZGxlZWFzdCI+5Lit5LicPC9hPjwvcD48cCBjbGFzcz0iZm9vdGVyLWxpbmsiPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvaW50ZXJuYXRpb25hbD9yZWdpb249bm9ydGhhbWVyaWNhIj7ljJfnvo7mtLI8L2E+PC9wPjxwIGNsYXNzPSJmb290ZXItbGluayI+PGEgaHJlZj0iL3poL3Jlc291cmNlcy9pbnRlcm5hdGlvbmFsP3JlZ2lvbj1zb3V0aGFtZXJpY2EiPuWNl+e+jua0sjwvYT48L3A+PC9kaXY+CiAgICAgICAgPC90ZD4KICAgICAgICA8dGQ+CiAgICAgICAgICAgIDxkaXYgY2xhc3M9ImZvb3Rlci1jb3B5cmlnaHQiPgogICAgICAgICAgICAgICAgPGRpdiBjbGFzcz0ic29jaWFsLWljb25zIj48YSBocmVmPSIvemgvcmVzb3VyY2VzL21vYmlsZS1hcHBsaWNhdGlvbnMiPjxpbWcgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9HbG9iYWwvSWNvbnMvbW9iaWxlYXBwXzMyLnBuZz9oPTMyJmxhPXpoLUNOLVJNQiZ3PTMyJnRzPWQyOTZhZTQwLTg2MDgtNDFiYy04MGQ5LTEyM2RiYjhjMTEzYiIgYWx0PSJEaWdpLUtleSBNb2JpbGUgQXBwcyIgLz48L2E+PGEgaHJlZj0iaHR0cDovL2kueW91a3UuY29tL2RpZ2lrZXkiIHRhcmdldD0iX2JsYW5rIj48aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvR2xvYmFsL0ljb25zL3lvdWt1XzMyLnBuZz9oPTMyJmxhPXpoLUNOLVJNQiZ3PTMyJnRzPThlNTU2NjU3LTgwNGItNGNkMS1hNGM1LWI0MGZiNWFlZjc2MSIgYWx0PSJ5b3VrdSIgLz48L2E+PGEgaHJlZj0iaHR0cDovL3d3dy53ZWliby5jb20vZGlnaWtleWVsZWN0cm9uaWNzIiB0YXJnZXQ9Il9ibGFuayI+PGltZyBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0dsb2JhbC9JY29ucy9XZWlib18zMi5wbmc/aD0zMiZsYT16aC1DTi1STUImdz0zMiZ0cz04ZDlkZTU4NS0yMjgxLTQwMzYtOTE3NS00M2I5YWM2MTMwNWIiIGFsdD0id2VpYm8iIC8+PC9hPjxhIGhyZWY9Ii96aC9yZXNvdXJjZXMvd2VjaGF0Ij48aW1nIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9JbWFnZXMvR2xvYmFsL0ljb25zL1dlY2hhdF8zMi5wbmc/aD0zMiZsYT16aC1DTi1STUImdz0zMiZ0cz04OGVjOWMyNy03Mzc5LTRhNTktYjFiNi1kNzBkMzBmNWEwMTciIGFsdD0iV2VjaGF0IiAvPjwvYT48YSBocmVmPSJodHRwczovL3d3dy5saW5rZWRpbi5jb20vY29tcGFueS9kaWdpLWtleS1jb3Jwb3JhdGlvbiIgdGFyZ2V0PSJfc2NOZXdUYWIiPjxpbWcgc3JjPSIvL3d3dy5kaWdpa2V5LmNvbS8tL21lZGlhL0ltYWdlcy9HbG9iYWwvSWNvbnMvbGlua2VkaW5fMzIucG5nP2g9MzImbGE9emgtQ04tUk1CJnc9MzImdHM9MGRkOTg5MzAtY2Q2Mi00ZGExLWE5N2UtZDA4MDBmZGMxOTlkIiBhbHQ9IkxpbmtlZEluIiAvPjwvYT48L2Rpdj4KICAgICAgICAgICAgICAgIDxwPkNvcHlyaWdodCAmY29weTsgMTk5NS0yMDE3PGJyIC8+5b6X5o2355S15a2Q77yI5LiK5rW377yJ5pyJ6ZmQ5YWs5Y+444CC5L+d55WZ5YWo6YOo54mI5p2D44CCPGJyIC8+5LiK5rW35a6i5pyN5Lit5b+D77yaIOS4iua1t+S4reWxseilv+i3rzEwNTXlj7c8YnIgLz5TT0hP5Lit5bGx5bm/5Zy6QeW6pzUwNOWupCDpgq7nvJYgMjAwMDUxPC9wPgogICAgICAgICAgICAgICAgPGEgaHJlZj0iL3poL2hlbHAvYXV0aG9yaXplZC1kaXN0cmlidXRvciI+PGltZyBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvSW1hZ2VzL0hvbWVwYWdlL2hvbWVwYWdlLWFzc29jaWF0aW9ucy5wbmc/aD00NiZsYT16aC1DTi1STUImdz0yMjUmdHM9NjAwNmZiZWItZTY4Ny00MWE4LWIzNGYtYmNkYzgzMDY4NDJjIiBhbHQ9IkVDSUEvQ0VEQS9FQ1NOIE1lbWJlciIgLz48L2E+CiAgICAgICAgICAgIDwvZGl2PgogICAgICAgIDwvdGQ+CiAgICAgIDwvdHI+CiAgICA8L3RhYmxlPgo8L2Rpdj4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij4oZnVuY3Rpb24oYSxiLGMsZCl7YT0nLy90YWdzLnRpcWNkbi5jb20vdXRhZy9kaWdpa2V5L21haW4vcHJvZC91dGFnLmpzJztiPWRvY3VtZW50O2M9J3NjcmlwdCc7ZD1iLmNyZWF0ZUVsZW1lbnQoYyk7ZC5zcmM9YTtkLnR5cGU9J3RleHQvamF2YScrYztkLmFzeW5jPXRydWU7YT1iLmdldEVsZW1lbnRzQnlUYWdOYW1lKGMpWzBdO2EucGFyZW50Tm9kZS5pbnNlcnRCZWZvcmUoZCxhKTt9KSgpOzwvc2NyaXB0PjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0IiBzcmM9Ii8vd3d3LmRpZ2lrZXkuY29tLy0vbWVkaWEvRGVzaWduZXIvRm9vdGVyL1JNQi9KUy9mb290ZXJxcWNoYXQuanM/bGE9emgtQ04tUk1CJmFtcDt0cz1mZmQ3YjgxYS1lNTQ4LTRkZTQtYTA0YS0wMTg5ZGVjZTkwNDAiPjwvc2NyaXB0PjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij5pZiAodHlwZW9mIHV0YWdfZGF0YSA9PT0gJ3VuZGVmaW5lZCcpIHsgdXRhZ19kYXRhID0geyB3dF91c2VfdWRvIDogImZhbHNlIiB9OyB9PC9zY3JpcHQ+PHNjcmlwdCB0eXBlPSJ0ZXh0L2phdmFzY3JpcHQiIHNyYz0iLy93d3cuZGlnaWtleS5jb20vLS9tZWRpYS9EZXNpZ25lci9XZWIgQW5hbHl0aWNzL0Nvb2tpZSBUcmFja2luZy9KUy9kaWdpa2V5LXdlYnRyZW5kcy5qcz90cz00NWFlZTk3ZC1hMmJhLTQxY2MtOTI2OS00YTY1Y2JjYTkyN2EiPjwvc2NyaXB0Pg0KDQo8IS0tIEVORCBGb290ZXIuanNwZiAtLT4NCg0KPHNjcmlwdCB0eXBlPSd0ZXh0L2phdmFzY3JpcHQnPg0KDQogICAgaWYgKGxvY2F0aW9uLmhhc2gubGVuZ3RoID4gMCkgew0KICAgIAl2YXIgX3BhcnROdW1iZXIgPSBsb2NhdGlvbi5oYXNoOw0KICAgIAlpZiAobmF2aWdhdG9yLmFwcE5hbWUgPT0gIk1pY3Jvc29mdCBJbnRlcm5ldCBFeHBsb3JlciIpIHsNCgkgICAgCWlmIChfcGFydE51bWJlci5jaGFyQXQoMCkgPT0gJyMnKSB7DQoJICAgIAkJX3BhcnROdW1iZXIgPSBfcGFydE51bWJlci5zbGljZSgxKTsNCgkgICAgCX0NCiAgICAJfQ0KICAgIAlkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnaXRlbW51bWJlcnNlbGVjdCcpLnZhbHVlID0gX3BhcnROdW1iZXI7DQogICAgfSANCiAgICAgIA0KJChkb2N1bWVudCkucmVhZHkoZnVuY3Rpb24gKCkgew0KICAgIGluaXREaWFsb2coJyNmYXZvcml0ZUFkZE1vZGVsV2luZG93JywgNTAwKTsNCiAgICBpbml0RGlhbG9nKCcjZmF2b3JpdGVBZGRFcnJvck1vZGVsV2luZG93JywgNTAwKTsNCn0pOw0KDQo8L3NjcmlwdD4NCjxzY3JpcHQgdHlwZT0idGV4dC9qYXZhc2NyaXB0Ij4NCgkJdmFyIHV0YWdfZGF0YSA9IHsNCgkJCXBhZ2VfdGl0bGU6ICdQYXJ0IERldGFpbCcsDQoJCSAgICBwYWdlX3R5cGU6ICJQUyIsDQoJCSAgICBwYWdlX3N1Yl90eXBlOiAnUEQnLA0KCQkgICAgcGFnZV9pZDogIlBEIiwNCgkJICAgIHBhcnRfaWQ6ICIzNDI2NjU3IiwNCgkJICAgIHBhcnRfc2VhcmNoX3Rlcm06ICIiLA0KCQkgICAgcGFydF9hdmFpbGFibGU6ICIwIiwNCgkJCXBhZ2VfbGFuZ3VhZ2U6ICJ6aCIsDQoJCQlwbl9za3U6ICIxNjMuNzAxMC4wMTAyLU5EIiwNCgkJCXd0X3VzZV91ZG86ICJ0cnVlIiwNCgkJCXBhZ2VfY29udGVudF9ncm91cDogIlBhcnQgU2VhcmNoIiwNCgkJCXBhcnRfc2VhcmNoX3Jlc3VsdHNfY291bnQ6ICIxIiwNCgkJCXRyYW5zYWN0aW9uX3R5cGU6ICJ2IiwNCgkJCXRyYW5zYWN0aW9uX3F1YW50aXR5OiAiMSIsDQoJCQlzdXBwbGllcl9pZDogIjE4IiwNCgkJCXZpZGVvX3NvdXJjZTogJ1BhcnQgRGV0YWlsJywNCgkJICAgIHBhZ2VfY29udGVudF9zdWJfZ3JvdXA6ICdQYXJ0IERldGFpbCcNCgkJfQ0KPC9zY3JpcHQ+DQo8L2JvZHk+DQo8L2h0bWw+DQo="
                        
                        
                        let fakedic = ["html":fakehtml, "ip":"220.133.26.74", "productId":"63.7010.0102", "url":"http://www.digikey.com.cn/search/zh/163-7010-0102/163-7010-0102-ND?recordId=3426657", "uuid": "6272C217-03F8-43E4-8962-F82D0FD47536"]
                        
                        
                        print("\(dic)")
                        
                        
                        
                        
                        do {
                            //let jsonData = try JSONSerialization.data(withJSONObject: fakedic, options: .prettyPrinted)
                            
                            let jsonData = try JSONSerialization.data(withJSONObject: fakedic, options: JSONSerialization.WritingOptions.prettyPrinted)
                            
                            let escapedStr = String(format: "%@parsers", arguments: [API_Manager.shared.PARSER_API_PATH]).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                            
                            
                            print("\(escapedStr)")
                            let url2 = URL(string:escapedStr)!
                            var request2 = URLRequest(url: url2)
                            request2.httpMethod = "POST"
                            request2.httpBody = jsonData

                            let session2 = URLSession.shared
                            let task2 = session2.dataTask(with: request2 as URLRequest) { data, response, error in
                            
                                
                                if error != nil{
                                    print("\(error?.localizedDescription)")
                                    return
                                } else {
                                
                                
                                }
//                                if let responseJSON = JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:Any]{
//                                    //NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String:AnyObject]{
//                                    print(responseJSON)
//                                }
                                
                                
                            }
                            
                            task2.resume()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
            
                }
    

}
        }
        task1.resume()
    }

}


