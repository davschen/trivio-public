//
//  BuildViewModel+FlowControl.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/17/22.
//

import Foundation

extension BuildViewModel {
    func back() {
        switch buildStage {
        case .trivioRound:
            buildStage = .details
            currentDisplay = .settings
        case .trivioRoundDD:
            buildStage = .trivioRound
            currentDisplay = .grid
        case .dtRound:
            moneySections = moneySectionsJ
            buildStage = .trivioRoundDD
            currentDisplay = .grid
        case .dtRoundDD:
            buildStage = .dtRound
            currentDisplay = .grid
        case .finalTrivio:
            if currCustomSet.hasTwoRounds {
                buildStage = .dtRoundDD
            } else {
                buildStage = .trivioRoundDD
            }
            currentDisplay = .grid
        default:
            buildStage = .finalTrivio
            currentDisplay = .finalTrivio
        }
    }
    
    func rectifyNextProhibited() {
        // Can't get this to work, but it's supposed to reconsider mostAdvancedStage
//        mostAdvancedStage = buildStage
    }
    
    func determineMostAdvancedStage() {
        var round1FilledCount = 0
        var round2FilledCount = 0
        for category in jCategories {
            round1FilledCount += (!category.name.isEmpty && !categoryEmpty(category: category)) ? 1 : 0
        }
        for category in djCategories {
            round2FilledCount += (!category.name.isEmpty && !categoryEmpty(category: category)) ? 1 : 0
        }
        
        let detailsCheck = true
        let trivioRoundCheck = !currCustomSet.tags.isEmpty && !currCustomSet.title.isEmpty
        let roundOneDailyCheck = round1FilledCount >= currCustomSet.round1Len
        let dtRoundCheck = !currCustomSet.roundOneDaily.isEmpty
        let roundTwoDailyCheck = round2FilledCount >= currCustomSet.round2Len
        let finalCheck = !currCustomSet.roundTwoDaily1.isEmpty && !currCustomSet.roundTwoDaily2.isEmpty
        
        let allBools = currCustomSet.hasTwoRounds ? [detailsCheck, trivioRoundCheck, roundOneDailyCheck, dtRoundCheck, roundTwoDailyCheck, finalCheck] : [detailsCheck, trivioRoundCheck, roundOneDailyCheck, dtRoundCheck]
        
        for i in allBools.indices {
            if allBools[i] {
                guard let stageAtIndex = MobileBuildStageIndexDict().reverseDict[i] else { return }
                if stageAtIndex == .dtRound && !currCustomSet.hasTwoRounds {
                    mostAdvancedStage = .finalTrivio
                } else {
                    mostAdvancedStage = stageAtIndex
                }
            } else {
                return
            }
        }
    }
    
    func checkForSetIsComplete() -> Bool {
        var round1FilledCount = 0
        var round2FilledCount = 0
        for category in jCategories {
            round1FilledCount += (!category.name.isEmpty && !categoryEmpty(category: category)) ? 1 : 0
        }
        for category in djCategories {
            round2FilledCount += (!category.name.isEmpty && !categoryEmpty(category: category)) ? 1 : 0
        }
        
        let detailsCheck = !currCustomSet.tags.isEmpty && !currCustomSet.title.isEmpty
        let trivioRoundCheck = round1FilledCount >= currCustomSet.round1Len
        let dtRoundCheck = round2FilledCount >= currCustomSet.round2Len
        let roundOneDailyCheck = !currCustomSet.roundOneDaily.isEmpty
        let roundTwoDailyCheck = !currCustomSet.roundTwoDaily1.isEmpty && !currCustomSet.roundTwoDaily2.isEmpty
        let finalCheck = !currCustomSet.finalCat.isEmpty && !currCustomSet.finalClue.isEmpty && !currCustomSet.finalResponse.isEmpty
        
        if currCustomSet.hasTwoRounds {
            return detailsCheck && trivioRoundCheck && dtRoundCheck && roundOneDailyCheck && roundTwoDailyCheck && finalCheck
        } else {
            return detailsCheck && trivioRoundCheck && roundOneDailyCheck && finalCheck
        }
    }
    
    func nextPermitted() -> Bool {
        switch buildStage {
        case .details:
            if currCustomSet.tags.isEmpty || currCustomSet.title.isEmpty {
                rectifyNextProhibited()
            }
            return !currCustomSet.tags.isEmpty && !currCustomSet.title.isEmpty
        case .trivioRound:
            var numFilled = 0
            for category in jCategories {
                numFilled += (!category.name.isEmpty && !categoryEmpty(category: category)) ? 1 : 0
            }
            if numFilled < currCustomSet.round1Len {
                rectifyNextProhibited()
            }
            return numFilled >= currCustomSet.round1Len
        case .dtRound:
            var numFilled = 0
            for category in djCategories {
                numFilled += (!category.name.isEmpty && !categoryEmpty(category: category)) ? 1 : 0
            }
            if numFilled < currCustomSet.round2Len {
                rectifyNextProhibited()
            }
            return numFilled >= currCustomSet.round2Len
        case .trivioRoundDD:
            if currCustomSet.roundOneDaily.isEmpty {
                rectifyNextProhibited()
            }
            return !currCustomSet.roundOneDaily.isEmpty
        case .dtRoundDD:
            if (currCustomSet.roundTwoDaily1.isEmpty  || currCustomSet.roundTwoDaily2.isEmpty) {
                rectifyNextProhibited()
            }
            return (!currCustomSet.roundTwoDaily1.isEmpty && !currCustomSet.roundTwoDaily2.isEmpty)
        default:
            if currCustomSet.finalCat.isEmpty || currCustomSet.finalClue.isEmpty || currCustomSet.finalResponse.isEmpty {
                rectifyNextProhibited()
            }
            return checkForSetIsComplete()
        }
    }
}

struct MobileBuildStageIndexDict {
    var dict: [BuildStage:Int] = [
        .details: 0,
        .trivioRound: 1,
        .trivioRoundDD: 2,
        .dtRound: 3,
        .dtRoundDD: 4,
        .finalTrivio: 5
    ]
    
    var reverseDict: [Int:BuildStage] = [
        0 : .details,
        1 : .trivioRound,
        2 : .trivioRoundDD,
        3 : .dtRound,
        4 : .dtRoundDD,
        5 : .finalTrivio
    ]
    
    func getIndex(from buildStage: BuildStage) -> Int {
        return dict[buildStage] ?? 0
    }
}
