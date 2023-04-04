//
//  GameViewModel.swift
//  Trivio
//
//  Created by David Chen on 2/3/21.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class GamesViewModel: ObservableObject {
    @Published var menuChoice: MenuChoice = .explore
    
    @Published var pointValueArray = ["200", "400", "600", "800", "1000"]
    @Published var gameSetupMode: GameSetupMode = .settings
    @Published var gamePhase: GamePhase = .round1
    @Published var gameplayDisplay: GameplayDisplay = .grid
    @Published var finalTrivioStage: FinalTrivioStage = .notBegun
    
    @Published var gamePreviews = [JeopardySetPreview]()
    @Published var jeopardySeasons = [JeopardySeason]()
    
    // Editing note: this could have far fewer variables
    // if I made classes with some of these variables
    
    // Flashcards
    @Published var flashcardClues2D = [[FlashcardClue]]()
    
    // Nested arrays clues & responses can be indexed into with [i][j]
    // where categoryIndex = i and pointValueIndex = j
    @Published var categories = [String]()
    @Published var clues: [[String]] = []
    @Published var responses: [[String]] = []
    @Published var round1TripleStumpers: [[Int]] = []
    @Published var round2TripleStumpers: [[Int]] = []
    
    @Published var selectedSeason = ""
    @Published var finishedClues2D = [[ClueCompletionStatus]]()
    @Published var finishedCategories = [Bool](repeating: false, count: 6)
    @Published var usedAnswers = [String]()
    @Published var clueMechanics = ClueMechanics()
    
    @Published var customSets = [CustomSetCherry]()
    @Published var customSet = CustomSetCherry()
    @Published var jeopardySet = JeopardySet()
    @Published var tidyCustomSet = TidyCustomSet()
    @Published var liveGameCustomSet = LiveGameCustomSet()
    @Published var liveGamePlayers = [LiveGamePlayer]()
    
    @Published var title = ""
    @Published var queriedUserName = ""

    @Published var previewViewShowing = false
    @Published var playedGames = [String]()
    
    public var currentSelectedClue = Clue()
    public var currentCategoryIndex = 0
    public var categoryCompletes = [Int](repeating: 0, count: 6)
    public var jCategoryCompletesReference = [Int](repeating: 0, count: 6)
    public var djCategoryCompletesReference = [Int](repeating: 0, count: 6)
    public var jRoundCompletes = 0
    public var djRoundCompletes = 0
    public var latestJeopardyDoc: DocumentSnapshot? = nil
    public var listener: ListenerRegistration?
    
    public var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        return df
    }
    
    public var round1PointValues = ["200", "400", "600", "800", "1000"]
    public var round2PointValues = ["400", "800", "1200", "1600", "2000"]
    
    public var db = FirebaseConfigurator.shared.getFirestore()
    
    init() {
        getSeasons()
        readCustomData()
    }
    
    // for starting a new game
    func reset() {
        gamePhase = .round1
        clues = tidyCustomSet.round1Clues
        responses = tidyCustomSet.round1Responses
        finishedClues2D = generateFinishedClues2D()
        pointValueArray = round1PointValues
        categories = tidyCustomSet.round1Cats
        finalTrivioStage = .notBegun
        currentCategoryIndex = 0
    }
    
    func moveOntoRound2() {
        gamePhase = .round2
        categories = tidyCustomSet.round2Cats
        finishedClues2D = generateFinishedClues2D()
        clues = tidyCustomSet.round2Clues
        responses = tidyCustomSet.round2Responses
        pointValueArray = round2PointValues
        currentCategoryIndex = 0
    }
    
    func setSeason(jeopardySeason: JeopardySeason) {
        selectedSeason = jeopardySeason.id ?? "NID"
    }
    
    func getCountdown(second: Int) -> (lower: Int, upper: Int) {
        let highBound = Int(clueMechanics.numCountdownSeconds * 2)
        if second <= Int(clueMechanics.numCountdownSeconds) {
            return (second, highBound - second)
        } else {
            return (0, 0)
        }
    }
    
    // for clearing your selection
    func clearAll() {
        usedAnswers.removeAll()
        tidyCustomSet = TidyCustomSet()
        gamePhase = .round1
        gameSetupMode = .settings
        round1TripleStumpers.removeAll()
        round2TripleStumpers.removeAll()
        customSet = CustomSetCherry(customSet: CustomSet())
        clearCategoryDones()
        jCategoryCompletesReference = [Int](repeating: 0, count: 6)
        djCategoryCompletesReference = [Int](repeating: 0, count: 6)
        jRoundCompletes = 0
        djRoundCompletes = 0
        queriedUserName.removeAll()
    }
    
    func generateFinishedClues2D() -> [[ClueCompletionStatus]] {
        let cluesNestedArray = gamePhase == .round1 ? tidyCustomSet.round1Clues : tidyCustomSet.round2Clues
        var finishedClues2D = [[ClueCompletionStatus]]()
        cluesNestedArray.forEach { cluesArray in
            finishedClues2D.append(cluesArray.compactMap { $0.isEmpty ? .empty : .incomplete })
        }
        finishedCategories = [Bool](repeating: false, count: finishedClues2D.count)
        return finishedClues2D
    }
    
    func modifyFinishedClues2D(categoryIndex: Int, clueIndex: Int, completed: Bool = true) {
        if finishedClues2D[categoryIndex][clueIndex] == .empty { return }
        finishedClues2D[categoryIndex][clueIndex] = completed ? .complete : .incomplete
        // this tricky piece of code marks a category as finished if all of its clues are finished
        finishedCategories[categoryIndex] = finishedClues2D[categoryIndex].allSatisfy({$0 != .incomplete})
    }
    
    func getNumCompletedClues() -> Int {
        return finishedClues2D.joined().filter{$0 == .complete}.count
    }
    
    func timerBlockIsUnlit(timeElapsed: Double, blockIndex: Int) -> Bool {
        let maxIndex = 8
        if timeElapsed <= 0 { return false }
        if timeElapsed > (Double(maxIndex) / 2.0) + 1 { return true }
        let a = 0
        let b = maxIndex
        let adjustedTimeElapsed = Int(timeElapsed - 1)
        return (blockIndex <= a + adjustedTimeElapsed) || (blockIndex >= b - adjustedTimeElapsed)
    }
    
    func getCurrentSelectedClue() -> Clue {
        return currentSelectedClue
    }
    
    func setCurrentSelectedClue(categoryIndex: Int, clueIndex: Int) {
        gameplayDisplay = .clue
        
        let clueCounts: Int = clues[categoryIndex].count
        let responsesCounts: Int = responses[categoryIndex].count
        let clueString: String = clueCounts - 1 >= clueIndex ? clues[categoryIndex][clueIndex] : ""
        let responseString: String = responsesCounts - 1 >= clueIndex ? responses[categoryIndex][clueIndex] : ""
        let pointValueInt = Int(pointValueArray[clueIndex]) ?? 0
        
        currentSelectedClue = Clue(categoryString: categories[categoryIndex], clueString: clueString, responseString: responseString, isDailyDouble: clueIsDailyDouble(categoryIndex: categoryIndex, clueIndex: clueIndex), isTripleStumper: clueIsTripleStumper(categoryIndex: categoryIndex, clueIndex: clueIndex), pointValueInt: pointValueInt)
        
        modifyFinishedClues2D(categoryIndex: categoryIndex, clueIndex: clueIndex)
        currentCategoryIndex = categoryIndex
    }
    
    func clueIsDailyDouble(categoryIndex: Int, clueIndex: Int) -> Bool {
        // Check if this is a Jeopardy-made set or not...
        let toCheck: [Int] = customSet.userID.isEmpty ? [clueIndex, categoryIndex] : [categoryIndex, clueIndex]
        if gamePhase == .round1 {
            return toCheck == customSet.roundOneDaily
        } else {
            return (toCheck == customSet.roundTwoDaily1 || toCheck == customSet.roundTwoDaily2)
        }
    }
    
    func clueIsTripleStumper(categoryIndex: Int, clueIndex: Int) -> Bool {
        let toCheck: [Int] = [categoryIndex, clueIndex]
        if gamePhase == .round1 {
            return round1TripleStumpers.contains(toCheck)
        } else {
            return round2TripleStumpers.contains(toCheck)
        }
    }
    
    func progressGame() {
        gameplayDisplay = .grid
        clueMechanics.resetAllVariables()
        if doneWithRound() {
            if gamePhase == .round1 && customSet.hasTwoRounds {
                moveOntoRound2()
            } else {
                gamePhase = .finalRound
            }
        }
    }
    
    func doneWithRound() -> Bool {
        if gamePhase != .finalRound {
            return finishedCategories.allSatisfy({ $0 })
        } else {
            return false
        }
    }
    
    func clearCategoryDones() {
        for i in 0..<self.categoryCompletes.count {
            categoryCompletes[i] = 0
        }
    }
    
    func gameInProgress() -> Bool {
        if gamePhase == .round1 && finishedClues2D.joined().filter({$0 == .complete}).count == 0 {
            return false
        } else {
            return true
        }
    }
}

enum ClueCompletionStatus {
    case empty, incomplete, complete
}

enum GameSetupMode {
    case settings, participants, play
}

enum GamePhase: CaseIterable {
    case round1, round2, finalRound
}

enum GameplayDisplay {
    case grid, clue
}

struct ClueMechanics {
    var showResponse: Bool = false
    var wvcWagerMade: Bool = false
    var numCountdownSeconds: Double = 5
    var timeElapsed: Double = 0
    var wvcWager: Double = 0
    
    mutating func resetAllVariables() {
        timeElapsed = 0
        wvcWager = 0
        wvcWagerMade = false
        showResponse = false
    }
    
    mutating func toggleWVCWagerMade() {
        wvcWagerMade.toggle()
    }
    
    mutating func toggleShowResponse() {
        showResponse.toggle()
    }
    
    mutating func setTimeElapsed(newValue: Double) {
        timeElapsed = newValue
    }
}
