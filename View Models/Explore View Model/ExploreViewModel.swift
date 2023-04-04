//
//  ExploreViewModel.swift
//  Trivio
//
//  Created by David Chen on 5/4/21.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore

class ExploreViewModel: ObservableObject {
    @Published var homepageIsDisplaying: HomepageDisplayMode = .publicSets
    @Published var currentSearchBy: SearchByOption = .allrecents
    @Published var searchItem = ""
    @Published var gameIDs = [String]()
    @Published var games = [Game]()
    @Published var hasSearch = false
    @Published var capSplit = [String]()
    
    @Published var allPublicSetsWithListener = [CustomSetCherry]()
    @Published var allPublicSets = [CustomSetCherry]()
    @Published var allPrivateSets = [CustomSetCherry]()
    @Published var recentlyPlayedSets = [CustomSetCherry]()
    @Published var titleSearchResults = [CustomSet]()
    @Published var categorySearchResults = [CustomSet]()
    @Published var tagsSearchResults = [CustomSet]()
    @Published var userResults = [CustomSetCherry]()
    @Published var userDrafts = [CustomSetCherry]()
    
    @Published var filterBy = "dateCreated"
    @Published var isDescending = true
    @Published var tagsString = [String]()
    @Published var tags = [String:Int]()
    
    @Published var selectedUserUsername = ""
    @Published var selectedUserName = ""
    
    @Published var isShowingUserView = false
    @Published var usernameIDDict = [String:String]()
    @Published var nameIDDict = [String:String]()
    @Published var queriedUserRecords = [MyUserRecords]()
    
    public var db = FirebaseConfigurator.shared.getFirestore()
    public var latestPublicDoc: DocumentSnapshot? = nil
    public var latestPrivateDoc: DocumentSnapshot? = nil
    
    public var currentSort: String {
        if filterBy == "dateCreated" && isDescending == true {
            return "Date created (newest)"
        } else if filterBy == "dateCreated" && isDescending == false {
            return "Date created (oldest)"
        } else if filterBy == "rating" && isDescending == true {
            return "Highest rating"
        } else {
            return "Most plays"
        }
    }
    
    init() {
        pullAllPublicSetsWithListener()
        pullAllPublicSets()
        pullAllPrivateSets()
        pullRecentlyPlayedSets()
    }
    
    func clearSearch() {
        self.searchItem.removeAll()
    }
    
    func addUsernameNameToDict(userID: String) {
        db.collection("users").document(userID).getDocument { docSnap, error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let doc = docSnap else { return }
            guard let username = doc.get("username") as? String else { return }
            guard let name = doc.get("name") as? String else { return }
            self.nameIDDict.updateValue(name, forKey: userID)
            self.usernameIDDict.updateValue(username, forKey: userID)
        }
    }
    
    func getUsernameFromUserID(userID: String) -> String {
        return usernameIDDict[userID] ?? "Creator"
    }
    
    func getInitialsFromUserID(userID: String) -> String {
        var initials: String = ""
        let name: String = nameIDDict[userID] ?? ""
        let fullNameArray = name.components(separatedBy: " ")
        for eachName in fullNameArray {
            initials += eachName.prefix(1)
            if initials.count > 2 {
                break
            }
        }
        return initials.uppercased()
    }
    
