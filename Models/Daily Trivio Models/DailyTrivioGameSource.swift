//
//  DailyTrivioGameSource.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 3/25/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct DailyTrivioGameSource: Encodable, Decodable, Hashable, Identifiable {
    @DocumentID var id: String?
    var date: Date = Date()
    var dateString: String
    var dtSetID: String
}
