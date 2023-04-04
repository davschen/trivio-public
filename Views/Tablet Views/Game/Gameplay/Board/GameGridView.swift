//
//  GameGridView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI

struct GameGridView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var body: some View {
        VStack (spacing: 7) {
            // Horizontal arrangement of category names
            HStack (spacing: 5) {
                ForEach(0..<(gamesVM.gamePhase == .round1 ? gamesVM.tidyCustomSet.round1Cats.count : gamesVM.tidyCustomSet.round2Cats.count), id: \.self) { i in
                    let category: String = gamesVM.gamePhase == .round1 ? gamesVM.tidyCustomSet.round1Cats[i] : gamesVM.tidyCustomSet.round2Cats[i]
                    
                    ZStack {
                        formatter.color(gamesVM.finishedCategories[i] ? .primaryFG : .primaryAccent)
                        Text(category.uppercased())
                            .font(formatter.fontFloat(sizeFloat: 20))
                            .foregroundColor(formatter.color(.highContrastWhite))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.1)
                            .padding(15)
                            .frame(maxWidth: .infinity)
                            .opacity(gamesVM.finishedCategories[i] ? 0 : 1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 130)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 25)

            // Clues grid
            HStack (spacing: 5) {
                ForEach(gamesVM.categories.indices, id: \.self) { categoryIndex in
                    VStack (spacing: 5) {
                        ForEach(0..<gamesVM.pointValueArray.count, id: \.self) { clueIndex in
                            GameCellView(categoryIndex: categoryIndex, clueIndex: clueIndex)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .padding(.horizontal, 25)
        }
    }
    
    func gameCellTapped(categoryIndex: Int, clueIndex: Int) {
        if gamesVM.finishedClues2D[categoryIndex][clueIndex] == .incomplete {
            formatter.hapticFeedback(style: .rigid)
            gamesVM.setCurrentSelectedClue(categoryIndex: categoryIndex, clueIndex: clueIndex)
            participantsVM.setDefaultIndex()
            
            if !gamesVM.currentSelectedClue.isWVC {
                formatter.speaker.speak(gamesVM.currentSelectedClue.clueString)
            }
        }
    }
}

struct GameCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    let categoryIndex: Int
    let clueIndex: Int
    
    var body: some View {
        ZStack {
            formatter.color(isIncomplete() ? .primaryAccent : .primaryFG)
            Text("\(gamesVM.pointValueArray[clueIndex])")
                .font(formatter.fontFloat(.bold, sizeFloat: 50))
                .foregroundColor(formatter.color(.secondaryAccent))
                .shadow(color: Color.black.opacity(0.2), radius: 5)
                .multilineTextAlignment(.center)
                .opacity(isIncomplete() ? 1 : 0)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .padding(15)
        }
        .cornerRadius(10)
    }
    
    func isIncomplete() -> Bool {
        if categoryIndex >= gamesVM.finishedClues2D.count {
            return false
        }
        if clueIndex >= gamesVM.finishedClues2D[categoryIndex].count {
            return false
        }
        return gamesVM.finishedClues2D[categoryIndex][clueIndex] == .incomplete
    }
}

