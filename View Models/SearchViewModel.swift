//
//  SearchViewModel.swift
//  Trivio
//
//  Created by David Chen on 3/10/21.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class SearchViewModel: ObservableObject {
    @Published var searchItem = ""
    @Published var gameIDs = [String]()
    @Published var games = [Game]()
    @Published var searchLimit = 100
    @Published var hasSearch = false
    @Published var capSplit = [String]()
    @Published var searchPending = false
    @Published var isShowingExpandedView = false
    @Published var isShowingSearchView = false
    @Published var lastSearches = [Search]()
    
    var finishedSearch: Bool {
        return self.gameIDs.count == self.games.count
    }
    
    private var db = FirebaseConfigurator.shared.getFirestore()
    private var myUID: String? {
        return FirebaseConfigurator.shared.auth.currentUser?.uid
    }
    
    init() {
//        pullLastSearches()
    }
    
    func pullLastSearches() {
        guard let myUID = myUID else { return }
        let docRef = db.collection("users").document(myUID).collection("lastSearches").order(by: "date", descending: true).limit(to: 7)
        docRef.addSnapshotListener { snap, error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            self.lastSearches = data.compactMap({ docSnap in
                return try? docSnap.data(as: Search.self)
            })
        }
    }
    
    func addToLastSearches(search: String) {
        for lastSearch in lastSearches {
            if lastSearch.search == search {
                return
            }
        }
        guard let myUID = myUID else { return }
        let docRef = db.collection("users").document(myUID).collection("lastSearches").document()
        try? docRef.setData(from: Search(search: search, date: Date()))
    }
    
    func removeFromLastSearches(search: Search) {
        guard let myUID = myUID else { return }
        guard let searchID = search.id else { return }
        let docRef = db.collection("users").document(myUID).collection("lastSearches").document(searchID)
        docRef.delete()
    }
    
    func resetSearchLimit() {
        self.searchLimit = 100
    }
    
    func searchAndPull() {
        if searchItem.isEmpty { return }
        addToLastSearches(search: searchItem)
        searchPending = true
        var convertedArray = [Date]()
        var datesDict = [Date:Game]()
        search { (success) in
            if success {
                for i in 0..<self.games.count {
                    let game = self.games[i]
                    let date = game.date
                    convertedArray.append(date)
                    datesDict.updateValue(game, forKey: date)
                }

                let sortedDates = convertedArray.sorted(by: { $0.compare($1) == .orderedDescending })
                self.games = [Game](repeating: Empty().game, count: sortedDates.count)
                for i in 0..<sortedDates.count {
                    let date = sortedDates[i]
                    self.games[i] = datesDict[date] ?? Empty().game
                }
                self.searchPending = false
            }
        }
    }
    
    func search(completion: @escaping (Bool) -> Void) {
        self.gameIDs.removeAll()
        self.games.removeAll()
        self.hasSearch = true
        
        let searchSplit = searchItem.split(separator: " ")
        
        capSplit = searchSplit.map { $0.uppercased() }
        self.db.collection("categories")
            .whereField("name_split", arrayContainsAny: capSplit)
            .order(by: "game_id", descending: true)
            .limit(to: searchLimit)
            .addSnapshotListener { (snap, err) in
                self.errorHandle(err: err)
                guard let data = snap?.documents else { return }
                self.readAll(data: data) { (success) in
                    if success {
                        completion(true)
                    }
                }
            }
    }
    
    func readAll(data: [QueryDocumentSnapshot], completion: @escaping (Bool) -> Void) {
        var counter = 0
        DispatchQueue.main.async {
            let group = DispatchGroup()
            data.forEach { (doc) in
                group.enter()
                guard let gameID = doc.get("game_id") as? String else { return }
                self.pull(gameID: gameID, counter: counter) { (success) in
                    if success {
                        group.leave()
                    }
                }
                counter += 1
            }
            group.notify(queue: .main) {
                completion(true)
            }
        }
    }
    
    func pull(gameID: String, counter: Int, completion: @escaping (Bool) -> Void) {
        self.gameIDs.append(gameID)
        
        self.db.collection("games").document(gameID).getDocument { (doc, error) in
            self.errorHandle(err: error)
            guard let doc = doc else { return }
            var game = try? doc.data(as: Game.self)
            game?.setID(id: doc.documentID)
            guard let unwrapGame = game else { return }
            if !self.games.contains(unwrapGame) {
                self.games.append(unwrapGame)
            }
            completion(true)
        }
    }
    
    func errorHandle(err: Error?) {
        if err != nil {
            print(err!.localizedDescription)
            return
        }
    }
    
    func clearSearch() {
        self.searchItem.removeAll()
    }
    
    func beenPlayed(playedGames: [String], gameID: String) -> Bool {
        return playedGames.contains(gameID)
    }
    
    func changeSearchLimit(increase: Bool) {
        let increaseFactor = increase ? 1 : -1
        self.searchLimit += increaseFactor * 100
        searchAndPull()
    }
}

struct Search: Encodable, Decodable, Hashable, Identifiable {
    @DocumentID var id: String?
    var search: String
    var date: Date
}

struct SeasonEpisode: Decodable, Hashable {
    var seasonID: String
    var episodeID: String
    var id: String
    
    init(seasonID: String, episodeID: String) {
        self.seasonID = seasonID
        self.episodeID = episodeID
        self.id = UUID().uuidString
    }
}

struct Game: Decodable, Hashable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var dj_category_ids: [String]
    var dj_dds_1, dj_dds_2: [Int]
    var dj_round_len: Int
    var fj_category: String
    var fj_clue: String
    var fj_response: String
    var game_id: String
    var group_index: Int
    var j_category_ids: [String]
    var j_round_len: Int
    var title, type, userID: String
    
    enum CodingKeys: String, CodingKey {
        case date, dj_category_ids, dj_dds_1, dj_dds_2, dj_round_len, fj_category, fj_clue, fj_response, game_id, group_index, j_category_ids, j_round_len, title, type, userID
    }
    
    mutating func setID(id: String) {
        self.id = id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
