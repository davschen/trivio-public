//
//  DailyTrivioSet.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 3/24/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct DailyTrivioSet: Encodable, Decodable, Hashable, Identifiable {
    @DocumentID var id: String?
    var amount: Int
    var clue: String
    var date: Date
    var name: String
    var num_chosen: Int
    var response: String
}
