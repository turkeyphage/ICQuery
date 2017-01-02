//
//  DBManager.swift
//  ICQuery
//
//  Created by Roger on 2016/12/15.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit
import CoreLocation

class DBManager: NSObject {

    static let shared: DBManager = DBManager()
    
    //數據庫檔案名
    let databaseFileName = "database.sqlite"
    // 帳號密碼數據庫
    let databaseAccount = "account.sqlite"
    
    
    
    //數據庫檔案路徑
    var pathToDatabase: String!
    var pathToAccount: String!
    
    //一個FMDatabase object, 用它來訪問和操作真正的數據庫
    var database: FMDatabase!
    var accountDatabase : FMDatabase!

    var systemInfo :SystemInfo!
    var accountInfo :AccountInfo!

    
    /***使用者資訊***/
    let field_UserEmail = "UserEmail"
    let field_UserPassword = "UserPassword"

    
    /***系統資訊***/
    let field_DeviceProductName = "DeviceProductName"
    let field_DeviceUUID = "DeviceUUID "
    //let field_DeviceLatitude = "DeviceLatitude"
    //let field_DeviceLongtitude = "Device_Longtitude"

    var locationManage:CLLocationManager!
    
    
    
    
    override init() {
        
        super.init()
        let documentDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString ) as String
        
        
        
        pathToDatabase = String(format: "%@/%@", arguments: [documentDirectory, databaseFileName])
        pathToAccount = String(format: "%@/%@", arguments: [documentDirectory, databaseAccount])
        
        
        //pathToDatabase = documentDirectory.appending("/\(databaseFileName)")
        print("database path = \(pathToDatabase)")
        print("account database path = \(pathToAccount)")

        locationManage = CLLocationManager()
        locationManage.requestAlwaysAuthorization()
        
