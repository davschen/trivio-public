//
//  BuildViewModel.swift
//  Trivio
//
//  Created by David Chen on 3/12/21.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class BuildViewModel: ObservableObject {
    @Published var buildStage: BuildStage = .details
    @Published var buildPhaseType: BuildPhaseType = .rounds1and2
    @Published var currentDisplay: CurrentDisplay = .settings
    @Published var currCustomSet = CustomSetCherry()

    @Published var moneySections = ["", "", "", "", ""]
    
    @Published var isPreviewDisplayModern = true
    @Published var mostAdvancedStage: BuildStage = .details
    @Published var isPublic = true
    @Published var tag = ""
    @Published var categories = [CustomSetCategory]()
    @Published var jCategories = [CustomSetCategory]()
    @Published var djCategories = [CustomSetCategory]()
    @Published var isRandomDD = false
    
    @Published var dirtyBit = 0
    @Published var editingClueIndex = 0
    @Published var choosingDailyDoubles = false
    @Published var round1CatsShowing = [Bool]()
    @Published var round2CatsShowing = [Bool]()
    
    @Published var cluePreview = ""
    @Published var responsePreview = ""
    @Published var processPending = false
    @Published var showingBuildView = false
    
    public var editingCategoryIndex = 0
    public var moneySectionsJ = ["200", "400", "600", "800", "1000"]
    public var moneySectionsDJ = ["400", "800", "1200", "1600", "2000"]
    public var emptyStrings = ["", "", "", "", ""]
    public var myUID = FirebaseConfigurator.shared.auth.currentUser?.uid ?? "noUID"
    public var db = FirebaseConfigurator.shared.getFirestore()
    
    init() {
        self.fillBlanks()
    }
    
    func clearAll() {
        self.categories.removeAll()
        self.jCategories.removeAll()
        self.djCategories.removeAll()
        self.currCustomSet = CustomSetCherry()
        
        self.editingClueIndex = 0
        self.round1CatsShowing.removeAll()
        self.round2CatsShowing.removeAll()
        self.moneySections = moneySectionsJ
        self.fillBlanks()
    }
    
    func getCategoryIDs(isDJ: Bool) -> [String] {
        var IDs = [String]()
        for i in 0..<(isDJ ? currCustomSet.round2Len : currCustomSet.round2Len) {
            let category = isDJ ? djCategories[i] : jCategories[i]
            if let id = category.id {
                IDs.append(id)
            }
        }
        return IDs
    }
    
    func fillBlanks() {
        guard let currSetID = currCustomSet.id else { return }
        for i in 0..<self.currCustomSet.round1Len {
            self.jCategories.append(Empty().category(index: i, emptyStrings: emptyStrings, gameID: currSetID))
            round1CatsShowing.append(true)
        }
        for i in 0..<self.currCustomSet.round2Len {
            self.djCategories.append(Empty().category(index: i, emptyStrings: emptyStrings, gameID: currSetID))
            round2CatsShowing.append(true)
        }
        moneySections = moneySectionsJ
        
        buildStage = .details
        currentDisplay = .settings
    }
    
    func incrementDirtyBit() {
        if MasterHandler().deviceType == .iPad { determineMostAdvancedStage() }
        dirtyBit += 1
    }
    
    func resetDirtyBit() {
        dirtyBit = 0
    }
    
    func start() {
        clearAll()
        showingBuildView.toggle()
        mostAdvancedStage = .details
    }
    
    func getNumClues() -> Int {
        var numClues = 0
        for i in 0..<currCustomSet.round1Len {
            let clues = jCategories[i].clues
            let responses = jCategories[i].responses
            for j in 0..<emptyStrings.count {
                if !clues[j].isEmpty && !responses[j].isEmpty {
                    numClues += 1
                }
            }
        }
        if !currCustomSet.hasTwoRounds { return numClues }
        for i in 0..<currCustomSet.round2Len {
            let clues = djCategories[i].clues
            let responses = djCategories[i].responses
            for j in 0..<emptyStrings.count {
                if !clues[j].isEmpty && !responses[j].isEmpty {
                    numClues += 1
                }
            }
        }
        return numClues
    }
    
    func clearDailyDoubles() {
        if buildStage == .trivioRoundDD {
            self.currCustomSet.roundOneDaily.removeAll()
        } else if buildStage == .dtRoundDD {
            self.currCustomSet.roundTwoDaily1.removeAll()
            self.currCustomSet.roundTwoDaily2.removeAll()
        }
    }
    
    func randomDDs() {
        clearDailyDoubles()
        if buildStage == .trivioRoundDD {
            while self.currCustomSet.roundOneDaily.isEmpty {
                let randCol = Int.random(in: 0..<currCustomSet.round1Len)
                let randRow = Int.random(in: 0..<5)

                if !(self.jCategories[randCol].clues[randRow].isEmpty && self.jCategories[randCol].responses[randRow].isEmpty) {
                    self.currCustomSet.roundOneDaily = [randCol, randRow]
                }
            }
        } else if buildStage == .dtRoundDD {
            while self.currCustomSet.roundTwoDaily1.isEmpty || self.currCustomSet.roundTwoDaily2.isEmpty {
                let randCol = Int.random(in: 0..<currCustomSet.round2Len)
                let randRow = Int.random(in: 0..<5)
                if self.currCustomSet.roundTwoDaily1.isEmpty {
                    if !self.djCategories[randCol].clues[randRow].isEmpty {
                        self.currCustomSet.roundTwoDaily1 = [randCol, randRow]
                    }
                } else if self.currCustomSet.roundTwoDaily2.isEmpty {
                    if !self.djCategories[randCol].clues[randRow].isEmpty
                        && self.currCustomSet.roundTwoDaily1[0] != randCol {
                        self.currCustomSet.roundTwoDaily2 = [randCol, randRow]
                    }
                }
            }
        }
    }
    
    func getCategoryName(catIndex: Int) -> String {
        if buildStage == .trivioRound || buildStage == .trivioRoundDD {
            return jCategories[catIndex].name
        } else {
            return djCategories[catIndex].name
        }
    }
    
    func getClueResponsePair(crIndex: Int, catIndex: Int) -> (clue: String, response: String) {
        if buildStage == .trivioRound {
            return (jCategories[catIndex].clues[crIndex], jCategories[catIndex].responses[crIndex])
        } else {
            return (djCategories[catIndex].clues[crIndex], djCategories[catIndex].responses[crIndex])
        }
    }
    
    func addCategoryName(name: String, catIndex: Int) {
        if buildStage == .trivioRound || buildStage == .trivioRoundDD {
            jCategories[catIndex].name = name
        } else {
            djCategories[catIndex].name = name
        }
    }
    
    func addClueResponsePair(clue: String, response: String, crIndex: Int, catIndex: Int) {
        if buildStage == .trivioRound {
            jCategories[catIndex].clues[crIndex] = clue
            jCategories[catIndex].responses[crIndex] = response
        } else {
            djCategories[catIndex].clues[crIndex] = clue
            djCategories[catIndex].responses[crIndex] = response
        }
    }
    
    func ddsFilled() -> Bool {
        switch buildStage {
        case .dtRoundDD:
            return !currCustomSet.roundTwoDaily1.isEmpty && !currCustomSet.roundTwoDaily2.isEmpty
        default:
            return !currCustomSet.roundOneDaily.isEmpty
        }
    }
    
    func setEditingIndex(index: Int) {
        self.editingClueIndex = index
    }
    
    func stepStringHandler() -> String {
        var stepString = ""
        switch buildStage {
        case .trivioRound:
            stepString = "Trivio! Round"
        case .trivioRoundDD:
            stepString = "Trivio! Round Duplexes"
        case .dtRound:
            stepString = "Double Trivio! Round"
        case .dtRoundDD:
            stepString = "Double Trivio! Round Duplexes"
        case .finalTrivio:
            stepString = "Final Trivio! Clue"
        default:
            stepString = "Finishing Touches"
        }
        return stepString
    }
    
    func descriptionHandler() -> String {
        var description = ""
        switch buildStage {
        case .trivioRound:
            description = "Add & Edit Categories"
        case .trivioRoundDD:
            description = "Select One Duplex of the Day"
        case .dtRound:
            description = "Add & Edit Categories"
        case .dtRoundDD:
            description = "Select Two Duplex of the Days"
        case .finalTrivio:
            description = "Add A Category, Clue, and Response"
        default:
            description = "Add a title, at least 2 tags, and decide if the set should be public"
        }
        return description
    }
    
    func backStringHandler() -> String {
        var backString = ""
        switch buildStage {
        case .trivioRoundDD, .dtRoundDD:
            backString = "Back to Editing Categories"
        case .dtRound, .finalTrivio:
            backString = "Back to Choosing Duplex of the Days"
        case .details:
            backString = "Back to Final Trivio"
        default:
            backString = "Back"
        }
        return backString
    }
    
    func categoryEmpty(category: CustomSetCategory) -> Bool {
        for i in 0..<category.clues.count {
            let clue = category.clues[i]
            let response = category.responses[i]
            if !clue.isEmpty && !response.isEmpty {
                return false
            }
        }
        return true
    }
    
    func stringArrEmpty(stringArr: [String]) -> Bool {
        for string in stringArr {
            if !string.isEmpty {
                return false
            }
        }
        return true
    }
    
    public func changePointValues(isAdvancing: Bool) {
        moneySections = isAdvancing ? moneySectionsDJ : moneySectionsJ
    }
    
    func nextButtonHandler() {
        let buildStageIndexDict = MobileBuildStageIndexDict()
        let buildStageIndex = buildStageIndexDict.getIndex(from: buildStage)
        let mostAdvancedStageIndex = buildStageIndexDict.getIndex(from: mostAdvancedStage)
        
        currCustomSet.isDraft = !checkForSetIsComplete()
        
        switch buildStage {
        case .details:
            buildStage = .trivioRound
            currentDisplay = .grid
            editingCategoryIndex = 0
        case .trivioRound:
            buildStage = .trivioRoundDD
            currentDisplay = .grid
            editingCategoryIndex = 0
        case .trivioRoundDD:
            if currCustomSet.hasTwoRounds {
                buildStage = .dtRound
                changePointValues(isAdvancing: true)
            } else {
                buildStage = .finalTrivio
                currentDisplay = .finalTrivio
            }
        case .dtRound:
            buildStage = .dtRoundDD
            isRandomDD = false
            currentDisplay = .grid
            editingCategoryIndex = 0
        case .dtRoundDD:
            buildStage = .finalTrivio
            currentDisplay = .finalTrivio
        default:
            writeToFirestore()
            showingBuildView.toggle()
        }
        if mostAdvancedStageIndex <= buildStageIndex {
            mostAdvancedStage = buildStage
        }
    }
    
    func addDailyDouble(i: Int, j: Int) {
        switch buildStage {
        case .dtRoundDD:
            if currCustomSet.roundTwoDaily1 == [i, j] {
                currCustomSet.roundTwoDaily1.removeAll()
            } else if currCustomSet.roundTwoDaily2 == [i, j] {
                currCustomSet.roundTwoDaily2.removeAll()
            } else {
                if currCustomSet.roundTwoDaily1.isEmpty {
                    currCustomSet.roundTwoDaily1 = [i, j]
                } else if i != currCustomSet.roundTwoDaily1[0] {
                    currCustomSet.roundTwoDaily2 = [i, j]
                }
            }
            determineMostAdvancedStage()
        default:
            currCustomSet.roundOneDaily = [i, j]
        }
    }
    
    func isDailyDouble(i: Int, j: Int) -> Bool {
        if buildStage == .dtRoundDD {
            return self.currCustomSet.roundTwoDaily1 == [i, j] || self.currCustomSet.roundTwoDaily2 == [i, j]
        } else if buildStage == .trivioRoundDD {
            return self.currCustomSet.roundOneDaily == [i, j]
        }
        return false
    }
    
    func addTag() {
        tag.split(separator: " ").forEach { tag in
            if !currCustomSet.tags.contains(String(tag)) {
                currCustomSet.tags.append(String(tag))
                incrementDirtyBit()
            }
        }
        self.tag.removeAll()
    }
    
    func removeTag(tag: String) {
        currCustomSet.tags = currCustomSet.tags.filter { $0 != tag }
        incrementDirtyBit()
    }
    
    func getKeywords() -> [String] {
        // example title: Jeopardy with host Alex Trebek
        let splitTitle = currCustomSet.title.split(separator: " ")
        
        var keywords = [""]
        
        for i in 0..<splitTitle.count {
            var growingName = ""
            let joinedTitle = Array(splitTitle[i..<splitTitle.count]).joined(separator: " ")
            joinedTitle.forEach { char in
                growingName += String(char).lowercased()
                keywords.append(growingName)
            }
        }
        
        return keywords
    }
    
    func getCategoryNames() -> [String] {
        var names = [String]()
        for i in 0..<currCustomSet.round1Len {
            let name = jCategories[i].name
            let nameSplit = name.split(separator: " ").compactMap { String($0).uppercased() }
            names.append(contentsOf: nameSplit)
        }
        for i in 0..<currCustomSet.round2Len {
            let name = djCategories[i].name
            let nameSplit = name.split(separator: " ").compactMap { String($0).uppercased() }
            names.append(contentsOf: nameSplit)
        }
        return names
    }
    
    func setPreviews(clue: String, response: String) {
        self.cluePreview = clue.uppercased()
        self.responsePreview = response.uppercased()
    }
    
    func swap(currentIndex: Int, swapToIndex: Int, categoryIndex: Int) {
        // good old fashioned swapping
        if buildStage == .trivioRound {
            let tempClue = jCategories[categoryIndex].clues[currentIndex]
            let tempResponse = jCategories[categoryIndex].responses[currentIndex]
            jCategories[categoryIndex].clues[currentIndex] = jCategories[categoryIndex].clues[swapToIndex]
            jCategories[categoryIndex].responses[currentIndex] = jCategories[categoryIndex].responses[swapToIndex]
            jCategories[categoryIndex].clues[swapToIndex] = tempClue
            jCategories[categoryIndex].responses[swapToIndex] = tempResponse
        } else {
            let tempClue = djCategories[categoryIndex].clues[currentIndex]
            let tempResponse = djCategories[categoryIndex].responses[currentIndex]
            djCategories[categoryIndex].clues[currentIndex] = djCategories[categoryIndex].clues[swapToIndex]
            djCategories[categoryIndex].responses[currentIndex] = djCategories[categoryIndex].responses[swapToIndex]
            djCategories[categoryIndex].clues[swapToIndex] = tempClue
            djCategories[categoryIndex].responses[swapToIndex] = tempResponse
        }
    }
}

struct Empty {
    var game = Game(id: "", date: Date(), dj_category_ids: [], dj_dds_1: [], dj_dds_2: [], dj_round_len: 0, fj_category: "", fj_clue: "", fj_response: "", game_id: "", group_index: 0, j_category_ids: [], j_round_len: 0, title: "", type: "", userID: "")
    var team = Team(id: UUID().uuidString, index: 0, name: "", members: [], score: 0, color: "blue")
    func category(index: Int, emptyStrings: [String], gameID: String) -> CustomSetCategory {
        return CustomSetCategory(id: UUID().uuidString, name: "", index: index, clues: emptyStrings, responses: emptyStrings, gameID: gameID, imageURLs: [:], audioURLs: [:])
    }
}

enum BuildStage {
    case details, trivioRound, trivioRoundDD, dtRound, dtRoundDD, finalTrivio
}

enum CurrentDisplay {
    case grid, buildAll, finalTrivio, settings, saveDraft
}
