//
//  BuildViewModel+Categories.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/17/22.
//

import Foundation

extension BuildViewModel {
    func addCategoryRound1() {
        guard let currSetID = currCustomSet.id else { return }
        if self.currCustomSet.round1Len == 6 { return }
        self.currCustomSet.round1Len += 1
        round1CatsShowing[currCustomSet.round1Len - 1] = true
        if jCategories.count <= currCustomSet.round1Len {
            self.jCategories.append(Empty().category(index: currCustomSet.round1Len - 1, emptyStrings: emptyStrings, gameID: currSetID))
        }
        incrementDirtyBit()
    }
    
    func addCategoryRound2() {
        guard let currSetID = currCustomSet.id else { return }
        if self.currCustomSet.round2Len == 6 { return }
        self.currCustomSet.round2Len += 1
        round2CatsShowing[currCustomSet.round2Len - 1] = true
        if djCategories.count <= currCustomSet.round2Len {
            self.djCategories.append(Empty().category(index: currCustomSet.round2Len - 1, emptyStrings: emptyStrings, gameID: currSetID))
        }
        incrementDirtyBit()
    }
    
    func addCategory() {
        if buildStage == .trivioRound {
            addCategoryRound1()
        } else if buildStage == .dtRound {
            addCategoryRound2()
        }
        determineMostAdvancedStage()
    }
    
    func subtractCategoryRound1() {
        if currCustomSet.round1Len == 3 { return }
        currCustomSet.round1Len -= 1
        round1CatsShowing[currCustomSet.round1Len] = false
        incrementDirtyBit()
    }
    
    func subtractCategoryRound2() {
        if currCustomSet.round2Len == 3 { return }
        currCustomSet.round2Len -= 1
        round2CatsShowing[currCustomSet.round2Len] = false
        incrementDirtyBit()
    }
    
    func subtractCategory() {
        if buildStage == .trivioRound {
            subtractCategoryRound1()
        } else if buildStage == .dtRound {
            subtractCategoryRound2()
        }
    }
}
