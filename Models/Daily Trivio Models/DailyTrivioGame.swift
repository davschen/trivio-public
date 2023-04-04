//
//  DailyTrivioGame.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 3/24/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
/*
 I've been using these users as my testers oops!
 I should do this in Python and not manually but I'm dumb
 
 03jVps16lYRJPgy1QEgvrcyRl3J3 - ari.0rg
 09X4tRw4NqPftTlXOYUI4YtVd2f1 - kohlere22
 0CF7zN6N5ucdyhaACNql3ftpaGD2 - brittongough
 0PjsM2l4EuZfj2YVZkKxPB4vRfI2 - wwgirl
 0Wygwtl6AfP40SqtNnhaLuoTYht2 - marybdaygetaway
 */
struct DailyTrivioGame: Encodable, Decodable, Hashable, Identifiable {
    @DocumentID var id: String?
    var attempts: [String]
    var time: Int
    var score: Int
    var username: String
    var userID: String
    var correct: Bool
    var date: Date = Date()
}
