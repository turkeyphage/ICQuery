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

    @IBOutlet weak var segmentSlider: MMSegmentSlider!
    //登入帳號：
    var account : String?
    
    var favorList = [Int]()
    
    
    var autoCompleteTask : URLSessionDataTask!
    
    // autocomplete function variable
    var autocompleteTableView : UITableView!
    var autocompleteItems = [String]()
    var autocompleteCacheItems = [String]()
    
    var leadingConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    var topConstraint :NSLayoutConstraint!
    var heightConstraint :NSLayoutConstraint!
    
    
    //delegate
    weak var delegate : DetailViewControllerDelegate?
    
    
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
    
    //let nc = NotificationCenter.default
    
    
    var selectedProduct : ProductDetail!
    var datasheetURLStr : String!
    var spec : [[String:String]] = []
    
    var allitems : [SupplierDetail] = []
    
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        checkPriceAlertList()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //print("selectedProduct的資料如下：")
        //print("\(selectedProduct)")
        
        
        
        
        searchTextField.delegate = self

        //autocomplete tableview
        autocompleteTableView = UITableView(frame: CGRect(), style: UITableViewStyle.plain)
        autocompleteTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        autocompleteTableView.delegate = self
        autocompleteTableView.dataSource = self
        autocompleteTableView.isScrollEnabled = true
        autocompleteTableView.isHidden = true
        autocompleteTableView.layer.borderWidth = 1
        autocompleteTableView.layer.borderColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1).cgColor
        autocompleteTableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(autocompleteTableView)
        
        // autocomplete tableview constaints:
        topConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: searchTextField, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)
        leadingConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1.0, constant: 8)
        trailingConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1.0, constant: -8)
        
        self.view.addConstraints([topConstraint,leadingConstraint,trailingConstraint])
        
        heightConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: NSLayoutAttribute.height, relatedBy: .equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 88)
        
        autocompleteTableView.addConstraint(heightConstraint)
        
        

        //set notification observer
        let notificationName = Notification.Name("SegmentWasSelected")
        NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.catchingNotification(notification:)), name: notificationName, object: nil)
        

   
        
        let placeholderStr = NSAttributedString(string: "請輸入查詢資料", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
        searchTextField.attributedPlaceholder = placeholderStr
    
        
        //datasheet button outline
        datasheetButton.backgroundColor = .clear
        datasheetButton.layer.cornerRadius = 5
        datasheetButton.layer.borderWidth = 1
        datasheetButton.layer.borderColor = UIColor.lightGray.cgColor
        
        check_datasheet_available()
        
        
        //產品內容
        //圖片
        product_imageview.image = UIImage(named: "logo_120_120")
        if let smallURL = URL(string: selectedProduct.picurl) {
            downloadTask = product_imageview.loadImage(url: smallURL)
        }
        
        //產品名稱，型號，細節內容
        company_label.text = selectedProduct.mfs
        model_label.text =  selectedProduct.pn
        detail_label.text = selectedProduct.desc

        
        //Segment control
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
        
        
        
        
        //兩個tableview的設定
        firstTableView.delegate = self
        secondTableView.delegate = self
        firstTableView.dataSource = self
        secondTableView.dataSource = self
        
        firstTableView.allowsSelection = true
        secondTableView.allowsSelection = false
        
        
        
        
        
        //為scrollview加上手勢辨識，用來切換兩個tableview
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(DetailViewController.swipe(_:)))
        swipeLeft.direction = .left
        swipeLeft.numberOfTouchesRequired = 1
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(DetailViewController.swipe(_:)))
        swipeRight.direction = .right
        swipeRight.numberOfTouchesRequired = 1
        
        theScrollView.addGestureRecognizer(swipeLeft)
        theScrollView.addGestureRecognizer(swipeRight)
        
        
        
        // tablewview cell的設定
        let manucellNib = UINib(nibName: CellID.manufacturer_cell, bundle: nil)
        firstTableView.register(manucellNib, forCellReuseIdentifier: CellID.manufacturer_cell)
        firstTableView.estimatedRowHeight = 50
        firstTableView.rowHeight = UITableViewAutomaticDimension
        
        
        let speccellNib = UINib(nibName: CellID.spec_cell, bundle: nil)
        secondTableView.register(speccellNib, forCellReuseIdentifier: CellID.spec_cell)
        secondTableView.estimatedRowHeight = 50
        secondTableView.rowHeight = UITableViewAutomaticDimension

        
        //取得物件的細部內容資料
        get_item_in_list(wholeList: selectedProduct.list)
        
        
        //取得spec資料
        get_spec_detail()
        
        
        
        //數量按鈕（segment slider）的字型大小
        segmentSlider.labelsFont = UIFont.systemFont(ofSize: 12.0)
        segmentSlider.values = [1, 50, 100, 1000, 10000]
        segmentSlider.labels = ["1", "50", "100", "1000", "10000"]
        
        segmentSlider.addTarget(self, action: #selector(self.sliderValueChanged), for: UIControlEvents.valueChanged)
        segmentSlider.setSelectedItemIndex(0, animated: true)
        self.sliderValueChanged()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    

    override func viewDidLayoutSubviews() {
        view.layoutIfNeeded()
        searchTextField.useUnderline()
        
        //依照segmentcontrol的選擇來判斷那一個tableview需要被呈現
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
        
        let notificationName = Notification.Name("SegmentWasSelected")
        
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)

        print("deinit of DetailViewController")
    }
    
    
    //search button被按了，進行新搜尋
    @IBAction func searchButtonPressed(_ sender: Any) {
        
        searchTextField.resignFirstResponder()
        
        if searchTextField.text!.isEmpty{
        
            let alert = UIAlertController(title: "尚未輸入任何搜尋關鍵字", message:"請重新輸入搜尋字串", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
            self.present(alert, animated: true, completion: nil)

        } else {
            self.delegate?.newSearchBegin(searchKey: self.searchTextField.text!, autoComplete: false)
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    
    
    
    //返回ListViewController
    @IBAction func backButtonPressed(_ sender: Any) {
        
        self.delegate?.reloadTable()
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func datasheetButtonPressed(_ sender: Any) {
        
        // get datasheet url string
        //print("\(self.datasheetURLStr)")
        
        let svc = SFSafariViewController(url: URL(string: self.datasheetURLStr)!)
        self.present(svc, animated: true, completion: nil)
    }
    

    
    func check_datasheet_available(){

        if let firstItem = selectedProduct.list.first{
        

            if let docurl = firstItem["docurl"] as! String?{
            
                //print("docurl = \(docurl)")
                if docurl != "null" , docurl != "NULL" , docurl != "Null", !docurl.isEmpty{
                    
                    
                    //檢查是否有多個url
                    if let firstURL = docurl.components(separatedBy: ",").first{
                        self.datasheetURLStr = firstURL
                        self.datasheetButton.isEnabled = true
                        self.datasheetButton.isHidden = false
                    } else {
                        self.datasheetButton.isEnabled = false
                        self.datasheetButton.isHidden = true
                    }
                    
                } else {
                    self.datasheetButton.isEnabled = false
                    self.datasheetButton.isHidden = true
                }
                
                
            } else {
                self.datasheetButton.isEnabled = false
                self.datasheetButton.isHidden = true
            }
        } else {
            self.datasheetButton.isEnabled = false
            self.datasheetButton.isHidden = true
        }
    }
    
    
    func whatCurrencySign(oriStr: String) -> String{
    
        switch oriStr {
            
        case "CNY", "RMB":
            return "¥"

        case "TWD", "NT.", "NT", "NTD":
            return "$"
        
        case "JPY":
            return "¥"
        
        case "GBP":
            return "£"
            
        case "USD", "U.S", "U.S.":
            return "$"
        
        case "CAN", "CAD":
            return "$"
            
        case "KRW":
            return "₩"
        
        case "THB":
            return "฿"
            
        case "INR":
            return "₹"
            
        case "EUR":
            return "€"
            
        case "HK", "HKD":
            return "$"
        
        case "SGD":
            return "$"
            
        default:
            return oriStr
        }
        
    }
    
    
    
    
    func sliderValueChanged(){
        
        
        //print("\(self.segmentSlider.currentValue)")
        self.firstTableView.reloadData()
        
    }
    
    
    
}



// MARK:UITableViewDatasource and UITableViewDelegate methods:

extension DetailViewController:UITableViewDataSource, UITableViewDelegate{


    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.firstTableView {
            return self.allitems.count
        } else if tableView == self.secondTableView {
            
            /*
            if let spec = self.allitems.first?.spec{
                return spec.keys.count
            } else {
                return 1
            }
            */
            
            if self.spec.isEmpty {
                return 1
            } else {
                return self.spec.count
            }
            
        } else {
            return autocompleteItems.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.firstTableView{
            
            
            //print("\(allitems[indexPath.row])")
            tableView.backgroundColor = UIColor.white
            let manuCell:ManufacturerCell = tableView.dequeueReusableCell(withIdentifier: "ManufacturerCell", for: indexPath) as! ManufacturerCell
            
            //button 顯示或不顯示:
            manuCell.buyButton.tag = indexPath.row
            
            if self.allitems[indexPath.row].url.isEmpty{
                manuCell.buyButton.isHidden = true
            } else {
                manuCell.buyButton.isHidden = false
            }
            
            //button 動作：
            manuCell.buyButton.addTarget(self, action: #selector(self.buyButtonTap(_:)), for: UIControlEvents.touchUpInside)
            
            
            //stockLabel
            manuCell.stockLabel.text = String(self.allitems[indexPath.row].amount)
     
            manuCell.keyLabel.text = self.allitems[indexPath.row].sup

            //print("\(allitems[indexPath.row].price)")
            
            
//            //過濾price的第一個
//            if let firstprice = self.allitems[indexPath.row].price.keys.sorted().first{
//                manuCell.valueLabel.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
//                manuCell.valueLabel.text = self.allitems[indexPath.row].price[firstprice]
//                manuCell.curLabel.text = self.whatCurrencySign(oriStr:self.allitems[indexPath.row].cur)
//            } else {
//                manuCell.valueLabel.textColor = UIColor.lightGray
//                manuCell.valueLabel.text = "N/A"
//                manuCell.curLabel.text = ""
//            }

            //選擇價錢
            
            if self.allitems[indexPath.row].price.isEmpty{
             
                manuCell.valueLabel.textColor = UIColor.lightGray
                manuCell.valueLabel.text = "N/A"
                manuCell.curLabel.text = ""
           
            } else {
                
                let segmentSelectedValue = self.segmentSlider.currentValue as! Int
                let allKeysInRow = self.allitems[indexPath.row].price.keys.sorted()
                
                var closest = 0
                
                for key in allKeysInRow{
                    //print("key = \(key)")
                    //print("segmentValue = \(segmentSelectedValue)")
                    if let intKey = Int(key){
                    
                        if intKey <= segmentSelectedValue , (intKey-segmentSelectedValue)>=(closest-segmentSelectedValue){
                            closest = intKey
                        }
                    }
                }
            
                if closest == 0 {
                    manuCell.valueLabel.textColor = UIColor.lightGray
                    manuCell.valueLabel.text = "N/A"
                    manuCell.curLabel.text = ""
                } else {
                    manuCell.valueLabel.textColor = UIColor(red: 255/255, green: 128/255, blue: 0, alpha: 1)
                    manuCell.valueLabel.text = self.allitems[indexPath.row].price[String(closest)]
                    manuCell.curLabel.text = self.whatCurrencySign(oriStr:self.allitems[indexPath.row].cur)
                }
            }
            
//            let segmentSelectedValue = self.segmentSlider.currentValue as! Int
//            let allKeysInRow = self.allitems[indexPath.row].price.keys.sorted()
            
            
            
            
            
            
            for item in favorList{
                let itemInString = String(item)
                if itemInString == self.allitems[indexPath.row].id{
                    // 顯示已加關注
                    manuCell.favorStar.image = UIImage(named: "tracking_1")
                    manuCell.favorStatus = true
                } else {
                    manuCell.favorStar.image = UIImage(named: "tracking_0")
                    manuCell.favorStatus = false
                }

            }
            
            
            
            
            
            return manuCell
        
        } else if tableView == self.secondTableView {
            
            tableView.backgroundColor = UIColor.white
            let spec_cell:SpecCell = tableView.dequeueReusableCell(withIdentifier: "SpecCell", for: indexPath) as! SpecCell
            

            if self.spec.isEmpty{
                spec_cell.keyLabel.text = "該物件"
                spec_cell.valueLabel.text = "目前尚無提供規格參考資料"
            } else {
                spec_cell.keyLabel.text = self.spec[indexPath.row].keys.first
                spec_cell.valueLabel.text = self.spec[indexPath.row].values.first
            }

            return spec_cell
        
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12.0)
            cell.textLabel?.text = autocompleteItems[indexPath.row]
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        //let cell = tableView.cellForRow(at: indexPath) as! ManufacturerCell
        
        
        if tableView == firstTableView {
            let cell = firstTableView.cellForRow(at: indexPath) as! ManufacturerCell
            
            let value = "\(allitems[indexPath.row].pn)+\(allitems[indexPath.row].mfs)+\(allitems[indexPath.row].sup)"
            self.searchLogSend(searchStr: value, key: "price")
            
            
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let priceChartVC = storyboard.instantiateViewController(withIdentifier: "PriceChartViewController") as! PriceChartViewController
            
            priceChartVC.supplier = allitems[indexPath.row]
            priceChartVC.account = self.account
            priceChartVC.favorStatus = cell.favorStatus
            
            self.present(priceChartVC, animated: true) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            
            
            
        } else if tableView == autocompleteTableView {
        
            if self.autoCompleteTask != nil{
                self.autoCompleteTask.cancel()
            }
            // 從auto complete 選單中選擇出來
            self.searchTextField.resignFirstResponder()
            self.searchTextField.text = autocompleteItems[indexPath.row]
            self.autocompleteTableView.isHidden = true
            
            self.delegate?.newSearchBegin(searchKey: self.searchTextField.text!, autoComplete: true)
            self.dismiss(animated: true, completion: nil)
        
        }
 
    }
    

    
    //buy button tap
    func buyButtonTap(_ sender:UIButton){
    
        //print("\(sender.tag)")
        //print("\(self.allitems[sender.tag].url)")
        let svc = SFSafariViewController(url: URL(string: self.allitems[sender.tag].url)!)
        self.present(svc, animated: true, completion: nil)
    
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

    
    func get_spec_detail(){
    
        if let firstItem = self.selectedProduct.list.first{
        
            if let specData = firstItem["spec"] as? String{
                
                if !specData.isEmpty{
                    //print("\(specData)")
                    //開始paring
                    //去掉{}
                    let noLeft = specData.replacingOccurrences(of: "{", with: "")
                    let noRight = noLeft.replacingOccurrences(of: "}", with: "")
                    
                    //以, 區隔
                    let separateByComma = noRight.components(separatedBy: ",")
                    
                    for eachItem in separateByComma{
                        
                        var separateByQuotation = eachItem.components(separatedBy: "'")
                        
                        if separateByQuotation.count == 5{
                            //去掉最前頭的""
                            separateByQuotation.removeFirst()
                            //去掉最後頭的""
                            separateByQuotation.removeLast()
                            
                            if separateByQuotation.count == 3{
                                self.spec.append([separateByQuotation.first!:separateByQuotation.last!])
                            }
                            
                        }
                    }

                }
            }

        }
    
    }
    
    
    func get_item_in_list(wholeList:[[String:Any]]){
    
        for item in wholeList{
            
            var supplierDetail = SupplierDetail()
            
            if let id = item["id"] as? String{
                supplierDetail.id = id.replacingOccurrences(of: " ", with: "")
            }
            
            if let pn = item["pn"] as? String{
                supplierDetail.pn = pn.replacingOccurrences(of: " ", with: "")
            }
            
            if let sku = item["sku"] as? String{
                supplierDetail.sku = sku.replacingOccurrences(of: " ", with: "")
            }

            if let mfs = item["mfs"] as? String{
                supplierDetail.mfs = mfs.replacingOccurrences(of: " ", with: "")
            }

            if let sup = item["sup"] as? String{
                supplierDetail.sup = sup.replacingOccurrences(of: " ", with: "")
            }

            if let url = item["url"] as? String{
                supplierDetail.url = url.replacingOccurrences(of: " ", with: "")
            }

            if let amount = item["amount"] as? Int{
                supplierDetail.amount = amount
            }

            if let cur = item["cur"] as? String{
                supplierDetail.cur = cur.replacingOccurrences(of: " ", with: "")
            }

            if let picurl = item["picurl"] as? String{
                supplierDetail.picurl = picurl.replacingOccurrences(of: " ", with: "")
            }
            
            if let docurl = item["docurl"] as? String{
                supplierDetail.docurl = docurl.replacingOccurrences(of: " ", with: "")
            }
            
            //spec
            if let spec = item["spec"] as? String{
                if !spec.isEmpty{
                    //print("\(specData)")
                    //開始paring
                    //去掉{}
                    let noLeft = spec.replacingOccurrences(of: "{", with: "")
                    let noRight = noLeft.replacingOccurrences(of: "}", with: "")
                    
                    //以, 區隔
                    let separateByComma = noRight.components(separatedBy: ",")
                    for eachItem in separateByComma{
                        var separateByQuotation = eachItem.components(separatedBy: "'")
                        if separateByQuotation.count == 5{
                            //去掉最前頭的""
                            separateByQuotation.removeFirst()
                            //去掉最後頭的""
                            separateByQuotation.removeLast()
                            
                            if separateByQuotation.count == 3{
                                
                                supplierDetail.spec[separateByQuotation.first!] = separateByQuotation.last!
                            }
                        }
                    }
                }
            }
            
            
            if let desc = item["desc"] as? String{
                supplierDetail.desc = desc
            }
            if let catagory = item["catagory"] as? String{
                supplierDetail.catagory = catagory
            }
            
            //price
            if let price = item["price"] as? String{
                //去除有的沒的空白
                
                
                //print("--------------------------------")
                //print("price = \(price)")
                
                
                let removeSpacePrice = price.replacingOccurrences(of: " ", with: "")
                //判別是否為空字串
                if !removeSpacePrice.isEmpty{
                    
                    //以;分開
                    let noSemicolon = removeSpacePrice.components(separatedBy: ";")
                    let filterEmpty1 = noSemicolon.filter{$0 != ""}
                    
                    for item1 in filterEmpty1{
                        let noColon = item1.components(separatedBy: ":")
                        let filterEmpty2 = noColon.filter{$0 != ""}
                        if filterEmpty2.count == 2{
                            
                            if let pureValue = Float(filterEmpty2.last!){
                                supplierDetail.price[filterEmpty2.first!] = String(pureValue)
                            }

                        }
                    }
                }
            }
            //print("supplierDetail = \(supplierDetail)")
            //print("-----------------")
        
            
            allitems.append(supplierDetail)
        }
    }
    
    
    //******** autocomplete list 下載 ********//
    
    func get_autoComplete_list(searchStr: String){
        
        if self.autoCompleteTask != nil{
            self.autoCompleteTask.cancel()
        }
        
        autocompleteCacheItems = []
        
        // 呼叫API
        let searchAPI = API_Manager.shared.SEARCH_API_PATH
        let combinedStr = String(format: "%@?t=a&q=%@", arguments: [searchAPI!, searchStr])
        let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //print("\(escapedStr)")
        
        //放request
        let url = URL(string: escapedStr)
        let request = URLRequest(url: url!)
        //request.httpMethod = "GET"
        let session = URLSession.shared
        
        self.autoCompleteTask = session.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil{
                print(error.debugDescription)
                //alert -- 連線錯誤
            } else {
                
                //print("\(response)")
                if let serverTalkBack = String(data: data!, encoding: String.Encoding.utf8){
                    let filter1 = serverTalkBack.replacingOccurrences(of: "null({\"result\":[", with: "")
                    let filter2 = filter1.replacingOccurrences(of: "]});", with: "")
                    let separateByComma = filter2.components(separatedBy: ",").filter{$0 != ""}
                    for item in separateByComma{
                        
                        let filter3 = item.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "\n", with: "")
                        self.autocompleteCacheItems.append(filter3)
                    }
                    
                    DispatchQueue.main.async {
                        self.autocompleteItems = self.autocompleteCacheItems
                        self.autocompleteTableView.reloadData()
                    }
                }
            }
        }
        self.autoCompleteTask.resume()
    }

    
    
    
    // 取得自己所設定的價格變動通知 selPriceAlert
    func checkPriceAlertList(){

        if self.account != nil{
            // 呼叫API
            
            //"latitude", "longitude"
            let latitude = DBManager.shared.get_device_position()["latitude"]!
            let longitude = DBManager.shared.get_device_position()["longitude"]!
            
            //name=UUID node=DeviceName
            let name = DBManager.shared.systemInfo.deviceUUID
            
  
            let combinedStr = String(format: "%@/selPriceAlert?deviceid=%@&latitude=%@&longtitude=%@&user_id=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, name, latitude, longitude, self.account!])
            
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            //print("\(escapedStr)")
        
            let url = URL(string:escapedStr)!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
                
                if let data = data, let jsonDictionary = self.parse(json: data) {
                    //print("jsonDic = \(jsonDictionary)")
                
                    if let favorList = jsonDictionary["id"] as? [Any]{
                        //print("favorList = \(favorList)")
                        
                        for item in favorList{
                            //print("\(item)")
                            if let each = item as? Int{
                                //print("\(each)")
                                self.favorList.append(each)
                            }
                        }
                        
                        // 重新整理table
                        self.firstTableView.reloadData()
                    }
                    
                    
                } else {
                    print("\(error)")
                }
                
                
                
                
            }
            task.resume()
            
            
            
        }
        
        
        
        
    
    }
    
    
    func parse(json data:Data) -> [String : Any]? {
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch{
            print("JSON Error:\(error)")
            return nil
        }
        
    }

    
    
    
    
    
    
    
    
    
}


// MARK: UITextFieldDelegate Method
extension DetailViewController:UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        autocompleteTableView.isHidden = true
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        //增加的時候
        let newLength = (textField.text?.characters.count)! + string.characters.count - range.length
        if newLength >= 3 {
            let searchStr = textField.text!+string
            get_autoComplete_list(searchStr: searchStr)
            autocompleteTableView.isHidden = false
        } else if newLength == 0 {
            autocompleteTableView.isHidden = true
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        autocompleteTableView.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.text?.characters.count)! >= 3{
            get_autoComplete_list(searchStr:textField.text!)
        }
    }

}


// MARK: Protocal for sending data back
protocol DetailViewControllerDelegate:class{
    
    func newSearchBegin(searchKey:String, autoComplete:Bool)
    func reloadTable()
    
}
