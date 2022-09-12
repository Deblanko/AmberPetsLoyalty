//
//  DataModel.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/17/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit
import CoreImage.CIFilterBuiltins
import Firebase
import FirebaseFirestoreSwift
import os.log
import Photos

struct OSLogger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.deblanko.amberpetsloyalty"
}

enum LoginState {
    case unknown
    case loggedIn
    case loggedOut
    case delete
}

enum Provider  {
    case apple
    case email(password:String)
}

struct CustomerQRData : Codable {
    var store = "AmberPets"
    let type:String
    let userId:String
}

struct TableInfo:Identifiable {
    let id = UUID()
    let title : String
    let details : String
}

struct Points {
    var total : Int
    var lastUpdate: String
}

struct Redeemed : Codable {
    var userId: String
    var date: String
}

struct RedeemedTable : Identifiable {
    let id = UUID()
    let userId: String
    let displayName: String
    let date: String
}

struct UserEntry : Identifiable, Hashable {
    let id : String
    let lastName : String   // for sorting
    let fullName : String
    let email : String
    let lastCheckin : Date?
    let lastPurchase : Date?
    let points : Int
    let totalPoints : Int
}

struct CustomerEntry : Codable {
    let displayName : String?
    let email: String
    var lastCheckin: String
    
    var lastName : String?  {
        guard let name = self.displayName else {
            return nil
        }
        let personNameComponents = PersonNameComponentsFormatter().personNameComponents(from: name)
        return personNameComponents?.familyName ?? name
    }
        
    enum CodingKeys : String, CodingKey{
        case displayName
        case email
        case lastCheckin
    }
}


class DataModel: ObservableObject {
    static let log = OSLog(subsystem: OSLogger.subsystem, category: "DataModel")
    
    static let imageCache = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    
    let redeemAmount = 10
    
    // access to database funcs
    let db = Firestore.firestore()
    // observers
    var handle: AuthStateDidChangeListenerHandle?
    //    var isAdminObserver : NSKeyValueObservation?
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    // KVOs
    @Published var isAdmin = false
    @Published var loginState = LoginState.unknown
    var loginProvider : Provider?
    @Published var lastRefresh = Date()
    @Published var errorMessage : String? = nil
    @Published var logoImage : UIImage?
    @Published var logoLive : PHLivePhoto?
    
    var appleSignInModel : AppleSignInModel?
    // current QR data
    var customerQRData : CustomerQRData?
    // id of logged in user
    var loggedInUserId : String? = nil

    // MARK: Computed properties
    var qrImage : UIImage? {
        var result : UIImage?
        if let theCode = self.base64StringFromCustomerData() {
            if let theImage = UIImage.generateQrCode(theCode) {
                result = theImage
            }
        }
        return result
    }

    public var loggedInName : String {
        let name = self.userTable().first?.details ?? "N/A"
        return name
    }

    public var currentUserEmail : String {
        if let userId = self.loggedInUserId, let customer = self.customers[userId] {
            return customer.email
        }
        else {
            return "???"
        }
    }
    
    // MARK: Cached data, updated by DB listeners
    // customer and users view
    var customers = [String : CustomerEntry]()
    // used by customer and users views
    var points = [String : Points]()
    // vouchers (redeemed) view
    var redeemed = [Redeemed]()
    
    var redeemedTableSections = [String]()
    var redeemedTableData = [[RedeemedTable]]()
    
    var usersListener : ListenerRegistration?
    var pointsListener : ListenerRegistration?
    var redeemListener : ListenerRegistration?
    
    // data tables
    
