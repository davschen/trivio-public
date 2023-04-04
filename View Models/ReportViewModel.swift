//
//  ReportViewModel.swift
//  Trivio
//
//  Created by David Chen on 3/6/21.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class ReportViewModel: ObservableObject {
    @Published var allGameReports = [Report]()
    @Published var scores: [String:[Int]] = [:]
    @Published var currentReport: Report? = nil
    @Published var currentSet: CustomSet? = nil
    @Published var selectedID = ""
    @Published var min: CGFloat = 0
    @Published var max: CGFloat = 0
    @Published var xAxis = [Int]()
    @Published var yAxis = [Int]()
    @Published var selectedGameID = ""
    @Published var gameIDNameDict = [String:String]()
    private var db = FirebaseConfigurator.shared.getFirestore()
    
    init() {
        getAllData()
    }
    
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .long
        return df
    }
    
    var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeStyle = .short
        return df
    }
    
    func addGameName(from gameID: String) {
        let collectionName = gameID.contains("game_id") ? "games" : "userSets"
        let docRef = db.collection(collectionName).document(gameID)
        docRef.getDocument { doc, error in
            DispatchQueue.main.async {
                guard let doc = doc else { return }
                let title = doc.get("title") as? String ?? ""
                self.gameIDNameDict.updateValue(title, forKey: gameID)
            }
        }
    }
    
    func getGameName(from gameID: String?) -> String {
        guard let id = gameID else { return "Play Game" }
        return gameIDNameDict[id] ?? "Play Game"
    }
    
    func getAllData() {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        let docRef = db.collection("users").document(myUID).collection("games").order(by: "date", descending: true)
        docRef.addSnapshotListener { (snap, err) in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            DispatchQueue.main.async {
                self.allGameReports = data.compactMap { (queryDocSnap) -> Report? in
                    let gameID = queryDocSnap.get("episode_played") as? String ?? "NID"
                    self.addGameName(from: gameID)
                    return try? queryDocSnap.data(as: Report.self)
                }
                if let gameID = self.allGameReports.first?.id {
                    self.getGameInfo(id: gameID)
                }
            }
        }
    }
    
    func delete(id: String) {
        let docRef = db.collection("users").document(FirebaseConfigurator.shared.auth.currentUser?.uid ?? "hello").collection("games").document(id)
        docRef.addSnapshotListener { (doc, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let doc = doc else { return }
            guard let team_ids = doc.get("team_ids") as? [String] else { return }
            for id in team_ids {
                docRef.collection(id).addSnapshotListener { (snap, error) in
                    if error != nil { return }
                    guard let data = snap?.documents else { return }
                    data.forEach { (queryDocSnap) in
                        docRef.collection(id).document(queryDocSnap.documentID)
                    }
                }
            }
        }
        docRef.delete()
    }
    
    func getGameInfo(id: String) {
        self.scores.removeAll()
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        let docRef = db.collection("users").document(myUID).collection("games").document(id)
        docRef.addSnapshotListener { (doc, err) in
            if err != nil {
                print(err!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                guard let doc = doc else { return }
                self.currentReport = try? doc.data(as: Report.self)
                self.selectedGameID = doc.documentID
            }
            
            if let gameID = doc?.get("episode_played") as? String {
                self.db.collection("userSets").document(gameID).addSnapshotListener { (doc, error) in
                    if error != nil { return }
                    guard let doc = doc else { return }
                    DispatchQueue.main.async {
                        self.currentSet = try? doc.data(as: CustomSet.self)
                    }
                }
            }
            
            // handle all scores
            guard let teamIDs = doc?.get("team_ids") as? [String] else { return }
            
            for id in teamIDs {
                docRef.collection(id).order(by: "step").addSnapshotListener { (snap, err) in
                    if err != nil {
                        print(err!.localizedDescription)
                        return
                    }
                    guard let data = snap?.documents else { return }
                    DispatchQueue.main.async {
                        var id_scores = [Int]()
                        data.forEach { (doc) in
                            id_scores.append(doc.get("score") as? Int ?? 0)
                        }
                        if !id_scores.isEmpty {
                            self.scores.updateValue(id_scores, forKey: id)
                        }
                        self.getMinMax()
                    }
                }
            }
        }
    }
    
    func getMinMax() {
        self.min = 0
        self.max = 0
        
        for teamScores in scores.values {
            guard let teamMin = teamScores.min() else { return }
            guard let teamMax = teamScores.max() else { return }
            
            self.min = teamMin < Int(min) ? CGFloat(teamMin) : min
            self.max = teamMax > Int(max) ? CGFloat(teamMax) : max
        }
        
        if let game = currentReport {
            var xArray = [Int]()
            var counter = 0
            while counter <= game.steps {
                xArray.append(counter)
                if game.steps < 30 {
                    counter += 2
                } else {
                    counter += 5
                }
            }
            self.xAxis = xArray
            
            var yArray = [Int]()
            var yCounter = (self.min + (self.min.truncatingRemainder(dividingBy: 100))) - (self.min == 0 ? 0 : 100)
            let roundedMax = self.max - (self.max.truncatingRemainder(dividingBy: 100)) + 100
            let dist = self.max - self.min
            while yCounter <= roundedMax {
                var increment: CGFloat = 50
                yArray.append(Int(yCounter))
                if dist > 50000 {
                    increment = 4000
                } else if dist > 30000 {
                    increment = 2000
                } else if dist > 10000 {
                    increment = 1000
                } else if dist > 5000 {
                    increment = 500
                } else if dist > 2000 {
                    increment = 200
                } else if dist > 1000 {
                    increment = 100
                }
                yCounter += increment
            }
            self.yAxis = yArray
        }
    }
    
    func getAverageScores() -> Double {
        var totalScores: Double = 0
        for pair in scores {
            let scoresArray = pair.value
            totalScores += Double(scoresArray.last ?? 0)
        }
        return totalScores / Double(scores.count)
    }
}

class Report: Decodable, Hashable {
    @DocumentID var id: String?
    var date = Date()
    var episode_played = ""
    var steps = 0
    var team_ids = [String]()
    var name_id_map = ["":""]
    var color_id_map = ["":""]
    var qs_solved = 0
    
    static func == (lhs: Report, rhs: Report) -> Bool {
        return lhs.date == rhs.date
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, episode_played, steps, team_ids, name_id_map, color_id_map, qs_solved
    }
    
    func getNames() -> [String] {
        var names = [String]()
        for pair in name_id_map {
            names.append(pair.value)
        }
        return names
    }
}
