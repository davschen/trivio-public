//
//  ParticipantsViewModel.swift
//  Trivio
//
//  Created by David Chen on 2/4/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class ParticipantsViewModel: ObservableObject {
    @Published var isTeams = false
    @Published var teams = [Team]()
    @Published var savedTeams = [Team]()
    @Published var wagers = [String]()
    @Published var finalJeopardyAnswers = [String]()
    @Published var questionTicker = 0
    @Published var spokespeople = [String]()
    @Published var toSubtracts = [Bool]()
    @Published var fjCorrects = [Bool]()
    @Published var fjReveals = [Bool]()
    @Published var selectedTeam = Team()
    @Published var teamCorrect = Team()
    
    @Published var scores: [[Int]] = []
    @Published var solved = 0
    @Published var myTeam = Team()
    @Published var teamToEdit = Team()
    
    private var db = FirebaseConfigurator.shared.getFirestore()
    private static let suffix = ["", "K", "M", "B", "T", "P", "E"]
    var defaultIndex = 0
    
    private var myUID: String? {
        return FirebaseConfigurator.shared.auth.currentUser?.uid
    }
    
    init() {
        getAllTeams()
    }
    
    func writeTeamToFirestore(team: Team, isSelf: Bool = false) {
        guard let uid = myUID else { return }
        let teamID = isSelf ? uid : team.id
        
        self.db.collection("users")
            .document(uid)
            .collection("contestants")
            .document(teamID)
            .setData([
                "name" : team.name,
                "color" : team.color,
                "id" : team.id,
                "members" : team.members,
                "score" : 0,
                "index" : 0
            ])
        
        self.getAllTeams()
    }
    
    func addSelfAsTeam() {
        guard let uid = myUID else { return }
        self.db.collection("users")
            .document(uid)
            .getDocument { docSnap, error in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                DispatchQueue.main.async {
                    guard let doc = docSnap else { return }
                    guard let name = doc.get("name") as? String else { return }
                    guard let firstName = name.components(separatedBy: " ").first else { return }
                    self.addTeam(id: uid, name: firstName, members: [], score: 0, color: "blue")
                    
                    guard let addedTeam = self.teams.last else { return }
                    self.writeTeamToFirestore(team: addedTeam)
                }
            }
    }
    
    func editTeamInDB(teamIndex: Int) {
        guard let uid = myUID else { return }
        try? self.db.collection("users")
            .document(uid)
            .collection("contestants")
            .document(teams[teamIndex].id)
            .setData(from: teams[teamIndex])
        getAllTeams()
    }
    
    func editTeamInDB(team: Team) { 
        guard let uid = myUID else { return }
        try? self.db.collection("users")
            .document(uid)
            .collection("contestants")
            .document(team.id)
            .setData(from: team)
        getAllTeams()
    }
    
    func getAllTeams() {
        guard let uid = myUID else { return }
        self.db.collection("users")
            .document(uid)
            .collection("contestants")
            .getDocuments { (snap, err) in
                if err != nil {
                    print(err!.localizedDescription)
                    return
                }
                guard let data = snap?.documents else { return }
                DispatchQueue.main.async {
                    self.savedTeams = data.compactMap { (queryDocSnap) -> Team? in
                        var updatedTeamToAdd = try? queryDocSnap.data(as: Team.self)
                        if let updatedTeam = updatedTeamToAdd, self.teams.contains(updatedTeam) {
                            for i in self.teams.indices {
                                if self.teams[i].id == updatedTeam.id {
                                    updatedTeamToAdd?.editIndex(index: i)
                                    if let updatedTeamToAdd = updatedTeamToAdd {
                                        self.teams[i] = updatedTeamToAdd
                                    }
                                }
                            }
                        }
                        return updatedTeamToAdd
                    }
                    var shouldAddSelf = true
                    for team in self.savedTeams {
                        if team.id == uid {
                            self.myTeam = team
                            shouldAddSelf = false
                            if !self.teams.contains(team) {
                                self.addTeam(id: team.id, name: team.name, members: team.members, score: 0, color: team.color)
                            }
                            break
                        }
                    }
                    if shouldAddSelf {
                        self.addSelfAsTeam()
                    }
                }
            }
    }
    
    func removeTeamFromFirestore(id: String) {
        for team in teams {
            team.id == id ? removeTeam(index: team.index) : ()
        }
        guard let uid = myUID else { return }
        let docRef = self.db.collection("users").document(uid).collection("contestants")
        docRef.whereField("id", isEqualTo: id).getDocuments { (snap, err) in
            if err != nil {
                print(err!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            guard let doc = data.first else { return }
            if doc.exists {
                docRef.document(doc.documentID).delete()
            }
            self.getAllTeams()
        }
    }
    
    func addTeam(id: String = "", name: String, members: [String], score: Int, color: String) {
        teams.append(Team(id: id, index: teams.count, name: name, members: members, score: score, color: color))
        wagers.append("")
        finalJeopardyAnswers.append("")
        spokespeople.append("")
        toSubtracts.append(false)
        fjCorrects.append(false)
        fjReveals.append(false)
        scores.append([Int](repeating: 0, count: questionTicker))
        
        if !teams.indices.contains(selectedTeam.index) {
            setSelectedTeam(index: teams.count - 1)
        }
    }
    
    func addTeam(team: Team) {
        teams.append(team)
        wagers.append("")
        finalJeopardyAnswers.append("")
        spokespeople.append("")
        toSubtracts.append(false)
        fjCorrects.append(false)
        fjReveals.append(false)
        scores.append([Int](repeating: 0, count: questionTicker))
        
        if !teams.indices.contains(selectedTeam.index) {
            setSelectedTeam(index: teams.count - 1)
        }
    }
    
    func didTapXmark(teamIndex: Int, pointValueInt: Int) {
        let team = teams[teamIndex]
        if team == teamCorrect {
            teamCorrect = Team()
            editScore(index: team.index, pointValueInt: -pointValueInt)
        }
        toSubtracts[team.index].toggle()
        let pointValueInt = toSubtracts[team.index] ? -pointValueInt : pointValueInt
        editScore(index: teamIndex, pointValueInt: pointValueInt)
    }
    
    func didTapCheckmark(teamIndex: Int, pointValueInt: Int) {
        let team = teams[teamIndex]
        resetToLastIncrement(pointValueInt: pointValueInt)
        // if the contestant is marked wrong, unmark them wrong
        if toSubtracts[team.index] {
            toSubtracts[team.index].toggle()
            editScore(index: team.index, pointValueInt: pointValueInt)
        }
        if team == teamCorrect {
            // reset teamCorrect
            teamCorrect = Team()
            setSelectedTeam(index: defaultIndex)
        } else {
            editScore(index: team.index, pointValueInt: pointValueInt)
            teamCorrect = team
            setSelectedTeam(index: team.index)
        }
    }
    
    func editScore(index: Int, pointValueInt: Int) {
        teams[index].editScore(amount: pointValueInt)
    }
    
    func addMember(index: Int, name: String) {
        teams[index].addMember(name: name)
        spokespeople[index] = name
    }
    
    func editName(index: Int, name: String) {
        teams[index].editName(name: name)
    }
    
    func removeTeam(index: Int) {
        teams.remove(at: index)
        wagers.remove(at: index)
        finalJeopardyAnswers.remove(at: index)
        spokespeople.remove(at: index)
        toSubtracts.remove(at: index)
        fjCorrects.remove(at: index)
        fjReveals.remove(at: index)
        scores.remove(at: index)
        
        for i in 0..<self.teams.count {
            teams[i].setIndex(index: i)
        }
        
        if selectedTeam.index == index && teams.count > 0 {
            setSelectedTeam(index: 0)
        }
    }
    
    func removeMember(index: Int, name: String) {
        teams[index].removeMember(name: name)
    }
    
    func editColor(index: Int, color: String) {
        if teams.indices.contains(index) {
            teams[index].editColor(color: color)
        }
    }
    
    func resetSubtracts() {
        for i in 0..<toSubtracts.count {
            toSubtracts[i] = false
        }
    }
    
    func resetCorrects() {
        for i in 0..<fjCorrects.count {
            fjCorrects[i] = false
        }
    }
    
    func resetScores() {
        for i in 0..<teams.count {
            teams[i].editScore(amount: -teams[i].score)
            wagers[i] = ""
            toSubtracts[i] = false
            fjCorrects[i] = false
            fjReveals[i] = false
            finalJeopardyAnswers[i] = ""
        }
        questionTicker = 0
        solved = 0
        scores = [[Int]](repeating: [], count: teams.count)
    }
    
    func getIndexByID(id: String) -> Int {
        for i in 0..<self.teams.count {
            if self.teams[i].id == id {
                return i
            }
        }
        return 0
    }
    
    func addSolved() {
        solved += 1
    }
    
    func progressGame(gameHasTwoRounds: Bool = false) {
        if gameHasTwoRounds {
            changeDJTeam()
        }
        if !teamCorrect.id.isEmpty {
            addSolved()
        }
        for team in teams {
            scores[team.index].append(team.score)
            if team.members.count > 0 {
                spokespeople[team.index] = team.members[questionTicker % team.members.count]
            }
        }
        questionTicker += 1
        resetSubtracts()
        teamCorrect = Team()
    }
    
    func getIDMap() -> [String : String] {
        var idMap = [String : String]()
        for team in self.teams {
            idMap.updateValue(team.name, forKey: team.id)
        }
        return idMap
    }
    
    func getColorMap() -> [String : String] {
        var colorMap = [String : String]()
        for team in self.teams {
            colorMap.updateValue(team.color, forKey: team.id)
        }
        return colorMap
    }
    
    func getIDs() -> [String] {
        var ids = [String]()
        for team in self.teams {
            ids.append(team.id)
        }
        return ids
    }
    
    func wagersValid() -> Bool {
        for i in 0..<teams.count {
            let wager = wagers[i]
            let intWager = Int(wager) ?? 0
            let score = teams[i].score
            if score <= 0 {
                continue
            }
            if Int(wager) == nil || wager.isEmpty || intWager > score || intWager < 0 {
                return false
            }
        }
        return true
    }
    
    func answersValid() -> Bool {
        for i in 0..<teams.count {
            let answer = finalJeopardyAnswers[i]
            let score = teams[i].score
            if score <= 0 {
                continue
            }
            if answer.isEmpty {
                return false
            }
        }
        return true
    }
    
    func setSelectedTeam(index: Int) {
        self.selectedTeam = teams[index]
    }
    
    func writeToFirestore(gameID: String, myRating: Int = 0) {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        if teams.isEmpty { return }
        let gameRef = db.collection("users").document(myUID).collection("games").document()
        let userSetRef = db.collection("userSets").document(gameID)
        let myDocRef = db.collection("users").document(myUID)
        
        var totalScore = 0
        
        gameRef.setData([
            "date" : Date(),
            "episode_played" : gameID,
            "steps" : self.questionTicker,
            "team_ids" : self.getIDs(),
            "name_id_map" : self.getIDMap(),
            "color_id_map" : self.getColorMap(),
            "qs_solved" : self.solved
        ])
        for team_i in 0..<self.teams.count {
            let id = self.getIDs()[team_i]
            let docRef = gameRef.collection(id)
            for step_i in 0..<self.questionTicker {
                docRef.addDocument(data: [
                    "step" : step_i,
                    "score" : self.scores[team_i][step_i]
                ])
            }
            // get score averages
            totalScore += self.teams[team_i].score
        }
        
        let myAverageScore: Int = teams.count > 0 ? (totalScore / teams.count) : 0
        
        userSetRef.getDocument { (doc, error) in
            if error != nil { return }
            guard let doc = doc else { return }
            let tags = doc.get("tags") as? [String] ?? []
            let rating = doc.get("rating") as? Int ?? 0
            let numRatings = doc.get("numRatings") as? Int ?? 0
            let averageScore = doc.get("averageScore") as? Double ?? 0.0
            let plays = doc.get("plays") as? Int ?? 0
            
            let newRating: Double = (myRating == 0) ? Double(rating) : (Double(rating * numRatings + myRating) / Double(numRatings + 1))
            let newAverageScore: Double = (averageScore * Double(plays) + Double(myAverageScore)) / Double(plays + 1)
            
            userSetRef.setData([
                "plays" : FieldValue.increment(Int64(1)),
                "rating" : newRating,
                "averageScore" : newAverageScore
            ], merge: true)
            if myRating > 0 {
                userSetRef.setData([
                    "numRatings" : FieldValue.increment(Int64(1)),
                ], merge: true)
            }
            
            // add set tags to my tags
            myDocRef.getDocument { (doc, error) in
                if error != nil { return }
                guard let doc = doc else { return }
                var myTags = doc.get("tags") as? [String:Int] ?? [:]
                
                for tag in tags {
                    if myTags.keys.contains(tag) {
                        myTags.updateValue((myTags[tag] ?? 0) + 1, forKey: tag.uppercased())
                    } else {
                        myTags.updateValue(1, forKey: tag.uppercased())
                    }
                }
                
                myDocRef.setData([
                    "tags" : myTags
                ], merge: true)
            }
        }
    }
    
    func resetToLastIncrement(pointValueInt: Int) {
        for i in 0..<teams.count {
            guard let last = scores[i].count > 0 ? scores[i].last : 0 else { return }
            var lastScore = last
            if toSubtracts[i] {
                lastScore -= pointValueInt
            }
            teams[i].score = lastScore
        }
    }
    
    func setDefaultIndex() {
        defaultIndex = selectedTeam.index
    }
    
    func changeDJTeam() {
        var latestScores = [Int:Int]()
        for i in 0..<scores.count {
            let scoreArray = scores[i]
            latestScores.updateValue(scoreArray.last ?? 0, forKey: i)
        }
        for i in 0..<teams.count {
            let score = teams[i].score
            if score == latestScores.values.min() {
                selectedTeam = teams[i]
                break
            }
        }
    }
    
    // MARK: - Final Trivio
    func teamHasLock(teamIndex: Int) -> Bool {
        if teams.count < 2 { return true }
        var allScores = [Int]()
        for scoreArray in scores {
            let finalScore: Int = scoreArray.last ?? 0
            allScores.append(finalScore)
        }
        let myScore: Int = self.scores[teamIndex].last ?? 0
        var sortedScores = allScores.sorted()
        let highestScore = sortedScores.removeLast()
        let runnerUpScore = sortedScores.removeLast()
        if myScore != highestScore {
            return false
        } else if myScore > 2 * runnerUpScore {
            return true
        }
        return false
    }
    
    func getTeamIndexForPlace(_ placing: Placing) -> Int? {
        if teams.count == 0 {
            return nil
        } else if placing == .second && teams.count < 2 {
            return nil
        } else if placing == .third && teams.count < 3 {
            return nil
        }
        var allScores = [Int:Int]()
        for i in 0..<teams.count {
            allScores.updateValue(teams[i].score, forKey: teams[i].index)
        }
        let sortedScores = Array(allScores.sortedByValue.reversed())
        
        switch placing {
        case .first:
            return sortedScores[0].0
        case .second:
            return sortedScores[1].0
        default:
            return sortedScores[2].0
        }
    }
    
    func addFJCorrect(index: Int) {
        var amount = Int(self.wagers[index]) ?? 0
        if self.fjCorrects[index] {
            amount = -amount
            self.editScore(index: index, pointValueInt: amount)
        } else {
            self.editScore(index: index, pointValueInt: amount)
        }
        self.fjCorrects[index].toggle()
    }
    
    func addFJIncorrect(index: Int) {
        var amount = Int(self.wagers[index]) ?? 0
        if self.toSubtracts[index] {
            self.editScore(index: index, pointValueInt: amount)
        } else {
            amount = -amount
            self.editScore(index: index, pointValueInt: amount)
        }
        self.toSubtracts[index].toggle()
    }
}

struct Team: Hashable, Identifiable, Decodable, Encodable {
    static func == (lhs: Team, rhs: Team) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var index: Int
    var name: String
    var members: [String]
    var score: Int
    var color: String
    
    init(id: String = "", index: Int = 0, name: String = "", members: [String] = [], score: Int = 0, color: String = "Blue") {
        self.id = id == "" ? UUID().uuidString : id
        self.index = index
        self.name = name
        self.members = members
        self.score = score
        self.color = color
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    mutating func editName(name: String) {
        self.name = name
    }
    
    mutating func editIndex(index: Int) {
        self.index = index
    }
    
    mutating func editScore(amount: Int) {
        self.score += amount
    }
    
    mutating func addMember(name: String) {
        self.members.append(name)
    }
    
    mutating func removeMember(name: String) {
        self.members = self.members.filter { $0 != name }
    }
    
    mutating func editColor(color: String) {
        self.color = color
    }
    
    mutating func getNextMember() {
        let firstMember = members.removeFirst()
        self.members.append(firstMember)
    }
    
    mutating func setIndex(index: Int) {
        self.index = index
    }
}
