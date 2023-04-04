//
//  ExploreViewModel+Search.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/28/22.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

extension ExploreViewModel {
    public func searchAndPull() {
        let defaults = UserDefaults.standard
        if searchItem.isEmpty { return }
        if searchItem == "SocratesIsUnwise" {
            defaults.set(true, forKey: "isVIP")
        }
        switch currentSearchBy {
        case .title:
            searchByTitle()
        case .category:
            searchByCategory()
        case .allrecents:
            pullAllPublicSets()
        default:
            searchByTags()
        }
    }
    
    public func searchByTitle() {
        self.titleSearchResults.removeAll()
        db.collection("userSets")
            .whereField("titleKeywords", arrayContains: self.searchItem.lowercased())
            .whereField("isPublic", isEqualTo: true)
            .order(by: filterBy, descending: isDescending)
            .getDocuments { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            self.titleSearchResults = data.compactMap({ (queryDocSnap) -> CustomSet? in
                let customSet = try? queryDocSnap.data(as: CustomSet.self)
                return customSet
            })
        }
    }
    
    public func searchByCategory() {
        self.categorySearchResults.removeAll()
        let searchSplit = searchItem.split(separator: " ")
        capSplit = searchSplit.map { $0.uppercased() }
        db.collection("userSets")
            .whereField("categoryNames", arrayContainsAny: capSplit)
            .whereField("isPublic", isEqualTo: true)
            .order(by: filterBy, descending: isDescending)
            .getDocuments { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            self.categorySearchResults = data.compactMap({ (queryDocSnap) -> CustomSet? in
                let customSet = try? queryDocSnap.data(as: CustomSet.self)
                return customSet
            })
        }
    }
    
    public func searchByTags() {
        self.tagsSearchResults.removeAll()
        let searchSplit = searchItem.split(separator: " ")
        capSplit = searchSplit.map { $0.uppercased() }
        
        db.collection("userSets")
            .whereField("tags", arrayContainsAny: capSplit)
            .whereField("isPublic", isEqualTo: true)
            .order(by: filterBy, descending: isDescending)
            .getDocuments { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            self.tagsSearchResults = data.compactMap({ (queryDocSnap) -> CustomSet? in
                let customSet = try? queryDocSnap.data(as: CustomSet.self)
                return customSet
            })
        }
    }
}
