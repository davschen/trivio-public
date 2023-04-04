//
//  AnswerView.swift
//  Trivio
//
//  Created by David Chen on 2/4/21.
//

import Foundation
import SwiftUI
import AVFoundation

struct ClueView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var wager: Double = 0
    @State var ddWagerMade = false
    @State var isTutorialAnimating = false
    
    var body: some View {
        if gamesVM.currentSelectedClue.isWVC && !ddWagerMade {
            DuplexWagerView(ddWagerMade: $ddWagerMade, wager: $wager) 
        } else {
            DraggableClueResponseView(wager: $wager, ddWagerMade: $ddWagerMade)
                .transition(AnyTransition.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.2))
            if !profileVM.myUserRecords.hasShownSwipeToDismissClue {
                ClueDismissTutorialView()
            }
        }
    }
}

struct DraggableClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var wager: Double
    @Binding var ddWagerMade: Bool
    
    @State var yOffset: CGFloat = 0
    @State var hapticWillTrigger = true
    @State var showResponse = false
    @State var teamCorrect = Team()
    
    var body: some View {
        ZStack (alignment: .topLeading) {
            HStack {
                Image(systemName: "arrow.left")
                    .font(formatter.iconFont(.small))
                Text("Back to the board")
                    .font(formatter.font())
            }
            .opacity(hapticWillTrigger ? (yOffset / 50) : 1)
            ClueResponseView(wager: $wager, showResponse: $showResponse, teamCorrect: $teamCorrect, progressGame: progressGame)
                .offset(y: yOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gamesVM.currentSelectedClue.isWVC {
                                return
                            }
                            if gesture.translation.height > 0 {
                                yOffset = log2(gesture.translation.height * 7000)
                            }
                            if yOffset >= 20 && hapticWillTrigger {
                                formatter.hapticFeedback(style: .soft, intensity: .strong)
                                formatter.stopSpeaker()
                                hapticWillTrigger.toggle()
                            }
                        }
                        .onEnded({ _ in
                            if yOffset > 20 {
                                progressGame()
                            }
                            yOffset = 0
                            hapticWillTrigger = true
                        })
                )
        }
    }
    
    func progressGame() {
        formatter.stopSpeaker()
        gamesVM.gameplayDisplay = .grid
        if !teamCorrect.id.isEmpty {
            participantsVM.addSolved()
        }
        if gamesVM.doneWithRound() {
            if gamesVM.gamePhase == .round1 && gamesVM.customSet.hasTwoRounds {
                gamesVM.moveOntoRound2()
                participantsVM.changeDJTeam()
            } else {
                gamesVM.gamePhase = .finalRound
            }
        }
        if !profileVM.myUserRecords.hasShownHeldClueCell {
            formatter.setAlertSettings(alertAction: {
                profileVM.updateMyUserRecords(fieldName: "hasShownHeldClueCell", newValue: true)
                profileVM.myUserRecords.hasShownHeldClueCell = true
            }, alertType: .tip, alertTitle: "Some advice", alertSubtitle: "If you'd like to bring back a clue, just hold down on the empty grid cell for a few seconds", hasCancel: false, actionLabel: "Got it")
        }
        participantsVM.progressGame(gameHasTwoRounds: gamesVM.customSet.hasTwoRounds)
        showResponse = false
        ddWagerMade = false
        wager = 0
        teamCorrect = Team()
    }
}

struct ClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var wager: Double
    @Binding var showResponse: Bool
    @Binding var teamCorrect: Team
    
    @State var timeElapsed: Double = 0
    @State var usedBlocks = [Int]()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var progressGame: () -> Void
    
    private var clueAppearance: ClueAppearance {
        return ClueAppearance(rawValue: UserDefaults.standard.string(forKey: "clueAppearance") ?? "modern") ?? .modern
    }
    
    var body: some View {
        ClassicClueResponseView(wager: $wager, showResponse: $showResponse, teamCorrect: $teamCorrect, usedBlocks: $usedBlocks, timeElapsed: $timeElapsed, progressGame: progressGame)
            .onReceive(timer) { time in
                if !formatter.speaker.isSpeaking
                    && timeElapsed < gamesVM.clueMechanics.numCountdownSeconds {
                    timeElapsed += 1
                    let elapsed = gamesVM.getCountdown(second: Int(timeElapsed))
                    usedBlocks.append(contentsOf: [elapsed.upper, elapsed.lower])
                }
            }
    }
}

