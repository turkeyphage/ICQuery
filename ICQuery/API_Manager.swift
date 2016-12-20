//
//  API_Manager.swift
//  ICQuery
//
//  Created by Roger on 2016/12/20.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class API_Manager: NSObject {

    
    static let shared: API_Manager = API_Manager()
    
    let API_retrive_path = "https://www.icquery.com/usermanager/api.php/list"
    
    var CURRENT_RATE_PATH:String! = "http://asper-bot-rates.appspot.com/currency.json"
    var DEVICE_API_PATH:String! = "https://www.icquery.com/usermanager/api.php"
    var PARSER_API_PATH:String! = "https://www.icquery.com/api/v1/"
    var SEARCH_API_PATH:String! = "https://www.icquery.com/fm/portal"
    
    
    override init() {
        super.init()
        
        
        
    }

    
    /******* post *******/
    func dataRequest() {
        
        let url = URL(string: self.API_retrive_path)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared

        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in

            if error != nil{
                print(error.debugDescription)
            }else{
                if let str = String(data: data!, encoding: String.Encoding.utf8){
                    self.get_api_address(str: str)
                }
            }
        }
        
        task.resume()
    }

    
    
    
    private func get_api_address(str: String){
        
        //刪除 “\\”
        let removeSlash = str.replacingOccurrences(of: "\\", with: "")
        //刪除 “[” 和 “,null” 和 “]”
        let removeLeftBracket = removeSlash.replacingOccurrences(of: "[", with: "")
        let removeRightBracket = removeLeftBracket.replacingOccurrences(of: "]", with: "")
        let removeNull = removeRightBracket.replacingOccurrences(of: ",null", with: "")
        
        // 以 "}," 去切斷
        let splitResult = removeNull.components(separatedBy: "},")
        
        
        var firstCleaner : [String] = []
        
        for item1 in splitResult{
            // 刪除 “{” 和 “}”
            let removeLeftBrac = item1.replacingOccurrences(of: "{", with: "")
            let removeRightBrac = removeLeftBrac.replacingOccurrences(of: "}", with: "")
            firstCleaner.append(removeRightBrac)
        }
        
        var finalResult = [String:String]()
        
        for item2 in firstCleaner{
            //print("\(item2)")
            let splitByComma = item2.components(separatedBy: ",")
            print("\(splitByComma)")
            
            let removeKey = splitByComma.first?.replacingOccurrences(of: "\"key\":", with: "")
            let key = removeKey?.replacingOccurrences(of: "\"", with: "")
            let removeValue = splitByComma.last?.replacingOccurrences(of: "\"value\":", with: "")
            let value = removeValue?.replacingOccurrences(of: "\"", with: "")
            finalResult[key!] = value
        }
        
        self.CURRENT_RATE_PATH = finalResult["CURRENT_RATE"]
        self.PARSER_API_PATH = finalResult["PARSER_API"]
        self.SEARCH_API_PATH = finalResult["SEARCH_API"]
        self.DEVICE_API_PATH = finalResult["DEVICE_API"]
        
        
        //print("\(finalResult)")
    }

    
    
    
    
}
