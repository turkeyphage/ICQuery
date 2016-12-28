//
//  DetailViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/8.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

//  


import UIKit
import SafariServices


class DetailViewController: UIViewController {

    @IBOutlet weak var datasheetButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var company_label: UILabel!
    
    @IBOutlet weak var model_label: UILabel!
    
    @IBOutlet weak var detail_label: UILabel!
    
    @IBOutlet weak var product_imageview: UIImageView!
    
    @IBOutlet weak var backgroundView4Segment: UIView!
    
    @IBOutlet weak var theScrollView: UIScrollView!
    
    
    @IBOutlet weak var firstTableView: UITableView!
    
    @IBOutlet weak var secondTableView: UITableView!
    
    var selectedProduct : ProductDetail!
    var datasheetURLStr : String!
    
    
    
    let mySegmentedControl = UnderlinedSegmentedControl()
    
    var downloadTask: URLSessionDownloadTask?
    
    var offset: CGFloat = 0.0 {
        // offset的值時，執行didSet
        didSet {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.theScrollView.contentOffset = CGPoint(x: self.offset, y: 0.0)
            })
        }
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        //set notification observer
        let nc = NotificationCenter.default
        nc.addObserver(forName: NSNotification.Name.init(rawValue: "SegmentWasSelected"), object: nil, queue: nil, using: catchingNotification)
        
        
        
        let placeholderStr = NSAttributedString(string: "請輸入查詢資料", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
        searchTextField.attributedPlaceholder = placeholderStr
    
        
        //datasheet button outline
        datasheetButton.backgroundColor = .clear
        
        datasheetButton.layer.cornerRadius = 5
        
        datasheetButton.layer.borderWidth = 1
        
        datasheetButton.layer.borderColor = UIColor.lightGray.cgColor
        
        check_datasheet_available()
        
        
        //顯示內容
        product_imageview.image = UIImage(named: "logo_120_120")
        
        if let smallURL = URL(string: selectedProduct.picurl) {
            downloadTask = product_imageview.loadImage(url: smallURL)
        }
        
        
        company_label.text = selectedProduct.mfs
        model_label.text =  selectedProduct.pn
        detail_label.text = selectedProduct.desc
        

       
        
        //add custom segment control item
        
        backgroundView4Segment.addSubview(mySegmentedControl)
        
        
        
        let horizonalContraints = NSLayoutConstraint(item: mySegmentedControl, attribute:
            .leadingMargin, relatedBy: .equal, toItem: backgroundView4Segment,
                            attribute: .leading, multiplier: 1.0,
                            constant: 0)
        
        let verticalContraints = NSLayoutConstraint(item: mySegmentedControl, attribute:.trailingMargin, relatedBy: .equal, toItem: backgroundView4Segment,
                             attribute: .trailing, multiplier: 1.0, constant: 0)
        
        
        let pinTop = NSLayoutConstraint(item: mySegmentedControl, attribute: .top, relatedBy: .equal, toItem: backgroundView4Segment, attribute: .top, multiplier: 1.0, constant: 0)
        
        let pinBottom = NSLayoutConstraint(item: mySegmentedControl, attribute: .bottom, relatedBy: .equal, toItem: backgroundView4Segment, attribute: .bottom, multiplier: 1.0, constant: 0)
        
        
        mySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([horizonalContraints, verticalContraints,pinTop,pinBottom])
        
        
        firstTableView.delegate = self
        secondTableView.delegate = self
        firstTableView.dataSource = self
        secondTableView.dataSource = self
        
        
        //為scrollview加上手勢辨識
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(DetailViewController.swipe(_:)))
        swipeLeft.direction = .left
        swipeLeft.numberOfTouchesRequired = 1
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(DetailViewController.swipe(_:)))
        swipeRight.direction = .right
        swipeRight.numberOfTouchesRequired = 1
        
        theScrollView.addGestureRecognizer(swipeLeft)
        theScrollView.addGestureRecognizer(swipeRight)
        
        
        // cell
        let manucellNib = UINib(nibName: CellID.manufacturer_cell, bundle: nil)
        
        firstTableView.register(manucellNib, forCellReuseIdentifier: CellID.manufacturer_cell)

        
        let speccellNib = UINib(nibName: CellID.spec_cell, bundle: nil)
        
        secondTableView.register(speccellNib, forCellReuseIdentifier: CellID.spec_cell)
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    

    override func viewDidLayoutSubviews() {
        view.layoutIfNeeded()
        searchTextField.useUnderline()
        
        if mySegmentedControl.selectedIndex == 0{
        
            offset = 0
        } else {
            offset = self.view.frame.width
        }

    }
    
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    
    func catchingNotification(notification:Notification){
        guard let userInfo = notification.userInfo,
            let selectedValue  = userInfo["selected"] as? Int else {
                print("No userInfo found in notification")
                return
        }
    
        if selectedValue == 0{
            offset = 0.0
        } else {
            offset = self.view.frame.width
        }
        
    }

    
    deinit {
        let nc = NotificationCenter.default
        nc.removeObserver(self)
    }
    
    
    //返回ListViewController
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func datasheetButtonPressed(_ sender: Any) {
        
        // get datasheet url string
        print("\(self.datasheetURLStr)")
        
        let svc = SFSafariViewController(url: URL(string: self.datasheetURLStr)!)
        self.present(svc, animated: true, completion: nil)
        
        
        
    }
    

    
    func check_datasheet_available(){

        if let firstItem = selectedProduct.list.first{
        

            if let docurl = firstItem["docurl"] as! String?{
            

                if docurl != "null" , docurl != "NULL" , docurl != "Null"{
                    self.datasheetURLStr = docurl
                    self.datasheetButton.isEnabled = true
                } else {
                    self.datasheetButton.isEnabled = false
                }
                
                
            } else {
                self.datasheetButton.isEnabled = false
            }
        } else {
                self.datasheetButton.isEnabled = false
        }
    }
    
    
    
}