    private func pullAllPublicSetsWithListener() {
        db.collection("userSets").whereField("isPublic", isEqualTo: true).order(by: "dateCreated", descending: true).limit(to: 10).addSnapshotListener { (snap, error) in
            if error != nil { return }
            guard let data = snap?.documents else { return }
            self.allPublicSetsWithListener = data.compactMap({ (queryDocSnap) -> CustomSetCherry? in
                let customSet = try? queryDocSnap.data(as: CustomSet.self)
                if let id = customSet?.userID {
                    self.addUsernameNameToDict(userID: id)
                }
                if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                    // Custom set for version 3.0
                    self.addUsernameNameToDict(userID: customSetCherry.userID)
                    return customSetCherry
                } else {
                    // default
                    return CustomSetCherry(customSet: customSet ?? CustomSet())
                }
            })
        }
    }
    
    public func shortenPublicSetsTo(_ newLength: Int, customSet: CustomSetCherry) {
//        let newPublicSetsCopy = Array(allPublicSets.prefix(newLength))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var ticker = 0
            self.allPublicSets = self.allPublicSets.filter({ customPublicSet in
                ticker += 1
                return (customPublicSet.id == customSet.id || ticker <= 10)
            })
        }
    }
    
    public func pullAllPublicSets() {
        // Is it a bit janky to limit to 10,000? Yes. I will never have 10,000 sets on my app, however.
        // When I do, I will be rich and I will sell this app to Kahoot or whomever and be even richer
        var query: Query!

        if allPublicSets.isEmpty {
            query = db.collection("userSets").whereField("isPublic", isEqualTo: true).order(by: filterBy, descending: isDescending).limit(to: 10)
        } else {
            query = db.collection("userSets").whereField("isPublic", isEqualTo: true).order(by: filterBy, descending: isDescending).start(afterDocument: latestPublicDoc!).limit(to: 5)
        }
        
        query.getDocuments { (snap, error) in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                guard let data = snap?.documents else { return }
                let newPublicSets = data.compactMap({ (queryDocSnap) -> CustomSetCherry? in
                    let customSet = try? queryDocSnap.data(as: CustomSet.self)
                    if let id = customSet?.userID {
                        self.addUsernameNameToDict(userID: id)
                    }
                    if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                        // Custom set for version 3.0
                        self.addUsernameNameToDict(userID: customSetCherry.userID)
                        return customSetCherry
                    } else {
                        // default
                        return CustomSetCherry(customSet: customSet ?? CustomSet())
                    }
                })
                self.allPublicSets.append(contentsOf: newPublicSets)
                self.latestPublicDoc = data.last
            }
        }
    }
    
    public func pullAllPrivateSets(isLimitingTo20: Bool = true) {
        var query: Query!

        if allPrivateSets.isEmpty {
            query = db.collection("userSets").whereField("isPublic", isEqualTo: false).order(by: filterBy, descending: isDescending).limit(to: 10)
        } else {
            query = db.collection("userSets").whereField("isPublic", isEqualTo: false).order(by: filterBy, descending: isDescending).start(afterDocument: latestPrivateDoc!).limit(to: 10)
        }
        
        query.getDocuments { (snap, error) in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                guard let data = snap?.documents else { return }
                let newPrivateSets = data.compactMap({ (queryDocSnap) -> CustomSetCherry? in
                    let customSet = try? queryDocSnap.data(as: CustomSet.self)
                    if let id = customSet?.userID {
                        self.addUsernameNameToDict(userID: id)
                    }
                    if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                        // Custom set for version 3.0
                        self.addUsernameNameToDict(userID: customSetCherry.userID)
                        return customSetCherry
                    } else {
                        // default
                        return CustomSetCherry(customSet: customSet ?? CustomSet())
                    }
                })
                self.allPrivateSets.append(contentsOf: newPrivateSets)
                self.latestPrivateDoc = data.last
            }
        }
    }
    
    private func pullRecentlyPlayedSets() {
        guard let uid = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        self.addUsernameNameToDict(userID: uid)
        db.collection("users").document(uid).collection("played").addSnapshotListener { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let snap = snap else { return }
            snap.documentChanges.forEach { (diff) in
                guard let playedGameID = diff.document.get("gameID") as? String else { return }
                if diff.type == .added {
                    self.addToRecentlyPlayed(customSetID: playedGameID)
                }
            }
        }
    }
    
    public func queryUserRecord(username: String) {
        self.queriedUserRecords.removeAll()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snap, error) in
            if error != nil { return }
            guard let data = snap?.documents else { return }
            let userIDs = data.compactMap({ (queryDocSnap) -> String in
                return queryDocSnap.documentID
            })
            
            userIDs.forEach { userID in
                self.db.collection("users").document(userID).collection("myUserRecords").document("myUserRecordsCherry").getDocument { (docSnap, error) in
                    if error != nil { return }
                    guard let myUserRecordsCherry = try? docSnap?.data(as: MyUserRecordsCherry.self) else { return }
                    var userRecord = MyUserRecords()
                    userRecord.assignFromMURCherry(myUserRecordsCherry: myUserRecordsCherry)
                    self.queriedUserRecords.append(userRecord)
                }
            }
        }
    }
    
    public func toggleUserRecordIsVIP(username: String) {
        guard username == queriedUserRecords.first?.username else { return }
        queriedUserRecords[0].isVIP.toggle()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snap, error) in
            if error != nil { return }
            guard let data = snap?.documents else { return }
            guard let docID = data.first?.documentID else { return }
            guard let currentIsVIP = self.queriedUserRecords.first?.isVIP else { return }
            self.db.collection("users").document(docID).collection("myUserRecords").document("myUserRecordsCherry").setData([
                "isVIP" : currentIsVIP
            ], merge: true)
        }
    }
    
    func addToRecentlyPlayed(customSetID: String) {
        db.collection("userSets")
            .document(customSetID)
            .getDocument { (snap, error) in
                if error != nil { return }
                guard let docSnap = snap else { return }
                let customSet = try? docSnap.data(as: CustomSet.self)
                if let customSetCherry = try? docSnap.data(as: CustomSetCherry.self) {
                    // Custom set for version 3.0
                    self.recentlyPlayedSets.append(customSetCherry)
                } else if let customSet = customSet {
                    self.recentlyPlayedSets.append(CustomSetCherry(customSet: customSet))
                } else {
                    // default
                    return
                }
                guard let customSetUserID = customSet?.userID else { return }
                self.addUsernameNameToDict(userID: customSetUserID)
                self.recentlyPlayedSets = self.recentlyPlayedSets.sorted(by: { $0.dateCreated > $1.dateCreated })
            }
    }
    
    func noMatchesFound() -> Bool {
        switch currentSearchBy {
        case .title:
            return titleSearchResults.count == 0
        case .category:
            return categorySearchResults.count == 0
        case .allrecents:
            return allPublicSets.count == 0
        default:
            return tagsSearchResults.count == 0
        }
    }
    
    // for user view
    func pullAllFromUser(withID userID: String) {
        userResults.removeAll()
        
        db.collection("drafts")
            .whereField("userID", isEqualTo: userID)
            .order(by: "dateCreated", descending: true)
            .getDocuments { (snap, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                guard let data = snap?.documents else { return }
                
                self.userDrafts = data.compactMap({ (queryDocSnap) -> CustomSetCherry? in
                    let customSet = try? queryDocSnap.data(as: CustomSet.self)
                    if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                        // Custom set for version 3.0
                        return customSetCherry
                    } else {
                        return CustomSetCherry(customSet: customSet ?? CustomSet())
                    }
                })
            }
        
        db.collection("userSets")
            .whereField("userID", isEqualTo: userID)
            .order(by: "dateCreated", descending: true)
            .getDocuments { (snap, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                guard let data = snap?.documents else { return }
                
                self.userResults = data.compactMap({ (queryDocSnap) -> CustomSetCherry? in
                    let customSet = try? queryDocSnap.data(as: CustomSet.self)
                    if let id = customSet?.userID {
                        self.addUsernameNameToDict(userID: id)
                    }
                    if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                        // Custom set for version 3.0
                        return customSetCherry
                    } else {
                        // default
                        return CustomSetCherry(customSet: customSet ?? CustomSet())
                    }
                })
            }
        
        db.collection("users").document(userID).getDocument { (docSnap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let doc = docSnap else { return }
            self.selectedUserUsername = doc.get("username") as? String ?? ""
            self.selectedUserName = doc.get("name") as? String ?? ""
        }
    }
}

enum SearchByOption {
    case title, category, tags, allrecents
}

enum HomepageDisplayMode {
    case publicSets, recentlyPlayed, myCustomSets, setPreview
}
