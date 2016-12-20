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


        
        
        
        
        //        login_popview.layer.cornerRadius = 10
//        let maskPath = UIBezierPath(roundedRect: member_label.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 9.0, height: 9.0))
//        
//        let shape = CAShapeLayer()
//        shape.path = maskPath.cgPath
//        member_label.layer.mask = shape
        
        //member_label.layer.masksToBounds = true
        //member_label.layer.cornerRadius = 10
        
        
        
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
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
                print("whichviewTag = \(whichview.tag)")
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
                print("whichviewTag = \(whichview.tag)")
                if let userInfo = notification.userInfo {
                    if let keyboardSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

                        
                        print("whichview.frame.origin.y = \(whichview.frame.origin.y)")
                        print("whichview.frame.size.height = \(whichview.frame.size.height)")
                        print("keyboardSize.origin.y = \(keyboardSize.origin.y)")
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
                print("whichviewTag = \(whichview.tag)")
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
        
        delegate?.sendValue(loginStatus: true)
        dismiss(animated: true, completion: nil)
        
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
        
        
    }
    
    //註冊會員 pressed
    // register pop-up view button_action methods
    @IBAction func register_now(_ sender: Any) {
        
        
    }
    
    
    func close(){
        dismiss(animated: true, completion: nil)
    }
    

}



// Mark: Protocal for sending data back


protocol LoginViewControllerDelegate{

    func sendValue(loginStatus:Bool)

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