    // info for customer details (mini table with title and details)
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
        self.lastRefresh = Date()
        os_log("Updating lastRefresh %{public}@", log: Self.log, type: .info, self.lastRefresh.description)
    }
    
    public func getPoints(userId:String) -> Int? {
        var result : Int? = nil
        if let points = self.points[userId] {
            result = points.total
        }
        return result
    }
    
    // Table with sections etc.
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
            os_log("Section Date:%{public}@", log: Self.log, type: .info, current.description)
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
            
            let displayName = self.customers[item.userId]?.displayName ?? "X-Customer:\(item.userId)"
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
                
                let entry = RedeemedTable(userId: item.userId, displayName: displayName, date: dateString)
                redeemedTableData[monthsDiff].append(entry)
            }
        }
    }
    
    // init
    init() {
        // listener for logged in/out
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            os_log("Auth -> %@", log: Self.log, type: .info, String(describing:user?.uid))
            if let user = user {
                self.loggedInUserId = user.uid
                self.updateAdminFlag(user: user) { isAdmin in
                    self.setupListeners(userId:isAdmin ? nil : user.uid)
                }
                self.customerQRData = CustomerQRData(type: user.providerID, userId: user.uid)
                let providerId = user.providerData.first?.providerID ?? "???"
                self.loginProvider = (providerId == "apple.com" ) ? .apple : .email(password: "")
                if self.loginState == .unknown {  // do not change the view state until login completed?
                    self.loginState = .loggedIn    // do this last, it triggers a refresh
                }
            }
            else {
                // logout
                self.loggedInUserId = nil
                self.isAdmin = false
                self.customerQRData = nil
                self.removeListeners()
                self.loginProvider = nil
                    self.loginState = .loggedOut   // do this last, it triggers a refresh
            }
        }
    }
    
    public func getUserInfoForId(_ userId:String) -> UserEntry? {
        guard let foundUser = allUsers.first(where: {$0.id == userId}) else {
            return nil
        }
        return foundUser
    }
    
    // table for list of users
    public var allUsers : [UserEntry] {
        let formatter = PersonNameComponentsFormatter()
        let result : [UserEntry] = self.customers.map {
            var fullName = $0.value.displayName ?? "Anonymous"
            if fullName.isEmpty {
                fullName = "Anonymous"
            }
            else {
                fullName = fullName.capitalized
            }
            let personName = formatter.personNameComponents(from: fullName)
            let lastName = personName?.familyName ?? "Anonymous"
            let key = $0.key
            let points = self.points[key]?.total ?? 0
            let totalPoints = points + (redeemAmount * self.redeemed.filter{ $0.userId == key }.count )
            let lastCheckin = getDateFromISO8601String($0.value.lastCheckin)
            let lastPurchase = getDateFromISO8601String(self.points[key]?.lastUpdate)
            return UserEntry(
                id: key,
                lastName: lastName,
                fullName: fullName,
                email: $0.value.email,
                lastCheckin: lastCheckin,
                lastPurchase: lastPurchase,
                points: points,
                totalPoints: totalPoints)
        }
        return result
    }
    
    // this only makes sense if logged in as an admin
    public func emailExists(_ email:String) -> Bool {
        let result = (self.customers.first{$0.value.email.compare(email, options: .caseInsensitive) == .orderedSame} != nil)
        return result
    }
    
    public func loadLogo() {
        guard let logoUrl = Self.imageCache?.appendingPathComponent("logo.jpg") else {
            return
        }
        self.logoImage = UIImage(contentsOfFile: logoUrl.path)
        
        loadLivePhoto() // Async loader
    }
    
    func loadLivePhoto() {
        guard let imageUrl = Self.imageCache?.appendingPathComponent("Live.heic"), let movieUrl = Self.imageCache?.appendingPathComponent("Live.mov") else {
            return
        }
        
        let placeHolder = UIImage(contentsOfFile: imageUrl.path)
        PHLivePhoto.request(
            withResourceFileURLs: [imageUrl, movieUrl],
            placeholderImage: placeHolder,
            targetSize: CGSize.zero,
            contentMode: PHImageContentMode.aspectFit) { livePhoto, info in
                if let livePhoto = livePhoto {
                    DispatchQueue.main.async {
                        self.logoLive = livePhoto
                    }
                }
                else {
                    os_log("Failed to create live image: %{public}@", log:Self.log, type:.error, info)
                }
            }
    }
    

        
    static public func saveLogo(logoImage:UIImage? = nil, logoLive:PHLivePhoto? = nil) {
        // delete logo images before we create new ones
        if let imageUrl = Self.imageCache?.appendingPathComponent("logo.jpg") {
            try? FileManager.default.removeItem(at: imageUrl)
        }
        if let imageUrl = Self.imageCache?.appendingPathComponent("Live.heic") {
            try? FileManager.default.removeItem(at: imageUrl)
        }
        if let movieUrl = Self.imageCache?.appendingPathComponent("Live.mov") {
            try? FileManager.default.removeItem(at: movieUrl)
        }
        // save new ones
        if let image = logoImage {
            if let data = image.jpegData(compressionQuality: 1.0), let imageUrl = Self.imageCache?.appendingPathComponent("logo.jpg") {
                try? data.write(to: imageUrl)
            }
        }
        if let image = logoLive {
            extractResources(from: image)
        }
    }
    
    static private func extractResources(from livePhoto: PHLivePhoto) {
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        let group = DispatchGroup()
        for resource in assetResources {
            group.enter()
            let url : URL?
            switch resource.type {
            case .photo:
                url = Self.imageCache?.appendingPathComponent("Live.heic")
            case .pairedVideo:
                url = Self.imageCache?.appendingPathComponent("Live.mov")
            default:
                url = nil
            }
            if let url = url {
                PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                    if let error = error {
                        os_log("Failed to save to %{public}@ -> %{public}@", log: Self.log, type:.error, url.path, error.localizedDescription)
                    }
                    group.leave()
                }
            }
        }
        group.wait()
    }
    
    public func removeCustomLogo() {
        guard let logoUrl = Self.imageCache?.appendingPathComponent("logo.jpg"),
              let imageUrl = Self.imageCache?.appendingPathComponent("Image.Live"),
              let movieUrl = Self.imageCache?.appendingPathComponent("Image.mov") else {
            return
        }
        try? FileManager.default.removeItem(at: logoUrl)
        try? FileManager.default.removeItem(at: imageUrl)
        try? FileManager.default.removeItem(at: movieUrl)
        self.logoLive = nil
        self.logoImage = nil
        self.lastRefresh = Date()
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
    
    private func getISO8601Date(_ date:Date? = nil) -> String {
        let now = date ?? Date()
        let iso8601DateFormatter = ISO8601DateFormatter()
        iso8601DateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let result = iso8601DateFormatter.string(from: now)
        return result
    }

    private func getDateFromISO8601String(_ input:String?) -> Date? {
        guard let input = input else {
            return nil
        }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from:input)
        return date
    }

    
    public func logout() {
        do {
            try Auth.auth().signOut()
//            Self.loginState = .loggedOut
        } catch let error {
            os_log("Logout Error %{public}@", log: Self.log, type: .error, error.localizedDescription)
        }
    }
    
    public func reAuthenticate(provider:Provider) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        switch provider {
        case .apple:
            self.appleSignInModel = AppleSignInModel(onComplete: { error in
                //...
                if let error = error {
                    // inform user?
                    os_log("Signin Error %{public}@", log: Self.log, type: .error, error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                }
                else {
                    self.delete(user: user)
                }
            })
            self.appleSignInModel?.startSignInWithAppleFlow()
        case .email(let password):
            // email signin
            if let email = user.email {
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                user.reauthenticate(with: credential) { result, error in
                    if let error = error {
                        // inform user?
                        os_log("Signin Error %{public}@", log: Self.log, type: .error, error.localizedDescription)
                        self.errorMessage = error.localizedDescription
                    }
                    else {
                        self.delete(user: user)
                    }
                }
            }
            break
        }
    }
    
    func deleteTableEntry(_ uid:String, tableName:String, onComplete: @escaping (_ error:Error?) -> ()) {
        // get a ref to the DB for the name table
        let ref = self.db.collection(tableName).document(uid)
        ref.delete { err in
            onComplete(err)
        }
    }
    
    // delete the user
    // must call this just after a succesful login
    public func delete(user:User) {
        let dispatchGroup = DispatchGroup()
        for tableName in ["users", "points"] {
            dispatchGroup.enter()
            deleteTableEntry(user.uid, tableName: tableName) { err in
                if let error = err {
                    os_log("Error removing uid %{public}@ in %{public}@ -> %{public}@", log:Self.log, type:.error, user.uid, tableName, error.localizedDescription)
                } else {
                    os_log("User %{public}@ successfully removed from %{public}@ ", log:Self.log, type:.info, user.uid, tableName)
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            user.delete { error in
                if let error = error {
                    // An error happened.
                    os_log("Delete Error %{public}@", log: Self.log, type: .error, error.localizedDescription)
                } else {
                    // Account deleted.
                    os_log("Account %{public}@ deleted", log: Self.log, type: .info, user.displayName ?? "???")
                }
            }
        }
    }


    public func updateAdminFlag(user:User, onComplete:@escaping (_ isAdmin:Bool)->()) {
        if let email = user.email {
            db.collection("admins").document(email).getDocument(completion: { (snapshot, error) in
                var isAdmin = false
                if let error = error {
                    os_log("updateAdminFlag error %{public}@", log: Self.log, type: .error, error.localizedDescription)
                } else {
                    isAdmin = (snapshot?.data()?.count ?? 0) > 0
                }
                self.isAdmin = isAdmin
                onComplete(isAdmin)
            })
        }
        else {
            self.isAdmin = false
            onComplete(false)
        }
    }
    
    
    public func updateUser(userId:String, displayName:String) {
        let ref = self.db.collection("users").document(userId)
        let lastCheckin = self.getISO8601Date()
        ref.updateData(["displayName" : displayName, "lastCheckin" : lastCheckin ]) { (error) in
            if let error = error {
                os_log("update user for uid %@, Error %{public}@", log:Self.log, type:.error, userId, error.localizedDescription)
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
        os_log("Add User %{public}@ for uid %@, ", log:Self.log, type:.info, String(describing:displayName), userId)
        let ref = self.db.collection("users").document(userId)
        ref.getDocument { (snapshot, error) in
            if let err = error {
                os_log("Add User for uid %@, Error %{public}@", log:Self.log, type:.error, userId, err.localizedDescription)
            } else {
                let lastCheckin = self.getISO8601Date()
                if snapshot?.exists ?? false {
                    snapshot?.reference.updateData(["lastCheckin":lastCheckin]) { (error) in
                        // if no error we could update the model?
                        if let error = error {
                            os_log("Could not update lastCheckin for %{public}@, %{public}@", log: Self.log, type: .error, userId, error.localizedDescription)
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
                                os_log("Could not add new user %{public}@, %{public}@", log: Self.log, type: .error, userId, error.localizedDescription)
                            }
                            else {
                                os_log("Update user %{public}@", log: Self.log, type: .info, userId)
                                self.customers[userId] = theUser
                                self.updateAll()
                                // adding points may also refresh too
                                self.addPointsForUserId(userId, points: 0)  // 0 points for new user
                            }
                        }
                    }
                    catch let error {
                        // log error
                        os_log("Could not parse new user %{public}@, %{public}@", log: Self.log, type: .error, userId, error.localizedDescription)
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
                os_log("Transaction failed, reason: %{public}@", log: Self.log, type: .error, err.localizedDescription)
            } else {
                os_log("Transaction succeeded", log: Self.log, type: .info)
                self.updateAll()
                
                if (points == -self.redeemAmount) {
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
                os_log("Redeem failed, reason: %{public}@", log: Self.log, type: .error, error.localizedDescription)
            }
            else {
                self.updateAll()
            }
        }
    }
    
    // watch for db updates and update our models
    func setupListeners(userId:String?) {
        if let userId = userId {
            os_log("Adding Listeners for just %{public}@", log: Self.log, type: .info, userId)
            let pointsRef = self.db.collection("points").document(userId)
            self.pointsListener = pointsRef.addSnapshotListener { (snapshot, error) in
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
            let userRef = db.collection("users").document(userId)
            self.usersListener = userRef.addSnapshotListener { (snapshot, error) in
                os_log("Users Listener %{public}@", log: Self.log, type: .info, Auth.auth().currentUser?.email ?? "N/A")
                if let error = error {
                    os_log("Fetch user for uid %@, Error %{public}@", userId, error.localizedDescription)
                } else {
                    if let entry = try? snapshot?.data(as: CustomerEntry.self) {
                        self.customers[userId] = entry
                        self.updateAll()
                    }
                }
            }
        }
        else {
            os_log("Adding Listeners for all users", log: Self.log, type: .info)
            let waitGroup = DispatchGroup()
            waitGroup.enter()
            var userWaitGroup : DispatchGroup? = waitGroup
            self.usersListener = db.collection("users").addSnapshotListener { (querySnapshot, error) in
                os_log("Users Listener %{public}@", log: Self.log, type: .info, Auth.auth().currentUser?.email ?? "N/A")
                guard let documents = querySnapshot?.documents else {
                    os_log("Users Listener no documents -> %{public}@", log: Self.log, type: .info, String(describing: error))
                    
                    return
                }
                self.customers.removeAll()
                os_log("Users Listener found %d documents", log: Self.log, type: .info, documents.count)
                
                for document in documents {
                    if let entry = try? document.data(as: CustomerEntry.self) {
                        self.customers[document.documentID] = entry
                    }
                }
                self.updateAll()
                if let group = userWaitGroup {
                    userWaitGroup = nil
                    group.leave()
                }
            }
            waitGroup.enter()
            var pointsWaitGroup : DispatchGroup? = waitGroup
            self.pointsListener = db.collection("points").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    os_log("Points Listener no documents", log: Self.log, type: .info)
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
                if let group = pointsWaitGroup {
                    pointsWaitGroup = nil
                    group.leave()
                }
            }
            waitGroup.enter()
            var redeemWaitGroup : DispatchGroup? = waitGroup
            self.redeemListener = db.collection("redeem").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    os_log("Reddem Listener no documents", log: Self.log, type: .info)
                    return
                }
                self.redeemed = documents.compactMap { queryDocumentSnapshot -> Redeemed? in
                    let entry = try? queryDocumentSnapshot.data(as: Redeemed.self)
                    return entry
                }
                if let group = redeemWaitGroup {
                    redeemWaitGroup = nil
                    group.leave()
                }
            }

            waitGroup.notify(queue: DispatchQueue.main) {
                self.buildRedeemedTable()
                self.updateAll()
            }
            
        }
    }
    
    func removeListeners() {
        self.usersListener?.remove()
        self.usersListener = nil
        self.pointsListener?.remove()
        self.pointsListener = nil
        self.redeemListener?.remove()
        self.redeemListener = nil
    }
}

extension DataModel {
    
    func generateQrCode(_ content: String)  -> UIImage? {
        let data = content.data(using: String.Encoding.ascii, allowLossyConversion: false)
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        if let qrCodeImage = (filter.outputImage){
            if let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
                return UIImage(cgImage: qrCodeCGImage)
            }
        }
        return nil
    }
}


