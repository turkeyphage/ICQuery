//
//  ListViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/7.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class ListViewController: UIViewController{
    
    
    
    
    var searchKeyword:String!
    var searchAPI_Address:String!
    
    var json_dic : [String : Any]!
    
    var totalPins : Int!
    var currentPage : Int!
    
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let placeholderStr = NSAttributedString(string: "請輸入查詢資料", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
        searchTextField.attributedPlaceholder = placeholderStr
        
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
        
        //self.parse(dictionary: self.json_dic)
        //print("\(self.get_total_pages(dictionary: self.json_dic))")
        
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
                    let searchResult =  ProductDetail()
                    searchResult.pn = resultDict["pn"] as! String
                    //拆到mfslist裡
                    if let mfslist = resultDict["mfslist"] as? [Any]{
                        if let detailDic = mfslist.first as? [String:Any]{
                            if let mfs = detailDic["mfs"] as? String{
                                searchResult.mfs = mfs
                            }
                            if let picurl = detailDic["picurl"] as? String{
                                searchResult.picurl = picurl
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
    
    
    /*******************/
    
    // paring json
    func parse(json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8, allowLossyConversion: false)
            else { return nil }
        do {
            return try JSONSerialization.jsonObject(
                with: data, options: []) as? [String: Any]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    
    
    
    //check if there is next page
    
    
    
    
    
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
        
        cell.itemImageView.image = UIImage(named: "logo_120_120")
        
        cell.companyNameLabel.text = allItems[indexPath.row].mfs
        cell.modelNameLabel.text = allItems[indexPath.row].pn
        cell.typeLabel.text = allItems[indexPath.row].catagory
        cell.detailLabel.text = allItems[indexPath.row].desc
        return cell
        
    }
    
}



// MARK: TableViewDelegate Method
extension ListViewController:UITableViewDelegate{
    
    
}

