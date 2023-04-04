//
//  GamesViewModel+Sets.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 7/17/21.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension GamesViewModel {
    
    // Fetching seasons
    func getSeasons() {
//        if !self.isVIP { return }
        db.collection("folders").order(by: "collection_index", descending: true).getDocuments { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            } else {
                guard let data = snap?.documents else { return }
                
                DispatchQueue.main.async {
                    self.jeopardySeasons = data.compactMap({ (querySnapshot) -> JeopardySeason? in
                        var jeopardySeason = try? querySnapshot.data(as: JeopardySeason.self)
                        jeopardySeason?.setID(id: querySnapshot.documentID)
                        return jeopardySeason
                    })
                    
                    // what even is this
                    if let mostRecentSeason = self.jeopardySeasons.first, let seasonID = mostRecentSeason.id {
                        self.getEpisodes(seasonID: seasonID, purge: false)
                        self.setSeason(jeopardySeason: mostRecentSeason)
                    }
                }
            }
        }
    }
    
    // Read previews
    func getEpisodes(seasonID: String?, purge: Bool = false) {
        if purge {
            gamePreviews.removeAll()
            latestJeopardyDoc = nil
        }
        var query: Query!

        guard let seasonID = seasonID else { return }
        if gamePreviews.isEmpty {
            query = db.collection("folders").document(seasonID).collection("games").order(by: "group_index", descending: true).limit(to: 10)
        } else {
            query = db.collection("folders").document(seasonID).collection("games").order(by: "group_index", descending: true).start(afterDocument: latestJeopardyDoc!).limit(to: 10)
        }
        
        query.getDocuments { (snap, error) in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                guard let data = snap?.documents else { return }
                let newJeopardySets = data.compactMap({ (queryDocSnap) -> JeopardySetPreview? in
                    var gamePreview = try? queryDocSnap.data(as: JeopardySetPreview.self)
                    gamePreview?.setID(id: queryDocSnap.documentID)
                    return gamePreview
                })
                self.gamePreviews.append(contentsOf: newJeopardySets)
                self.latestJeopardyDoc = data.last
            }
        }
    }
    
    func getEpisodeData(gameID: String) {
        let gameDocRef = db.collection("games").document(gameID)
        clearAll()
        reset()
        gameDocRef.getDocument { (doc, error) in
            guard let jeopardySet = try? doc?.data(as: JeopardySet.self) else { return }
            // there are six categories, should be doing stuff for category
            for id in jeopardySet.j_category_ids {
                self.db.collection("categories").document(id).getDocument { (doc, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    guard let jeopardyCategory = try? doc?.data(as: JeopardyCategory.self) else { return }
                    
                    DispatchQueue.main.async {
                        if self.tidyCustomSet.round1Clues.isEmpty {
                            let toAdd = (jeopardySet.j_round_len - self.tidyCustomSet.round1Clues.count)
                            self.tidyCustomSet.round1Clues = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round1Responses = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round1Cats = [String](repeating: "", count: toAdd)
                        }
                        let index = jeopardyCategory.index
                        let clues = jeopardyCategory.clues
                        
                        self.tidyCustomSet.round1Clues[index] = jeopardyCategory.clues
                        self.tidyCustomSet.round1Responses[index] = jeopardyCategory.responses
                        self.tidyCustomSet.round1Cats[index] = jeopardyCategory.name
                        
                        self.finishedClues2D = self.generateFinishedClues2D()
                        
                        self.clues = self.tidyCustomSet.round1Clues
                        self.responses = self.tidyCustomSet.round1Responses
                        self.categories = self.tidyCustomSet.round1Cats
                        clues.forEach {
                            self.jRoundCompletes += ($0.isEmpty ? 0 : 1)
                            self.jCategoryCompletesReference[index] += ($0.isEmpty ? 0 : 1)
                        }
                    }
                }
            }
            
            for id in jeopardySet.dj_category_ids {
                self.db.collection("categories").document(id).getDocument { (doc, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    guard let jeopardyCategory = try? doc?.data(as: JeopardyCategory.self) else { return }
                    
                    DispatchQueue.main.async {
                        if self.tidyCustomSet.round2Clues.isEmpty {
                            let toAdd = (jeopardySet.dj_round_len - self.tidyCustomSet.round2Clues.count)
                            self.tidyCustomSet.round2Clues = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round2Responses = [[String]](repeating: [""], count: toAdd)
                            self.tidyCustomSet.round2Cats = [String](repeating: "", count: toAdd)
                        }
                        let index = jeopardyCategory.index
                        
                        self.tidyCustomSet.round2Clues[index] = jeopardyCategory.clues
                        self.tidyCustomSet.round2Responses[index] = jeopardyCategory.responses
                        self.tidyCustomSet.round2Cats[index] = jeopardyCategory.name
                        
                        jeopardyCategory.clues.forEach {
                            self.djRoundCompletes += ($0.isEmpty ? 0 : 1)
                            self.djCategoryCompletesReference[index] += ($0.isEmpty ? 0 : 1)
                        }
                    }
                }
            }
            
            gameDocRef.collection("j_round_triple_stumpers").getDocuments { (snap, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                guard let data = snap?.documents else { return }
                data.forEach { (queryDocSnap) in
                    let stumper = queryDocSnap.get("stumper") as? [Int] ?? []
                    DispatchQueue.main.async {
                        self.round1TripleStumpers.append(stumper)
                    }
                }
            }
            
            gameDocRef.collection("dj_round_triple_stumpers").getDocuments { (snap, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                guard let data = snap?.documents else { return }
                data.forEach { (queryDocSnap) in
                    let stumper = queryDocSnap.get("stumper") as? [Int] ?? []
                    DispatchQueue.main.async {
                        self.round2TripleStumpers.append(stumper)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.customSet.roundOneDaily = jeopardySet.j_dds
                self.customSet.roundTwoDaily1 = jeopardySet.dj_dds_1
                self.customSet.roundTwoDaily2 = jeopardySet.dj_dds_2
                
                self.customSet.title = jeopardySet.title
                self.customSet.finalCat = jeopardySet.fj_category
                self.customSet.finalClue = jeopardySet.fj_clue
                self.customSet.finalResponse = jeopardySet.fj_response
            }
        }
    }
}

struct JeopardySetPreview: Decodable, Hashable, Identifiable {
    @DocumentID var id: String?
    var contestants: String
    var date: Date
    var details: String
    var group_index: Int
    var title: String
    
    enum CodingKeys: String, CodingKey {
        case contestants, date, details, group_index, title
    }
    
    static func == (lhs: JeopardySetPreview, rhs: JeopardySetPreview) -> Bool {
        lhs.title == rhs.title
    }
    
    mutating func setID(id: String) {
        self.id = id
    }
}

struct JeopardySeason: Decodable, Hashable, Identifiable {
    @DocumentID var id: String?
    var collection_index: Int
    var num_games: Int
    var title: String
    
    enum CodingKeys: String, CodingKey {
        case collection_index, num_games, title
    }
    
    mutating func setID(id: String) {
        self.id = id
    }
    
    init(id: String? = nil, collection_index: Int = 0, num_games: Int = 0, title: String = "") {
        self.id = id
        self.collection_index = collection_index
        self.num_games = num_games
        self.title = title
    }
}
