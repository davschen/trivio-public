//
//  BuildViewModel+Database.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/17/22.
//

import Foundation

extension BuildViewModel {
    func writeToFirestore() {
        guard let currCustomSetID = self.currCustomSet.id else { return }

        if currCustomSet.isDraft {
            // If i'm editing a draft and I've just published it for the first time
            currCustomSet.dateCreated = Date()
        }
        
        currCustomSet.isDraft = !checkForSetIsComplete()
        currCustomSet.dateLastModified = Date()
        currCustomSet.userID = myUID
        currCustomSet.round1CatIDs = jCategories[0..<currCustomSet.round1Len].compactMap { $0.id }
        currCustomSet.round2CatIDs = djCategories[0..<currCustomSet.round2Len].compactMap { currCustomSet.hasTwoRounds ? $0.id : "" }
        currCustomSet.categoryNames = getCategoryNames()
        currCustomSet.numClues = getNumClues()

        let docRef = db.collection(currCustomSet.isDraft ? "drafts" : "userSets").document(currCustomSetID)
        
        // TODO: find out why setData is dismissing BuildView only after `edit` is called
        try? docRef.setData(from: self.currCustomSet)
        self.writeCategories()
        self.updateTagsDB()
        self.dirtyBit = 0
        if !self.currCustomSet.isDraft {
            self.db.collection("drafts").document(currCustomSetID).delete()
        } else {
            self.db.collection("userSets").document(currCustomSetID).delete()
        }
    }
    
    func writeCategories() {
        for i in 0..<self.currCustomSet.round1Len {
            let category = jCategories[i]
            guard let id = category.id else { return }
            let docRef = db.collection("userCategories").document(id)
            try? docRef.setData(from: category)
        }
        if !self.currCustomSet.hasTwoRounds {
            // If someone reduces their set with 2 cats down to 1, I don't want the userCategories DB table to be crowded with empty categories
            // We will delete all round two categories in userCategories
            for i in 0..<self.currCustomSet.round2Len {
                guard let categoryID = self.djCategories[i].id else { return }
                self.db.collection("userCategories").document(categoryID).delete()
            }
            return
        }
        for i in 0..<self.currCustomSet.round2Len {
            var category = djCategories[i]
            guard let categoryID = category.id else { return }
            guard let currSetID = currCustomSet.id else { return }
            // Must set gameID to currSetID or else it will be assigned to ID of a non-existent userSet
            category.gameID = currSetID
            let docRef = db.collection("userCategories").document(categoryID)
            try? docRef.setData(from: category)
        }
    }
    
    func getCategoriesWithIDs(isDJ: Bool, ids: [String]) {
        guard let currSetID = currCustomSet.id else { return }
        if isDJ {
            self.djCategories = [CustomSetCategory](repeating: Empty().category(index: 0, emptyStrings: emptyStrings, gameID: currSetID), count: ids.count)
        } else {
            self.jCategories = [CustomSetCategory](repeating: Empty().category(index: 0, emptyStrings: emptyStrings, gameID: currSetID), count: ids.count)
        }
        for i in 0..<ids.count {
            let id = ids[i]
            db.collection("userCategories").document(id).getDocument { (doc, error) in
                if error != nil { return }
                guard let doc = doc else { return }
                guard let category = try? doc.data(as: CustomSetCategory.self) else { return }
                DispatchQueue.main.async {
                    if isDJ {
                        self.djCategories[category.index] = category
                    } else {
                        self.jCategories[category.index] = category
                    }
                }
            }
        }
    }
    
    func deleteSet(customSet: CustomSetCherry) {
        guard let setID = customSet.id else { return }
        db.collection("userCategories")
            .whereField("gameID", isEqualTo: setID)
            .getDocuments { (snap, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    guard let data = snap?.documents else { return }
                    data.forEach { docSnap in
                        self.db.collection("userCategories").document(docSnap.documentID).delete()
                    }
                }
            }
        db.collection(customSet.isDraft ? "drafts" : "userSets").document(setID).delete()
    }
    
    func updateTagsDB(tags: [String] = []) {
        let myDocRef = db.collection("users").document(myUID)
        myDocRef.getDocument { (docSnap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let doc = docSnap else { return }
            var dbTags = doc.get("tags") as? [String:Int] ?? [:]
            let tagsToAdd = self.currCustomSet.tags.isEmpty ? self.currCustomSet.tags : tags
            for tag in tagsToAdd {
                let upperTag = tag.uppercased()
                if dbTags.keys.contains(upperTag) {
                    dbTags[upperTag]! += 1
                } else {
                    dbTags.updateValue(1, forKey: upperTag)
                }
            }
            myDocRef.setData([
                "tags" : dbTags
            ], merge: true)
        }
    }
    
    func edit(customSet: CustomSetCherry) {
        self.clearAll()
        
        guard let customSetID = customSet.id else { return }
        let docRef = db.collection(customSet.isDraft ? "drafts" : "userSets").document(customSetID)
        
        docRef.getDocument { (doc, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let doc = doc else { return }
            
            let customSet: CustomSetCherry
            if let customSetOG = try? doc.data(as: CustomSet.self) {
                customSet = CustomSetCherry(customSet: customSetOG)
            } else if let customSetCherry = try? doc.data(as: CustomSetCherry.self) {
                customSet = customSetCherry
            } else {
                return
            }
            DispatchQueue.main.async {
                self.currCustomSet = customSet
                self.getCategoriesWithIDs(isDJ: false, ids: customSet.round1CatIDs)
                if self.currCustomSet.hasTwoRounds { self.getCategoriesWithIDs(isDJ: true, ids: customSet.round2CatIDs) }
                
                self.categories = self.jCategories
                self.round1CatsShowing = [Bool](repeating: true, count: customSet.round1Len) + [Bool](repeating: false, count: 6 - customSet.round1Len)
                self.round2CatsShowing = [Bool](repeating: true, count: customSet.round2Len) + [Bool](repeating: false, count: 6 - customSet.round2Len)
                self.determineMostAdvancedStage()
            }
        }
    }
}
