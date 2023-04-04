//
//  MobileClueView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI
import AVFoundation

struct MobileClueView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var isTutorialAnimating = false
    @State var showResponse = false
    
    var body: some View {
        if gamesVM.currentSelectedClue.isWVC && !gamesVM.clueMechanics.wvcWagerMade {
            MobileDuplexWagerView()
        } else {
            MobileDraggableClueResponseView()
                .transition(AnyTransition.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.2))
            if !profileVM.myUserRecords.hasShownSwipeToDismissClue {
                MobileClueDismissTutorialView()
            }
        }
    }
}

struct MobileDraggableClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var yOffset: CGFloat = 0
    @State var hapticWillTrigger = true
    
    var isDisplayingLandscapeMode: Bool = false
    
    var body: some View {
        ZStack (alignment: .topLeading) {
            HStack {
                Image(systemName: "arrow.left")
                    .font(formatter.iconFont(.small))
                    .rotationEffect(Angle.degrees(180))
                Text("Back to the board")
                    .font(formatter.font())
            }
            .opacity(hapticWillTrigger ? (yOffset / 50) : 1)
            MobileClueResponseView(progressGame: progressGame, isDisplayingLandscapeMode: isDisplayingLandscapeMode)
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
        gamesVM.progressGame()
        if !profileVM.myUserRecords.hasShownHeldClueCell {
            formatter.setAlertSettings(alertAction: {
                profileVM.updateMyUserRecords(fieldName: "hasShownHeldClueCell", newValue: true)
                profileVM.myUserRecords.hasShownHeldClueCell = true
            }, alertType: .tip, alertTitle: "Some advice", alertSubtitle: "If you'd like to bring back a clue, just hold down on the empty grid cell for a few seconds", hasCancel: false, actionLabel: "Got it")
        }
        participantsVM.progressGame(gameHasTwoRounds: gamesVM.customSet.hasTwoRounds)
    }
}

struct MobileClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var gamesVM: GamesViewModel

    @State var hasWaited = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var progressGame: () -> Void
    var isDisplayingLandscapeMode: Bool = false
    
    private var clueAppearance: ClueAppearance {
        return ClueAppearance(rawValue: UserDefaults.standard.string(forKey: "clueAppearance") ?? "classic") ?? .classic
    }
    private var readingSpeedFloat: Double {
        return Double(100 * (UserDefaults.standard.value(forKey: "speechSpeed") as? Float ?? 0.5) / 2)
    }
    
    var body: some View {
        ZStack {
            VStack {
                MobileClueCountdownTimerView(timeElapsed: $gamesVM.clueMechanics.timeElapsed)
                VStack (alignment: .leading, spacing: 0) {
                    MobileClueHeaderView(progressGame: progressGame)
                    if clueAppearance == .modern {
                        MobileModernClueResponseView()
                    } else {
                        MobileClassicClueResponseView()
                            .padding(.bottom, 10)
                    }
                    if !isDisplayingLandscapeMode {
                        MobileClueRevealedSubView(progressGame: progressGame)
                    }
                }
                .background(formatter.color(gamesVM.clueMechanics.timeElapsed >= gamesVM.clueMechanics.numCountdownSeconds ? .primaryFG : .primaryAccent))
                .cornerRadius(10)
            }
        }
        .onReceive(timer) { time in
            let timeElapsed = gamesVM.clueMechanics.timeElapsed
            if timeElapsed > gamesVM.clueMechanics.numCountdownSeconds {
                timer.upstream.connect().cancel()
            } else if (formatter.speaker.volume == 0) && !hasWaited {
                let secondsToWait = Double(gamesVM.currentSelectedClue.clueString.count) / readingSpeedFloat
                if gamesVM.clueMechanics.timeElapsed < -secondsToWait {
                    gamesVM.clueMechanics.setTimeElapsed(newValue: 0)
                    hasWaited = true
                } else {
                    gamesVM.clueMechanics.setTimeElapsed(newValue: timeElapsed - 1)
                }
            } else if !formatter.speaker.isSpeaking && timeElapsed < gamesVM.clueMechanics.numCountdownSeconds {
                gamesVM.clueMechanics.setTimeElapsed(newValue: timeElapsed + 1)
            }
        }
    }
}

