//
//  DataModel.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/17/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import os.log

struct CustomerQRData : Codable {
    var store = "AmberPets"
    let type:String
    let userId:String
}

class TableInfo:NSObject {
    var title : String
    var details : String
    
    init(title:String, details:String) {
        self.title = title
        self.details = details
    }
}

struct Points {
    var total : Int
    var lastUpdate: String
}

struct Redeemed : Codable {
    var userId: String
    var date: String
}

struct RedeemedTable {
    var displayName: String
    var date: String
    var userId: String
}


struct CustomerEntry : Codable {
    //    var userId : String = ""
    let displayName : String?
    let email: String
    var lastCheckin: String
    
    lazy var lastName : String? = {
        guard let name = self.displayName else {
            return nil
        }
        let personNameComponents = PersonNameComponentsFormatter().personNameComponents(from: name)
        return personNameComponents?.familyName ?? name
    }()
    
    func getPoints(userId:String) -> Int? {
        var result : Int? = nil
        if let points = DataModel.sharedInstance.points[userId] {
            result = points.total
        }
        return result
    }
    
    var prettyDate : String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from:lastCheckin) {
            let dateFormatter = DateFormatter()
            // Set Date/Time Style
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        }
        else {
            return lastCheckin
        }
    }
    
    enum CodingKeys : String, CodingKey{
        case displayName
        case email
        case lastCheckin
    }
}


class DataModel: NSObject {
    
    let xxx: Void = FirebaseApp.configure()
    
    static let sharedInstance = DataModel()
    
    // access to database funcs
    let db = Firestore.firestore()
    // observers
    var handle: AuthStateDidChangeListenerHandle?
    var isAdminObserver : NSKeyValueObservation?
    
    // KVOs
    @objc dynamic private var _isAdmin = false
    
    @objc dynamic public var isAdmin:Bool {
        get {
            return _isAdmin
        }
        
        set {
            // update keystore
            
            _isAdmin = newValue
        }
    }
    
    @objc class func keyPathsForValuesAffectingisAdmin() -> Set<String> {
        return ["_isAdmin"]
    }
    
    @objc dynamic public var loggedIn = false
    @objc dynamic public var lastRefresh = Date()
    
    // current QR data
    var customerQRData : CustomerQRData?
    
    // Cached data, updated by DB listeners
    // customer and users view
    var customers = [String : CustomerEntry]()
    // used by customer and users views
    var points = [String : Points]()
    // vouchers (redeemed) view
    var redeemed = [Redeemed]()
    
    var redeemedTableSections = [String]()
    
    var redeemedTableData = [[RedeemedTable]]()
    
    // id of logged in user
    var loggedInUserId : String? = nil
    
    var usersListener : ListenerRegistration?
    var pointsListener : ListenerRegistration?
    var redeemListener : ListenerRegistration?
    
    
    public var deletingAccount = false
    
    // data tables
    
    // info for customer details
    public func userTable(userId:String? = nil) -> [TableInfo] {
        var userTable = [TableInfo]()
        if let userId = userId ?? self.loggedInUserId {
            if let customer = self.customers[userId] {
                userTable.append(TableInfo(title: "Name", details: customer.displayName ?? "N/A"))
                userTable.append(TableInfo(title: "Email", details: customer.email))
                var value = "N/A"
                if let points = self.points[userId] {
                    value = "\(points.total)"
                }
                userTable.append(TableInfo(title: "Points", details: value))
            }
            else {
                userTable.append(TableInfo(title: "Name", details: "N/A"))
            }
        }
        else {
            userTable.append(TableInfo(title: "Name", details: "<Not Logged In>"))
        }
        
        return userTable
    }
    
    private func updateAll() {
        os_log("Updating lastRefresh", log: OSLog.dataModel, type: .info)
        self.lastRefresh = Date()
        
    }
    