struct ClassicClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var wager: Double
    @Binding var showResponse: Bool
    @Binding var teamCorrect: Team
    @Binding var usedBlocks: [Int]
    @Binding var timeElapsed: Double
    
    var progressGame: () -> Void
    
    var body: some View {
        VStack (spacing: 15) {
            ClueCountdownTimerView(usedBlocks: $usedBlocks)
                .padding(.top, 5)
            VStack (alignment: .leading, spacing: 0) {
                ZStack {
                    VStack (alignment: .center, spacing: 5) {
                        if gamesVM.currentSelectedClue.isWVC {
                            Text("\(gamesVM.currentSelectedClue.categoryString.uppercased()) (Wager-value clue)")
                            Text("\(participantsVM.selectedTeam.name)'s wager: \(String(format: "%.0f", wager))")
                                .font(formatter.font(.regularItalic, fontSize: .mediumLarge))
                        } else {
                            Text("\(gamesVM.currentSelectedClue.categoryString.uppercased()) for \(gamesVM.currentSelectedClue.pointValueInt)")
                        }
                    }
                    HStack {
                        Spacer()
                        Button {
                            progressGame()
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                    }
                }
                .font(formatter.font(.bold, fontSize: .mediumLarge))
                .id(gamesVM.currentSelectedClue.categoryString)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(30)
                Spacer(minLength: 15)
                VStack {
                    Text(gamesVM.currentSelectedClue.clueString.uppercased())
                        .font(formatter.font(.bold, fontSize: .large))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .id(gamesVM.currentSelectedClue.clueString)
                        .lineSpacing(5)
                        .padding(.horizontal, 45)
                        .padding(.bottom, showResponse ? 5 : 0)
                    if showResponse {
                        Text(gamesVM.currentSelectedClue.responseString.uppercased())
                            .font(formatter.font(.bold, fontSize: .large))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .foregroundColor(formatter.color(.secondaryAccent))
                            .id(gamesVM.currentSelectedClue.responseString)
                            .padding(.horizontal, 45)
                    }
                }
                Spacer(minLength: 0)
                HStack (alignment: .bottom) {
                    if gamesVM.currentSelectedClue.isWVC {
                        if participantsVM.teams.count > 0 && showResponse {
                            DailyTrivioGraderView(wager: $wager) {
                                progressGame()
                            }
                        }
                    } else if showResponse {
                        CorrectSelectorView(teamCorrect: $teamCorrect, pointValueInt: gamesVM.currentSelectedClue.pointValueInt)
                            .transition(.slide)
                    }
                    Button {
                        formatter.hapticFeedback(style: .light, intensity: .normal)
                        formatter.stopSpeaker()
                        showResponse.toggle()
                    } label: {
                        Text(showResponse ? "Hide Response" : "Show Response")
                            .font(formatter.font(fontSize: .regular))
                            .foregroundColor(formatter.color(showResponse ? .primaryBG : .highContrastWhite))
                            .padding(25)
                            .frame(maxWidth: 250)
                            .background(showResponse ? formatter.color(.highContrastWhite) : nil)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(formatter.color(.highContrastWhite), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical)
            }
            .background(formatter.color(timeElapsed == gamesVM.clueMechanics.numCountdownSeconds ? .primaryFG : .primaryAccent))
            .cornerRadius(20)
        }
    }
}

struct ClueCountdownTimerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var usedBlocks: [Int]
    
    var body: some View {
        // Countdown timer blocks
        HStack (spacing: 4) {
            ForEach(0..<9) { i in
                Rectangle()
                    .foregroundColor(formatter.color(self.usedBlocks.contains(i + 1) ? .primaryFG : .secondaryAccent))
                    .frame(maxWidth: .infinity)
                    .frame(height: 15)
            }
        }
        .clipShape(Capsule())
    }
}

struct DailyTrivioGraderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var wager: Double
    
    var progressGame: () -> Void
    
    var body: some View {
        VStack (spacing: 0) {
            Text("\(participantsVM.selectedTeam.name)")
                .font(formatter.font())
                .padding(.horizontal)
                .padding(.top, 5)
                .frame(height: 40)
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 2)
            HStack (spacing: 0) {
                // Xmark button
                Button(action: {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    let teamIndex = participantsVM.selectedTeam.index
                    participantsVM.editScore(index: teamIndex, pointValueInt: Int(-wager))
                    progressGame()
                }, label: {
                    Image(systemName: "xmark")
                        .font(formatter.iconFont(.small))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(formatter.color(.red))
                        .background(formatter.color(.lowContrastWhite))
                })
                
                Rectangle()
                    .frame(maxHeight: .infinity)
                    .frame(width: 2)
                
                // Checkmark button
                Button(action: {
                    let teamIndex = participantsVM.selectedTeam.index
                    participantsVM.editScore(index: teamIndex, pointValueInt: Int(wager))
                    progressGame()
                }, label: {
                    Image(systemName: "checkmark")
                        .font(formatter.iconFont(.small))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(formatter.color(.green))
                        .background(formatter.color(.lowContrastWhite))
                })
            }
        }
        .cornerRadius(10)
        .frame(height: 80)
        .frame(maxWidth: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .inset(by: 1)
                .stroke(formatter.color(.highContrastWhite), lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct CorrectSelectorView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @Binding var teamCorrect: Team
    
    var pointValueInt: Int
    
    var body: some View {
        ScrollView (.horizontal, showsIndicators: false) {
            HStack (spacing: 5) {
                Spacer(minLength: 10)
                ForEach(participantsVM.teams) { team in
                    IndividualCorrectSelectorView(teamCorrect: $teamCorrect, team: team, pointValueInt: pointValueInt)
                }
                Spacer(minLength: 10)
            }
        }
    }
}

struct IndividualCorrectSelectorView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @Binding var teamCorrect: Team
    
    let team: Team
    var pointValueInt: Int
    
    var body: some View {
        VStack (spacing: 0) {
            Text("\(team.name)")
                .font(formatter.font())
                .padding(.horizontal)
                .padding(.top, 5)
                .frame(height: 50)
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 2)
            HStack (spacing: 0) {
                // Xmark button
                Button(action: {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    if team == teamCorrect {
                        teamCorrect = Team(index: 0, name: "", members: [], score: 0, color: "")
                        self.participantsVM.editScore(index: team.index, pointValueInt: -pointValueInt)
                    }
                    self.participantsVM.toSubtracts[team.index].toggle()
                    let pointValueInt = self.participantsVM.toSubtracts[team.index] ? -self.pointValueInt : self.pointValueInt
                    self.participantsVM.editScore(index: team.index, pointValueInt: pointValueInt)
                }, label: {
                    Image(systemName: "xmark")
                        .font(formatter.iconFont(.small))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(formatter.color(.red).opacity(self.participantsVM.toSubtracts[team.index] ? 1 : 0))
                        .background(formatter.color(.lowContrastWhite))
                })
                
                Rectangle()
                    .frame(maxHeight: .infinity)
                    .frame(width: 2)
                
                // Checkmark button
                Button(action: {
                    markCorrect(teamIndex: team.index)
                }, label: {
                    Image(systemName: "checkmark")
                        .font(formatter.iconFont(.small))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(formatter.color(.green).opacity(team == teamCorrect ? 1 : 0))
                        .background(formatter.color(.lowContrastWhite))
                })
            }
        }
        .cornerRadius(10)
        .frame(width: 150, height: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .inset(by: 1)
                .stroke(formatter.color(.highContrastWhite), lineWidth: 2)
        )
    }
    
    // I am very proud of this logic, but it belongs in ParticipantsVM
    func markCorrect(teamIndex: Int) {
        formatter.hapticFeedback(style: .heavy)
        let team = participantsVM.teams[teamIndex]
        participantsVM.resetToLastIncrement(pointValueInt: pointValueInt)
        // if the contestant is marked wrong, unmark them wrong
        if participantsVM.toSubtracts[team.index] {
            participantsVM.toSubtracts[team.index].toggle()
            participantsVM.editScore(index: team.index, pointValueInt: pointValueInt)
        }
        if team == teamCorrect {
            // reset teamCorrect
            teamCorrect = Team(index: 0, name: "", members: [], score: 0, color: "")
            participantsVM.setSelectedTeam(index: participantsVM.defaultIndex)
        } else {
            participantsVM.editScore(index: team.index, pointValueInt: pointValueInt)
            teamCorrect = team
            participantsVM.setSelectedTeam(index: team.index)
        }
    }
}

struct ClueDismissTutorialView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var isTutorialAnimating = false
    
    var body: some View {
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.8)
            VStack (spacing: 30) {
                Image(systemName: "hand.point.up.fill")
                    .font(.system(size: 80))
                    .offset(y: isTutorialAnimating ? 100 : 0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false))
                    .padding(.bottom, 100)
                Text("Swipe down to go back to the board")
                    .font(formatter.font(fontSize: .mediumLarge))
                    .frame(width: 300)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                Button {
                    isTutorialAnimating = false
                    profileVM.myUserRecords.hasShownSwipeToDismissClue.toggle()
                    profileVM.updateMyUserRecords(fieldName: "hasShownSwipeToDismissClue", newValue: true)
                } label: {
                    Text("Got it")
                        .foregroundColor(formatter.color(.primaryBG))
                        .frame(maxWidth: 200)
                        .padding(20)
                        .background(formatter.color(.highContrastWhite))
                        .clipShape(Capsule())
                        .padding(.horizontal)
                }
            }
        }
        .onAppear {
            isTutorialAnimating = true
        }
    }
}