struct MobileModernClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var body: some View {
        VStack (spacing: 20) {
            Text(gamesVM.currentSelectedClue.clueString)
                .lineSpacing(5)
                .font(formatter.font(.regular, fontSize: .semiLarge))
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            if gamesVM.clueMechanics.showResponse {
                Text(gamesVM.currentSelectedClue.responseString.capitalized)
                    .font(formatter.font(.regular, fontSize: .semiLarge))
                    .foregroundColor(formatter.color(gamesVM.currentSelectedClue.isTripleStumper ? .red : .secondaryAccent))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                if gamesVM.currentSelectedClue.isTripleStumper {
                    Text("(Triple Stumper)")
                        .font(formatter.font(.regular, fontSize: .medium))
                        .foregroundColor(formatter.color(.red))
                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

struct MobileClassicClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var body: some View {
        VStack {
            Text(gamesVM.currentSelectedClue.clueString.uppercased())
                .font(formatter.korinnaFont(sizeFloat: 20))
                .shadow(color: formatter.color(.primaryBG), radius: 0, x: 1, y: 2)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .id(gamesVM.currentSelectedClue.clueString)
                .lineSpacing(5)
                .padding(.bottom, gamesVM.clueMechanics.showResponse ? 5 : 0)
            if gamesVM.clueMechanics.showResponse {
                Text(gamesVM.currentSelectedClue.responseString.uppercased())
                    .font(formatter.korinnaFont(sizeFloat: 20))
                    .shadow(color: formatter.color(.primaryBG), radius: 0, x: 1, y: 2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .foregroundColor(formatter.color(gamesVM.currentSelectedClue.isTripleStumper ? .red : .secondaryAccent))
                    .id(gamesVM.currentSelectedClue.responseString)
                if gamesVM.currentSelectedClue.isTripleStumper {
                    Text("(Triple Stumper)")
                        .font(formatter.korinnaFont(sizeFloat: 20))
                        .foregroundColor(formatter.color(.red))
                        .shadow(color: formatter.color(.primaryBG), radius: 0, x: 1, y: 2)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding([.horizontal, .bottom])
    }
}

struct MobileClueRevealedSubView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var progressGame: () -> Void
    
    var body: some View {
        VStack {
            if gamesVM.currentSelectedClue.isWVC {
                if participantsVM.teams.count > 0 && gamesVM.clueMechanics.showResponse {
                    MobileDailyTrivioGraderView(progressGame: progressGame)
                        .padding(.horizontal)
                }
            } else if gamesVM.clueMechanics.showResponse {
                MobileCorrectSelectorView(pointValueInt: gamesVM.currentSelectedClue.pointValueInt)
                    .transition(.opacity)
            }
            Button {
                formatter.hapticFeedback(style: .light, intensity: .normal)
                formatter.stopSpeaker()
                gamesVM.clueMechanics.setTimeElapsed(newValue: 6)
                gamesVM.clueMechanics.toggleShowResponse()
            } label: {
                VStack (spacing: 0) {
                    Rectangle()
                        .foregroundColor(formatter.color(.highContrastWhite))
                        .frame(maxWidth: .infinity, maxHeight: 1)
                    Text(gamesVM.clueMechanics.showResponse ? "Hide Response" : "Show Response")
                        .font(formatter.font(fontSize: .medium))
                        .foregroundColor(formatter.color(gamesVM.clueMechanics.showResponse ? .primaryBG : .highContrastWhite))
                        .padding(.vertical, 25)
                        .frame(maxWidth: .infinity)
                        .background(gamesVM.clueMechanics.showResponse ? formatter.color(.highContrastWhite) : nil)
                }
            }
            .padding(.top, 10)
        }
    }
}

struct MobileClueHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var isSpeakerMuted = false
    
    var progressGame: () -> Void
    
    var body: some View {
        ZStack {
            VStack (alignment: .center, spacing: 5) {
                if gamesVM.currentSelectedClue.isWVC {
                    Text("\(gamesVM.currentSelectedClue.categoryString.uppercased())")
                    Text("\(participantsVM.selectedTeam.name)'s wager: \(String(format: "%.0f", gamesVM.clueMechanics.wvcWager))")
                        .font(formatter.font(.regularItalic, fontSize: .regular))
                        .padding(.top, 2)
                } else {
                    Text("\(gamesVM.currentSelectedClue.categoryString.uppercased())")
                    Text("for \(gamesVM.currentSelectedClue.pointValueInt)")
                }
            }
            .frame(maxWidth: 200)
            HStack {
                Button {
                    formatter.stopSpeaker()
                    progressGame()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20))
                        .opacity(gamesVM.currentSelectedClue.isWVC ? 0.4 : 1)
                }
                .disabled(gamesVM.currentSelectedClue.isWVC)
                Spacer()
                Button {
                    formatter.speaker.toggleNarrationOn()
                    formatter.stopSpeaker()
                    isSpeakerMuted.toggle()
                } label: {
                    Image(systemName: isSpeakerMuted ? "speaker.slash" : "speaker.wave.3")
                        .font(.system(size: 20))
                }
            }
        }
        .font(formatter.font(.bold, fontSize: .regular))
        .id(gamesVM.currentSelectedClue.categoryString)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding([.horizontal, .vertical])
        .padding(.top, 5)
        .onAppear {
            if formatter.speaker.volume == 0 {
                isSpeakerMuted = true
            }
        }
    }
}

struct MobileClueCountdownTimerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var timeElapsed: Double
    
    var body: some View {
        // Countdown timer blocks
        HStack (spacing: 2) {
            ForEach(0..<9) { i in
                Rectangle()
                    .foregroundColor(formatter.color(gamesVM.timerBlockIsUnlit(timeElapsed: timeElapsed, blockIndex: i) ? .primaryFG : .secondaryAccent))
                    .frame(maxWidth: .infinity)
                    .frame(height: 7)
            }
        }
        .clipShape(Capsule())
    }
}

struct MobileDailyTrivioGraderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var gamesVM: GamesViewModel

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
                .frame(height: 1)
                .padding(.horizontal, 0.2)
            HStack (spacing: 0) {
                // Xmark button
                Button(action: {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    let teamIndex = participantsVM.selectedTeam.index
                    participantsVM.editScore(index: teamIndex, pointValueInt: Int(-gamesVM.clueMechanics.wvcWager))
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
                    .frame(width: 1)
                
                // Checkmark button
                Button(action: {
                    let teamIndex = participantsVM.selectedTeam.index
                    participantsVM.editScore(index: teamIndex, pointValueInt: Int(gamesVM.clueMechanics.wvcWager))
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
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .inset(by: 1)
                .stroke(formatter.color(.highContrastWhite), lineWidth: 1)
        )
    }
}

struct MobileCorrectSelectorView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var pointValueInt: Int
    
    var body: some View {
        if participantsVM.teams.count > 3 {
            ScrollView (.horizontal, showsIndicators: false) {
                HStack (spacing: 5) {
                    Spacer(minLength: 10)
                    ForEach(participantsVM.teams) { team in
                        MobileIndividualCorrectSelectorView(team: team, pointValueInt: pointValueInt)
                            .frame(width: 120)
                    }
                    Spacer(minLength: 10)
                }
            }
        } else {
            HStack (spacing: 5) {
                ForEach(participantsVM.teams) { team in
                    MobileIndividualCorrectSelectorView(team: team, pointValueInt: pointValueInt)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MobileIndividualCorrectSelectorView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    let team: Team
    
    var pointValueInt: Int
    
    var body: some View {
        VStack (spacing: 0) {
            Text("\(team.name)")
                .font(formatter.font())
                .padding(.horizontal)
                .padding(.top, 5)
                .frame(height: 40)
                .multilineTextAlignment(.center)
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .padding(.horizontal, 0.2)
            HStack (spacing: 0) {
                // Xmark button
                Button(action: {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    participantsVM.didTapXmark(teamIndex: team.index, pointValueInt: pointValueInt)
                }, label: {
                    Image(systemName: "xmark")
                        .font(formatter.iconFont(.small))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(formatter.color(.red).opacity(self.participantsVM.toSubtracts[team.index] ? 1 : 0))
                        .background(formatter.color(.lowContrastWhite))
                })
                
                Rectangle()
                    .frame(maxHeight: .infinity)
                    .frame(width: 1)
                
                // Checkmark button
                Button(action: {
                    formatter.hapticFeedback(style: .heavy)
                    participantsVM.didTapCheckmark(
                        teamIndex: team.index,
                        pointValueInt: pointValueInt
                    )
                }, label: {
                    Image(systemName: "checkmark")
                        .font(formatter.iconFont(.small))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(formatter.color(.green).opacity(team == participantsVM.teamCorrect ? 1 : 0))
                        .background(formatter.color(.lowContrastWhite))
                    // AECOM is giving lunch out for lunar new year
                    // Everyone who went is Camille's age or a little older
                    // Bosh -> 7 months. 1 year older than Camille
                    //  Nice guy, introduced
                    // Very similar to B&M, has more international
                })
            }
        }
        .cornerRadius(10)
        .frame(maxWidth: .infinity, maxHeight: 80)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .inset(by: 1)
                .stroke(formatter.color(.highContrastWhite), lineWidth: 1)
        )
    }
}

// Deprecated in Version Cherry
struct MobileVolumeControlView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var showingVolumeSlider: Bool
    
    var speakerIconName: String {
        if formatter.volume > 0 && formatter.volume <= 0.33 {
            return "speaker.1.fill"
        } else if formatter.volume > 0.33 && formatter.volume <= 0.66 {
            return "speaker.2.fill"
        } else if formatter.volume > 0.66 {
            return "speaker.3.fill"
        } else {
            return "speaker.slash.fill"
        }
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: speakerIconName)
                    .font(formatter.iconFont(.small))
                if showingVolumeSlider {
                    Slider(value: Binding(get: {
                        formatter.volume
                    }, set: { (newVal) in
                        formatter.volume = newVal
                        formatter.setVolume()
                    }))
                    .accentColor(formatter.color(.secondaryAccent))
                    .foregroundColor(formatter.color(.mediumContrastWhite))
                }
                Spacer()
            }
            .frame(width: 200)
            .frame(alignment: .leading)
            .onTapGesture {
                showingVolumeSlider.toggle()
            }
            if showingVolumeSlider {
                Text("Effective next clue")
                    .font(formatter.font(fontSize: .small))
            }
        }
    }
}

struct MobileClueDismissTutorialView: View {
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
                        .frame(maxWidth: .infinity)
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

