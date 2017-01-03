//
//  SearchViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/5.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController{
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var loginStatusLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    
    // autocomplete function variable
    var autocompleteTableView : UITableView!
    var autocompleteItems = [String]()
    var autocompleteCacheItems = [String]()
    
    var leadingConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    var topConstraint :NSLayoutConstraint!
    var heightConstraint :NSLayoutConstraint!
    
    
    var searchTypes:[String] = ["半導體產品","無源元件","連接器","測試設備","電線電纜","光電元件","電源產品與電池","工業控制和量表","電路保護和開關","辦公設備和配件","工具和用品","外殼和緊固件"]
    
    
    
    var account : String!
    
    var loginStatus:Bool = false {
        didSet {
            change_login_label(login: loginStatus)
        }
    }
    
    let reachability = Reachability()!
    
    
    var autoCompleteTask : URLSessionDataTask!
    
    
    deinit {
        //print("deinit of SearchViewController")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
        topConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: textField, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)
        leadingConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1.0, constant: 8)
        trailingConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: .trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1.0, constant: -8)
        self.view.addConstraints([topConstraint,leadingConstraint,trailingConstraint])
        
        //        self.view.addConstraint(NSLayoutConstraint(item: autocompleteTableView, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: textField, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: -80))
        //        self.view.addConstraint(NSLayoutConstraint(item: autocompleteTableView, attribute: .leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1.0, constant: 8))
        //        self.view.addConstraint(NSLayoutConstraint(item: autocompleteTableView, attribute: .trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1.0, constant: -8))
        
        heightConstraint = NSLayoutConstraint(item: autocompleteTableView, attribute: NSLayoutAttribute.height, relatedBy: .equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 88)
        
        autocompleteTableView.addConstraint(heightConstraint)
        
        // 按空白處可以縮鍵盤
        let gestureRecognizer = UITapGestureRecognizer(target: self,action:#selector(keyboardClose))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        
        auto_login()
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
        
        
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        
        change_login_label(login: loginStatus)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification, object: nil)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        view.layoutIfNeeded()
        textField.useUnderline()
    }
    
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        
        coordinator.animate(alongsideTransition: nil) { (_) in
            
            if UIDevice.current.orientation.isLandscape {
                //print("Landscape")
                self.topConstraint.constant = -(self.textField.frame.size.height+self.autocompleteTableView.frame.size.height+10)
                
                //self.heightConstraint.constant = 60
            } else {
                //print("Portrait")
                self.topConstraint.constant = 0
                //self.heightConstraint.constant = 80
            }
            
        }
        
        
        collectionView.reloadData()
    }
    
    
    
    
    // login 按下去，會有放大縮小的效果
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        if loginStatus {
            //self.loginButton.isEnabled = false

        
            let alert = UIAlertController(title: "你目前已經登入囉", message:nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
 
        
            //return
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                
                self.loginButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: { finished in
                
                self.loginButton.transform = CGAffineTransform.identity
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
                loginVC.delegate = self
                
                self.present(loginVC, animated: true, completion: nil)
                
                /*
                 UIView.animate(withDuration: 0.1, animations: {
                 self.loginButton.transform = CGAffineTransform.identity
                 //print("login")
                 
                 //self.performSegue(withIdentifier: Segue_Identifiers.login_segue, sender: nil)
                 
                 
                 let storyboard = UIStoryboard(name: "Main", bundle: nil)
                 let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
                 loginVC.delegate = self
                 
                 self.present(loginVC, animated: true, completion: nil)
                 
                 })
                 */
            })
        }
        
    }
    
    
    func keyboardClose(){
        self.textField.resignFirstResponder()
    }
    
    
    
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        print("\(segue.identifier)")
    //
    //    }
    
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        
        
        self.textField.resignFirstResponder()
        
        if self.textField.text!.isEmpty{
            
            let alert = UIAlertController(title: "尚未輸入任何搜尋關鍵字", message:"請重新輸入搜尋字串", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            searchLogSend(searchStr: self.textField.text!)
            
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            
            //hud.mode = MBProgressHUDMode.annularDeterminate
            hud.label.text = "搜尋中"
            let queue = DispatchQueue.global()
            
            queue.async {
                
                let searchAPI = API_Manager.shared.SEARCH_API_PATH
                
                var searchKeyword = ""
                if self.textField.text!.characters.last == " " || self.textField.text!.characters.last == "\n" || self.textField.text!.characters.last == "\t" {
                    searchKeyword = self.textField.text!.substring(to: self.textField.text!.index(before: self.textField.text!.endIndex))
                } else {
                    searchKeyword = self.textField.text!
                }
                
                //組裝url-string
                let combinedStr = String(format: "%@?t=f&p=1&q=%@", arguments: [searchAPI!, searchKeyword])
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
                            hud.hide(animated: true)
                            let alert = UIAlertController(title: "連線錯誤", message: "請稍後再試", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                            self.present(alert, animated: true, completion:{
                                hud.removeFromSuperview()
                            })
                        }
                        
                    } else {
                        
                        if let data = data, let jsonDictionary = self.parse(json: data) {
                            //print("\(jsonDictionary)")
                            
                            //確定page總數：
                            
                            if self.get_total(dictionary: jsonDictionary) <= 0{
                                
                                DispatchQueue.main.async {
                                    hud.hide(animated: true)
                                    let alert = UIAlertController(title: "查無資料", message: "請嘗試其他關鍵字", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                    self.present(alert, animated: true, completion:{
                                        self.textField.text = ""
                                        hud.removeFromSuperview()
                                    })
                                }
                                
                            } else {
                                DispatchQueue.main.async {
                                    hud.hide(animated: true)
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                    let lsVC = storyboard.instantiateViewController(withIdentifier: "ListViewController") as! ListViewController
                                    lsVC.type = "f"
                                    lsVC.currentPage = 1
                                    lsVC.totalPins = self.get_total(dictionary: jsonDictionary)
                                    lsVC.json_dic = jsonDictionary
                                    lsVC.searchKeyword =  self.textField.text
                                    lsVC.searchAPI_Address = API_Manager.shared.SEARCH_API_PATH
                                    
                                    // 動畫
                                    lsVC.modalPresentationStyle = UIModalPresentationStyle.custom
                                    lsVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                                    self.present(lsVC, animated: true, completion: {
                                        self.textField.text = ""
                                        hud.removeFromSuperview()
                                    })
                                }
                            }
                            
                        } else {
                            
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let alert = UIAlertController(title: "查無資料", message: "請嘗試其他關鍵字", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                self.present(alert, animated: true, completion:{
                                    self.textField.text = ""
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
    
    //****** Parsing ******//
    func parse(json data:Data) -> [String : Any]? {
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch{
            print("JSON Error:\(error)")
            
//            DispatchQueue.main.async {
//                let alert = UIAlertController(title: "查無資料", message: "請再嘗試用其他關鍵字進行搜尋", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
//                self.present(alert, animated: true, completion:nil)
//            }
//            
            
            return nil
        }
        
    }
    
    
    func get_total(dictionary:[String:Any]) -> Int{
        guard let total = dictionary["total"] as? String else {
            return 0
        }
        
        return Int(total)!
    }
    //**********************//
    
    
    
    //******** Network Change notification ********//
    
    func reachabilityChanged(note: NSNotification) {
        
        let reachability = note.object as! Reachability
        
        if reachability.isReachable {
            if reachability.isReachableViaWiFi {
                print("Reachable via WiFi")
                /*
                 let alert = UIAlertController(title: "網路連線方式更動", message: "目前採用WiFi連線", preferredStyle: .alert)
                 alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                 self.present(alert, animated: true, completion: nil)
                 */
            } else {
                print("Reachable via Cellular")
                /*
                 let alert = UIAlertController(title: "網路連線方式更動", message: "目前採用行動網路連線", preferredStyle: .alert)
                 alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                 self.present(alert, animated: true, completion: nil)
                 */
            }
        } else {
            print("Network not reachable")
            /*
             let alert = UIAlertController(title: "網路連線方式更動", message: "網路目前無法連線", preferredStyle: .alert)
             alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
             self.present(alert, animated: true, completion: nil)
             */
            
        }
    }
    
    
    //******** 判斷是否登入 ********//
    
    func change_login_label(login:Bool){
        if login {
            self.loginStatusLabel.text = self.account
        } else {
            self.loginStatusLabel.text = "未登入"
        }
    }
    
    
    //******** 判斷是否能自動登入 ********//
    //
    func auto_login(){
        
        if let recentlyUser = DBManager.shared.checkAccountTable(){
            
            let email = recentlyUser.email
            let password = recentlyUser.password
            
            
            //"latitude", "longitude"
            let latitude = DBManager.shared.get_device_position()["latitude"]!
            let longitude = DBManager.shared.get_device_position()["longitude"]!
            
            //name=UUID node=DeviceName
            let name = DBManager.shared.systemInfo.deviceUUID
            let node = DBManager.shared.systemInfo.deviceName
            
            let combinedStr = String(format: "%@/login?email=%@&pwd=%@&latitude=%@&longtitude=%@&name=%@&node=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, email, password, latitude, longitude, name, node])
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            //print("\(escapedStr)")
            //connectToServer(URLString: escapedStr, Type:"Login")
            let url = URL(string:escapedStr)!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                
                if error != nil{
                
                    print(error.debugDescription)
                } else {
                    if let serverTalkBack = String(data: data!, encoding: String.Encoding.utf8){
                        if serverTalkBack == "0"{
                            //資料有誤！
                            DispatchQueue.main.async {
                                self.loginStatus = false
                            }  
                        } else {
                            let syslog = serverTalkBack
                            
                            //目前時間
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let date = Date()
                            //formatter.string(from: date)
                            
                            
                            
                            //更換account table資料
                            DBManager.shared.update_data(inTable: "accountinfo", column_name: DBManager.shared.field_LoginDate, new_Data: formatter.string(from: date), withReference: DBManager.shared.field_ServerLog, referValue: syslog)

                            // 更換登入狀態
                            DispatchQueue.main.async {
                                self.loginStatus = true
                                self.loginStatusLabel.text = email
                            }
 
                        }
                    }
                }
            }
            task.resume()
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
        print("\(escapedStr)")
        
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
    
    
    
    
    //****************************************//
}



// MARK: Delegate Methods


extension SearchViewController:LoginViewControllerDelegate{
    func sendValue(loginStatus: Bool, value:String) {
        self.loginStatus = loginStatus
        self.account = value
        change_login_label(login: self.loginStatus)
    }
}


extension SearchViewController:UITextFieldDelegate{
    
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

extension SearchViewController:UIGestureRecognizerDelegate{
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
    
}


//MARK: UICollectionViewDelegate Method

extension SearchViewController:UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! SearchCollectionCell
        
        //print("cell selected: \(cell.tag)")
        
        
        //searchLogSend
        
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "類別搜尋中"
        let queue = DispatchQueue.global()
        
        queue.async {
            
            // 背後做事情
            // 呼叫API
            let searchAPI = API_Manager.shared.SEARCH_API_PATH
            let combinedStr = String(format: "%@?t=g&p=1&q=%@", arguments: [searchAPI!, String(cell.tag+1)])
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
                        hud.hide(animated: true)
                        let alert = UIAlertController(title: "連線錯誤", message: "請稍後再試", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                        self.present(alert, animated: true, completion:{
                            self.collectionView.deselectItem(at: indexPath, animated: true)
                            hud.removeFromSuperview()
                        })
                    }
                } else {
                    
                    if let data = data, let jsonDictionary = self.parse(json: data) {
                        //print("\(jsonDictionary)")
                        //確定page總數：
                        if self.get_total(dictionary: jsonDictionary) <= 0{
                            
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let alert = UIAlertController(title: "查無相關資料", message: "請嘗試其他類別", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                self.present(alert, animated: true, completion:{
                                    //self.textField.text = ""
                                    self.collectionView.deselectItem(at: indexPath, animated: true)
                                    hud.removeFromSuperview()
                                })
                            }
                        } else {
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let lsVC = storyboard.instantiateViewController(withIdentifier: "ListViewController") as! ListViewController
                                
                                lsVC.type = "g"
                                lsVC.currentPage = 1
                                lsVC.totalPins = self.get_total(dictionary: jsonDictionary)
                                lsVC.json_dic = jsonDictionary
                                lsVC.searchKeyword =  String(cell.tag+1)
                                lsVC.searchAPI_Address = API_Manager.shared.SEARCH_API_PATH
                                
                                // 動畫
                                lsVC.modalPresentationStyle = UIModalPresentationStyle.custom
                                lsVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                                self.present(lsVC, animated: true, completion: {
                                    self.collectionView.deselectItem(at: indexPath, animated: true)
                                    hud.removeFromSuperview()
                                })
                            }
                        }
                    } else {
                        
                        DispatchQueue.main.async {
                            hud.hide(animated: true)
                            let alert = UIAlertController(title: "無法獲得搜尋結果", message: "請重新搜尋", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                            self.present(alert, animated: true, completion:{
                                hud.removeFromSuperview()
                            })
                        }
                    }
                    
                }
            }
            
            task.resume()

        }
        
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! SearchCollectionCell
        
        cell.backgroundColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5)
        //cell.layer.borderWidth = 2.0
        //cell.layer.borderColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5).cgColor
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        
        
        let cell = collectionView.cellForItem(at: indexPath) as! SearchCollectionCell
        cell.backgroundColor = UIColor.white
        //cell.layer.borderWidth = 0
        //cell.layer.borderColor = UIColor.white.cgColor
        
    }
    
    
}



//MARK: UICollectionViewDatasource Method
extension SearchViewController:UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchTypes.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCollectionCell", for: indexPath) as! SearchCollectionCell
        
        cell.tag = indexPath.row
        
        cell.searchTypeLabel.text = searchTypes[indexPath.row]
        
        return cell
    }
    
    
}


//MARK: UICollectionViewDelegateFlowLayout Method
extension SearchViewController:UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.collectionView.frame.size.width, height: 44)
        
    }
    
}



