//
//  Live.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/17/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct LiveGameCustomSet: Decodable, Hashable, Identifiable, Encodable {
    @DocumentID var id: String?
    var hostUsername, hostName, userSetID, hostCode, playerCode, title, finalCat, finalClue, finalResponse: String
    var hostHasJoined, gameHasBegun, hasTwoRounds: Bool
    var numSubmitted, numClues, round1Len, round2Len: Int
    var roundOneDaily, roundTwoDaily1, roundTwoDaily2: [Int]
    var round1CategoryNames, round2CategoryNames: [String]
    var round1Clues, round1Responses, round2Clues, round2Responses : [Int:[String]]
    var dateInitiated: Date
    var currentPlayerId: String = ""
    var buzzerWinnerId: String = ""
    var buzzersEnabled: Bool = false
    var buzzersEnabledDateTime: Date = Date()
    var currentRound: String = "round1"
    var currentCategoryIndex: Int = 0
    var currentClueIndex: Int = 0
    var isCurrentClueWVC: Bool = false
    var hasBegunDictating: Bool = false
    var hasFinishedDictating: Bool = false
    var currentGameDisplay: String = "board"
    
    init(hostUsername: String, hostName: String, userSetId: String, hostCode: String, playerCode: String, tidyCustomSet: TidyCustomSet, customSet: CustomSetCherry, hostHasJoined: Bool = false, gameHasBegun: Bool = false, numSubmitted: Int = 0) {
        self.hostUsername = hostUsername
        self.hostName = hostName
        self.userSetID = userSetId
        self.hostCode = hostCode
        self.playerCode = playerCode
        self.hostHasJoined = hostHasJoined
        self.gameHasBegun = gameHasBegun
        self.numSubmitted = numSubmitted
        self.round1CategoryNames = tidyCustomSet.round1Cats
        self.round2CategoryNames = tidyCustomSet.round2Cats
        self.round1Clues = MasterHandler().nestedStringArrayToDict(tidyCustomSet.round1Clues)
        self.round1Responses = MasterHandler().nestedStringArrayToDict(tidyCustomSet.round1Responses)
        self.round2Clues = MasterHandler().nestedStringArrayToDict(tidyCustomSet.round2Clues)
        self.round2Responses = MasterHandler().nestedStringArrayToDict(tidyCustomSet.round2Responses)
        self.title = customSet.title
        self.finalCat = customSet.finalCat
        self.finalClue = customSet.finalClue
        self.finalResponse = customSet.finalResponse
        self.roundOneDaily = customSet.roundOneDaily
        self.roundTwoDaily1 = customSet.roundTwoDaily1
        self.roundTwoDaily2 = customSet.roundTwoDaily2
        self.numClues = customSet.numClues
        self.round1Len = customSet.round1Len
        self.round2Len = customSet.round2Len
        self.hasTwoRounds = customSet.hasTwoRounds
        self.dateInitiated = Date()
    }
}

extension LiveGameCustomSet {
    init(hostUsername: String = "", hostName: String = "", userSetID: String = "", hostCode: String = "", playerCode: String = "", title: String = "", finalCat: String = "", finalClue: String = "", finalResponse: String = "", hostHasJoined: Bool = false, gameHasBegun: Bool = false, hasTwoRounds: Bool = false, numSubmitted: Int = 0, numClues: Int = 0, round1Len: Int = 0, round2Len: Int = 0, roundOneDaily: [Int] = [], roundTwoDaily1: [Int] = [], roundTwoDaily2: [Int] = [], round1CategoryNames: [String] = [], round2CategoryNames: [String] = [], round1Clues: [[String]] = [], round1Responses: [[String]] = [], round2Clues: [[String]] = [], round2Responses: [[String]] = [], currentPlayerId: String = "", buzzerWinnerId: String = "", buzzersEnabled: Bool = false, buzzersEnabledDateTime: Date = Date(), currentRound: String = "round1", currentCategoryIndex: Int = 0, currentClueIndex: Int = 0, isCurrentClueWVC: Bool = false, hasBegunDictating: Bool = false, hasFinishedDictating: Bool = false, currentGameDisplay: String = "board") {
        self.hostUsername = hostUsername
        self.hostName = hostName
        self.userSetID = userSetID
        self.hostCode = hostCode
        self.playerCode = playerCode
        self.hostHasJoined = hostHasJoined
        self.gameHasBegun = gameHasBegun
        self.numSubmitted = numSubmitted
        self.round1CategoryNames = round1CategoryNames
        self.round2CategoryNames = round2CategoryNames
        self.round1Clues = MasterHandler().nestedStringArrayToDict(round1Clues)
        self.round1Responses = MasterHandler().nestedStringArrayToDict(round1Responses)
        self.round2Clues = MasterHandler().nestedStringArrayToDict(round2Clues)
        self.round2Responses = MasterHandler().nestedStringArrayToDict(round2Responses)
        self.title = title
        self.finalCat = finalCat
        self.finalClue = finalClue
        self.finalResponse = finalResponse
        self.roundOneDaily = roundOneDaily
        self.roundTwoDaily1 = roundTwoDaily1
        self.roundTwoDaily2 = roundTwoDaily2
        self.numClues = numClues
        self.round1Len = round1Len
        self.round2Len = round2Len
        self.hasTwoRounds = hasTwoRounds
        self.dateInitiated = Date()
        self.currentPlayerId = currentPlayerId
        self.buzzerWinnerId = buzzerWinnerId
        self.buzzersEnabled = buzzersEnabled
        self.buzzersEnabledDateTime = buzzersEnabledDateTime
        self.currentRound = currentRound
        self.currentCategoryIndex = currentCategoryIndex
        self.currentClueIndex = currentClueIndex
        self.isCurrentClueWVC = isCurrentClueWVC
        self.hasBegunDictating = hasBegunDictating
        self.hasFinishedDictating = hasFinishedDictating
        self.currentGameDisplay = currentGameDisplay
    }
}

struct LiveGamePlayer: Codable, Hashable, Identifiable {
    @DocumentID var id: String?
    var nickname: String
    var currentScore: Int
    var previousScore: Int
    var currentRank: Int
    var previousRank: Int
    var currentResponse: String
    var responseSubmitted: Bool
    var currentWager: Int
    var wagerSubmitted: Bool
    var lastBuzzedDateTime: Date

    init(id: String? = nil,
         nickname: String = "",
         currentScore: Int = 0,
         previousScore: Int = 0,
         currentRank: Int = 0,
         previousRank: Int = 0,
         currentResponse: String = "",
         responseSubmitted: Bool = false,
         currentWager: Int = 0,
         wagerSubmitted: Bool = false,
         lastBuzzedDateTime: Date = Date()) {

        self.id = id
        self.nickname = nickname
        self.currentScore = currentScore
        self.previousScore = previousScore
        self.currentRank = currentRank
        self.previousRank = previousRank
        self.currentResponse = currentResponse
        self.responseSubmitted = responseSubmitted
        self.currentWager = currentWager
        self.wagerSubmitted = wagerSubmitted
        self.lastBuzzedDateTime = lastBuzzedDateTime
    }
}

