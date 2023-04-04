//
//  ExploreViewModel+Sort.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/28/22.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

extension ExploreViewModel {
    public func applyCurrentSort(sortByOption: String, isSortingPublicSets: Bool = true) {
        switch sortByOption {
        case "Date created (newest)":
            filterBy = "dateCreated"
            isDescending = true
        case "Date created (oldest)":
            filterBy = "dateCreated"
            isDescending = false
        case "Highest rating":
            filterBy = "rating"
            isDescending = true
        default:
            filterBy = "plays"
            isDescending = true
        }
        if isSortingPublicSets {
            pullSortedPublicSets()
        } else {
            pullSortedPrivateSets()
        }
    }
    
    public func getCurrentSort() -> String {
        return currentSort
    }
    
    public func pullSortedPublicSets() {
        db.collection("userSets")
            .whereField("isPublic", isEqualTo: true)
            .order(by: filterBy, descending: isDescending)
            .limit(to: 10).getDocuments { (snap, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    guard let data = snap?.documents else { return }
                    self.allPublicSets = data.compactMap({ (queryDocSnap) -> CustomSetCherry? in
                        let customSet = try? queryDocSnap.data(as: CustomSet.self)
                        if let id = customSet?.userID {
                            self.addUsernameNameToDict(userID: id)
                        }
                        if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                            // Custom set for version 3.0
                            self.addUsernameNameToDict(userID: customSetCherry.userID)
                            return customSetCherry
                        } else {
                            // default
                            return CustomSetCherry(customSet: customSet ?? CustomSet())
                        }
                    })
                    self.latestPublicDoc = data.last
                }
            }
    }
    
    public func pullSortedPrivateSets() {
        db.collection("userSets")
            .whereField("isPublic", isEqualTo: false)
            .order(by: filterBy, descending: isDescending)
            .limit(to: 10)
            .getDocuments { (snap, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    guard let data = snap?.documents else { return }
                    self.allPrivateSets = data.compactMap({ (queryDocSnap) -> CustomSetCherry? in
                        let customSet = try? queryDocSnap.data(as: CustomSet.self)
                        if let id = customSet?.userID {
                            self.addUsernameNameToDict(userID: id)
                        }
                        if let customSetCherry = try? queryDocSnap.data(as: CustomSetCherry.self) {
                            // Custom set for version 3.0
                            self.addUsernameNameToDict(userID: customSetCherry.userID)
                            return customSetCherry
                        } else {
                            // default
                            return CustomSetCherry(customSet: customSet ?? CustomSet())
                        }
                    })
                    self.latestPrivateDoc = data.last
                }
            }
    }
}