        self.systemInfo = SystemInfo(deviceUUID: self.get_device_uuid(), deviceName: self.get_device_name())
    
    }
    
    
    // for create database --> return Bool, success or not
    func createDataBase() -> Bool{
        let created = false
        
        // not exist?
        if !FileManager.default.fileExists(atPath: pathToDatabase){
            
            //create database
            database = FMDatabase(path: pathToDatabase!)
            
            
            if database != nil{
                
                // open account database
                if database.open(){
                    //******* create table *******//
                    // SQL syntax
                    let createSysteminfoTableQuery = "create table systeminfo (\(field_DeviceProductName) text, \(field_DeviceUUID) text)"
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
    
    
    
    
    // for create account Database --> return Bool, success or not
    func createAccountDataBase() -> Bool{
        let created = false
        
        // not exist?
        if !FileManager.default.fileExists(atPath: pathToDatabase){
            
            //create account database
            accountDatabase = FMDatabase(path: pathToAccount!)

            /*
            if accountDatabase != nil{
                
                // open account database
                if accountDatabase.open(){
                    //******* create table *******//
                    // SQL syntax
                    let createAccountInfoTableQuery = "create table accountinfo (\(field_UserEmail) text, \(field_UserPassword) text)"
                    do {
                        try database.executeUpdate(createAccountInfoTableQuery, values: nil)
                        //
                        return true
                    } catch{
                        //fail create table
                        print("Could not create accountinfo table")
                        print(error.localizedDescription)
                    }
                    
                    accountDatabase.close()
                    
                } else {
                    print("cannot open the accountDatabase")
                }
                
            }
             */
            
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

    
    
    // openAccountDataBase
    func openAccountDatabase()-> Bool{
        if accountDatabase == nil {
            if FileManager.default.fileExists(atPath: pathToAccount) {
                accountDatabase = FMDatabase(path: pathToAccount)
            }
        }
        
        
        if accountDatabase != nil {
            if accountDatabase.open() {
                return true
            }
        }
        
        return false
    }
    
    
    
    
    
    
    //獲得系統版本
    func get_system_version() -> String{
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        
        return "\(systemName)_\(systemVersion)"
    }
    
    //獲得device UUID
    func get_device_uuid() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString{
        
            return uuid
        } else {
            return ""
        }
    }
    

    
    //獲得device model
    func get_device_name() -> String{
        //let model = UIDevice.current.localizedModel
        let model = UIDevice.current.modelName
        return model
    }
    
    //獲得目前經緯度
    func get_device_position() -> Dictionary<String, String>{
        //let cordinate = locationManage.location?.coordinate
    
        let nf = NumberFormatter()
        nf.numberStyle = NumberFormatter.Style.decimal
        nf.maximumFractionDigits = 5

        if let cordinate = locationManage.location?.coordinate{
            
            if let latitude = nf.string(from: NSNumber(value: Double(cordinate.latitude))), let longitude = nf.string(from: NSNumber(value: Double(cordinate.longitude))){
                return ["latitude":latitude, "longitude":longitude]
            
            } else {
                return ["latitude":"", "longtitude":""]
            }
            
        } else {
            return ["latitude":"", "longitude":""]
        }
    }
    
    
    
    
    func insert_systemInfo_Data(){
        if openDatabase(){
            let name = self.get_device_name()
            let uuid = self.get_device_uuid()
            
            //insert SQL syntax
            let query = "insert into systeminfo (\(field_DeviceProductName), \(field_DeviceUUID)) values ('\(name)', '\(uuid)');"
            
            //執行insert SQL，如果執行失敗，顯示出理由
            
            if !database.executeStatements(query) {
                print("Failed to insert initial data into the database.")
                print(database.lastError(), database.lastErrorMessage())
            }
            database.close()
        }
    }
    
    func insert_accountInfo_Data(email:String, password:String){
        if openAccountDatabase(){
            let email = email
            let password = password
            
            //insert SQL syntax
            let query = "insert into accountinfo (\(field_UserEmail), \(field_UserPassword)) values ('\(email)', '\(password)');"
            
            //執行insert SQL，如果執行失敗，顯示出理由
            
            if !accountDatabase.executeStatements(query) {
                print("Failed to insert initial data into the account database.")
                print(accountDatabase.lastError(), accountDatabase.lastErrorMessage())
            }
            accountDatabase.close()
        }
    }
    
    
    

    
    //update data
    func update_data(inTable table:String, column_name:String, new_Data:String, withReference:String, referValue:String){
    
        if openDatabase(){
            let query = "update \(table) set \(column_name)=? where \(withReference)=?"
            
            do{
                try database.executeUpdate(query, values: [new_Data, referValue])
                
            } catch{
                print(error.localizedDescription)
            }

            database.close()
        }
    }
    
    
    
    //update account data
    func update_account_data(inTable table:String, column_name:String, new_Data:String, withReference:String, referValue:String){
        
        if openAccountDatabase(){
            let query = "update \(table) set \(column_name)=? where \(withReference)=?"
            
            do{
                try accountDatabase.executeUpdate(query, values: [new_Data, referValue])
                
            } catch{
                print(error.localizedDescription)
            }
            
            accountDatabase.close()
        }
    }
    
    

    
    //刪除整筆資料
    func deleteData(inTable table:String, withReference:String, referValue:String) -> Bool{
        var deleted = false
        
        if openDatabase() {
            let query = "delete from \(table) where \(withReference)=?"
            
            do {
                try database.executeUpdate(query, values: [referValue])
                deleted = true
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        return deleted
        
    }
    
    //刪除整筆資料
    func deleteAccountData(inTable table:String, withReference:String, referValue:String) -> Bool{
        var deleted = false
        
        if openAccountDatabase() {
            let query = "delete from \(table) where \(withReference)=?"
            
            do {
                try accountDatabase.executeUpdate(query, values: [referValue])
                deleted = true
            }
            catch {
                print(error.localizedDescription)
            }
            
            accountDatabase.close()
        }
        
        return deleted
        
    }
    
    
    
    
    
    //讀取systemInfo資料
    
    func loadSystemInfo(completionHandler: (_ systemInfo: SystemInfo?) -> Void) {
        var systemInfo: SystemInfo!
        
        if openDatabase() {
            let query = "select * from systemInfo where \(field_DeviceUUID)=?"
            
            do {
                let results = try database.executeQuery(query, values: [self.get_device_uuid()])
                
                if results.next() {
                    systemInfo = SystemInfo(deviceUUID: results.string(forColumn: field_DeviceUUID), deviceName: results.string(forColumn: field_DeviceProductName))
                }
                else {
                    print(database.lastError())
                }
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        completionHandler(systemInfo)
        
    }

    
    
    

}





struct SystemInfo{
    var deviceUUID:String
    var deviceName:String
}


struct AccountInfo{
    var accountName:String
    var password:String
}

