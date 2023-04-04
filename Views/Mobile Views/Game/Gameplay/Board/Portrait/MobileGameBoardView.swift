//
//  MobileGameBoardView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileGameBoardView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var showInfoView = false
    @State var currOrientation: UIInterfaceOrientationMask = .portrait
    
    var body: some View {
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
            if currOrientation == .portrait {
                VStack (spacing: 10) {
                    MobileGameplayHeaderView(showInfoView: $showInfoView, currOrientation: $currOrientation)
                        .padding(.horizontal)
                    MobileGamePlayersView()
                        .padding(.horizontal)
                    MobileGameplayGridView(showInfoView: $showInfoView)
                }
            } else {
                HStack (spacing: 15) {
                    MobileGameDisplayLandscapeView(showInfoView: $showInfoView)
                    MobileGameRailLandscapeView(showInfoView: $showInfoView, currOrientation: $currOrientation)
                }
                .edgesIgnoringSafeArea(.trailing)
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden()
        .animation(.easeInOut(duration: 0.2))
    }
}

struct MobileGameplayGridView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var showInfoView: Bool
    
    var body: some View {
        ZStack {
            ZStack {
                if gamesVM.gamePhase == .finalRound && gamesVM.finalTrivioStage != .notBegun {
                    MobileFinalTrivioView()
                        .padding(.horizontal)
                } else {
                    MobileGameGridView()
                        .opacity(gamesVM.gameplayDisplay == .grid ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2))
                    if gamesVM.gameplayDisplay == .clue {
                        MobileClueView()
                            .padding(.horizontal)
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

struct MobileGameplayHeaderView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @Binding var showInfoView: Bool
    @Binding var currOrientation: UIInterfaceOrientationMask
    
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
                        .font(.system(size: 20))
                }
                Text("\(headerString)")
                    .font(formatter.fontFloat(.bold, sizeFloat: 24))
                    .lineLimit(1)
                    .offset(y: 1)
                Spacer()
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    AppDelegate.orientationLock = .landscapeRight
                    UINavigationController.attemptRotationToDeviceOrientation()
                    currOrientation = .landscapeRight
                } label: {
                    Image(systemName: "iphone.landscape")
                        .font(.system(size: 30, weight: .light))
                }
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    showInfoView.toggle()
                } label: {
                    Image(systemName: showInfoView ? "info.circle.fill" : "info.circle")
                        .font(.system(size: 20))
                }
            }
            // Progress bar
            if gamesVM.gamePhase == .round1 || gamesVM.gamePhase == .round2 {
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
                        Text("Progress: \(gamesVM.getNumCompletedClues()) of \(cluesInRound) clues completed")
                            .font(formatter.font(.regularItalic, fontSize: .small))
                        Spacer()
                        Button {
                            if gamesVM.gamePhase == .round1 && gamesVM.customSet.hasTwoRounds {
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

struct MobileContinueToFinalTrivioView: View {
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
