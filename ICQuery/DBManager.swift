//
//  DBManager.swift
//  ICQuery
//
//  Created by Roger on 2016/12/15.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit

class DBManager: NSObject {

    static let shared: DBManager = DBManager()
    
    //數據庫檔案名
    let databaseFileName = "database.sqlite"
    //數據庫檔案路徑
    var pathToDatabase: String!
    //一個FMDatabase object, 用它來訪問和操作真正的數據庫
    var database: FMDatabase!
    

    /***使用者資訊***/
    let field_UserID = "UserID"
    let field_UserPassword = "UserPassword"
    let field_UserEmail = "UserEmail"
    
    let field_DeviceProductName = "DeviceProductName"
    let field_DeviceUUID = "DeviceUUID "
    let field_DeviceLatitude = "DeviceLatitude"
    let field_DeviceLongtitude = "Device_Longtitude"

    
    
    
/*
    //ID / Password
    var uid :String!       //user_ID
    var pwd :String!       //user_password
    var email :String!     //user_email
    
    /***設備資訊***/
    var node:String!       //device product name
    var name:String!       //device UUID
    var latitude:String!   //device latitude
    var longtitude:String! //device longtitude
    
*/
    
    
    
    override init() {
        
        super.init()
        let documentDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString ) as String
        
        pathToDatabase = documentDirectory.appending("/\(databaseFileName)")
        print("database path = \(pathToDatabase)")

    }
    
    
    // for create database --> return Bool, success or not
    func createDataBase() -> Bool{
        var created = false
        
        // not exist?
        if !FileManager.default.fileExists(atPath: pathToDatabase){
            
            //create database
            database = FMDatabase(path: pathToDatabase!)
            
            if database != nil{
                // open database
                if database.open(){
                    //******* create table *******//
                    // SQL syntax
                    let createSysteminfoTableQuery = "create table systeminfo (\(field_UserID) text, \(field_UserPassword) text, \(field_UserEmail) text, \(field_DeviceProductName) text, \(field_DeviceUUID) text, \(field_DeviceLatitude) float, \(field_DeviceLongtitude) float)"
                    do {
                        try database.executeUpdate(createSysteminfoTableQuery, values: nil)
                            //
                        return true
                    } catch{
                        //fail create table
                        print("Could not create table")
                        print(error.localizedDescription)
                    }
                    
                    database.close()
                    
                } else {
                    print("cannot open the database")
                }
                
            }
            
        }
        // exist?
        return created
    }
    
    // openDataBase
    func openDatabase()-> Bool{
        if database == nil {
            if FileManager.default.fileExists(atPath: pathToDatabase) {
                database = FMDatabase(path: pathToDatabase)
            }
        }
        
        
        if database != nil {
            if database.open() {
                return true
            }
        }
        
        return false
        
    }

    
    
    func get_device_uuid() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    func get_system_version() -> String{
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        
        return "\(systemName)_\(systemVersion)"
    }
    
    func get_device_name() -> String{
        //let model = UIDevice.current.localizedModel
        let model = UIDevice.current.modelName
        return model
    }
    
    
    func get_device_position(){
    
    
    }
    
}
