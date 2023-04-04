//
//  MobileLiveGameBoardView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 4/4/23.
//

import Foundation
import SwiftUI

struct MobileLiveGameBoardView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var liveGameOnRound1: Bool {
        return gamesVM.liveGameCustomSet.currentRound == "round1"
    }
    
    var body: some View {
        VStack (spacing: 0) {
            // Horizontal arrangement of category names
            HStack (spacing: 3) {
                ForEach(0..<(liveGameOnRound1 ? gamesVM.liveGameCustomSet.round1Len : gamesVM.liveGameCustomSet.round2Len), id: \.self) { categoryIndex in
                    let categoryName: String = liveGameOnRound1 ? gamesVM.liveGameCustomSet.round1CategoryNames[categoryIndex] : gamesVM.tidyCustomSet.round2Cats[categoryIndex]
                    ZStack {
                        formatter.color(gamesVM.finishedCategories[categoryIndex] ? .primaryFG : .primaryAccent)
                        Text(categoryName.uppercased())
                            .font(formatter.font(.bold, fontSize: .small))
                            .foregroundColor(formatter.color(.highContrastWhite))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.1)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .opacity(gamesVM.finishedCategories[categoryIndex] ? 0 : 1)
                    }
                    .frame(maxWidth: 100, maxHeight: 65)
                    .cornerRadius(5.8)
                }
            }
            .padding(.bottom, 5)

            // Clues grid
            HStack (spacing: 3) {
                ForEach(0..<(liveGameOnRound1 ? gamesVM.liveGameCustomSet.round1Len : gamesVM.liveGameCustomSet.round2Len), id: \.self) { categoryIndex in
                    VStack (spacing: 3) {
                        ForEach(0..<gamesVM.pointValueArray.count, id: \.self) { clueIndex in
                            MobileLiveGameBoardCellView(categoryIndex: categoryIndex, clueIndex: clueIndex)
                                .frame(maxWidth: 100, maxHeight: .infinity)
                                .shadow(color: Color.black.opacity(0.2), radius: 10)
                                .onTapGesture {
                                    gameCellTapped(categoryIndex: categoryIndex, clueIndex: clueIndex)
                                }
                                .onLongPressGesture {
                                    gamesVM.modifyFinishedClues2D(categoryIndex: categoryIndex, clueIndex: clueIndex, completed: false)
                                }
                        }
                    }
                }
            }
        }
    }
    
    func gameCellTapped(categoryIndex: Int, clueIndex: Int) {
        if gamesVM.finishedClues2D[categoryIndex][clueIndex] == .incomplete {
            formatter.hapticFeedback(style: .rigid)
            
            gamesVM.setLiveCurrentSelectedClue(categoryIndex: categoryIndex, clueIndex: clueIndex)
            
            if !Clue(liveGameCustomSet: gamesVM.liveGameCustomSet).isWVC {
                formatter.speaker.speak(gamesVM.currentSelectedClue.clueString)
            }
        }
    }
}

struct MobileLiveGameBoardCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    let categoryIndex: Int
    let clueIndex: Int
    
    var currentlyPlayingJeopardySet: Bool {
        return gamesVM.customSet.userID.isEmpty
    }
    
    var body: some View {
        ZStack {
            formatter.color(isIncomplete() ? .primaryAccent : .primaryFG)
            Text("\(gamesVM.pointValueArray[clueIndex])")
                .font(formatter.fontFloat(.bold, sizeFloat: 25))
                .foregroundColor(formatter.color(.secondaryAccent))
                .shadow(color: currentlyPlayingJeopardySet ? .black : .black.opacity(0.2), radius: currentlyPlayingJeopardySet ? 0 : 5, x: 1, y: 2)
                .multilineTextAlignment(.center)
                .opacity(isIncomplete() ? 1 : 0)
                .minimumScaleFactor(0.5)
        }
        .cornerRadius(5.8)
    }
    
    func isIncomplete() -> Bool {
        let liveGameOnRound1 = gamesVM.liveGameCustomSet.currentRound == "round1"
        let numCategories = liveGameOnRound1 ? gamesVM.liveGameCustomSet.round1Len : gamesVM.liveGameCustomSet.round2Len
        if categoryIndex >= numCategories {
            return false
        }
        return gamesVM.finishedClues2D[categoryIndex][clueIndex] == .incomplete
    }
}
