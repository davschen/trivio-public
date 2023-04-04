//
//  UpdateRecords.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/23/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct MyUserRecords: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var hasShownSwipeToDismissClue, hasShownHeldClueCell, isSubscribed, isAdmin, isVIP: Bool
    var numLiveTokens, numTrackedSessions: Int
    var username, lastVersionReviewPrompt, freeTokenLastGeneratedMonth: String
    var mostRecentSession: Date
    
    init() {
        self.hasShownSwipeToDismissClue = false
        self.hasShownHeldClueCell = false
        self.isSubscribed = false
        self.isAdmin = false
        self.isVIP = false
        self.numLiveTokens = 1
        self.numTrackedSessions = 0
        self.username = ""
        self.lastVersionReviewPrompt = ""
        self.freeTokenLastGeneratedMonth = ""
        self.mostRecentSession = Date()
    }
    
    mutating func assignFromMURCherry(myUserRecordsCherry: MyUserRecordsCherry) {
        self.hasShownSwipeToDismissClue = myUserRecordsCherry.hasShownSwipeToDismissClue
        self.hasShownHeldClueCell = myUserRecordsCherry.hasShownHeldClueCell
        self.isSubscribed = myUserRecordsCherry.isSubscribed
        self.isAdmin = myUserRecordsCherry.isAdmin
        self.isVIP = myUserRecordsCherry.isVIP
        self.numLiveTokens = myUserRecordsCherry.numLiveTokens
        self.numTrackedSessions = myUserRecordsCherry.numTrackedSessions
        self.freeTokenLastGeneratedMonth = myUserRecordsCherry.freeTokenLastGeneratedMonth
        self.mostRecentSession = myUserRecordsCherry.mostRecentSession
        self.username = myUserRecordsCherry.username
        self.lastVersionReviewPrompt = myUserRecordsCherry.lastVersionReviewPrompt
    }
}

// As of January 2023, this struct is basically identical to MyUserRecords.
// However, after version Cherry, MyUserRecords will continue to update and MyUserRecordsCherry will remain
// as it is forever.
struct MyUserRecordsCherry: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var hasShownSwipeToDismissClue, hasShownHeldClueCell, isSubscribed, isAdmin, isVIP: Bool
    var numLiveTokens, numTrackedSessions: Int
    var username, lastVersionReviewPrompt, freeTokenLastGeneratedMonth: String
    var mostRecentSession: Date
    
    init(hasShownSwipeToDismissClue: Bool = false, hasShownRatingsPromptCherry: Bool = false, hasShownHeldClueCell: Bool = false, isSubscribed: Bool = false, isAdmin: Bool = false, isVIP: Bool = false, numLiveTokens: Int = 1, username: String = "", lastVersionReviewPrompt: String = "") {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        
        self.hasShownSwipeToDismissClue = hasShownSwipeToDismissClue
        self.hasShownHeldClueCell = hasShownHeldClueCell
        self.isSubscribed = isSubscribed
        self.isAdmin = isAdmin
        self.isVIP = isVIP
        self.numLiveTokens = numLiveTokens
        self.numTrackedSessions = 0
        self.freeTokenLastGeneratedMonth = dateFormatter.string(from: Date())
        self.username = username
        self.lastVersionReviewPrompt = lastVersionReviewPrompt
        self.mostRecentSession = Date()
    }
}