// MARK:TableView delegate method:

extension DetailViewController:UITableViewDataSource, UITableViewDelegate{


    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        if tableView == self.firstTableView {
            return self.selectedProduct.list.count
        } else {
            return 10
        }
        
        
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if tableView == self.firstTableView{
            
            tableView.backgroundColor = UIColor.white
            let manuCell:ManufacturerCell = tableView.dequeueReusableCell(withIdentifier: "ManufacturerCell", for: indexPath) as! ManufacturerCell
            
            manuCell.keyLabel.text = self.selectedProduct.list[indexPath.row]["sup"] as! String?
            
            
            // 獲得價錢單位：
            var oneprice = ""
            var currance = ""
            if let cur = self.selectedProduct.list[indexPath.row]["cur"] as! String?{
                
                currance = cur
                
                // 取得價錢：
                if let price = self.selectedProduct.list[indexPath.row]["price"] as! String?{
                    //print("price =\(price)")
                    
                    let removeSpacePrice = price.replacingOccurrences(of: " ", with: "")
                    
                    if let getOne = removeSpacePrice.components(separatedBy: ";").first{
                        if let getPureValue = getOne.components(separatedBy: ":").last{
                            if getPureValue != ""{
                                
                                if let pureValue_in_float = Float(getPureValue){
                                
                                    let value = String(format: "%.2f", pureValue_in_float)
                                    oneprice = "\(currance) \(value)"
                                }
                            }
                        }
                    }
                
                } else {
                   
                }
                
            } else {
                // 取得價錢：
                if let price = self.selectedProduct.list[indexPath.row]["price"] as! String?{
                    //print("price =\(price)")
                    let removeSpacePrice = price.replacingOccurrences(of: " ", with: "")
                    
                    if let getOne = removeSpacePrice.components(separatedBy: ";").first{
                        if let getPureValue = getOne.components(separatedBy: ":").last{
                            if getPureValue != ""{
                                
                                if let pureValue_in_float = Float(getPureValue){
                                    
                                    let value = String(format: "%.2f", pureValue_in_float)
                                    oneprice = "\(value)"
                                }
                            }
                        }
                    }

                } else {
                    //print("no price")
                }

            }
            
            if oneprice != ""{
                manuCell.valueLabel.text = oneprice
            } else {
                manuCell.valueLabel.textColor = UIColor.lightGray
                manuCell.valueLabel.text = "N/A"
            }

            
            
            
            
            return manuCell
        
        } else {
            
            tableView.backgroundColor = UIColor.white
            let spec_cell:SpecCell = tableView.dequeueReusableCell(withIdentifier: "SpecCell", for: indexPath) as! SpecCell
            
            
            
            
            
            
            
            
            
            
            
            return spec_cell
        }
        
        
    }
    

    
    func swipe(_ gesture: UISwipeGestureRecognizer) {
        
        if gesture.direction == .left {
            // 左滑，顯示第二個tableview,並同時設置選中的segmented item
            offset = self.view.frame.width
            mySegmentedControl.selectedIndex = 1
        }
        else {
            offset = 0.0
            mySegmentedControl.selectedIndex = 0
        }
    }

    
    
    
}


