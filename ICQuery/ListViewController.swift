//
//  ListViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/7.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, DetailViewControllerDelegate{
    
    
    
    
    var searchKeyword:String!
    var searchAPI_Address:String!
    
    var json_dic : [String : Any]!
    
    var totalPins : Int!
    var currentPage : Int!
    var isLoading : Bool = false
    
    //搜尋的方式
    var type : String!
    
    var totalPages: Int{
        get {
            if totalPins%10 != 0{
                return Int(self.totalPins/10)+1
            } else {
                return Int(self.totalPins/10)
            }
        }
    }
    
    
    var isNextPageExist : Bool{
        
        get{
            if currentPage < totalPages {
                return true
            } else {
                return false
            }
        }
        
    }
    
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var listTableView: UITableView!
    
    @IBOutlet weak var title_background_view: UIView!
    
    
    var allItems : [ProductDetail]!
    
    var isLoadingMore = false // flag
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let placeholderStr = NSAttributedString(string: "請輸入查詢資料", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
        searchTextField.attributedPlaceholder = placeholderStr
        searchTextField.delegate = self
        
        //print("keyword: \(self.searchKeyword)")
        //print("searchAPI = \(self.searchAPI_Address)")
        //print("totalPage = \(self.totalPins)")
        //print("currentPage = \(self.currentPage)")
        
        
        
        //print("\(self.json_dic)")
        
        //listTableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        // 上面的背景顏色
        //title_background_view.backgroundColor = UIColor(patternImage: UIImage(named: "background_pattern")!)
        
        //status bar 背景顏色
        //        let app = UIApplication.shared
        //        let statusBarHeight = app.statusBarFrame.size.height
        //        let statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: statusBarHeight))
        //        statusBarView.backgroundColor = UIColor(patternImage: UIImage(named: "background_pattern")!)
        //
        //        self.view.addSubview(statusBarView)
        
        
        
        let cellNib = UINib(nibName: CellID.list_cell, bundle: nil)
        
        listTableView.register(cellNib, forCellReuseIdentifier: CellID.list_cell)
        
        listTableView.estimatedRowHeight = 106
        listTableView.rowHeight = UITableViewAutomaticDimension
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.allItems = self.parse(dictionary: json_dic)
        
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    override func viewDidLayoutSubviews() {
        view.layoutIfNeeded()
        searchTextField.useUnderline()
    }
    
    
    
    @IBAction func main_icon_pressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    /****** parsing *****/
    
    func get_total_pages(dictionary:[String:Any]) -> Int{
        guard let total = dictionary["total"] as? String else {
            return 0
        }
        return Int(total)!
    }
    
    
    func parse(dictionary:[String:Any])-> [ProductDetail]{
        
        //pnlist裡的數量
        guard let array = dictionary["pnlist"] as? [Any] else {
            print("Expected 'pnlist' array")
            return []
        }
        
        if array.isEmpty {
            return []
            
        } else {
            var searchResults: [ProductDetail] = []
            
            //get each item in pnlist
            for resultDict in array{
                //print("\(resultDict)")
                //resultDict代表每一個item，都是dictionary，也代表每一個cell
                if let resultDict = resultDict as? [String: Any] {
                    var searchResult =  ProductDetail()
                    searchResult.pn = resultDict["pn"] as! String
                    //拆到mfslist裡
                    if let mfslist = resultDict["mfslist"] as? [Any]{
                        if let detailDic = mfslist.first as? [String:Any]{
                            if let mfs = detailDic["mfs"] as? String{
                                searchResult.mfs = mfs
                            }
                            if let picurl = detailDic["picurl"] as? String{
                                searchResult.picurl = picurl
                                //print("\(picurl)")
                            }
                            
                            if let desc = detailDic["desc"] as? String{
                                searchResult.desc = desc
                            }
                            // 拆到list裡
                            if let list = detailDic["list"] as? [[String:Any]]{
                                searchResult.list = list
                                //找出catagory
                                if let catagory = list.first?["catagory"] as? String{
                                    searchResult.catagory = catagory
                                }
                            }
                        }
                    }
                    searchResults.append(searchResult)
                }
            }
            return searchResults
        }
    }
    
    
    
    func parse(json data:Data) -> [String : Any]? {
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch{
            print("JSON Error:\(error)")
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "JSON解析錯誤", message: "請再嘗試用其他關鍵字進行搜尋", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                self.present(alert, animated: true, completion:nil)
            }
            
            
            return nil
        }
        
    }
    
    func get_total(dictionary:[String:Any]) -> Int{
        guard let total = dictionary["total"] as? String else {
            return 0
        }
        
        return Int(total)!
    }
    
    
    
    /*******************/
    
    // paring json
    //    func parse(json: String) -> [String: Any]? {
    //        guard let data = json.data(using: .utf8, allowLossyConversion: false)
    //            else { return nil }
    //        do {
    //            return try JSONSerialization.jsonObject(
    //                with: data, options: []) as? [String: Any]
    //        } catch {
    //            print("JSON Error: \(error)")
    //            return nil
    //        }
    //    }
    
    
    //check if there is next page
    
    
    
    
    //search button pressed
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        print("get another search")
        searchTextField.resignFirstResponder()
        
        
        self.allItems = []
        self.listTableView.reloadData()
        
        
        if searchTextField.text!.isEmpty{
            
            let alert = UIAlertController(title: "尚未輸入任何搜尋關鍵字", message:"請重新輸入搜尋字串", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            
            let searchAPI = API_Manager.shared.SEARCH_API_PATH
            let searchKeyword = self.searchTextField.text!.components(separatedBy: "\t").first
            let no_space_and_getFirstWord = searchKeyword!.components(separatedBy: " ").first
            self.type = "f"
            
            //組裝url-string
            
            let combinedStr = String(format: "%@?t=%@&p=1&q=%@", arguments: [searchAPI!, self.type, no_space_and_getFirstWord!])
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            print("\(escapedStr)")
            
            
            //放request
            let url = URL(string: escapedStr)
            let request = URLRequest(url: url!)
            //request.httpMethod = "GET"
            let session = URLSession.shared
            
            
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                if error != nil{
                    //print(error.debugDescription)
                    
                    //alert -- 連線錯誤
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "連線錯誤", message: "請稍後再試", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                        self.present(alert, animated: true, completion:nil)
                    }
                    
                } else {
                    
                    if let data = data, let jsonDictionary = self.parse(json: data) {
                        //print("\(jsonDictionary)")
                        
                        //確定總共有幾筆：
                        if self.get_total(dictionary: jsonDictionary) <= 0{
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "查無資料", message: "請嘗試其他關鍵字", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                self.present(alert, animated: true, completion:{
                                    self.searchTextField.text = ""
                                })
                            }
                        } else {
                            DispatchQueue.main.async {
                                //設定筆數：
                                self.totalPins = self.get_total(dictionary: jsonDictionary)
                                //設定目前頁數：
                                self.currentPage = 1
                                self.searchKeyword = self.searchTextField.text
                                // 爬資料：
                                // 存資料到json_dic
                                self.json_dic = jsonDictionary
                                
                                //更新資料
                                self.allItems = self.parse(dictionary: self.json_dic)
                                self.listTableView.reloadData()
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    
    //load more data:
    func loadMore(){
        //check page
        
        if isNextPageExist, !isLoading{
            //往下一頁
            isLoading = true
            self.currentPage! += 1
            
            
            let searchAPI = self.searchAPI_Address
            let searchKeyword = self.searchKeyword.components(separatedBy: "\t").first
            let no_space_and_getFirstWord = searchKeyword!.components(separatedBy: " ").first
            
            //組裝url-string
            
            let combinedStr = String(format: "%@?t=%@&p=%@&q=%@", arguments: [searchAPI!, self.type,"\(self.currentPage!)",no_space_and_getFirstWord!])
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            print("\(escapedStr)")
            
            
            // 放request
            let url = URL(string: escapedStr)
            let request = URLRequest(url: url!)
            //request.httpMethod = "GET"
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                if error != nil{
                    print(error.debugDescription)
                    
                    //alert -- 連線錯誤
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "資料更新異常", message: "請稍後再試", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                        self.present(alert, animated: true, completion:{
                            self.currentPage! -= 1
                            self.isLoading = false
                        })
                    }
                    
                } else {
                    
                    if let data = data, let jsonDictionary = self.parse(json: data) {
                        //print("\(jsonDictionary)")
                        
                        
                        // 爬資料：
                        // 存資料到json_dic
                        self.json_dic = jsonDictionary
                        
                        //更新資料
                        self.allItems! += self.parse(dictionary: self.json_dic)
                        
                        DispatchQueue.main.async {
                            self.listTableView.reloadData()
                            self.isLoading = false
                        }
                        
                    } else {
                        
                        print("json parsing error")
                        self.isLoading = false
                    }
                }
            }
            task.resume()
            
        } else {
            print("已經到達最後一頁")
            self.isLoading = false
        }
        
        
        
    }
    
    
    
    
}




// MARK: TableViewDataSource Method

extension ListViewController:UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView.dequeueReusableCell(withIdentifier: CellID.list_cell, for: indexPath) as! ListTableViewCell
        let searchResult = allItems[indexPath.row]
        cell.configure(for: searchResult)
        
        
        if indexPath.row == self.allItems.count-1 {
            print("current page:\(self.currentPage!), final row")
            self.loadMore()
        }
        
        
        
        return cell
        
    }
    
}



