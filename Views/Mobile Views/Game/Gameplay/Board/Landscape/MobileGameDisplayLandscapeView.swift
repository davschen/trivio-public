//
//  MobileGameGridLandscapeView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/23/23.
//

import Foundation
import SwiftUI

struct MobileGameDisplayLandscapeView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @Binding var showInfoView: Bool
    
    var body: some View {
        ZStack {
            ZStack {
                if gamesVM.gamePhase == .finalRound && gamesVM.finalTrivioStage != .notBegun {
                    MobileFinalTrivioView()
                        .padding(.horizontal)
                } else {
                    MobileGameGridLandscapeView(showInfoView: $showInfoView)
                        .opacity(gamesVM.gameplayDisplay == .grid ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2))
                    if gamesVM.gameplayDisplay == .clue {
                        MobileClueLandscapeView()
                            .padding(.top)
                    }
                    if gamesVM.gamePhase == .finalRound && gamesVM.finalTrivioStage == .notBegun {
                        MobileContinueToFinalTrivioView()
                    }
                }
            }
            MobileGameInfoView(showInfoView: $showInfoView)
        }
    }
}

struct MobileGameGridLandscapeView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @Binding var showInfoView: Bool
    
    var currentlyPlayingJeopardySet: Bool {
        return gamesVM.customSet.userID.isEmpty
    }
    
    var body: some View {
        VStack (spacing: 0) {
            // Horizontal arrangement of category names
            HStack (spacing: 3) {
                ForEach(0..<(gamesVM.gamePhase == .round1 ? gamesVM.tidyCustomSet.round1Cats.count : gamesVM.tidyCustomSet.round2Cats.count), id: \.self) { i in
                    let category: String = gamesVM.gamePhase == .round1 ? gamesVM.tidyCustomSet.round1Cats[i] : gamesVM.tidyCustomSet.round2Cats[i]
                    
                    ZStack {
                        formatter.color(gamesVM.finishedCategories[i] ? .primaryFG : .primaryAccent)
                        Text(category.uppercased())
                            .font(currentlyPlayingJeopardySet ? formatter.swiss911Font(sizeFloat: 14) : formatter.font(.bold, fontSize: .small))
                            .shadow(color: currentlyPlayingJeopardySet ? .black : .clear, radius: 0, x: 1, y: 2)
                            .foregroundColor(formatter.color(.highContrastWhite))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.1)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .opacity(gamesVM.finishedCategories[i] ? 0 : 1)
                    }
                    .frame(maxWidth: 100, maxHeight: 65)
                    .cornerRadius(5.8)
                }
            }
            .padding(.bottom, 5)

            // Clues grid
            HStack (spacing: 3) {
                ForEach(gamesVM.categories.indices, id: \.self) { categoryIndex in
                    VStack (spacing: 3) {
                        ForEach(0..<gamesVM.pointValueArray.count, id: \.self) { clueIndex in
                            MobileGameCellLandscapeView(categoryIndex: categoryIndex, clueIndex: clueIndex)
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
        .padding(.top)
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

struct MobileClueLandscapeView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var isTutorialAnimating = false
    
    var body: some View {
        if gamesVM.currentSelectedClue.isWVC && !gamesVM.clueMechanics.wvcWagerMade {
            MobileDuplexWagerView(isDisplayingLandscapeMode: true)
        } else {
            MobileDraggableClueResponseView(isDisplayingLandscapeMode: true)
                .transition(AnyTransition.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.2))
            if !profileVM.myUserRecords.hasShownSwipeToDismissClue {
                MobileClueDismissTutorialView()
            }
        }
    }
}

struct MobileGameCellLandscapeView: View {
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
                .font(currentlyPlayingJeopardySet ? formatter.swiss911Font(sizeFloat: 30) : formatter.fontFloat(.bold, sizeFloat: 30))
                .foregroundColor(formatter.color(.secondaryAccent))
                .shadow(color: currentlyPlayingJeopardySet ? .black : .black.opacity(0.2), radius: currentlyPlayingJeopardySet ? 0 : 5, x: 1, y: 2)
                .multilineTextAlignment(.center)
                .opacity(isIncomplete() ? 1 : 0)
                .minimumScaleFactor(0.5)
        }
        .cornerRadius(5.8)
    }
    
    func isIncomplete() -> Bool {
        if categoryIndex >= gamesVM.categories.count {
            return false
        }
        return gamesVM.finishedClues2D[categoryIndex][clueIndex] == .incomplete
    }
}
