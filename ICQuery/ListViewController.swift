//
//  ListViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/7.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, DetailViewControllerDelegate{
    
    
    
    var autoCompleteTask : URLSessionDataTask!
    
    
    var searchKeyword:String!
    var searchAPI_Address:String!
    
    var json_dic : [String : Any]!
    
    var totalPins : Int!
    var currentPage : Int!
    var isLoading : Bool = false
    
    //登入帳號：
    var account : String?
    
    
    
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
    
    
    // autocomplete function variable
    var autocompleteTableView : UITableView!
    var autocompleteItems = [String]()
    var autocompleteCacheItems = [String]()
    
    var leadingConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    var topConstraint :NSLayoutConstraint!
    var heightConstraint :NSLayoutConstraint!
    
    
    deinit {
        print("deinit of ListViewController")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let placeholderStr = NSAttributedString(string: "請輸入查詢資料", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
        searchTextField.attributedPlaceholder = placeholderStr
        searchTextField.delegate = self
        
        
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
        
        // constaints:
        topConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: searchTextField, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)
        leadingConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1.0, constant: 8)
        trailingConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1.0, constant: -8)
        
        self.view.addConstraints([topConstraint,leadingConstraint,trailingConstraint])
        
        heightConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: NSLayoutAttribute.height, relatedBy: .equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 88)
        
        autocompleteTableView.addConstraint(heightConstraint)
        
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        self.listTableView.reloadData()
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
            return nil
        }
        
    }
    
    func get_total(dictionary:[String:Any]) -> Int{
        guard let total = dictionary["total"] as? String else {
            return 0
        }
        
        return Int(total)!
    }
    
    //search button pressed
    @IBAction func searchButtonPressed(_ sender: Any) {
        //print("get another search")
        
        if self.autoCompleteTask != nil{
            self.autoCompleteTask.cancel()
        }
        
        searchTextField.resignFirstResponder()
        self.allItems = []
        self.listTableView.reloadData()
        
        if searchTextField.text!.isEmpty{
            let alert = UIAlertController(title: "尚未輸入任何搜尋關鍵字", message:"請重新輸入搜尋字串", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            self.searchLogSend(searchStr: self.searchTextField.text!, key:"query")
            
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.label.text = "搜尋中"
            let queue = DispatchQueue.global()
            queue.async {
                let searchAPI = API_Manager.shared.SEARCH_API_PATH
                var searchKeyword = ""
                if self.searchTextField.text!.characters.last == " " || self.searchTextField.text!.characters.last == "\n" || self.searchTextField.text!.characters.last == "\t" {
                    searchKeyword = self.searchTextField.text!.substring(to: self.searchTextField.text!.index(before: self.searchTextField.text!.endIndex))
                } else {
                    searchKeyword = self.searchTextField.text!
                }

                self.type = "f"
                //組裝url-string
                
                let combinedStr = String(format: "%@?t=%@&p=1&q=%@", arguments: [searchAPI!, self.type, searchKeyword])
                let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                //print("\(escapedStr)")
                
                
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
                            hud.hide(animated: true)
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
                                    hud.hide(animated: true)
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
                                    hud.hide(animated: true)
                                }
                            }
                        } else {
                            
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let alert = UIAlertController(title: "無法獲得搜尋結果", message: "請重新搜尋", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                self.present(alert, animated: true, completion:nil)
                            }
                        }
                    }
                }
                task.resume()
            }
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
            //print("\(escapedStr)")
            
            
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
            //print("已經到達最後一頁")
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
        if tableView == self.listTableView{
            return allItems.count
        } else {
            return autocompleteItems.count
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.listTableView{
            let cell =  tableView.dequeueReusableCell(withIdentifier: CellID.list_cell, for: indexPath) as! ListTableViewCell
            let searchResult = allItems[indexPath.row]
            cell.configure(for: searchResult)
            if indexPath.row == self.allItems.count-1 {
                //print("current page:\(self.currentPage!), final row")
                self.loadMore()
            }
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12.0)
            cell.textLabel?.text = autocompleteItems[indexPath.row]
            
            return cell
        }
    }
    
}



// MARK: TableViewDelegate Method
extension ListViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        if tableView == listTableView{
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            let value = "\(allItems[indexPath.row].pn)+\(allItems[indexPath.row].mfs)"
            self.searchLogSend(searchStr: value, key: "view")
            
            // 轉到DetailViewController
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
            
            detailVC.selectedProduct = allItems[indexPath.row]
            // 動畫
            detailVC.modalPresentationStyle = UIModalPresentationStyle.custom
            detailVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            detailVC.delegate = self
            detailVC.account = self.account
            
