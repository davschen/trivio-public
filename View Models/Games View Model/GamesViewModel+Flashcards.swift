//
//  GamesViewModel+Flashcards.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/17/23.
//

import Foundation

extension GamesViewModel {
    func markCardAsCorrect(flashcardClue: FlashcardClue) {
        flashcardClue.isLearned = true
    }
    
    func markCardAsIncorrect(flashcardClue: FlashcardClue) {
        flashcardClue.isLearned = false
        incrementNumAttemptsFlashcard(flashcardClue: flashcardClue)
    }
    
    func incrementNumAttemptsFlashcard(flashcardClue: FlashcardClue) {
        flashcardClue.numAttempts += 1
    }
    
    func resetFlashcardCategory(adjustedCategoryIndex: Int) {
        for clueIndex in flashcardClues2D[adjustedCategoryIndex].indices {
            let flashcardClue = flashcardClues2D[adjustedCategoryIndex][clueIndex]
            flashcardClue.isLearned = false
            flashcardClue.numAttempts = 0
        }
    }
    
    func getReadjustedCategoryIndex(flashcardClue: FlashcardClue) -> (round: Int, categoryIndex: Int) {
        var round = 1
        var categoryIndex = flashcardClue.adjustedCategoryIndex
        
        if categoryIndex - customSet.round1Len >= 0 {
            round = 2
            categoryIndex = categoryIndex - customSet.round1Len
        }
        
        return (round, categoryIndex)
    }
    
    func getCardCategoryName(adjustedCategoryIndex: Int) -> String {
        if adjustedCategoryIndex - customSet.round1Len >= 0 {
            let newCatIndex = adjustedCategoryIndex - customSet.round1Len
            return tidyCustomSet.round2Cats[newCatIndex]
        }
        return tidyCustomSet.round1Cats[adjustedCategoryIndex]
    }
    
    func getCardIsLearned(categoryIndex: Int, cardIndex: Int) -> Bool {
        return flashcardClues2D[categoryIndex][cardIndex].isLearned
    }
    
    func getCardIndicesToStudy(categoryIndex: Int) -> [Int] {
        var cardIndicesToStudy = [Int]()
        for flashcardClueIndex in flashcardClues2D[categoryIndex].indices {
            let flashcardClue = flashcardClues2D[categoryIndex][flashcardClueIndex]
            if !flashcardClue.isLearned {
                cardIndicesToStudy.append(flashcardClueIndex)
            }
        }
        return cardIndicesToStudy
    }
    
    func generateFlashcards2D() -> [[FlashcardClue]] {
        // returns a boolean array whose values are false for every category from rounds 1 and 2
        var masteredFlashcards2DRound1 = [[FlashcardClue]](repeating: [FlashcardClue](), count: customSet.round1Len)
        var masteredFlashcards2DRound2 = [[FlashcardClue]]()
        
        func generateByRound(roundIndex: Int) {
            let clues2DArray = roundIndex == 0 ? tidyCustomSet.round1Clues : tidyCustomSet.round2Clues
            let responses2DArray = roundIndex == 0 ? tidyCustomSet.round1Responses : tidyCustomSet.round2Responses
            let pointValuesArray = roundIndex == 0 ? round1PointValues : round2PointValues
            let categoryIndexAdjustor = roundIndex == 0 ? 0 : customSet.round1Len
            
            for categoryIndex in clues2DArray.indices {
                for clueIndex in clues2DArray[categoryIndex].indices {
                    let clue = clues2DArray[categoryIndex][clueIndex]
                    let response = responses2DArray[categoryIndex][clueIndex]
                    if !clue.isEmpty {
                        let newFlashcardClue = FlashcardClue(
                            clueString: clue,
                            responseString: response,
                            pointValue: pointValuesArray[clueIndex],
                            adjustedCategoryIndex: categoryIndex + categoryIndexAdjustor
                        )
                        roundIndex == 0 ? masteredFlashcards2DRound1[categoryIndex].append(newFlashcardClue) : masteredFlashcards2DRound2[categoryIndex].append(newFlashcardClue)
                    }
                }
            }
        }
        generateByRound(roundIndex: 0)
        if customSet.hasTwoRounds {
            masteredFlashcards2DRound2 = [[FlashcardClue]](repeating: [FlashcardClue](), count: customSet.round2Len)
            generateByRound(roundIndex: 1)
        }
        return masteredFlashcards2DRound1 + masteredFlashcards2DRound2
    }
}

class FlashcardClue {
    var clueString: String
    var responseString: String
    var pointValue: String
    var isLearned: Bool
    var numAttempts: Int
    var adjustedCategoryIndex: Int
    
    init(clueString: String = "", responseString: String = "", pointValue: String = "200", isLearned: Bool = false, numAttempts: Int = 0, adjustedCategoryIndex: Int) {
        self.clueString = clueString
        self.responseString = responseString
        self.pointValue = pointValue
        self.isLearned = isLearned
        self.numAttempts = numAttempts
        self.adjustedCategoryIndex = adjustedCategoryIndex
    }
}
