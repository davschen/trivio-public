//
//  MobileLiveGameSideRailView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 4/4/23.
//

import Foundation
import SwiftUI

struct MobileLiveGameSideRailView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var variableButtonLabel: String {
        switch LiveGameDisplay(from: gamesVM.liveGameCustomSet.currentGameDisplay) {
        case .clue: return "Show Response"
        case .response: return "Back to the Board"
        case .preWVC: return "Show the Clue"
        case .preFinalClue: return "Show Final Clue"
        case .finalClue: return "Show Response"
        case .finalResponse: return "Finish Game"
        default: return "Pick Random Clue"
        }
    }
    
    func variableButtonAction() {
        var newLiveGameDisplay = ""
        
        switch LiveGameDisplay(from: gamesVM.liveGameCustomSet.currentGameDisplay) {
        case .clue: newLiveGameDisplay = "response"
        case .response: newLiveGameDisplay = "board"
        case .preWVC: newLiveGameDisplay = "clue"
        case .preFinalClue: newLiveGameDisplay = "finalClue"
        case .finalClue: newLiveGameDisplay = "finalResponse"
        case .finalResponse: newLiveGameDisplay = "response"
        default:
            if let randomClueCoords = gamesVM.getRandomIncompleteClue() {
                gamesVM.setLiveCurrentSelectedClue(categoryIndex: randomClueCoords.categoryIndex, clueIndex: randomClueCoords.clueIndex)
                newLiveGameDisplay = "clue"
            }
        }

        gamesVM.liveGameCustomSet.currentGameDisplay = newLiveGameDisplay
    }
    
    var body: some View {
        VStack (spacing: 20) {
            MobileLiveGameSideRailHeaderView()
            VStack (alignment: .leading, spacing: 0) {
                Text("Leaderboard")
                    .font(formatter.font(fontSize: .medium))
                    .padding(.bottom, 10)
                Rectangle()
                    .frame(maxWidth: .infinity, maxHeight: 1)
                    .foregroundColor(formatter.color(.highContrastWhite))
                ScrollView {
                    ForEach(gamesVM.liveGamePlayers, id: \.self) { player in
                        VStack (spacing: 10) {
                            HStack (spacing: 5) {
                                Text("\(player.nickname)")
                                Circle()
                                    .frame(width: 4, height: 4)
                                    .opacity(gamesVM.liveGameCustomSet.currentPlayerId == player.id ? 1 : 0)
                                Spacer()
                                Text("\(player.currentScore)")
                                    .font(formatter.font(.regular))
                            }
                            Rectangle()
                                .frame(maxWidth: .infinity, maxHeight: 1)
                                .foregroundColor(formatter.color(.highContrastWhite))
                        }
                        .padding(.top, 10)
                        .font(formatter.font(fontSize: .regular))
                    }
                }
            }
            Button {
                variableButtonAction()
            } label: {
                Text("\(variableButtonLabel)")
                    .font(formatter.font(fontSize: .regular))
                    .foregroundColor(formatter.color(.primaryBG))
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(formatter.color(.highContrastWhite))
                    .cornerRadius(10)
            }
        }
        .frame(width: 230)
    }
}

struct MobileLiveGameSideRailHeaderView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var headerString: String {
        switch gamesVM.liveGameCustomSet.currentRound {
        case "round1":
            return "Round 1"
        case "round2":
            return gamesVM.liveGameCustomSet.hasTwoRounds ? "Round 2" : "Final Clue"
        default:
            return "Final Clue"
        }
    }
    
    var cluesInRound: Int {
        return gamesVM.liveGameCustomSet.currentRound == "round1" ? gamesVM.jRoundCompletes : gamesVM.djRoundCompletes
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            HStack (spacing: 7) {
                Text("\(headerString)")
                    .font(formatter.fontFloat(.bold, sizeFloat: 24))
                    .lineLimit(1)
                    .offset(y: 1)
                Spacer(minLength: 0)
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    presentationMode.wrappedValue.dismiss()
                    gamesVM.gameSetupMode = .settings
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                }
            }
            // Progress bar
            let noProgressBarDisplays: [LiveGameDisplay] = [.preFinalClue, .finalClue, .finalStats, .finalResponse]
            if !noProgressBarDisplays.contains(LiveGameDisplay(from: gamesVM.liveGameCustomSet.currentGameDisplay) ?? .board) {
                VStack (spacing: 7) {
                    GeometryReader { geometry in
                        ZStack (alignment: .leading) {
                            Capsule()
                                .frame(width: geometry.size.width, height: 10)
                                .foregroundColor(formatter.color(.primaryFG))
                            Capsule()
                                .frame(width: (CGFloat(gamesVM.getNumCompletedClues()) / CGFloat(cluesInRound)) * geometry.size.width, height: 10)
                                .foregroundColor(formatter.color(.primaryAccent))
                        }
                    }
                    // Must specify frame height b/c using geometryReader
                    .frame(height: 10)
                    HStack {
                        // For example, 26/30
                        Text("\(gamesVM.getNumCompletedClues())/\(cluesInRound) completed")
                            .font(formatter.font(.regularItalic, fontSize: .small))
                        Spacer()
                        Button {
                            if gamesVM.gamePhase == .round1 && gamesVM.liveGameCustomSet.hasTwoRounds {
                                gamesVM.moveOntoRound2()
                                gamesVM.gameplayDisplay = .grid
                            } else {
                                gamesVM.finalTrivioStage = .makeWager
                                gamesVM.gamePhase = .finalRound
                            }
                        } label: {
                            Text("Skip round")
                                .font(formatter.font(.boldItalic, fontSize: .small))
                        }
                    }
                }
            } else if gamesVM.finalTrivioStage == .submitAnswer {
                MobileFinalTrivioCountdownTimerView()
            }
        }
    }
}

