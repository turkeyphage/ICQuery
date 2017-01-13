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
    //數據庫檔案路徑
    var pathToDatabase: String!
    //一個FMDatabase object, 用它來訪問和操作真正的數據庫
    var database: FMDatabase!
    

    var systemInfo :SystemInfo!


    /***使用者資訊***/
    let field_ServerLog = "ServerLog"
    let field_UserPassword = "UserPassword"
    let field_UserEmail = "UserEmail"
    let field_LoginDate = "LoginDate"
    let field_History = "History"
    
    
    
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
        //pathToDatabase = documentDirectory.appending("/\(databaseFileName)")
        //print("database path = \(pathToDatabase)")

        locationManage = CLLocationManager()
        locationManage.requestAlwaysAuthorization()
        
        self.systemInfo = SystemInfo(deviceUUID: self.get_device_uuid(), deviceName: self.get_device_name())
    
    }
    
    
    // 建立account table
    func createAccountTable() {
        
        if openDatabase(){
        
            //******* create table *******//
            // SQL syntax
            let createAccountInfoTableQuery = "CREATE TABLE IF NOT EXISTS accountinfo (\(field_ServerLog) TEXT, \(field_UserEmail) TEXT , \(field_UserPassword) TEXT, \(field_History) TEXT, \(field_LoginDate) TEXT)"
            do {
                try database.executeUpdate(createAccountInfoTableQuery, values: nil)
                //
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
    

    
    // for create database --> return Bool, success or not
    func createDataBase() -> Bool{
        let created = false
        
        // not exist?
        if !FileManager.default.fileExists(atPath: pathToDatabase){
            
            //create database
            database = FMDatabase(path: pathToDatabase!)
            
            if database != nil{
                // open database
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
    
    
    
    func insert_accountInfo_Data(syslog:String, email:String, password:String){

        let history = ""
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        
        if openDatabase(){
            //insert SQL syntax
            let query = "insert into accountinfo (\(field_ServerLog), \(field_UserEmail), \(field_UserPassword), \(field_History), \(field_LoginDate)) values ('\(syslog)', '\(email)', '\(password)', '\(history)', '\(formatter.string(from: date))');"
            
            //執行insert SQL，如果執行失敗，顯示出理由
            
            if !database.executeStatements(query) {
                print("Failed to insert initial data into the database.")
                print(database.lastError(), database.lastErrorMessage())
            }
            database.close()
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
    
    
    
    //檢查是否有這筆資料
    func checkDataAvailable(searchTable: String, searchStr: String) -> Bool{
        var exist = false
        var accountLists : [AccountManager]  = [AccountManager]()
        if openDatabase(){
            
            let query = "select * from accountinfo where \(field_ServerLog)=?"
            
            do {
                let results = try database.executeQuery(query, values: [searchStr])
                while results.next() {
                    
                    let each = AccountManager(email: results.string(forColumn: field_UserEmail), password: results.string(forColumn: field_UserPassword), serverLog: results.string(forColumn: field_ServerLog), loginDate: results.string(forColumn: field_LoginDate), history: results.string(forColumn: field_History))
                    
                    accountLists.append(each)
                }
                
            } catch {
                print(error.localizedDescription)
            }
            database.close()

            if !accountLists.isEmpty{
                exist = true
            }
        }
        return exist
    }
    
    
    
    
    
    
    
    // 檢查是否有最近一筆的登入資料
    func checkAccountTable() -> AccountManager?{
        var accountLists : [AccountManager]  = [AccountManager]()
        var recentAccount : AccountManager?
        if openDatabase(){
            let query = "select * from accountinfo"
        
            do {
                let results = try database.executeQuery(query, values: nil)
                while results.next() {
                    
                    let each = AccountManager(email: results.string(forColumn: field_UserEmail), password: results.string(forColumn: field_UserPassword), serverLog: results.string(forColumn: field_ServerLog), loginDate: results.string(forColumn: field_LoginDate), history: results.string(forColumn: field_History))

                    accountLists.append(each)
                }
                
            } catch {
                print(error.localizedDescription)
            }
            database.close()

            // 檢查
            if !accountLists.isEmpty{
                let sortedArray = accountLists.sorted(by: { $0.realDate > $1.realDate })
                recentAccount = sortedArray.first!
            }
        }
        return recentAccount
    }
    
    
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            var addr = ptr.pointee.ifa_addr.pointee
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return addresses
    }
    
    
    
    
    
    // Return IP address of WiFi interface (en0) as a String, or `nil`
    func getWiFiAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    
    
}





struct SystemInfo{
    var deviceUUID:String
    var deviceName:String
}

struct AccountManager{
    var email : String
    var password : String
    var serverLog : String
    var loginDate : String
    var history : String
    
    var realDate : Date{
        get{
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.date(from: self.loginDate)!
        }
    }
}
