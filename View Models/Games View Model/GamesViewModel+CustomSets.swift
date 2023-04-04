//
//  GamesViewModel+CustomSets.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 7/15/21.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension GamesViewModel {
    func readCustomData() {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        db.collection("userSets")
            .whereField("userID", isEqualTo: myUID)
            .order(by: "dateCreated", descending: true).addSnapshotListener { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            DispatchQueue.main.async {
                self.customSets = data.compactMap { (queryDocSnap) -> CustomSetCherry? in
                    let customSet = try? queryDocSnap.data(as: CustomSet.self)
                    if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                        // Custom set for version 3.0
                        return customSetCherry
                    } else {
                        // default
                        return CustomSetCherry(customSet: customSet ?? CustomSet())
                    }
                }
            }
        }
    }

    func getUserName(userID: String) {
        db.collection("users").document(userID).getDocument { docSnap, error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let doc = docSnap else { return }
            DispatchQueue.main.async {
                self.queriedUserName = doc.get("username") as? String ?? ""
            }
        }
    }
    
    func getCustomData(setID: String) {
        clearAll()
        reset()
        let group = DispatchGroup()
        db.collection("userSets").document(setID).getDocument { (doc, err) in
            group.enter()
            if err != nil {
                print(err!.localizedDescription)
                return
            }
            guard let doc = doc else { return }
            var customSet: CustomSetCherry
            if let customSetOG = try? doc.data(as: CustomSet.self) {
                customSet = CustomSetCherry(customSet: customSetOG)
            } else if let customSetCherry = try? doc.data(as: CustomSetCherry.self) {
                customSet = customSetCherry
            } else {
                return
            }
            
            self.customSet = customSet
            
            for id in customSet.round1CatIDs {
                self.db.collection("userCategories").document(id).getDocument { (doc, err) in
                    if err != nil {
                        print(err!.localizedDescription)
                        return
                    }
                    guard let doc = doc else { return }
                    guard let customSetCategory = try? doc.data(as: CustomSetCategory.self) else { return }
                    
                    DispatchQueue.main.async {
                        let index = customSetCategory.index
                        if self.tidyCustomSet.round1Clues.isEmpty {
                            let toAdd = (customSet.round1Len - self.tidyCustomSet.round1Clues.count)
                            self.tidyCustomSet.round1Clues = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round1Responses = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round1Cats = [String](repeating: "", count: toAdd)
                        }
                        if self.tidyCustomSet.round1Clues.indices.contains(index) {
                            self.tidyCustomSet.round1Clues[index] = customSetCategory.clues
                            self.tidyCustomSet.round1Responses[index] = customSetCategory.responses
                            self.tidyCustomSet.round1Cats[index] = customSetCategory.name
                            self.finishedClues2D = self.generateFinishedClues2D()
                            self.clues = self.tidyCustomSet.round1Clues
                            self.responses = self.tidyCustomSet.round1Responses
                            self.categories = self.tidyCustomSet.round1Cats
                            customSetCategory.clues.forEach {
                                self.jRoundCompletes += ($0.isEmpty ? 0 : 1)
                                self.jCategoryCompletesReference[index] += ($0.isEmpty ? 0 : 1)
                            }
                        }
                    }
                }
            }
            
            if !customSet.hasTwoRounds {
                self.tidyCustomSet.round2Cats.removeAll()
                return
            }
            
            for id in customSet.round2CatIDs {
                self.db.collection("userCategories").document(id).getDocument { (doc, err) in
                    if err != nil {
                        print(err!.localizedDescription)
                        return
                    }
                    
                    guard let doc = doc else { return }
                    guard let customSetCategory = try? doc.data(as: CustomSetCategory.self) else { return }
                    
                    DispatchQueue.main.async {
                        let index = customSetCategory.index
                        if self.tidyCustomSet.round2Clues.isEmpty {
                            let toAdd = (customSet.round2Len - self.tidyCustomSet.round2Clues.count)
                            self.tidyCustomSet.round2Clues = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round2Responses = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round2Cats = [String](repeating: "", count: toAdd)
                        }
                        if self.tidyCustomSet.round2Clues.indices.contains(index) {
                            self.tidyCustomSet.round2Clues[index] = customSetCategory.clues
                            self.tidyCustomSet.round2Responses[index] = customSetCategory.responses
                            self.tidyCustomSet.round2Cats[index] = customSetCategory.name
                            customSetCategory.clues.forEach {
                                self.djRoundCompletes += ($0.isEmpty ? 0 : 1)
                                self.djCategoryCompletesReference[index] += ($0.isEmpty ? 0 : 1)
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.getUserName(userID: customSet.userID)
                self.customSet = customSet
            }
        }
    }
    
    func deleteSet(setID: String) {
        var copyOfCustomSets = customSets
        for i in 0..<customSets.count {
            let set = customSets[i]
            guard let id = set.id else { return }
            if setID == id {
                copyOfCustomSets.remove(at: i)
            }
        }
        customSets = copyOfCustomSets
    }
    
    // for scrolling
    func getUnitPoint() -> UnitPoint {
        let categoryCount = gamePhase == .round1 ? customSet.round1Len : customSet.round2Len
        return currentCategoryIndex == categoryCount - 1 ? .trailing : .center
    }
}