            self.present(detailVC, animated: true, completion: nil)
            
        } else if tableView == autocompleteTableView {
            
            
            self.searchTextField.resignFirstResponder()
            self.autocompleteTableView.isHidden = true
            
            if self.autoCompleteTask != nil{
                self.autoCompleteTask.cancel()
            }
            
            // 從auto complete 選單中選擇出來
            self.searchTextField.text = autocompleteItems[indexPath.row]
            self.searchLogSend(searchStr: searchTextField.text!, key:"query")
            
            self.allItems = []
            self.listTableView.reloadData()
            
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.label.text = "搜尋中"
            let queue = DispatchQueue.global()
            
            queue.async {
                
                self.type = "f"
                let searchAPI = API_Manager.shared.SEARCH_API_PATH
                
                let searchKeyword = self.searchTextField.text!.components(separatedBy: "\t").first!
                
                //組裝url-string
                let combinedStr = String(format: "%@?t=%@&p=1&q=%@", arguments: [searchAPI!, self.type, searchKeyword])
                let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                //print("\(escapedStr)")
                
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
                            hud.hide(animated: true)
                            let alert = UIAlertController(title: "連線錯誤", message: "請稍後再試", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                            self.present(alert, animated: true, completion:{
                                self.searchTextField.text = ""
                                hud.removeFromSuperview()
                            })
                        }
                        
                    } else {
                        
                        if let data = data, let jsonDictionary = self.parse(json: data) {
                            //確定總共有幾筆：
                            if self.get_total(dictionary: jsonDictionary) <= 0{
                                DispatchQueue.main.async {
                                    hud.hide(animated: true)
                                    let alert = UIAlertController(title: "查無資料", message: "請嘗試其他關鍵字", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                    self.present(alert, animated: true, completion:{
                                        self.searchTextField.text = ""
                                        hud.removeFromSuperview()
                                    })
                                }
                                
                            } else {
                                DispatchQueue.main.async {
                                    hud.hide(animated: true)
                                    //設定筆數：
                                    self.totalPins = self.get_total(dictionary: jsonDictionary)
                                    //設定目前頁數：
                                    self.currentPage = 1
                                    self.searchKeyword = self.searchTextField.text!.components(separatedBy: "\t").first!
                                    // 爬資料：
                                    // 存資料到json_dic
                                    self.json_dic = jsonDictionary
                                    
                                    //更新資料
                                    self.allItems = self.parse(dictionary: self.json_dic)
                                    self.listTableView.reloadData()
                                    hud.removeFromSuperview()
                                    
                                }
                            }
                        } else {
                            
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let alert = UIAlertController(title: "無法獲得搜尋結果", message: "請重新搜尋", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                self.present(alert, animated: true, completion:{
                                    self.searchTextField.text = ""
                                    hud.removeFromSuperview()
                                })
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }
    
    
    //  make sure you can only select rows with actual search results
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if tableView == autocompleteTableView{
            return indexPath
        } else {
            if self.isLoading || self.allItems.count == 0 {
                return nil
            } else {
                return indexPath
            }
        }
    }
    
}


//MARK: TextfieldDelegate Method
extension ListViewController:UITextFieldDelegate{
    
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


//MARK: DetailViewControllerDelegate Method
extension ListViewController{
    
    func reloadTable(){
        self.listTableView.reloadData()
    }
    
    func newSearchBegin(searchKey:String, autoComplete:Bool){
        
        self.searchTextField.text = searchKey
        self.searchLogSend(searchStr: searchKey, key:"query")
        
        self.allItems = []
        self.listTableView.reloadData()
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        //hud.mode = MBProgressHUDMode.annularDeterminate
        hud.label.text = "搜尋中"
        let queue = DispatchQueue.global()
        
        queue.async {
            
            self.type = "f"
            let searchAPI = API_Manager.shared.SEARCH_API_PATH
            
            var searchKeyword = ""
            
            if autoComplete{
                searchKeyword = searchKey.components(separatedBy: "\t").first!
            } else {
                
                if searchKey.characters.last == " " || searchKey.characters.last == "\n" || searchKey.characters.last == "\t" {
                    searchKeyword = searchKey.substring(to: searchKey.index(before: searchKey.endIndex))
                } else {
                    searchKeyword = searchKey
                }
            }
            
            //組裝url-string
            
            let combinedStr = String(format: "%@?t=%@&p=1&q=%@", arguments: [searchAPI!, self.type, searchKeyword])
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            //print("\(escapedStr)")
            
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
                        self.present(alert, animated: true, completion:{
                            hud.hide(animated: true)
                            hud.removeFromSuperview()
                        })
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
                                    hud.hide(animated: true)
                                    self.searchTextField.text = ""
                                    hud.removeFromSuperview()
                                })
                            }
                        } else {
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
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
                                hud.removeFromSuperview()
                            }
                        }
                    }
                }
            }
            task.resume()
        
        
        }
    }
    
}





