//
//  MobileLiveClueView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 4/4/23.
//

import Foundation
import SwiftUI

struct MobileLiveClueView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    var body: some View {
        MobileLiveClueResponseView(progressGame: progressGame)
            .transition(AnyTransition.move(edge: .bottom))
            .animation(.easeInOut(duration: 0.2))
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

struct MobileLiveDuplexWagerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var questionIsSelected = false
    
    var maxScore: Int {
        return gamesVM.gamePhase == .round1 ? 1000 : 2000
    }
    
    var body: some View {
        VStack (spacing: 15) {
            VStack {
                Spacer()
                VStack (spacing: 10) {
                    Text(gamesVM.currentSelectedClue.categoryString.uppercased())
                        .font(formatter.font(fontSize: .medium))
                    Text("WAGER-VALUED CLUE")
                        .font(formatter.fontFloat(sizeFloat: 35))
                        .frame(maxWidth: .infinity)
                    Text("Waiting for \(gamesVM.liveGamePlayers.first(where: { $0.id == gamesVM.liveGameCustomSet.currentPlayerId } )?.nickname ?? "NULL") to enter a wager...")
                        .font(formatter.font(.regular))
                }
                .padding(25)
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(formatter.color(.primaryAccent))
        .cornerRadius(10)
    }
}

struct MobileLiveClueResponseView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var gamesVM: GamesViewModel

    @State var hasWaited = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var progressGame: () -> Void
    var isDisplayingLandscapeMode: Bool = false
    
    private var currentLiveClue: Clue {
        return Clue(liveGameCustomSet: gamesVM.liveGameCustomSet)
    }
    
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
                    MobileLiveClueHeaderView()
                    VStack {
                        Text(currentLiveClue.clueString.uppercased())
                            .font(formatter.korinnaFont(sizeFloat: currentLiveClue.clueString.count > 150 ? 15 : 20))
                            .shadow(color: formatter.color(.primaryBG), radius: 0, x: 1, y: 2)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .id(gamesVM.currentSelectedClue.clueString)
                            .lineSpacing(5)
                            .padding(.bottom, gamesVM.clueMechanics.showResponse ? 5 : 0)
                        if LiveGameDisplay(from: gamesVM.liveGameCustomSet.currentGameDisplay) == .response {
                            Text(currentLiveClue.responseString.uppercased())
                                .font(formatter.korinnaFont(sizeFloat: 20))
                                .shadow(color: formatter.color(.primaryBG), radius: 0, x: 1, y: 2)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .foregroundColor(formatter.color(gamesVM.currentSelectedClue.isTripleStumper ? .red : .secondaryAccent))
                                .id(gamesVM.currentSelectedClue.responseString)
                                .padding(.top, 10)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding([.horizontal, .bottom])
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

struct MobileLiveClueHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var isSpeakerMuted = false
    
    private var currentLiveClue: Clue {
        return Clue(liveGameCustomSet: gamesVM.liveGameCustomSet)
    }
    
    var body: some View {
        ZStack {
            VStack (alignment: .center, spacing: 5) {
                if gamesVM.currentSelectedClue.isWVC {
                    Text("\(currentLiveClue.categoryString.uppercased())")
                    Text("\(gamesVM.liveGamePlayers.first(where: { $0.id == gamesVM.liveGameCustomSet.currentPlayerId})?.nickname ?? "NULL")'s wager: \(String(format: "%.0f", gamesVM.clueMechanics.wvcWager))")
                        .font(formatter.font(.regularItalic, fontSize: .regular))
                        .padding(.top, 2)
                } else {
                    Text("\(currentLiveClue.categoryString.uppercased())")
                    Text("for \(currentLiveClue.pointValueInt)")
                }
            }
            .frame(maxWidth: 200)
            HStack {
                Button {
                    formatter.speaker.toggleNarrationOn()
                    formatter.stopSpeaker()
                    isSpeakerMuted.toggle()
                } label: {
                    Image(systemName: isSpeakerMuted ? "speaker.slash" : "speaker.wave.3")
                        .font(.system(size: 20))
                }
                Spacer()
                Button {
                    formatter.stopSpeaker()
                } label: {
                    Image(systemName: gamesVM.liveGameCustomSet.buzzersEnabled ? "rectangle.portrait.fill" : "rectangle.portrait.slash.fill")
                        .font(.system(size: 20))
                        .opacity(gamesVM.currentSelectedClue.isWVC ? 0.4 : 1)
                        .foregroundColor(formatter.color(.red))
                }
                .disabled(gamesVM.currentSelectedClue.isWVC)
            }
        }
        .font(formatter.font(.bold, fontSize: .regular))
        .id(currentLiveClue.categoryString)
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
