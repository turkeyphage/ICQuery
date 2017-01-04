//
//  LoginViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/6.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit
import QuartzCore

class LoginViewController: UIViewController {
    
    //delegate
    var delegate : LoginViewControllerDelegate!
    
    // scrollView
    @IBOutlet weak var theScrollView: UIScrollView!
    
    
    deinit {
        print("deinit of LoginViewController")
    }
    
    
    var offset: CGFloat = 0.0 {
        // offset的值時，執行didSet
        didSet {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.theScrollView.contentOffset = CGPoint(x: self.offset, y: 0.0)
            })
        }
    }
    
    
    
    //login Pop-up view
    @IBOutlet weak var login_popview: UIView!
    //@IBOutlet weak var member_label: UILabel!
    @IBOutlet weak var login_button: UIButton!
    
    @IBOutlet weak var login_email_textField: UITextField!
    
    @IBOutlet weak var login_password_textField: UITextField!
    
    
    
    //forget password Pop-up view
    
    @IBOutlet weak var forget_popview: UIView!
    
    @IBOutlet weak var forget_email_textField: UITextField!
    
    @IBOutlet weak var reset_password_button: UIButton!
    
    
    //register Pop-up view
    
    @IBOutlet weak var register_popview: UIView!
    @IBOutlet weak var register_email_textField: UITextField!
    
    @IBOutlet weak var register_password_textField: UITextField!
    
    @IBOutlet weak var register_reenter_password_textField: UITextField!
    
    
    @IBOutlet weak var register_button: UIButton!

    @IBOutlet weak var original_top_constraint: NSLayoutConstraint!
    
    var original_constraint_constant : CGFloat = 35.0
    

    override func viewDidLoad() {
        super.viewDidLoad()
 
        //gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(close))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        
        //button 圓角
        login_button.layer.cornerRadius = 5
        reset_password_button.layer.cornerRadius = 5
        register_button.layer.cornerRadius = 5


        //print("\(API_Manager.shared.DEVICE_API_PATH)")
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    
    
    // *********** don't let keyboard cover textfield ***********
    
    func keyboardWillShow(_ notification: Notification) {
        for whichview in self.login_popview.subviews{
            if whichview.isFirstResponder{
                //print("whichviewTag = \(whichview.tag)")
                if let userInfo = notification.userInfo {
                    if let keyboardSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

                        let dist = (whichview.frame.origin.y + whichview.frame.size.height + original_constraint_constant) - keyboardSize.origin.y

                        if dist > 0 {
                                let newConstant = original_constraint_constant - dist - 70
                                original_top_constraint.constant = newConstant
                                return
                        } else {}
                    }
                }
            }
        }

        for whichview in self.forget_popview.subviews{
            if whichview.isFirstResponder{
                //print("whichviewTag = \(whichview.tag)")
                if let userInfo = notification.userInfo {
                    if let keyboardSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

                        let dist = (whichview.frame.origin.y + whichview.frame.size.height+original_constraint_constant) - keyboardSize.origin.y
        
                        if dist > 0 {
                            let newConstant = original_constraint_constant - dist - 70
                            original_top_constraint.constant = newConstant
                            return
                        } else {
                        }
                    }
                }
            }
        }
        
        for whichview in self.register_popview.subviews{
            if whichview.isFirstResponder{
                //print("whichviewTag = \(whichview.tag)")
                if let userInfo = notification.userInfo {
                    if let keyboardSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

                        let dist = (whichview.frame.origin.y + whichview.frame.size.height+original_constraint_constant) - keyboardSize.origin.y
                        
                        if dist > 0 {
                            let newConstant = original_constraint_constant - dist - 70
                            original_top_constraint.constant = newConstant
                            return
                        } else {
                        }
                    }
                }
            }
        }
        
    
    
    }
    
    func keyboardWillHide(_ notification: Notification){
        original_top_constraint.constant = original_constraint_constant
    }
    
 
    // login pop-up view button_action methods
    // 登入 pressed
    @IBAction func login(_ sender: Any) {
        
        for whichview in self.login_popview.subviews{
            if whichview.isFirstResponder{
                whichview.resignFirstResponder()
            }
        }

        if self.login_email_textField.text! != "", self.login_password_textField.text! != ""{
            
            //email,pwd,latitude,longtitude,name,node
            let email = self.login_email_textField.text!
            let password = self.login_password_textField.text!
            
            //"latitude", "longitude"
            let latitude = DBManager.shared.get_device_position()["latitude"]!
            let longitude = DBManager.shared.get_device_position()["longitude"]!
            
            //name=UUID node=DeviceName
            let name = DBManager.shared.systemInfo.deviceUUID
            let node = DBManager.shared.systemInfo.deviceName
            
            let combinedStr = String(format: "%@/login?email=%@&pwd=%@&latitude=%@&longtitude=%@&name=%@&node=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, email, password, latitude, longitude, name, node])
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            //print("\(escapedStr)")
            connectToServer(URLString: escapedStr, Type:"Login")
        } else {
            
            var alertMessage = ""
            if self.login_password_textField.text == ""{
                alertMessage = "密碼尚未填入"
            } else if self.login_email_textField.text == ""{
                alertMessage = "Email尚未填入"
            } else if self.login_email_textField.text == "", self.login_password_textField.text == ""{
                alertMessage = "Email與密碼皆未填入"
            }
            
            let alert = UIAlertController(title: "WOO! 資料未填寫完全", message: alertMessage,     preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

    }
    //忘記密碼 pressed
    @IBAction func forget_password(_ sender: Any) {
            offset = -(self.theScrollView.frame.size.width)
    }
    
    //加入會員 pressed
    @IBAction func sign_up_member(_ sender: Any) {
            offset = self.theScrollView.frame.size.width
    }
    
    
    // forget password pop-up view button_action methods
    //重設密碼 pressed
    @IBAction func reset_password(_ sender: Any) {
        
        for whichview in self.forget_popview.subviews{
            if whichview.isFirstResponder{
                whichview.resignFirstResponder()
            }
        }
        
        if self.forget_email_textField.text! != ""{
            
            //email,pwd,latitude,longtitude,name,node
            let email = self.forget_email_textField.text!
            
            
            //"latitude", "longitude"
            let latitude = DBManager.shared.get_device_position()["latitude"]!
            let longitude = DBManager.shared.get_device_position()["longitude"]!
            
            //name=UUID node=DeviceName
            let name = DBManager.shared.systemInfo.deviceUUID
            let node = DBManager.shared.systemInfo.deviceName
            
            let combinedStr = String(format: "%@/reset?email=%@&latitude=%@&longtitude=%@&name=%@&node=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, email, latitude, longitude, name, node])
            let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            print("\(escapedStr)")
            connectToServer(URLString: escapedStr, Type:"Reset")
        } else {
            
            let alertMessage = "Email尚未填入"
            let alert = UIAlertController(title: "WOO! 資料未填寫完全", message: alertMessage,     preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
 
    }
  
    
    
    //註冊會員 pressed
    // register pop-up view button_action methods
    @IBAction func register_now(_ sender: Any) {
        
        for whichview in self.register_popview.subviews{
            if whichview.isFirstResponder{
                whichview.resignFirstResponder()
            }
        }

        if self.register_email_textField.text != "", self.register_password_textField.text != "", self.register_reenter_password_textField.text != "" {
            
            // 檢查email格式是否正確：
            if isValidEmail(testStr: self.register_email_textField.text!){
                
                // 確認password是否相同？
                if self.register_password_textField.text != register_reenter_password_textField.text{
                    // 密碼輸入錯誤
                    let alert = UIAlertController(title: "密碼輸入錯誤", message: "請再次確認輸入的密碼是否正確",     preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    //email,pwd,latitude,longtitude,name,node
                    let email = self.register_email_textField.text!
                    let password = self.register_password_textField.text!
                    
                    //"latitude", "longitude"
                    let latitude = DBManager.shared.get_device_position()["latitude"]!
                    let longitude = DBManager.shared.get_device_position()["longitude"]!
                    
                    //name=UUID node=DeviceName
                    let name = DBManager.shared.systemInfo.deviceUUID
                    let node = DBManager.shared.systemInfo.deviceName
                    
                    
                    let combinedStr = String(format: "%@/signin?email=%@&pwd=%@&latitude=%@&longtitude=%@&name=%@&node=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, email, password, latitude, longitude, name, node])
                    let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                    print("\(escapedStr)")
                    connectToServer(URLString: escapedStr, Type: "Register")
                }
                
            } else {
                
                let alert = UIAlertController(title: "Email格式錯誤", message: "請再次檢查輸入的Email是否正確",     preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            
            }
            
        } else {
        
            var alertMessage = ""
            if self.register_password_textField.text == "" || self.register_reenter_password_textField.text == "" {
                alertMessage = "密碼尚未填入"
            } else if self.register_email_textField.text == "" {
                alertMessage = "Email尚未填入"
            } else if self.register_password_textField.text == "", self.register_email_textField.text == "", self.register_reenter_password_textField.text == "" {
                alertMessage = "所有表格都還沒填寫喔！"
            }
            
            let alert = UIAlertController(title: "WOO! 資料未填寫完全", message: alertMessage,     preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

    }
    
    
    func close(){
        dismiss(animated: true, completion: nil)
    }
    


    //login確認
    func connectToServer(URLString: String, Type: String) {
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        //hud.mode = MBProgressHUDMode.annularDeterminate
        hud.label.text = "連線中，請稍候"
        
        let queue = DispatchQueue.global()
        
        queue.async {
            
            let url = URL(string:URLString)!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                
                if error != nil{
                    print(error.debugDescription)
                    
                    DispatchQueue.main.async {
                        hud.hide(animated: true)
                        let alert = UIAlertController(title: "連線失敗", message: "伺服器連線失敗，請稍後再試", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: {
                            hud.removeFromSuperview()
                        })
                    }
                    
                    
                    
                    
                }else{
                    if let serverTalkBack = String(data: data!, encoding: String.Encoding.utf8){
                        if serverTalkBack == "0"{
                            //資料有誤！
                            
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let alert = UIAlertController(title: "登入失敗", message: "請再次確認填入帳號與密碼是否正確", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(alert, animated: true, completion: {
                                    self.login_email_textField.text = ""
                                    self.login_password_textField.text = ""
                                    hud.removeFromSuperview()
                                })
                            }
                            
                        } else if serverTalkBack == "ERR: email registed" {
                            
                            DispatchQueue.main.async {
                                hud.hide(animated: true)
                                let alert = UIAlertController(title: "該Email已註冊過", message: "請使用有效的Email", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(alert, animated: true, completion: {
                                    
                                    self.register_email_textField.text = ""
                                    self.register_password_textField.text = ""
                                    self.register_reenter_password_textField.text = ""
                                    hud.removeFromSuperview()
                                })
                            }
                            
                        } else {
                            
                            //print("\(serverTalkBack)")
                            
                            //登入成功
                            if Type == "Login"{
                                
                                DispatchQueue.main.async {
                                    hud.hide(animated: true)
                                    self.delegate?.sendValue(loginStatus: true, value: [self.login_email_textField.text!, serverTalkBack])
                                    
                                    
                                    //查詢是否有這筆資料

                                    if DBManager.shared.checkDataAvailable(searchTable: "accountinfo", searchStr: serverTalkBack){
                                        // 有->更新
                                        // 密碼
                                        DBManager.shared.update_data(inTable: "accountinfo", column_name: DBManager.shared.field_UserPassword, new_Data: self.login_password_textField.text!, withReference: DBManager.shared.field_ServerLog, referValue: serverTalkBack)
                                        // 登入日期
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                        let date = Date()
                                        DBManager.shared.update_data(inTable: "accountinfo", column_name: DBManager.shared.field_LoginDate, new_Data: formatter.string(from: date), withReference: DBManager.shared.field_ServerLog, referValue: serverTalkBack)
                                    } else {
                                        // 無->新增
                                        DBManager.shared.insert_accountInfo_Data(syslog: serverTalkBack, email: self.login_email_textField.text!, password: self.login_password_textField.text!)
                                    }
                                    
                                    
                                    
                                    self.close()
                                
                                }
                            } else if Type == "Register" {
                                
                                DispatchQueue.main.async {
                                    hud.hide(animated: true)
                                    
                                    
                                    DBManager.shared.insert_accountInfo_Data(syslog: serverTalkBack, email: self.register_email_textField.text!, password: self.register_password_textField.text!)
                                    
                                    self.delegate?.sendValue(loginStatus: true, value: [self.register_email_textField.text!, serverTalkBack])
                                    
                                    self.close()
                                    
                                }
                                
                            } else {
                                
                                if serverTalkBack == ""{
                                    // 找不到該email
                                    
                                    DispatchQueue.main.async {
                                        hud.hide(animated: true)
                                        let alert = UIAlertController(title: "此Email尚未註冊會員", message: "請重新輸入Email帳號", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style:.default, handler:nil))
                                        //self.present(alert, animated: true, completion: nil)
                                        self.present(alert, animated: true, completion: {
                                            self.forget_email_textField.text = ""
                                            hud.removeFromSuperview()
                                        })
                                    }
                                    
                                } else {
                                    DispatchQueue.main.async {
                                        hud.hide(animated: true)
                                        let alert = UIAlertController(title: "密碼已重新設定", message: "請使用新密碼重新登入", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style:.default, handler: { (action) in
                                            
                                            self.close()
                                        }))
                                        self.present(alert, animated: true, completion: nil)
                                    }
                                }
                                
                            }
                            
                        }
                    }
                }
            }
            
            task.resume()

        
        }
        
        
        
    }
    
  
}



// MARK: Protocal for sending data back


protocol LoginViewControllerDelegate{

    func sendValue(loginStatus:Bool, value:[String])

}







// MARK:UIViewControllerTransitionDelegate Methods
extension LoginViewController: UIViewControllerTransitioningDelegate{
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}

// MARK:UITextFieldDelegate Methods

extension LoginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension LoginViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
}



// MARK: Email format check function
extension LoginViewController{
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
