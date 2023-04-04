//
//  Gameplay.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 10/26/22.
//

import Firebase
import FirebaseFirestoreSwift

struct TidyCustomSet: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var round1Cats: [String]
    var round2Cats: [String]
    var round1Clues: [[String]] = []
    var round2Clues: [[String]] = []
    var round1Responses: [[String]] = []
    var round2Responses: [[String]] = []
    var title: String
    var dateCreated: Date
    var authorUserID: String
    var authorUsername: String
    var authorName: String
    var tags: [String]
    var round1Len: Int
    var round2Len: Int
    
    init(id: String? = nil, round1Cats: [String] = [String](repeating: "", count: 6), round2Cats: [String] = [String](repeating: "", count: 6), round1Clues: [[String]] = [], round2Clues: [[String]] = [], round1Responses: [[String]] = [], round2Responses: [[String]] = [], title: String = "", dateCreated: Date = Date(), authorUserID: String = "", authorUsername: String = "", authorName: String = "", tags: [String] = [String](), round1Len: Int = 0, round2Len: Int = 0) {
        self.id = id
        self.round1Cats = round1Cats
        self.round2Cats = round2Cats
        self.round1Clues = round1Clues
        self.round2Clues = round2Clues
        self.round1Responses = round1Responses
        self.round2Responses = round2Responses
        self.title = title
        self.dateCreated = dateCreated
        self.authorUserID = authorUserID
        self.authorUsername = authorUsername
        self.authorName = authorName
        self.tags = tags
        self.round1Len = round1Len
        self.round2Len = round2Len
    }
}

struct CustomSetCategory: Decodable, Hashable, Encodable {
    @DocumentID var id: String?
    var name: String
    var index: Int
    var clues: [String]
    var responses: [String]
    var gameID: String
    // in hindsight the below does not work. I will implement it later.
    // stored as [<index>, <URL>]
    var imageURLs: [Int:String]
    var audioURLs: [Int:String]
    
    mutating func setIndex(index: Int) {
        self.index = index
    }
    
    init(id: String? = UUID().uuidString, name: String = "", index: Int = 0, clues: [String] = ["", "", "", "", ""], responses: [String] = ["", "", "", "", ""], gameID: String = "", imageURLs: [Int : String] = [:], audioURLs: [Int : String] = [:]) {
        self.id = id
        self.name = name
        self.index = index
        self.clues = clues
        self.responses = responses
        self.gameID = gameID
        self.imageURLs = imageURLs
        self.audioURLs = audioURLs
    }
}


// MARK: - For Jeopardy games: 'games' parent collection in the DB
struct JeopardySet: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var date: Date
    var dj_category_ids: [String]
    var dj_dds_1: [Int]
    var dj_dds_2: [Int]
    var dj_round_len: Int
    var dj_round_scores: [String]
    var final_scores: [String]
    var fj_category: String
    var fj_clue: String
    var fj_response: String
    var game_id: String
    var group_index: Int
    var j_category_ids: [String]
    var j_dds: [Int]
    var j_round_len: Int
    var j_round_scores: [String]
    var title: String
    var type: String
    var userID: String
    
    init(id: String? = nil, date: Date = Date(), dj_category_ids: [String] = [], dj_dds_1: [Int] = [], dj_dds_2: [Int] = [], dj_round_len: Int = 0, dj_round_scores: [String] = [], final_scores: [String] = [], fj_category: String = "", fj_clue: String = "", fj_response: String = "", game_id: String = "", group_index: Int = 0, j_category_ids: [String] = [], j_dds: [Int] = [], j_round_len: Int = 0, j_round_scores: [String] = [], title: String = "", type: String = "", userID: String = "") {
        self.id = id
        self.date = date
        self.dj_category_ids = dj_category_ids
        self.dj_dds_1 = dj_dds_1
        self.dj_dds_2 = dj_dds_2
        self.dj_round_len = dj_round_len
        self.dj_round_scores = dj_round_scores
        self.final_scores = final_scores
        self.fj_category = fj_category
        self.fj_clue = fj_clue
        self.fj_response = fj_response
        self.game_id = game_id
        self.group_index = group_index
        self.j_category_ids = j_category_ids
        self.j_dds = j_dds
        self.j_round_len = j_round_len
        self.j_round_scores = j_round_scores
        self.title = title
        self.type = type
        self.userID = userID
    }
}

struct JeopardyCategory: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var clues: [String]
    var game_id: String
    var index: Int
    var name: String
    var name_split: [String]
    var responses: [String]
}

struct Clue {
    var categoryString, clueString, responseString: String
    var isWVC, isTripleStumper: Bool
    var pointValueInt: Int
    
    init(categoryString: String = "", clueString: String = "", responseString: String = "", isDailyDouble: Bool = false, isTripleStumper: Bool = false, pointValueInt: Int = 200) {
        self.categoryString = categoryString
        self.clueString = clueString
        self.responseString = responseString
        self.isWVC = isDailyDouble
        self.isTripleStumper = isTripleStumper
        self.pointValueInt = pointValueInt
    }
    
    init(liveGameCustomSet: LiveGameCustomSet) {
        var round1PointValues = [200, 400, 600, 800, 1000]
        var clues = liveGameCustomSet.currentRound == "round1" ? liveGameCustomSet.round1Clues : liveGameCustomSet.round2Clues
        var responses = liveGameCustomSet.currentRound == "round1" ? liveGameCustomSet.round1Responses : liveGameCustomSet.round2Responses
        var categoryNames = liveGameCustomSet.currentRound == "round1" ? liveGameCustomSet.round1CategoryNames : liveGameCustomSet.round2CategoryNames
        var categoryIndex = liveGameCustomSet.currentCategoryIndex
        var clueIndex = liveGameCustomSet.currentClueIndex
        var coordsToCheckWVC = [categoryIndex, clueIndex]
        
        self.categoryString = categoryNames[categoryIndex]
        self.clueString = clues[categoryIndex]?[clueIndex] ?? ""
        self.responseString = responses[categoryIndex]?[clueIndex] ?? ""
        self.isWVC = liveGameCustomSet.currentRound == "round1" ? liveGameCustomSet.roundOneDaily == coordsToCheckWVC : (liveGameCustomSet.roundTwoDaily1 == coordsToCheckWVC || liveGameCustomSet.roundTwoDaily2 == coordsToCheckWVC)
        self.isTripleStumper = false
        self.pointValueInt = (liveGameCustomSet.currentRound == "round1" ? 1 : 2) * round1PointValues[clueIndex]
    }
}

enum MenuChoice {
    case explore, game, gamepicker, reports, profile
}
