//
//  Build.swift
//  Trivio!
//
//  Created by David Chen on 10/28/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

enum BuildPhaseType {
    case rounds1and2, ddSelections
}

var BuildStageValueDict: [BuildStage:Int] {
    return [
        .details : 0,
        .trivioRound : 1,
        .trivioRoundDD : 2,
        .dtRound : 3,
        .dtRoundDD : 4,
        .finalTrivio: 5
    ]
}

// A set that a user has built
struct CustomSet: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var jCategoryIDs: [String]
    var djCategoryIDs: [String]
    var categoryNames: [String]
    var title: String
    var titleKeywords: [String]
    var fjCategory: String
    var fjClue: String
    var fjResponse: String
    var dateCreated: Date
    var jeopardyDailyDoubles: [Int]
    var djDailyDoubles1: [Int]
    var djDailyDoubles2: [Int]
    var userID: String
    var isPublic: Bool
    var tags: [String]
    var plays: Int
    var rating: Double
    var numRatings: Int
    var numclues: Int
    var averageScore: Double
    var jRoundLen: Int
    var djRoundLen: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(id: String? = nil, jCategoryIDs: [String] = [], djCategoryIDs: [String] = [], categoryNames: [String] = [], title: String = "", titleKeywords: [String] = [], fjCategory: String = "", fjClue: String = "", fjResponse: String = "", dateCreated: Date = Date(), jeopardyDailyDoubles: [Int] = [], djDailyDoubles1: [Int] = [], djDailyDoubles2: [Int] = [], userID: String = "", isPublic: Bool = false, tags: [String] = [], plays: Int = 0, rating: Double = 0.0, numRatings: Int = 0, numclues: Int = 0, averageScore: Double = 0.0, jRoundLen: Int = 6, djRoundLen: Int = 6) {
        self.id = id
        self.jCategoryIDs = jCategoryIDs
        self.djCategoryIDs = djCategoryIDs
        self.categoryNames = categoryNames
        self.title = title
        self.titleKeywords = titleKeywords
        self.fjCategory = fjCategory
        self.fjClue = fjClue
        self.fjResponse = fjResponse
        self.dateCreated = dateCreated
        self.jeopardyDailyDoubles = jeopardyDailyDoubles
        self.djDailyDoubles1 = djDailyDoubles1
        self.djDailyDoubles2 = djDailyDoubles2
        self.userID = userID
        self.isPublic = isPublic
        self.tags = tags
        self.plays = plays
        self.rating = rating
        self.numRatings = numRatings
        self.numclues = numclues
        self.averageScore = averageScore
        self.jRoundLen = jRoundLen
        self.djRoundLen = djRoundLen
    }
}

struct CustomSetCherry: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var round1CatIDs: [String]
    var round2CatIDs: [String]
    var categoryNames: [String]
    var title: String
    var titleKeywords: [String]
    var description: String
    var finalCat: String
    var finalClue: String
    var finalResponse: String
    var dateCreated: Date
    var dateLastModified: Date
    var roundOneDaily: [Int]
    var roundTwoDaily1: [Int]
    var roundTwoDaily2: [Int]
    var userID: String
    var tags: [String]
    var plays: Int
    var rating: Double
    var numRatings: Int
    var numClues: Int
    var round1Len: Int
    var round2Len: Int
    var hasTwoRounds: Bool
    var isDraft: Bool
    var isPublic: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(customSet: CustomSet) {
        self.id = customSet.id
        self.round1CatIDs = customSet.jCategoryIDs
        self.round2CatIDs = customSet.djCategoryIDs
        self.categoryNames = customSet.categoryNames
        self.title = customSet.title
        self.titleKeywords = customSet.titleKeywords
        self.description = ""
        self.finalCat = customSet.fjCategory
        self.finalClue = customSet.fjClue
        self.finalResponse = customSet.fjResponse
        self.dateCreated = customSet.dateCreated
        self.dateLastModified = customSet.dateCreated
        self.roundOneDaily = customSet.jeopardyDailyDoubles
        self.roundTwoDaily1 = customSet.djDailyDoubles1
        self.roundTwoDaily2 = customSet.djDailyDoubles2
        self.userID = customSet.userID
        self.tags = customSet.tags
        self.plays = customSet.plays
        self.rating = customSet.rating
        self.numRatings = customSet.numRatings
        self.numClues = customSet.numclues
        self.round1Len = customSet.jRoundLen
        self.round2Len = customSet.djRoundLen
        self.isPublic = customSet.isPublic
        self.hasTwoRounds = true
        self.isDraft = false
    }
}

extension CustomSetCherry {
    init(id: String? = UUID().uuidString, round1CatIDs: [String] = [], round2CatIDs: [String] = [], categoryNames: [String] = [], title: String = "", titleKeywords: [String] = [], description: String = "", finalCat: String = "", finalClue: String = "", finalResponse: String = "", dateCreated: Date = Date(), dateLastModified: Date = Date(), roundOneDaily: [Int] = [], roundTwoDaily1: [Int] = [], roundTwoDaily2: [Int] = [], userID: String = "", tags: [String] = [], plays: Int = 0, rating: Double = 0.0, numRatings: Int = 0, numClues: Int = 0, round1Len: Int = 6, round2Len: Int = 6, hasTwoRounds: Bool = false, isDraft: Bool = true, isPublic: Bool = false) {
        self.id = id
        self.round1CatIDs = round1CatIDs
        self.round2CatIDs = round2CatIDs
        self.categoryNames = categoryNames
        self.title = title
        self.titleKeywords = titleKeywords
        self.description = description
        self.finalCat = finalCat
        self.finalClue = finalClue
        self.finalResponse = finalResponse
        self.dateCreated = dateCreated
        self.dateLastModified = dateLastModified
        self.roundOneDaily = roundOneDaily
        self.roundTwoDaily1 = roundTwoDaily1
        self.roundTwoDaily2 = roundTwoDaily2
        self.userID = userID
        self.tags = tags
        self.plays = plays
        self.rating = rating
        self.numRatings = numRatings
        self.numClues = numClues
        self.round1Len = round1Len
        self.round2Len = round2Len
        self.hasTwoRounds = hasTwoRounds
        self.isDraft = isDraft
        self.isPublic = isPublic
    }
}
