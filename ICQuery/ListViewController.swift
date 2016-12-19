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
    
    

}



extension ListViewController:UITableViewDataSource{

    func numberOfSections(in tableView: UITableView) -> Int {
            return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView.dequeueReusableCell(withIdentifier: CellID.list_cell, for: indexPath) as! ListTableViewCell
        
        cell.itemImageView.image = UIImage(named: "logo_120_120")
        
        cell.companyNameLabel.text = "Texas Instruments"
        cell.modelNameLabel.text = "LM555"
        cell.typeLabel.text = "oscillation && timer"
        cell.detailLabel.text = "Output Can Source or Sink 200 mA, Temperature Stability Better than 0.005% per °C"
        return cell
        
    }
    
}

extension ListViewController:UITableViewDelegate{


}

