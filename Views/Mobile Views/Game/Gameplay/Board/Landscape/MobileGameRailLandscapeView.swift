//
//  MobileGameBoardLandscapeView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/23/23.
//

import Foundation
import SwiftUI
import MovingNumbersView

struct MobileGameRailLandscapeView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var showInfoView: Bool
    @Binding var currOrientation: UIInterfaceOrientationMask
    
    var body: some View {
        VStack {
            MobileGameplayHeaderLandscapeView(showInfoView: $showInfoView, currOrientation: $currOrientation)
            if gamesVM.clueMechanics.wvcWagerMade {
                Spacer()
                MobileDailyTrivioGraderView(progressGame: progressGame)
                    .padding(.top)
                    .opacity(gamesVM.clueMechanics.showResponse ? 1 : 0)
            } else {
                MobileGameplayPlayersLandscapeView()
                    .padding(.top)
            }
            if gamesVM.gameplayDisplay == .clue {
                MobileGameplayRailLandscapeShowResponseButtonView()
            }
        }
        .padding([.top, .trailing])
        .frame(minWidth: 250, maxWidth: 280)
    }
    
    func progressGame() {
        formatter.stopSpeaker()
        gamesVM.progressGame()
        participantsVM.progressGame(gameHasTwoRounds: gamesVM.customSet.hasTwoRounds)
        rotateBackToPortrait()
    }
    
    func rotateBackToPortrait() {
        if gamesVM.doneWithRound() {
            if gamesVM.customSet.hasTwoRounds && gamesVM.gamePhase == .round1 { return }
            AppDelegate.orientationLock = .portrait
            UINavigationController.attemptRotationToDeviceOrientation()
            currOrientation = .portrait
        }
    }
}

struct MobileGameplayHeaderLandscapeView: View {
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
                    AppDelegate.orientationLock = .portrait
                    UINavigationController.attemptRotationToDeviceOrientation()
                    currOrientation = .portrait
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
                    AppDelegate.orientationLock = .portrait
                    UINavigationController.attemptRotationToDeviceOrientation()
                    currOrientation = .portrait
                } label: {
                    Image(systemName: "iphone")
                        .font(.system(size: 20))
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
                        // For example, 26/30
                        Text("\(gamesVM.getNumCompletedClues())/\(cluesInRound) completed")
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

struct MobileGameplayPlayersLandscapeView: View {
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var body: some View {
        // Contestants HStack
        if participantsVM.teams.count > 0 {
            ScrollView (.vertical, showsIndicators: false) {
                VStack (spacing: 5) {
                    ForEach(participantsVM.teams) { team in
                        MobileIndividualPlayerLandscapeView(team: team)
                            .padding(1)
                    }
                }
            }
        }
    }
}

struct MobileIndividualPlayerLandscapeView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    let team: Team
    
    var body: some View {
        VStack (spacing: 0) {
            Spacer(minLength: 0)
            Text("\(team.name)")
                .offset(y: 1)
                .font(formatter.font(fontSize: participantsVM.teams.count > 3 ? .regular : .medium))
                .foregroundColor(formatter.color(.highContrastWhite))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .padding(.horizontal, 7)
            Spacer(minLength: 0)
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 2)
                .foregroundColor(ColorMap().getColor(color: team.color))
            ZStack {
                if gamesVM.clueMechanics.showResponse {
                    HStack (spacing: 0) {
                        Button(action: {
                            formatter.hapticFeedback(style: .soft, intensity: .strong)
                            participantsVM.didTapXmark(teamIndex: team.index, pointValueInt: gamesVM.currentSelectedClue.pointValueInt)
                        }, label: {
                            Image(systemName: "xmark")
                                .offset(y: -1)
                                .padding(.trailing, 10)
                                .font(formatter.iconFont(.small))
                                .foregroundColor(formatter.color(.highContrastWhite))
                                .frame(maxWidth: 80, maxHeight: .infinity)
                                .background(formatter.color(participantsVM.toSubtracts[team.index] ? .red : .secondaryFG))
                        })
                        Spacer()
                        // Checkmark button
                        Button(action: {
                            formatter.hapticFeedback(style: .heavy)
                            participantsVM.didTapCheckmark(teamIndex: team.index, pointValueInt: gamesVM.currentSelectedClue.pointValueInt)
                        }, label: {
                            Image(systemName: "checkmark")
                                .offset(y: -2)
                                .padding(.leading, 10)
                                .font(formatter.iconFont(.small))
                                .foregroundColor(formatter.color(.highContrastWhite))
                                .frame(maxWidth: 80, maxHeight: .infinity)
                                .background(formatter.color(team == participantsVM.teamCorrect ? .green : .secondaryFG))
                        })
                    }
                }
                Group {
                    MovingNumbersView(
                        number: Double(participantsVM.teams[team.index].score),
                        numberOfDecimalPlaces: 0) { str in
                            Text(str)
                                .frame(height: 35)
                        }
                }
                .frame(width: 130)
                .background(formatter.color(.primaryFG))
                .cornerRadius(7)
            }
            .font(formatter.font(fontSize: .semiLarge))
            .foregroundColor(formatter.color(participantsVM.teams[team.index].score < 0 ? .red : .highContrastWhite))
            .frame(maxWidth: .infinity)
            .frame(height: 35)
            .background(formatter.color(.primaryFG))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 70)
        .background(formatter.color(.primaryAccent))
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(formatter.color(.highContrastWhite), lineWidth: participantsVM.selectedTeam == team ? 2 : 0)
        )
        .cornerRadius(10)
        .onTapGesture {
            if !(participantsVM.selectedTeam == team) {
                participantsVM.setSelectedTeam(index: team.index)
            }
        }
        .onAppear {
            if !participantsVM.teams.contains(participantsVM.selectedTeam) {
                participantsVM.setSelectedTeam(index: 0)
            }
        }
    }
}

struct MobileGameplayRailLandscapeShowResponseButtonView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var shouldDisplayWVCButton: Bool {
        return gamesVM.currentSelectedClue.isWVC && !gamesVM.clueMechanics.wvcWagerMade
    }
    
    var variableButtonText: String {
        if shouldDisplayWVCButton {
            return "Show me the clue"
        } else {
            return gamesVM.clueMechanics.showResponse ? "Hide Response" : "Show Response"
        }
    }
    
    var body: some View {
        Button {
            if shouldDisplayWVCButton {
                formatter.hapticFeedback(style: .soft, intensity: .strong)
                gamesVM.clueMechanics.toggleWVCWagerMade()
                formatter.speaker.speak(gamesVM.currentSelectedClue.clueString)
            } else {
                formatter.hapticFeedback(style: .light, intensity: .normal)
                formatter.stopSpeaker()
                gamesVM.clueMechanics.setTimeElapsed(newValue: 6)
                gamesVM.clueMechanics.toggleShowResponse()
            }
        } label: {
            Text("\(variableButtonText)")
                .foregroundColor(formatter.color(gamesVM.clueMechanics.showResponse ? .primaryBG : .highContrastWhite))
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(formatter.color(gamesVM.clueMechanics.showResponse ? .highContrastWhite : .primaryBG))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(formatter.color(.highContrastWhite), lineWidth: 1))
        }
    }
}
