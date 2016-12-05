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
    
    var activeField: UITextField?
    
    var kbHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //textField.becomeFirstResponder()
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        textField.useUnderline()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
//    func registerForKeyboardNotifications()
//    {
//        
//        //Adding notifies on keyboard appearing
//        NotificationCenter.default.addObserver(self, selector: Selector("keyboardWillShow:"), name: .UIKeyboardWillShow, object: nil)
//        
//        
//        NotificationCenter.default.addObserver(self, selector: Selector("keyboardWillBeHidden:"), name: .UIKeyboardWillHide, object: nil)
//
//    }
    

    
//    func keyboardWillShow(notification:NSNotification){
//        if let userInfo = notification.userInfo {
//            
//            
//            if let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue?.cgrect.valu
//            
//            //if let keyboardSize =  (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//              //  kbHeight = keyboardSize.height
//                //self.animateTextField(true)
//            //}
//        }
//    
//    }
//    
    
    
    
    
    
//    
//    func deregisterFromKeyboardNotifications()
//    {
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
//      
//    }
//    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
    }
    
    
//    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//
//        
//    }
    
}





extension SearchViewController:UITextFieldDelegate{

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}


extension UITextField {
    
    func useUnderline() {
        
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor.gray.cgColor

        border.frame = CGRect(x: 0, y: (self.frame.size.height - borderWidth), width: self.frame.size.width, height: self.frame.size.height)
        border.borderWidth = borderWidth
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}
