//
//  ProfileVM.swift
//  Trivio!
//
//  Created by David Chen on 5/24/21.
//

import Foundation
import UIKit
import Firebase
import FirebaseFirestoreSwift

class ProfileViewModel: ObservableObject {
    @Published var playedGameIDs = [String]()
    @Published var menuSelectedItem = "Summary"
    @Published var username = "" 
    @Published var name = ""
    @Published var usernameValid = false
    @Published var drafts = [CustomSetCherry]()
    @Published var searchItem = ""
    @Published var showingSettingsView = false
    @Published var settingsMenuSelectedItem = "Game Settings"
    @Published var myUserRecords = MyUserRecords()
    @Published var allUserRecords = [MyUserRecords]()
    
    @Published var currentVIPs = [String:String]()
    
    private var db = FirebaseConfigurator.shared.getFirestore()
    public var myUID = FirebaseConfigurator.shared.auth.currentUser?.uid
    
    init() {
        getUserInfo()
        pullUserRecordsData()
    }
    
    func markAsPlayed(gameID: String) {
        guard let myUID = myUID else { return }
        db.collection("users")
            .document(myUID)
            .collection("played").whereField(gameID, isEqualTo: gameID).getDocuments { (snap, error) in
                if error != nil { return }
                guard let firstDoc = snap?.documents.first else {
                    return
                }
                if !firstDoc.exists {
                    self.db.collection("users").document(myUID).collection("played").addDocument(data: [
                        "gameID" : gameID
                    ])
                }
        }
    }
    
    func beenPlayed(gameID: String) -> Bool {
        return playedGameIDs.contains(gameID)
    }
    
    func categoryInSearch(categoryName: String, searchQuery: [String]) -> Bool {
        var toReturn = false
        for word in searchQuery {
            if categoryName.lowercased().contains(word.lowercased()) {
                toReturn = true
            }
        }
        return toReturn
    }
    
    func checkForbiddenChars() -> String {
        var forbiddenReport = ""
        let forbiddenChars: [Character] = [" ", "/", "-", "&", "$", "#", "@", "!", "%", "^", "*", "(", ")", "+"]
        for char in forbiddenChars {
            if username.contains(String(char)) {
                forbiddenReport = String(char)
            }
        }
        if forbiddenReport.isEmpty {
            return ""
        } else {
            return forbiddenReport == " " ? "space" : "'" + forbiddenReport + "'"
        }
    }
    