//MARK: UITableViewDelegate and DataSource methods
extension SearchViewController:UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autocompleteItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12.0)
        cell.textLabel?.text = autocompleteItems[indexPath.row]
        
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.textField.resignFirstResponder()
        self.autocompleteTableView.isHidden = true
        
        if autoCompleteTask != nil{
            autoCompleteTask.cancel()
        }
        
        self.textField.text = self.autocompleteItems[indexPath.row]
        self.searchLogSend(searchStr: self.textField.text!)
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "搜尋中"
        
        let queue = DispatchQueue.global()
        queue.async {
            
            let searchAPI = API_Manager.shared.SEARCH_API_PATH
            let searchKeyword = self.autocompleteItems[indexPath.row].components(separatedBy: "\t").first
            let no_space_and_getFirstWord = searchKeyword!.components(separatedBy: " ").first
            
            //組裝url-string
            
            let combinedStr = String(format: "%@?t=f&p=1&q=%@", arguments: [searchAPI!, no_space_and_getFirstWord!])
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            print("\(escapedStr)")
            //connectToServer(URLString: escapedStr, Type:"Login")
            
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
                        hud.hide(animated: true)
                        let alert = UIAlertController(title: "連線錯誤", message: "請稍後再試", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                        self.present(alert, animated: true, completion:{
                            self.textField.text = ""
                            hud.removeFromSuperview()
                        })
                    }
                } else {
                    if let data = data, let jsonDictionary = self.parse(json: data) {
                        //print("\(jsonDictionary)")
                        
                        //確定page總數：
                        if self.get_total(dictionary: jsonDictionary) <= 0{
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let alert = UIAlertController(title: "查無資料", message: "請嘗試其他關鍵字", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                self.present(alert, animated: true, completion:{
                                    self.textField.text = ""
                                    hud.removeFromSuperview()
                                })
                            }
                        } else {
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let lsVC = storyboard.instantiateViewController(withIdentifier: "ListViewController") as! ListViewController
                                lsVC.type = "f"
                                lsVC.currentPage = 1
                                lsVC.totalPins = self.get_total(dictionary: jsonDictionary)
                                lsVC.json_dic = jsonDictionary
                                lsVC.searchKeyword =  no_space_and_getFirstWord!
                                lsVC.searchAPI_Address = API_Manager.shared.SEARCH_API_PATH
                                // 動畫
                                lsVC.modalPresentationStyle = UIModalPresentationStyle.custom
                                lsVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                                self.present(lsVC, animated: true, completion: {
                                    self.textField.text = ""
                                    hud.removeFromSuperview()
                                })
                            }
                        }
                    } else {
                        
                        DispatchQueue.main.async {
                            hud.hide(animated: true)
                            let alert = UIAlertController(title: "無法獲得搜尋結果", message: "請重新搜尋", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                            self.present(alert, animated: true, completion:{
                                self.textField.text = ""
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


// syslog
extension UIViewController{

    func searchLogSend(searchStr: String){
        //要用post
        //"latitude", "longitude"
        let latitude = DBManager.shared.get_device_position()["latitude"]!
        let longitude = DBManager.shared.get_device_position()["longitude"]!
        
        //name=UUID
        let name = DBManager.shared.systemInfo.deviceUUID
        
        let combinedStr = String(format: "%@/syslog?deviceid=%@&latitude=%@&longtitude=%@&key=query&value=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, name, latitude, longitude, searchStr])
        let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        print("\(escapedStr)")

        let url = URL(string:escapedStr)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
            if error != nil{
                print(error.debugDescription)
            } else{
                if let serverTalkBack = String(data: data!, encoding: String.Encoding.utf8){
                    print("\(serverTalkBack)")
                } else {
                    print("error")
                }
            }
        }
        task.resume()
    }


}




// MARK: UITextfield EXTENSION METHODS

extension UITextField {
    
    func useUnderline() {
        
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor.gray.cgColor
        
        //        let screenRect = UIScreen.main.bounds
        //        let screenWidth = screenRect.size.width
        //        let screenHeight = screenRect.size.height
        
        
        border.frame = CGRect(x: 0, y: (self.frame.size.height - borderWidth), width: self.frame.size.width, height: self.frame.size.height)
        border.borderWidth = borderWidth
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}



// MARK: CONSTANTS


struct Segue_Identifiers{
    static let login_segue = "login_segue"
}



struct CellID{
    static let list_cell = "ListCell"
    static let manufacturer_cell = "ManufacturerCell"
    static let spec_cell = "SpecCell"
    static let price_cell = "PriceTitleCell"
    static let value_cell = "PriceValueCell"
    
}
