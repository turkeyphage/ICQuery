//
//  ProductDetail.swift
//  ICQuery
//
//  Created by Roger on 2016/12/22.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

struct ProductDetail {

    var pn : String = ""
    var mfs : String = ""
    
    
    var picurl : String = ""
    var catagory : String = ""
    var desc : String = ""
    var list : [[String:Any]] = [[:]]
    
    
    
}


struct SupplierDetail{
    
    var id : String = ""
    var pn : String = ""
    var sku : String = ""
    var mfs : String = ""
    var sup : String = ""
    var url : String = ""
    var amount : Int = 0
    var cur : String = ""
    var picurl : String = ""
    var docurl : String = ""
    var spec : [String:String] = [String:String]()
    var desc:String = ""
    var catagory = ""
    var price : [String:String] = [String:String]()
}