    public func buildRedeemedTable(selectedUserId : String? = nil) {
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        isoDateFormatter.formatOptions = [
            .withFullDate,
            .withFullTime,
            .withDashSeparatorInDate,
            .withFractionalSeconds]
        
        let calendar = Calendar.current
        
        let sectionFormatter = DateFormatter()
        sectionFormatter.dateFormat = "MMMM YYYY"
        
        let now = Date()
        // clean up old data (or initial data)
        self.redeemedTableSections.removeAll()
        self.redeemedTableData.removeAll()
        
        var current = now
        for _ in 0...5 {
            // create a section title
            os_log("Section Date:%{public}@", log: OSLog.dataModel, type: .info, current as CVarArg)
            let sectionTitle = sectionFormatter.string(from: current)
            self.redeemedTableSections.append(sectionTitle)
            if let newDate = calendar.date(byAdding: .month, value: -1, to: current) {
                current = newDate
            }
            // add an empty array
            self.redeemedTableData.append([RedeemedTable]())
        }
        self.redeemedTableSections.append("Older")
        self.redeemedTableData.append([RedeemedTable]())
        
        let ordFormatter = NumberFormatter()
        ordFormatter.numberStyle = .ordinal
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "E 'Ord' '@' HH:mm"
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.timeZone = TimeZone.current
        fullDateFormatter.locale = Locale.current
        fullDateFormatter.dateFormat = "E 'Ord' MMM '@' HH:mm"
        
        for item in self.redeemed {
            if let selectedUserId = selectedUserId, item.userId != selectedUserId {
                continue    // do not process none user stuff
            }
            if let displayName = self.customers[item.userId]?.displayName {
                if let realDate = isoDateFormatter.date(from: item.date) {
                    let pastDate = calendar.dateComponents([.month,.year], from: realDate)
                    let nowDate = calendar.dateComponents([.month,.year], from: now)
                    var monthsDiff = calendar.dateComponents([.month], from: pastDate, to: nowDate).month ?? 6
                    
                    if monthsDiff > 6 {
                        monthsDiff = 6
                    }
                    
                    var dateString = (monthsDiff == 6) ? fullDateFormatter.string(from: realDate) : dateFormatter.string(from: realDate)
                    let day = calendar.component(.day, from: realDate)
                    let ordDay = ordFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
                    dateString = dateString.replacingOccurrences(of: "Ord", with: ordDay)
                    
                    let entry = RedeemedTable(displayName: displayName, date: dateString, userId: item.userId)
                    redeemedTableData[monthsDiff].append(entry)
                }
            }
        }
    }
    
    // init
    
    override init() {
        super.init()
        
        
        // listener for logged in/out
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            os_log("Auth -> %@", log: OSLog.dataModel, type: .info, String(describing:user?.uid))
            if let user = user {
                self.loggedInUserId = user.uid
                self.updateAdminFlag(email: user.email)
                self.addUser(userId: user.uid, displayName: user.displayName ?? "Anonymous", email: user.email)
                self.customerQRData = CustomerQRData(type: user.providerID, userId: user.uid)
                self.loggedIn = true    // do this last, it triggers a refresh
            }
            else {
                // login
                self.loggedInUserId = nil
                self.isAdmin = false
                self.updateAll()
                self.customerQRData = nil
                self.loggedIn = false   // do this last, it triggers a refresh
            }
        }
        
