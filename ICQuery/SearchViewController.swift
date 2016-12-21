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
    
    var account : String!
    
    var loginStatus:Bool = false {
        didSet {
            change_login_label(login: loginStatus)
        }
    }
    
    let reachability = Reachability()!
    
    
    
    deinit {
        print("deinit of SearchViewController")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 按空白處可以縮鍵盤
        let gestureRecognizer = UITapGestureRecognizer(target: self,action:#selector(keyboardClose))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        
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
        
        if self.textField.text!.isEmpty{
        
            let alert = UIAlertController(title: "尚未輸入任何搜尋關鍵字", message:"請重新輸入搜尋字串", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        
        } else {
            
            let searchAPI = API_Manager.shared.SEARCH_API_PATH
            let searchKeyword = self.textField.text!.components(separatedBy: "\t").first
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
            
            
            
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
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
                        //print("\(jsonDictionary)")
                        DispatchQueue.main.async {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let lsVC = storyboard.instantiateViewController(withIdentifier: "ListViewController") as! ListViewController
                            
                            lsVC.json_dic = jsonDictionary
                            // 動畫
                            lsVC.modalPresentationStyle = UIModalPresentationStyle.custom
                            lsVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                            self.present(lsVC, animated: true, completion: nil)
                        }
                    }
                    
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
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "JSON解析錯誤", message: "請再嘗試用其他關鍵字進行搜尋", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                self.present(alert, animated: true, completion:nil)
            }
            
            
            return nil
        }
        
    }
    
    
    
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
        return true
    }
    
}

extension SearchViewController:UIGestureRecognizerDelegate{
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
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
    
}
