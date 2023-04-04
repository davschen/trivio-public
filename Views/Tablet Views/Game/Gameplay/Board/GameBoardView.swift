//
//  GameBoardView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var showInfoView = false
    
    var body: some View {
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
            VStack (spacing: 10) {
                GameplayHeaderView(showInfoView: $showInfoView)
                    .padding(.horizontal, 25)
                GamePlayersView()
                    .padding(.horizontal, 25)
                GameplayGridView(showInfoView: $showInfoView)
            }
            .padding(.bottom, 15)
        }
        .animation(.easeInOut(duration: 0.2))
    }
}

struct GameplayGridView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var showInfoView: Bool
    
    var body: some View {
        ZStack {
            ZStack {
                if gamesVM.gamePhase == .finalRound && gamesVM.finalTrivioStage != .notBegun {
                    FinalTrivioView()
                        .padding(.horizontal, 25)
                } else {
                    GameGridView()
                        .opacity(gamesVM.gameplayDisplay == .grid ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2))
                    if gamesVM.gameplayDisplay == .clue {
                        ClueView()
                            .padding(.horizontal, 25)
                    }
                    if gamesVM.gamePhase == .finalRound && gamesVM.finalTrivioStage == .notBegun {
                        ContinueToFinalTrivioView()
                    }
                }
            }
            // Funky, but not having it crashed the app so
            GameInfoView(showInfoView: $showInfoView)
                .environmentObject(formatter)
                .environmentObject(exploreVM)
                .environmentObject(gamesVM)
        }
    }
}

struct GameplayHeaderView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @Binding var showInfoView: Bool
    
    var headerString: String {
        switch gamesVM.gamePhase {
        case .round1:
            return "Round 1"
        case .round2:
            return "Round 2"
        default:
            return "Final Clue"
        }
    }
    
    var cluesInRound: Int {
        return gamesVM.gamePhase == .round1 ? gamesVM.jRoundCompletes : gamesVM.djRoundCompletes
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            HStack (spacing: 7) {
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    presentationMode.wrappedValue.dismiss()
                    gamesVM.gameSetupMode = .settings
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22))
                }
                Text("\(headerString)")
                    .font(formatter.fontFloat(.bold, sizeFloat: 30))
                    .lineLimit(1)
                    .offset(y: 1)
                Spacer()
                Button {
                    if gamesVM.gamePhase == .round1 && gamesVM.customSet.hasTwoRounds {
                        gamesVM.moveOntoRound2()
                        gamesVM.gameplayDisplay = .grid
                    } else {
                        gamesVM.gamePhase = .finalRound
                        gamesVM.finalTrivioStage = .makeWager
                    }
                } label: {
                    Text("Skip Round")
                        .font(formatter.font(.regularItalic, fontSize: .small))
                        .padding()
                        .frame(maxHeight: 25)
                        .background(formatter.color(.primaryFG))
                        .clipShape(Capsule())
                }
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    showInfoView.toggle()
                } label: {
                    Image(systemName: showInfoView ? "info.circle.fill" : "info.circle")
                        .font(.system(size: 22))
                }
            }
            .padding(.top)
            if gamesVM.finalTrivioStage == .submitAnswer {
                FinalTrivioCountdownTimerView()
            }
        }
    }
}

struct ContinueToFinalTrivioView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var finalTrivioLoading = false
    
    var body: some View {
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.7)
            HStack {
                Button(action: {
                    formatter.hapticFeedback(style: .light, intensity: .strong)
                    gamesVM.finalTrivioStage = .makeWager
                }, label: {
                    HStack (spacing: 15) {
                        Text("On to Final Clue")
                        Image(systemName: "arrow.right.circle.fill")
                            .font(formatter.iconFont(.mediumLarge))
                            .offset(x: finalTrivioLoading ? 15 : 0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true))
                    }
                    .font(formatter.font(fontSize: .medium))
                    .foregroundColor(formatter.color(.primaryFG))
                    .multilineTextAlignment(.center)
                    .padding()
                    .padding(.horizontal)
                })
            }
            .background(formatter.color(.highContrastWhite))
            .clipShape(Capsule())
            .onAppear {
                finalTrivioLoading = true
            }
        }
    }
}