// MARK: TableViewDelegate Method
extension ListViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        // 轉到DetailViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        
        detailVC.selectedProduct = allItems[indexPath.row]
        
        
        // 動畫
        detailVC.modalPresentationStyle = UIModalPresentationStyle.custom
        detailVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        detailVC.delegate = self
        self.present(detailVC, animated: true, completion: nil)
        
        
        
    }
    
    
    //  make sure you can only select rows with actual search results
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if self.isLoading || self.allItems.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
    
    
    
    /*
     func scrollViewDidScroll(_ scrollView: UIScrollView) {
     let contentOffset = Double(scrollView.contentOffset.y)
     let maximumOffset = Double(scrollView.contentSize.height - scrollView.frame.size.height)
     
     if !isLoadingMore && (maximumOffset - contentOffset == 0) {
     // Get more data - API call
     self.isLoadingMore = true
     
     print("is LoadingMore")
     print("*************************")
     DispatchQueue.main.async {
     self.isLoadingMore = false
     }
     
     //            // Update UI
     //            dispatch_async(dispatch_get_main_queue()) {
     //                tableView.reloadData()
     //                self.isLoadingMore = false
     //            }
     }
     }
     
     */
    
}


//MARK: TextfieldDelegate Method
extension ListViewController:UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}


