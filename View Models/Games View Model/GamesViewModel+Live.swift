//
//  GamesViewModel+Live.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/17/22.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension GamesViewModel {
    public func startLiveGame(hostUsername: String, hostName: String) {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        createLiveGameDocument(hostUsername: hostUsername, hostName: hostName)
        listenToLiveGameDocument(liveGameCustomSetId: myUID)
        listenToLiveGamePlayers(liveGameCustomSetId: myUID)
    }
    
    public func createLiveGameDocument(hostUsername: String, hostName: String) {
        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
        guard let customSetID = self.customSet.id else { return }
        let hostCode = String(randomNumberWith(digits: 6))
        let playerCode = String(randomNumberWith(digits: 6))
        self.liveGameCustomSet = LiveGameCustomSet(hostUsername: hostUsername, hostName: hostName, userSetId: customSetID, hostCode: hostCode, playerCode: playerCode, tidyCustomSet: self.tidyCustomSet, customSet: self.customSet)
        // the document ID is myUID because I don't want one user to be making multiple live games
        do {
            try self.db.collection("liveGames").document(myUID).setData(from: self.liveGameCustomSet)
        } catch let error {
            print("Error writing live game custom set: \(error.localizedDescription)")
        }
    }

    public func randomNumberWith(digits:Int) -> Int {
        let min = Int(pow(Double(10), Double(digits-1))) - 1
        let max = Int(pow(Double(10), Double(digits))) - 1
        return Int(Range(uncheckedBounds: (min, max)))
    }
    
    func listenToLiveGameDocument(liveGameCustomSetId: String) {
        let liveGameRef = db.collection("liveGames").document(liveGameCustomSetId)

        listener = liveGameRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error listening for live game document updates: \(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot {
                self.liveGameCustomSet = try! snapshot.data(as: LiveGameCustomSet.self)!
            }
        }
    }
    
    func listenToLiveGamePlayers(liveGameCustomSetId: String) {
        let playersRef = db.collection("liveGames")
            .document(liveGameCustomSetId)
            .collection("players")
            .order(by: "currentScore", descending: true)

        listener = playersRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error listening for live game players updates: \(error.localizedDescription)")
                return
            }

            self.liveGamePlayers = snapshot?.documents.compactMap { document in
                return try? document.data(as: LiveGamePlayer.self)
            } ?? []
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func setLiveCurrentSelectedClue(categoryIndex: Int, clueIndex: Int) {
        liveGameCustomSet.currentCategoryIndex = categoryIndex
        liveGameCustomSet.currentClueIndex = clueIndex
        liveGameCustomSet.currentGameDisplay = "clue"
        
        modifyFinishedClues2D(categoryIndex: categoryIndex, clueIndex: clueIndex)
        currentCategoryIndex = categoryIndex
    }

    func getRandomIncompleteClue() -> (categoryIndex: Int, clueIndex: Int)? {
        var n = 0
        var selected: (categoryIndex: Int, clueIndex: Int)? = nil
        
        for categoryIndex in 0..<finishedClues2D.count {
            for clueIndex in 0..<finishedClues2D[categoryIndex].count {
                if finishedClues2D[categoryIndex][clueIndex] == .incomplete {
                    n += 1
                    if Int.random(in: 0..<n) == 0 {
                        selected = (categoryIndex, clueIndex)
                    }
                }
            }
        }
        return selected
    }
    
    func updateLiveGameCustomSet() {
        guard let liveGameCustomSetID = self.liveGameCustomSet.id else {
            print("Error: liveGameCustomSet ID not found")
            return
        }

        let documentReference = db.collection("liveGames").document(liveGameCustomSetID)

        do {
            let data = try Firestore.Encoder().encode(liveGameCustomSet)
            documentReference.updateData(data) { error in
                if let error = error {
                    print("Error updating liveGameCustomSet: \(error)")
                } else {
                    print("liveGameCustomSet successfully updated")
                }
            }
        } catch let error {
            print("Error encoding liveGameCustomSet: \(error)")
        }
    }
}

// Flow so I can get this shit out of my head and onto a screen:
/// iOS User creates this live game doc by tapping on "Host this game live!" in Gameplay : MobileGameSettingsView
///     This live game doc contains all the information anyone with low-level privileges will ever need to read or write to
/// When web user on desktop joins with hostCode, hostHasJoined = true
///     All web users have the same permissions upon visiting www.trivio.live, namely read and write access to the "liveGames" collection
/// If hostHasJoined, mobile web users can add themselves to "players" collection by entering playerCode
///
