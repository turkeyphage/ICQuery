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


    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        // 按空白處可以縮鍵盤
        let gestureRecognizer = UITapGestureRecognizer(target: self,action:#selector(keyboardClose))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        //textField.becomeFirstResponder()

        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        
//        print("\(DBManager.shared.get_device_name())")
//        print("\(DBManager.shared.get_system_version())")
//        print("\(DBManager.shared.get_device_uuid())")
//        
//    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print("\(DBManager.shared.get_device_position())")
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
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
    
        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
            
            self.loginButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { finished in
            
            UIView.animate(withDuration: 0.1, animations: {
                self.loginButton.transform = CGAffineTransform.identity
                //print("login")
                
                //self.performSegue(withIdentifier: Segue_Identifiers.login_segue, sender: nil)
                
            })
        })

        
        
        
        
    }

    
    func keyboardClose(){
        self.textField.resignFirstResponder()
    }

    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("\(segue.identifier)")
        
        
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




struct Segue_Identifiers{
    static let login_segue = "login_segue"
}



struct CellID{
    static let list_cell = "ListCell"

}
