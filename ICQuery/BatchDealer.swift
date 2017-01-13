//
//  BatchDealer.swift
//  ICQuery
//
//  Created by Roger on 2017/1/10.
//  Copyright © 2017年 ICQuery. All rights reserved.
//

import UIKit
import SwiftHTTP


class BatchDealer: NSObject {
    
    var batchURL = [String]()
    
    //static let shared: BatchDealer = BatchDealer()

    override init() {
        super.init()
        getBatchURL()
    }
    
    
    func getBatchURL(){
        weak var weakSelf = self
        
        //取batchID
        let escapedStr = String(format: "%@/get_new_batch?name=%@&pwd=%@&sid=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, "sammy", "sammy123", "0"]).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        //print("\(escapedStr)")
        
        let url = URL(string:escapedStr)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
            if error != nil{
                print(error.debugDescription)
            } else{
                if let batchID = String(data: data!, encoding: String.Encoding.utf8){
                
                    print("\(batchID)")
                    //取batchHTML
                    
                    let getBatchHTMLStr = String(format: "%@/getBatchHtml?deviceid=%@&batch_id=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, DBManager.shared.systemInfo.deviceUUID, batchID]).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                    //print("\(getBatchHTMLStr)")
                    let url2 = URL(string:getBatchHTMLStr)!
                    
                    var request2 = URLRequest(url: url2)
                    request2.httpMethod = "POST"
                    
                    let session2 = URLSession.shared
                    let task2 = session2.dataTask(with: request2 as URLRequest) { data, response, error in
                        
                        if error != nil{
                            print(error.debugDescription)
                        } else{
                            if let data = data, let jsonDictionary = weakSelf?.parse(json: data) {
                                //print("\(jsonDictionary)")
                                
                                if let list = jsonDictionary["list"] as? [Any]{
                                    
                                    var allURL = [String]()
                                    for item in list {
                                        if let each = item as? [String:Any]{
                                            if let eachURL = each["url"] as? String{
                                                 allURL.append(eachURL)
                                            }
                                        }
                                    }
                                    //print("\(allURL)")
                                    weakSelf?.batchURL = allURL
                                    
                                    if !(weakSelf?.batchURL.isEmpty)!{
                                        for eachURL in (weakSelf?.batchURL)!{
                                            weakSelf?.connectToBatchAPI(urlStr:eachURL)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    task2.resume()
                }
            }
        }
        task.resume()
    }
    
    
    
    
    deinit{
        
        print("object BatchDealer remove")
    
    }

    
    
    func connectToBatchAPI(urlStr:String){
        
        
        DispatchQueue.global().async {
            weak var weakSelf = self
            
            // get batchID
            
            //取batchID
            let escapedStr = String(format: "%@/get_new_batch?name=%@&pwd=%@&sid=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, "sammy", "sammy123", "0"]).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            //print("\(escapedStr)")
            
            let url = URL(string:escapedStr)!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                
                if error != nil{
                    print(error.debugDescription)
                } else{
                    
                    if let batchID = String(data: data!, encoding: String.Encoding.utf8){
                        //print("\(batchID)")
                        
                        //取得HTML
                        let htmlURL = URL(string:urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
                        let htmlRequest = URLRequest(url: htmlURL)
                        let htmlSession = URLSession.shared
                        let task1 = htmlSession.dataTask(with: htmlRequest as URLRequest) { data, response, error in
                            if error != nil{
                                print("error happend on getting html: \(error)")
                            } else {
                                
                                if let serverTalkBack1 = String(data: data!, encoding: String.Encoding.utf8){
                                    let webData = serverTalkBack1.data(using: String.Encoding.utf8)
                                    
                                    let web64Encode = webData?.base64EncodedString()
                                    
                                    if DBManager.shared.getIFAddresses().isEmpty{
                                        print("no-connection")
                                        
                                    } else {
                                        
                                        //連接Alin API
                                        //包成一個 json
                                        
                                        let ip = DBManager.shared.getIFAddresses().first
                                        let dic = ["data":[["url":urlStr, "html":web64Encode]], "ip":ip, "uuid": DBManager.shared.systemInfo.deviceUUID, "batchId": batchID] as [String: Any?]
                                        
                                        //print("dic = \(dic)")
                                        
                                        let batchEscapedStr = String(format: "%@batch/parsers", arguments: [API_Manager.shared.PARSER_API_PATH]).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                                        //print("\(batchEscapedStr)")
                                        
                                        do {
                                            let opt = try HTTP.POST(batchEscapedStr, parameters: dic)
                                            opt.start { response in
                                                if let err = response.error {
                                                    print("response error: \(err.localizedDescription)")
                                                }
                                                
                                                if let jsonDictionary = weakSelf?.parse(json: response.data) {
                                                    
                                                    if let success = jsonDictionary["success"] as? Bool{
                                                        if success == true{
                                                            print("URL:\(urlStr), success!")
                                                            
                                                            //                                                        print("supplier = \(weakSelf?.supplier)")
                                                            let value = "\(batchID)+\(urlStr)+1"
                                                            //print("\(value)")
                                                            weakSelf?.searchLogSend(searchStr: value, key: "batch")
                                                            
                                                            
                                                            
                                                            
                                                        } else {
                                                            print("batch failed")
                                                            let value = "\(batchID)+\(urlStr)+0"
                                                            //print("\(value)")
                                                            weakSelf?.searchLogSend(searchStr: value, key: "batch")
                                                        }
                                                    }
                                                    
                                                }
                                                
                                            }
                                        } catch let error {
                                            print("got an error creating the request: \(error)")
                                        }
                                        
                                        
                                    }
                                    
                                    
                                }
                            }
                        }
                        
                        task1.resume()
                    }
                }
            }
            task.resume()

        
        }
        
    
    }
    
    
    
    
    
    func parse(json data:Data) -> [String : Any]? {
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch{
            print("JSON Error:\(error)")
            return nil
        }
        
    }

    
    func searchLogSend(searchStr: String, key: String){
        //要用post
        //"latitude", "longitude"
        let latitude = DBManager.shared.get_device_position()["latitude"]!
        let longitude = DBManager.shared.get_device_position()["longitude"]!
        
        //name=UUID
        let name = DBManager.shared.systemInfo.deviceUUID
        
        let combinedStr = String(format: "%@/syslog?deviceid=%@&latitude=%@&longtitude=%@&key=%@&value=%@", arguments: [API_Manager.shared.DEVICE_API_PATH, name, latitude, longitude, key , searchStr])
        let escapedStr = combinedStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //print("\(escapedStr)")
        
        let url = URL(string:escapedStr)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
            if error != nil{
                print(error.debugDescription)
            } else{
                if let serverTalkBack = String(data: data!, encoding: String.Encoding.utf8){
                    print("\(serverTalkBack)")
                } else {
                    print("error")
                }
            }
        }
        task.resume()
    }

    

}