    func checkUsernameExists(completion: @escaping (Bool) -> Void) {
        guard let uid = myUID else { return }
        let docRef = db.collection("users")
            .whereField("username", isEqualTo: username.lowercased())
        docRef.addSnapshotListener { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            if let doc = data.first {
                if (doc.documentID == uid) {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(true)
            }
        }
    }
    
    func checkUsernameValidWithHandler(completion: @escaping (Bool) -> Void) {
        checkUsernameExists { (success) -> Void in
            if success && !self.username.isEmpty && self.checkForbiddenChars().isEmpty {
                completion(true)
            } else {
                self.usernameValid = false
                completion(false)
            }
        }
    }
    
    func checkUsernameValid() {
        checkUsernameExists { (success) -> Void in
            if success && !self.username.isEmpty {
                self.usernameValid = true 
            } else {
                self.usernameValid = false
            }
        }
    }
    
    private func pullAllVIPs() {
        db.collectionGroup("myUserRecords").getDocuments { (snap, error) in
            if error != nil { return }
            guard let data = snap?.documents else { return }
            data.forEach { docSnap in
                guard let username = docSnap.get("username") as? String else { return }
                guard let isVIP = docSnap.get("isVIP") as? Bool else { return }
                guard isVIP else { return }
                self.db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snap, error) in
                    if error != nil { return }
                    guard let data = snap?.documents else { return }
                    guard let firstDoc = data.first else { return }
                    guard let username = firstDoc.get("username") as? String else { return }
                    guard let name = firstDoc.get("name") as? String else { return }
                    self.currentVIPs[username] = name
                }
            }
        }
    }
    
    private func pullUserRecordsData() {
        guard let myUID = myUID else { return }
        let cherryUpdatesDocRef = db.collection("users").document(myUID).collection("myUserRecords").document("myUserRecordsCherry")
        cherryUpdatesDocRef.getDocument(completion: { (docSnap, error) in
            if error != nil {
                return
            }
            guard let doc = docSnap else { return }
            // Ideally, I'd check if the doc is of the type MyUserRecordsCherry, but not today.
            if !doc.exists || doc.get("mostRecentSession") == nil {
                self.db.collection("users").document(myUID).getDocument(completion: { (docSnap, error) in
                    if error != nil { return }
                    guard let doc = docSnap else { return }
                    let username = doc.get("username") as! String
                    var newUserRecord = MyUserRecordsCherry()
                    newUserRecord.username = username
                    try? cherryUpdatesDocRef.setData(from: newUserRecord)
                })
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "LLLL"
                
                guard let myUserRecordsCherry = try? doc.data(as: MyUserRecordsCherry.self) else { return }
                DispatchQueue.main.async {
                    if myUserRecordsCherry.numLiveTokens == 0 && myUserRecordsCherry.freeTokenLastGeneratedMonth != dateFormatter.string(from: Date()) {
                        // If the user is due for a free token
                        self.incrementNumTokens()
                        self.updateMyUserRecords(fieldName: "freeTokenLastGeneratedMonth", newValue: dateFormatter.string(from: Date()))
                        var murCherry = myUserRecordsCherry
                        murCherry.numLiveTokens += 1
                        self.myUserRecords.assignFromMURCherry(myUserRecordsCherry: murCherry)
                    } else {
                        self.myUserRecords.assignFromMURCherry(myUserRecordsCherry: myUserRecordsCherry)
                    }
                    self.updateMostRecentSession()
                    self.incrementNumSessions()
                    if self.myUserRecords.isAdmin { self.pullAllVIPs() }
                }
                if myUserRecordsCherry.isAdmin {
                    self.pullAllUserRecords()
                }
            }
        })
    }
    
    public func purgeAndPullAllUserRecords() {
        allUserRecords.removeAll()
        pullAllUserRecords()
    }
    
    private func pullAllUserRecords() {
        db.collection("userSessions").order(by: "mostRecentSession").limit(to: 50).getDocuments { (snap, error) in
            if error != nil { return }
            guard let data = snap?.documents else { return }
            let userSessionIDs = data.compactMap({ (docSnap) -> String in
                return docSnap.documentID
            })
            userSessionIDs.forEach { userID in
                self.db.collection("users").document(userID).collection("myUserRecords").document("myUserRecordsCherry").getDocument { (docSnap, error) in
                    if error != nil {
                        return
                    }
                    guard let myUserRecordCherry = try? docSnap?.data(as: MyUserRecordsCherry.self) else { return }
                    var userRecord = MyUserRecords()
                    userRecord.assignFromMURCherry(myUserRecordsCherry: myUserRecordCherry)
                    let insertionIndex = self.allUserRecords.insertionIndexOf(userRecord) { $0.mostRecentSession > $1.mostRecentSession }
                    self.allUserRecords.insert(userRecord, at: insertionIndex)
                }
            }
        }
    }
    
    public func updateMyUserRecords(fieldName: String, newValue: Any) {
        guard let myUID = myUID else { return }
        let cherryUpdatesDocRef = db.collection("users").document(myUID).collection("myUserRecords").document("myUserRecordsCherry")
        cherryUpdatesDocRef.setData([
            fieldName : newValue
        ], merge: true)
    }
    
    public func updateMostRecentSession() {
        guard let myUID = myUID else { return }
        let cherryUpdatesDocRef = db.collection("users").document(myUID).collection("myUserRecords").document("myUserRecordsCherry")
        cherryUpdatesDocRef.setData([
            "mostRecentSession" : Date()
        ], merge: true)
        db.collection("userSessions").document(myUID).setData([
            "mostRecentSession" : Date()
        ], merge: true)
    }
    
    private func getUserInfo() {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        let myProfileDocRef = db.collection("users").document(myUID)
        myProfileDocRef.getDocument { (docSnap, error) in
            if error != nil { return }
            guard let doc = docSnap else { return }
            let name = doc.get("name") as? String ?? ""
            let username = doc.get("username") as? String ?? ""
            DispatchQueue.main.async {
                self.name = name
                self.username = username
            }
            self.db.document("users/\(myUID)/myUserRecords/myUserRecordsCherry").setData([
                "username" : username,
            ], merge: true)
        }
        db.collection("drafts")
            .whereField("userID", isEqualTo: myUID)
            .order(by: "dateCreated", descending: true)
            .addSnapshotListener { snap, error in
                if error != nil { return }
                guard let data = snap?.documents else { return }
                self.drafts = data.compactMap { (queryDocSnap) -> CustomSetCherry? in
                    let customSet = try? queryDocSnap.data(as: CustomSet.self)
                    if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                        // Custom set for version 3.0
                        return customSetCherry
                    } else {
                        // default
                        return CustomSetCherry(customSet: customSet ?? CustomSet())
                    }
                }
        }
        if UserDefaults.standard.string(forKey: "clueAppearance") == nil {
            UserDefaults.standard.set("classic", forKey: "clueAppearance")
        }
        if UserDefaults.standard.string(forKey: "speechLanguage") == nil {
            UserDefaults.standard.set("americanEnglish", forKey: "speechLanguage")
        }
        if UserDefaults.standard.string(forKey: "speechSpeed") == nil {
            UserDefaults.standard.set(0.5, forKey: "speechSpeed")
        }
        if UserDefaults.standard.string(forKey: "speechGender") == nil {
            UserDefaults.standard.set("male", forKey: "speechGender")
        }
    }
    
    public func incrementNumTokens() {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        let usersRef = db.collection("users").document(myUID).collection("myUserRecords").document("myUserRecordsCherry")
        usersRef.setData([
            "numLiveTokens" : FieldValue.increment(Int64(1)),
        ], merge: true)
        self.myUserRecords.numLiveTokens += 1
    }
    
    public func incrementNumSessions() {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        let usersRef = db.collection("users").document(myUID).collection("myUserRecords").document("myUserRecordsCherry")
        usersRef.setData([
            "numTrackedSessions" : FieldValue.increment(Int64(1)),
        ], merge: true)
        self.myUserRecords.numTrackedSessions += 1
    }
    
    func writeKeyValueToFirestore(key: String, value: Any) {
        db.collection("users").document(FirebaseConfigurator.shared.auth.currentUser?.uid ?? "NID").setData([
            key : value
        ], merge: true)
    }
    
    func shouldRequestAppStoreReview() -> (Bool, String) {
        let currentVersion = "Cherry"
        return (myUserRecords.numTrackedSessions > 10 && !(myUserRecords.lastVersionReviewPrompt == currentVersion), currentVersion)
    }
    
    func getInitials(name: String) -> String {
        var initials = ""
        let nameSplit = name.split(separator: " ")
        for i in 0..<nameSplit.count {
            let name = nameSplit[i]
            if initials.count < 3 {
                initials += name.prefix(1)
            }
        }
        return initials
    }
    
    func getAuthProvider() -> String {
        let providerData = FirebaseConfigurator.shared.auth.currentUser?.providerData
        var provider = ""
        providerData?.forEach({ userInfo in
            if userInfo.phoneNumber != nil {
                provider = "Phone"
            } else {
                provider = "Google"
            }
        })
        return provider
    }
    
    func editAccountInfo() {
        guard let uid = myUID else { return }
        db.collection("users").document(uid).setData([
            "name": self.name,
            "username": self.username.lowercased()
        ], merge: true)
        getUserInfo()
    }
    
    func getPhoneNumber() -> String {
        return FirebaseConfigurator.shared.auth.currentUser?.phoneNumber ?? ""
    }
    
    func updatePhoneNumber(newPhoneNumber: String) {
        // I assume I may try this in the future but definitely not anytime soon
    }
    
    func accountInformationError(usernameTaken: Bool) -> Bool {
        return !nameError().isEmpty || !usernameError(usernameTaken: usernameTaken).isEmpty
    }
    
    func usernameError(usernameTaken: Bool) -> String {
        if usernameTaken {
            return "That username is already taken"
        } else if self.username.isEmpty {
            return "Your username cannot be empty"
        } else if !self.checkForbiddenChars().isEmpty {
            return "Your username cannot contain a " + self.checkForbiddenChars()
        } else {
            return ""
        }
    }
    
    func nameError() -> String {
        if self.name.isEmpty {
            return "Your name cannot be empty"
        } else {
            return ""
        }
    }
    
    func logOut() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        NotificationCenter.default.post(name: NSNotification.Name("LogInStatusChange"), object: nil)
        try? FirebaseConfigurator.shared.auth.signOut()
    }
    
    func deleteCurrentUserFromDB() {
        guard let uid = myUID else { return }
        let docRef = self.db.collection("users").document(uid)
        docRef.delete()
        logOut()
    }
}

enum DeviceType {
    case iPad, iPhone
}