        isAdminObserver = self.observe(\.isAdmin, changeHandler: { (theModel, change) in
            if theModel.isAdmin {
                self.pointsListener?.remove()   // remove any single user listeners
                self.setupListeners()
                
            }
            else {
                self.removeListeners()
                if let userId = self.loggedInUserId {
                    self.fetchPointsForUserId(userId)
                }
            }
        })
    }
    
    public func emailExists(_ email:String) -> Bool {
        let result = (self.customers.first{$0.value.email.compare(email, options: .caseInsensitive) == .orderedSame} != nil)
        return result
    }
    
    
    // helper functions
    func getJSONStringFromCustomerData() -> String? {
        var result:String? = nil
        if let customerData = self.customerQRData {
            let jsonEncoder = JSONEncoder()
            if let jsonData = try? jsonEncoder.encode(customerData) {
                result = String(data: jsonData, encoding: String.Encoding.utf8)
            }
        }
        return result
    }
    
    func base64StringFromCustomerData() -> String? {
        var result:String? = nil
        if let customerData = self.customerQRData {
            let jsonEncoder = JSONEncoder()
            if let jsonData = try? jsonEncoder.encode(customerData) {
                let base64Encoded = jsonData.base64EncodedData()
                result = String(data: base64Encoded, encoding: .utf8)
            }
        }
        return result
    }
    
    func customerDataFromBase64String(_ base64String:String) -> CustomerQRData? {
        var result: CustomerQRData?
        if let base64Data = Data(base64Encoded: base64String) {
            let jsonDecoder = JSONDecoder()
            result = try? jsonDecoder.decode(CustomerQRData.self, from: base64Data)
        }
        return result
    }
    
    private func getISO8601Date(_ date:Date? = nil) -> String {
        let now = date ?? Date()
        let iso8601DateFormatter = ISO8601DateFormatter()
        iso8601DateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let result = iso8601DateFormatter.string(from: now)
        return result
    }
    
    
    public func logout() {
        do {
            try Auth.auth().signOut()
            
        } catch let error {
            os_log("Logout Error %{public}@", log: OSLog.dataModel, type: .error, error.localizedDescription)
        }
    }
    
    
    // delete the user
    // must call this just after a succesful login
    public func delete(user:User) {
        // get a ref to the DB for the users table
        let ref = self.db.collection("users").document(user.uid)
        // 1st delete the entry in the table (must be logged in)
        ref.delete { err in
            if let error = err {
                os_log("Error removing user %{public}@ -> %{public}@", log:OSLog.dataModel, type:.error, user.uid, error.localizedDescription)
            } else {
                os_log("User %{public}@ successfully removed", log:OSLog.dataModel, type:.info, user.uid)
                // now delete the user account, must have just logged in to do this
                user.delete { error in
                    if let error = error {
                        // An error happened.
                        os_log("Delete Error %{public}@", log: OSLog.dataModel, type: .error, error.localizedDescription)
                    } else {
                        // Account deleted.
                        os_log("Account %{public}@ deleted", log: OSLog.dataModel, type: .info, user.displayName ?? "???")
                    }
                }
            }
        }
    }
    
    
    public func updateAdminFlag(email:String?) {
        if let email = email {
            db.collection("admins").document(email).getDocument(completion: { (snapshot, error) in
                var isAdmin = false
                if let error = error {
                    os_log("updateAdminFlag error %{public}@", log: OSLog.dataModel, type: .error, error as CVarArg)
                } else {
                    isAdmin = (snapshot?.data()?.count ?? 0) > 0
                }
                self.isAdmin = isAdmin
            })
        }
        else {
            self.isAdmin = false
        }
    }
    
    // get for one (the current) user
    public func fetchPointsForUserId(_ userId:String) {
        
        let ref = self.db.collection("points").document(userId)
        self.pointsListener = ref.addSnapshotListener { (snapshot, error) in
            if let error = error {
                os_log("Fetch points for uid %@, Error %{public}@", userId, error.localizedDescription)
            } else {
                if let data = snapshot?.data() {
                    if let total = data["total"] as? Int {
                        let lastUpdate = data["lastUpdate"] as? String ?? "N/A"
                        self.points[userId] = Points(total: total, lastUpdate: lastUpdate)
                        self.updateAll()
                    }
                }
            }
        }
    }
    
    
    public func updateUser(userId:String, displayName:String) {
        let ref = self.db.collection("users").document(userId)
        let lastCheckin = self.getISO8601Date()
        ref.updateData(["displayName" : displayName, "lastCheckin" : lastCheckin ]) { (error) in
            if let error = error {
                os_log("update user for uid %@, Error %{public}@", log:OSLog.dataModel, type:.error, userId, error.localizedDescription)
            } else {
                if let customerEntry = self.customers[userId] {
                    let updatedCustomerEntry = CustomerEntry(displayName: displayName, email: customerEntry.email, lastCheckin: lastCheckin)
                    self.customers[userId] = updatedCustomerEntry
                    self.updateAll()
                }
            }
        }
    }
    
    public func addUser(userId:String, displayName:String?, email:String?) {
        os_log("Add User %{public}@ for uid %@, ", log:OSLog.dataModel, type:.info, String(describing:displayName), userId)
        let ref = self.db.collection("users").document(userId)
        ref.getDocument { (snapshot, error) in
            if let err = error {
                os_log("Add User for uid %@, Error %{public}@", log:OSLog.dataModel, type:.error, userId, err as CVarArg)
            } else {
                let lastCheckin = self.getISO8601Date()
                if snapshot?.exists ?? false {
                    snapshot?.reference.updateData(["lastCheckin":lastCheckin]) { (error) in
                        // if no error we could update the model?
                        if let error = error {
                            os_log("Could not update lastCheckin for %{public}@, %{public}@", log: OSLog.dataModel, type: .error, userId, error as CVarArg)
                        }
                        else {
                            let theName = self.customers[userId]?.displayName ?? displayName ?? "Anonymous"
                            self.customers[userId] = CustomerEntry( displayName: theName, email: email ?? "N/A", lastCheckin: lastCheckin)
                            self.updateAll()
                            self.addPointsForUserId(userId, points: 0)  // 0 points for existing user
                        }
                    }
                }
                else {
                    let theName = self.customers[userId]?.displayName ?? displayName ?? "Anonymous"
                    let theUser = CustomerEntry( displayName: theName, email: email ?? "N/A", lastCheckin: lastCheckin)
                    do {
                        try ref.setData(from: theUser, encoder: Firestore.Encoder()) { (error) in
                            // check for error
                            if let error = error {
                                os_log("Could not add new user %{public}@, %{public}@", log: OSLog.dataModel, type: .error, userId, error as CVarArg)
                            }
                            else {
                                os_log("Update user %{public}@", log: OSLog.dataModel, type: .info, userId)
                                self.customers[userId] = theUser
                                self.updateAll()
                                // adding points may also refresh too
                                self.addPointsForUserId(userId, points: 0)  // 0 points for new user
                            }
                        }
                    }
                    catch let error {
                        // log error
                        os_log("Could not parse new user %{public}@, %{public}@", log: OSLog.dataModel, type: .error, userId, error.localizedDescription)
                    }
                }
            }
        }
    }
    
    
    
    public func addPointsForUserId(_ userId:String, points:Int = 1) {
        let ref = db.collection("points").document(userId)
        
        self.db.runTransaction({ (transaction, errorPointer) -> Any? in
            let docSnapshot: DocumentSnapshot
            // get the document via transaction
            do {
                try docSnapshot = transaction.getDocument(ref)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            let lastCheckin = self.getISO8601Date()
            // get the counter value
            var counter = 0
            if let total = docSnapshot.data()?["total"] as? Int {
                counter = total
            }
            else {
                transaction.setData(["total":0, "lastUpdate": lastCheckin], forDocument: ref)
            }
            
            if counter + points < 0 {
                let err = NSError(domain: "AppErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Not enough points to redeem"])
                errorPointer?.pointee = err
                return "Only have \(counter) points. Cannot redeem"
            }
            if points != 0 {
                // update counter value via transaction (don't do it for 0, that is just for the set above!)
                transaction.updateData(["total": counter + points, "lastUpdate":lastCheckin], forDocument: ref)
            }
            return nil
        }) { (object, err) in
            if let err = err {
                os_log("Transaction failed, reason: %{public}@", log: OSLog.dataModel, type: .error, err as CVarArg)
            } else {
                os_log("Transaction succeeded", log: OSLog.dataModel, type: .info)
                self.updateAll()
                
                if (points == -10) {
                    // redeem
                    self.redeemPointsForUser(userId)
                }
                
            }
        }
        
    }
    
    func redeemPointsForUser(_ userId:String) {
        let redeemDate = self.getISO8601Date()
        let ref = self.db.collection("redeem").document()
        ref.setData(["userId": userId, "date": redeemDate]) { (error) in
            if let error = error {
                os_log("Redeem failed, reason: %{public}@", log: OSLog.dataModel, type: .error, error as CVarArg)
            }
            else {
                self.updateAll()
            }
        }
    }
    
    // watch for db updates and update our models
    func setupListeners() {
        os_log("Adding Listeners for user %{public}@", log: OSLog.dataModel, type: .info, Auth.auth().currentUser?.email ?? "N/A")
        self.usersListener = db.collection("users").addSnapshotListener { (querySnapshot, error) in
            os_log("Users Listener %{public}@", log: OSLog.dataModel, type: .info, Auth.auth().currentUser?.email ?? "N/A")
            guard let documents = querySnapshot?.documents else {
                os_log("Users Listener no documents -> %{public}@", log: OSLog.dataModel, type: .info, String(describing: error))
                
                return
            }
            self.customers.removeAll()
            os_log("Users Listener found %d documents", log: OSLog.dataModel, type: .info, documents.count)
            
            for document in documents {
                if let entry = try? document.data(as: CustomerEntry.self) {
                    self.customers[document.documentID] = entry
                }
            }
            self.updateAll()
        }
        
        self.pointsListener = db.collection("points").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                os_log("Points Listener no documents", log: OSLog.dataModel, type: .info)
                return
            }
            self.points.removeAll()
            for document in documents {
                let total = document.data()["total"] as? Int ?? 0
                let lastUpdate = document.data()["lastUpdate"] as? String ?? "N/A"
                let points = Points(total: total, lastUpdate: lastUpdate)
                self.points[document.documentID] = points
            }
            self.updateAll()
        }
        
        self.redeemListener = db.collection("redeem").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                os_log("Reddem Listener no documents", log: OSLog.dataModel, type: .info)
                return
            }
            self.redeemed = documents.compactMap { queryDocumentSnapshot -> Redeemed? in
                let entry = try? queryDocumentSnapshot.data(as: Redeemed.self)
                return entry
            }
            self.updateAll()
        }
    }
    
    func removeListeners() {
        self.usersListener?.remove()
        self.pointsListener?.remove()
        self.redeemListener?.remove()
    }
}