//MARK: DetailViewControllerDelegate Method
extension ListViewController{
    
    func newSearchBegin(searchKey:String){
        
        
        self.allItems = []
        self.listTableView.reloadData()

        self.searchTextField.text = searchKey
        self.type = "f"
        let searchAPI = API_Manager.shared.SEARCH_API_PATH
        let searchKeyword = searchKey.components(separatedBy: "\t").first
        let no_space_and_getFirstWord = searchKeyword!.components(separatedBy: " ").first
        
        //組裝url-string
        
        let combinedStr = String(format: "%@?t=%@&p=1&q=%@", arguments: [searchAPI!, self.type,no_space_and_getFirstWord!])
        let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        print("\(escapedStr)")
        
        //放request
        let url = URL(string: escapedStr)
        let request = URLRequest(url: url!)
        //request.httpMethod = "GET"
        
        let session = URLSession.shared

        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil{
                //print(error.debugDescription)
                
                //alert -- 連線錯誤
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "連線錯誤", message: "請稍後再試", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                    self.present(alert, animated: true, completion:nil)
                }
                
            } else {
                
                if let data = data, let jsonDictionary = self.parse(json: data) {
                    //print("\(jsonDictionary)")
                    
                    //確定總共有幾筆：
                    if self.get_total(dictionary: jsonDictionary) <= 0{
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "查無資料", message: "請嘗試其他關鍵字", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                            self.present(alert, animated: true, completion:{
                                self.searchTextField.text = ""
                            })
                        }
                    } else {
                        DispatchQueue.main.async {
                            //設定筆數：
                            self.totalPins = self.get_total(dictionary: jsonDictionary)
                            //設定目前頁數：
                            self.currentPage = 1
                            self.searchKeyword = self.searchTextField.text
                            // 爬資料：
                            // 存資料到json_dic
                            self.json_dic = jsonDictionary
                            
                            //更新資料
                            self.allItems = self.parse(dictionary: self.json_dic)
                            self.listTableView.reloadData()
                        }
                    }
                }
            }
        }
        task.resume()
    }
 
}
