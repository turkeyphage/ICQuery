//
//  ListViewController.swift
//  ICQuery
//
//  Created by Roger on 2016/12/7.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class ListViewController: UIViewController{


    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var listTableView: UITableView!
    
    @IBOutlet weak var title_background_view: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let placeholderStr = NSAttributedString(string: "請輸入查詢資料", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
        searchTextField.attributedPlaceholder = placeholderStr
        listTableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)

        // 上面的背景顏色
        title_background_view.backgroundColor = UIColor(patternImage: UIImage(named: "background_pattern")!)
        
        //status bar 背景顏色
//        let app = UIApplication.shared
//        let statusBarHeight = app.statusBarFrame.size.height
//        let statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: statusBarHeight))
//        statusBarView.backgroundColor = UIColor(patternImage: UIImage(named: "background_pattern")!)
//
//        self.view.addSubview(statusBarView)
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
    
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
 
}
