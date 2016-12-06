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

    
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        
//    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
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
