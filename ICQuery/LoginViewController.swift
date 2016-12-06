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
    
    
    
    @IBOutlet weak var login_popview: UIView!
    
    @IBOutlet weak var member_label: UILabel!
    @IBOutlet weak var login_button: UIButton!
    
    @IBOutlet weak var email_textField: UITextField!
    
    @IBOutlet weak var password_textField: UITextField!
    
    @IBOutlet weak var original_top_constraint: NSLayoutConstraint!
    var original_constraint_constant : CGFloat = 35.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        login_popview.layer.cornerRadius = 10
        login_button.layer.cornerRadius = 5
        
        let maskPath = UIBezierPath(roundedRect: member_label.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 9.0, height: 9.0))
        
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        member_label.layer.mask = shape
        
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
                        
                        print("whichview frame origin y: \(whichview.frame.origin.y)")
                        print("keyboard frame origin y: \(keyboardSize.origin.y)")
                        let dist = whichview.frame.origin.y - keyboardSize.origin.y

                        if dist > 0 {
                                let newConstant = original_constraint_constant - dist - 70
                                original_top_constraint.constant = newConstant
                        }
                    }
                }
            }
        }
    }
    
    func keyboardWillHide(_ notification: Notification){
        original_top_constraint.constant = original_constraint_constant
    }
    
    
    
    
    
    
    
    
    
    
    
}



extension LoginViewController: UIViewControllerTransitioningDelegate{
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}


extension LoginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
