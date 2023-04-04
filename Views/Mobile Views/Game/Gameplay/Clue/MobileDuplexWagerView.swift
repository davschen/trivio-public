//
//  MobileDuplexWagerView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileDuplexWagerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var questionIsSelected = false
    
    var isDisplayingLandscapeMode: Bool = false
    
    var maxScore: Int {
        return gamesVM.gamePhase == .round1 ? 1000 : 2000
    }
    
    var body: some View {
        VStack (spacing: 15) {
            VStack {
                Spacer()
                    .frame(height: 5)
                VStack (spacing: 10) {
                    Text(gamesVM.currentSelectedClue.categoryString.uppercased())
                        .font(formatter.font(fontSize: .medium))
                    Text("WAGER-VALUED CLUE")
                        .font(formatter.fontFloat(sizeFloat: 22))
                        .frame(maxWidth: .infinity)
                }
                .padding(25)
                Spacer()
                    .frame(height: 30)
                HStack {
                    Text("\(participantsVM.teams[participantsVM.selectedTeam.index].name), make a wager:")
                    Spacer()
                    Text("\(Int(gamesVM.clueMechanics.wvcWager))")
                }
                .font(formatter.fontFloat(.regular, sizeFloat: 18))
                VStack {
                    Slider(value: $gamesVM.clueMechanics.wvcWager, in: 0...Double(max(maxScore, participantsVM.teams.indices.contains(participantsVM.selectedTeam.index) ? participantsVM.teams[participantsVM.selectedTeam.index].score : 0)), step: 100)
                        .accentColor(formatter.color(.secondaryAccent))
                        .foregroundColor(formatter.color(.mediumContrastWhite))
                }
                if (gamesVM.clueMechanics.wvcWager == 0) {
                    ScrollView (showsIndicators: false) {
                        Text("""
                        Select a wager using the slider above. Game show rules apply to wager amounts. The number you choose will either be added or subtracted from your score, depending on if you get it right.

                        When you tap the button at the bottom of the screen, a question will appear. Only the contestant highlighted (\(participantsVM.teams[participantsVM.selectedTeam.index].name)) may answer. If the answer given is correct, reward \(participantsVM.teams[participantsVM.selectedTeam.index].name) the points. If the answer given is incorrect, subtract the points. When finished, tap anywhere to proceed.
                        """)
                            .font(formatter.font(.regularItalic, fontSize: .regular))
                            .lineSpacing(2)
                            .padding(.top, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal)
            if !isDisplayingLandscapeMode {
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    gamesVM.clueMechanics.toggleWVCWagerMade()
                    formatter.speaker.speak(gamesVM.currentSelectedClue.clueString)
                } label: {
                    VStack (spacing: 0) {
                        Rectangle()
                            .foregroundColor(formatter.color(.highContrastWhite))
                            .frame(maxWidth: .infinity, maxHeight: 1)
                        Text("Show me the clue")
                            .font(formatter.font(fontSize: .medium))
                            .foregroundColor(formatter.color(.highContrastWhite))
                            .padding(.vertical, 25)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(formatter.color(.primaryAccent))
        .cornerRadius(10)
    }
}

